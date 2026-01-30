import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Check, X, ExternalLink, Calendar, User, Store, Pencil, Trash2, Plus } from "lucide-react";
import { useAuth } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { useToast } from "@/hooks/use-toast";
import { formatDistanceToNow } from "date-fns";
import { pl } from "date-fns/locale";
import type { Tables } from "@/integrations/supabase/types";

type ShopLink = Tables<"shops_links"> & {
  profile?: { display_name: string | null; email: string } | null;
};

const typeLabels: Record<string, string> = {
  sklep: "Sklep",
  usluga: "Usługa",
  katalog: "Katalog",
};

const statusLabels: Record<string, string> = {
  pending: "Oczekujące",
  approved: "Zatwierdzone",
  rejected: "Odrzucone",
};

export function ShopsApproval() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState("pending");
  
  // Edit dialog state
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [editingShop, setEditingShop] = useState<ShopLink | null>(null);
  const [editForm, setEditForm] = useState({
    title: "",
    url: "",
    type: "sklep" as "sklep" | "usluga" | "katalog",
    country: "PL",
    status: "pending" as "pending" | "approved" | "rejected",
  });
  
  // Delete dialog state
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [shopToDelete, setShopToDelete] = useState<ShopLink | null>(null);
  
  // Add new shop dialog state
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [addForm, setAddForm] = useState({
    title: "",
    url: "",
    type: "sklep" as "sklep" | "usluga" | "katalog",
    country: "PL",
    status: "approved" as "pending" | "approved" | "rejected",
  });
  
  const { user } = useAuth();

  const fetchShops = async (status: "pending" | "approved" | "rejected") => {
    const { data: shops, error } = await supabase
      .from("shops_links")
      .select("*")
      .eq("status", status)
      .order("created_at", { ascending: false });

    if (error) throw error;
    if (!shops || shops.length === 0) return [];

    const userIds = shops.map(s => s.user_id);
    
    let profilesMap: Record<string, { display_name: string | null; email: string }> = {};
    
    if (userIds.length > 0) {
      const { data: profiles } = await supabase
        .from("profiles")
        .select("id, display_name, email")
        .in("id", userIds);
      
      if (profiles) {
        profilesMap = profiles.reduce((acc, p) => {
          acc[p.id] = { display_name: p.display_name, email: p.email };
          return acc;
        }, {} as typeof profilesMap);
      }
    }

    return shops.map(shop => ({
      ...shop,
      profile: profilesMap[shop.user_id] || null,
    })) as ShopLink[];
  };

  const { data: pendingShops, isLoading: pendingLoading } = useQuery({
    queryKey: ["admin-shops", "pending"],
    queryFn: () => fetchShops("pending"),
  });

  const { data: approvedShops, isLoading: approvedLoading } = useQuery({
    queryKey: ["admin-shops", "approved"],
    queryFn: () => fetchShops("approved"),
  });

  const { data: rejectedShops, isLoading: rejectedLoading } = useQuery({
    queryKey: ["admin-shops", "rejected"],
    queryFn: () => fetchShops("rejected"),
  });

  const updateStatus = useMutation({
    mutationFn: async ({ id, status }: { id: string; status: "approved" | "rejected" }) => {
      const { error } = await supabase
        .from("shops_links")
        .update({ status })
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["admin-shops"] });
      toast({
        title: variables.status === "approved" ? "Sklep zatwierdzony" : "Sklep odrzucony",
        description: variables.status === "approved" 
          ? "Link do sklepu jest teraz widoczny publicznie."
          : "Link do sklepu został odrzucony.",
      });
      setProcessingId(null);
    },
    onError: (error: any) => {
      toast({
        title: "Błąd",
        description: error.message || "Nie udało się zaktualizować sklepu.",
        variant: "destructive",
      });
      setProcessingId(null);
    },
  });

  const updateShop = useMutation({
    mutationFn: async (data: { id: string; title: string; url: string; type: string; country: string; status: string }) => {
      const { error } = await supabase
        .from("shops_links")
        .update({
          title: data.title,
          url: data.url,
          type: data.type as "sklep" | "usluga" | "katalog",
          country: data.country,
          status: data.status as "pending" | "approved" | "rejected",
        })
        .eq("id", data.id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-shops"] });
      toast({
        title: "Zapisano",
        description: "Link został zaktualizowany.",
      });
      setIsEditDialogOpen(false);
      setEditingShop(null);
    },
    onError: (error: any) => {
      toast({
        title: "Błąd",
        description: error.message || "Nie udało się zapisać zmian.",
        variant: "destructive",
      });
    },
  });

  const deleteShop = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("shops_links")
        .delete()
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-shops"] });
      toast({
        title: "Usunięto",
        description: "Link został usunięty.",
      });
      setDeleteDialogOpen(false);
      setShopToDelete(null);
    },
    onError: (error: any) => {
      toast({
        title: "Błąd",
        description: error.message || "Nie udało się usunąć linku.",
        variant: "destructive",
      });
    },
  });

  const addShop = useMutation({
    mutationFn: async (data: { title: string; url: string; type: string; country: string; status: string }) => {
      if (!user) throw new Error("Musisz być zalogowany");
      
      const { error } = await supabase
        .from("shops_links")
        .insert({
          title: data.title,
          url: data.url,
          type: data.type as "sklep" | "usluga" | "katalog",
          country: data.country,
          status: data.status as "pending" | "approved" | "rejected",
          user_id: user.id,
        });

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-shops"] });
      toast({
        title: "Dodano",
        description: "Nowy link został dodany.",
      });
      setIsAddDialogOpen(false);
      setAddForm({
        title: "",
        url: "",
        type: "sklep",
        country: "PL",
        status: "approved",
      });
    },
    onError: (error: any) => {
      toast({
        title: "Błąd",
        description: error.message || "Nie udało się dodać linku.",
        variant: "destructive",
      });
    },
  });

  const handleApprove = (id: string) => {
    setProcessingId(id);
    updateStatus.mutate({ id, status: "approved" });
  };

  const handleReject = (id: string) => {
    setProcessingId(id);
    updateStatus.mutate({ id, status: "rejected" });
  };

  const openEditDialog = (shop: ShopLink) => {
    setEditingShop(shop);
    setEditForm({
      title: shop.title,
      url: shop.url,
      type: shop.type,
      country: shop.country || "PL",
      status: shop.status,
    });
    setIsEditDialogOpen(true);
  };

  const handleSaveEdit = () => {
    if (!editingShop) return;
    updateShop.mutate({
      id: editingShop.id,
      ...editForm,
    });
  };

  const openDeleteDialog = (shop: ShopLink) => {
    setShopToDelete(shop);
    setDeleteDialogOpen(true);
  };

  const handleDelete = () => {
    if (!shopToDelete) return;
    deleteShop.mutate(shopToDelete.id);
  };

  const handleAddShop = () => {
    addShop.mutate(addForm);
  };

  const openAddDialog = () => {
    setAddForm({
      title: "",
      url: "",
      type: "sklep",
      country: "PL",
      status: "approved",
    });
    setIsAddDialogOpen(true);
  };

  const renderShopsTable = (shops: ShopLink[] | undefined, isLoading: boolean, showApprovalActions: boolean = false) => {
    if (isLoading) {
      return (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        </div>
      );
    }

    if (!shops || shops.length === 0) {
      return (
        <div className="card-automotive p-12 text-center">
          <Check className="h-12 w-12 text-green-500 mx-auto mb-4" />
          <h2 className="text-xl font-semibold text-foreground mb-2">
            Brak linków
          </h2>
          <p className="text-muted-foreground">
            Nie ma linków w tej kategorii.
          </p>
        </div>
      );
    }

    return (
      <div className="card-automotive overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow className="border-border/50 hover:bg-transparent">
              <TableHead className="text-foreground font-semibold">Nazwa</TableHead>
              <TableHead className="text-foreground font-semibold">Typ</TableHead>
              <TableHead className="text-foreground font-semibold">Kraj</TableHead>
              <TableHead className="text-foreground font-semibold">URL</TableHead>
              <TableHead className="text-foreground font-semibold">Użytkownik</TableHead>
              <TableHead className="text-foreground font-semibold">Dodano</TableHead>
              <TableHead className="text-foreground font-semibold text-right">Akcje</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {shops.map((shop) => (
              <TableRow key={shop.id} className="border-border/30">
                <TableCell>
                  <p className="font-medium text-foreground">
                    {shop.title}
                  </p>
                </TableCell>
                <TableCell>
                  <Badge variant="outline">
                    {typeLabels[shop.type] || shop.type}
                  </Badge>
                </TableCell>
                <TableCell>
                  <Badge variant="secondary">
                    {shop.country || "PL"}
                  </Badge>
                </TableCell>
                <TableCell>
                  <a
                    href={shop.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary hover:underline flex items-center gap-1 text-sm max-w-[200px] truncate"
                    title={shop.url}
                  >
                    <ExternalLink className="h-3 w-3 flex-shrink-0" />
                    {shop.url.replace(/^https?:\/\//, "").slice(0, 30)}...
                  </a>
                </TableCell>
                <TableCell>
                  <div className="flex items-center gap-2">
                    <User className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm text-muted-foreground">
                      {shop.profile?.display_name || shop.profile?.email || "Anonimowy"}
                    </span>
                  </div>
                </TableCell>
                <TableCell>
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Calendar className="h-4 w-4" />
                    {formatDistanceToNow(new Date(shop.created_at), {
                      addSuffix: true,
                      locale: pl,
                    })}
                  </div>
                </TableCell>
                <TableCell>
                  <div className="flex items-center justify-end gap-2">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => openEditDialog(shop)}
                      className="gap-1"
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => openDeleteDialog(shop)}
                      className="gap-1 text-destructive hover:text-destructive"
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                    {showApprovalActions && (
                      <>
                        <Button
                          size="sm"
                          onClick={() => handleApprove(shop.id)}
                          disabled={processingId === shop.id}
                          className="gap-1"
                        >
                          <Check className="h-4 w-4" />
                          Zatwierdź
                        </Button>
                        <Button
                          size="sm"
                          variant="destructive"
                          onClick={() => handleReject(shop.id)}
                          disabled={processingId === shop.id}
                          className="gap-1"
                        >
                          <X className="h-4 w-4" />
                          Odrzuć
                        </Button>
                      </>
                    )}
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-heading text-2xl font-bold text-foreground flex items-center gap-3">
            <Store className="h-6 w-6 text-primary" />
            Zarządzanie linkami sklepów
          </h2>
          <p className="text-muted-foreground mt-1">
            Przeglądaj, edytuj i zarządzaj linkami do sklepów
          </p>
        </div>
        <Button onClick={openAddDialog} className="gap-2">
          <Plus className="h-4 w-4" />
          Dodaj sklep
        </Button>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="pending" className="gap-2">
            Oczekujące
            {pendingShops && pendingShops.length > 0 && (
              <Badge variant="secondary" className="ml-1">
                {pendingShops.length}
              </Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="approved" className="gap-2">
            Zatwierdzone
            {approvedShops && approvedShops.length > 0 && (
              <Badge variant="secondary" className="ml-1">
                {approvedShops.length}
              </Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="rejected" className="gap-2">
            Odrzucone
            {rejectedShops && rejectedShops.length > 0 && (
              <Badge variant="secondary" className="ml-1">
                {rejectedShops.length}
              </Badge>
            )}
          </TabsTrigger>
        </TabsList>

        <TabsContent value="pending" className="mt-6">
          {renderShopsTable(pendingShops, pendingLoading, true)}
        </TabsContent>

        <TabsContent value="approved" className="mt-6">
          {renderShopsTable(approvedShops, approvedLoading)}
        </TabsContent>

        <TabsContent value="rejected" className="mt-6">
          {renderShopsTable(rejectedShops, rejectedLoading)}
        </TabsContent>
      </Tabs>

      {/* Edit Dialog */}
      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent className="sm:max-w-[500px]">
          <DialogHeader>
            <DialogTitle>Edytuj link</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="edit-title">Nazwa</Label>
              <Input
                id="edit-title"
                value={editForm.title}
                onChange={(e) => setEditForm({ ...editForm, title: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-url">URL</Label>
              <Input
                id="edit-url"
                value={editForm.url}
                onChange={(e) => setEditForm({ ...editForm, url: e.target.value })}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Typ</Label>
                <Select
                  value={editForm.type}
                  onValueChange={(value: "sklep" | "usluga" | "katalog") => 
                    setEditForm({ ...editForm, type: value })
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="sklep">Sklep</SelectItem>
                    <SelectItem value="usluga">Usługa</SelectItem>
                    <SelectItem value="katalog">Katalog</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Kraj</Label>
                <Select
                  value={editForm.country}
                  onValueChange={(value) => setEditForm({ ...editForm, country: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="PL">Polska</SelectItem>
                    <SelectItem value="DE">Niemcy</SelectItem>
                    <SelectItem value="US">USA</SelectItem>
                    <SelectItem value="UK">UK</SelectItem>
                    <SelectItem value="EU">Europa</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div className="space-y-2">
              <Label>Status</Label>
              <Select
                value={editForm.status}
                onValueChange={(value: "pending" | "approved" | "rejected") => 
                  setEditForm({ ...editForm, status: value })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pending">Oczekujący</SelectItem>
                  <SelectItem value="approved">Zatwierdzony</SelectItem>
                  <SelectItem value="rejected">Odrzucony</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => setIsEditDialogOpen(false)}>
              Anuluj
            </Button>
            <Button onClick={handleSaveEdit} disabled={updateShop.isPending}>
              {updateShop.isPending ? "Zapisywanie..." : "Zapisz"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Usunąć link?</AlertDialogTitle>
            <AlertDialogDescription>
              Czy na pewno chcesz usunąć link "{shopToDelete?.title}"? 
              Ta operacja jest nieodwracalna.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Anuluj</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {deleteShop.isPending ? "Usuwanie..." : "Usuń"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Add New Shop Dialog */}
      <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
        <DialogContent className="sm:max-w-[500px]">
          <DialogHeader>
            <DialogTitle>Dodaj nowy sklep</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="add-title">Nazwa</Label>
              <Input
                id="add-title"
                value={addForm.title}
                onChange={(e) => setAddForm({ ...addForm, title: e.target.value })}
                placeholder="Nazwa sklepu"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="add-url">URL</Label>
              <Input
                id="add-url"
                value={addForm.url}
                onChange={(e) => setAddForm({ ...addForm, url: e.target.value })}
                placeholder="https://..."
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Typ</Label>
                <Select
                  value={addForm.type}
                  onValueChange={(value: "sklep" | "usluga" | "katalog") => 
                    setAddForm({ ...addForm, type: value })
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="sklep">Sklep</SelectItem>
                    <SelectItem value="usluga">Usługa</SelectItem>
                    <SelectItem value="katalog">Katalog</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Kraj</Label>
                <Select
                  value={addForm.country}
                  onValueChange={(value) => setAddForm({ ...addForm, country: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="PL">Polska</SelectItem>
                    <SelectItem value="DE">Niemcy</SelectItem>
                    <SelectItem value="US">USA</SelectItem>
                    <SelectItem value="UK">UK</SelectItem>
                    <SelectItem value="EU">Europa</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div className="space-y-2">
              <Label>Status</Label>
              <Select
                value={addForm.status}
                onValueChange={(value: "pending" | "approved" | "rejected") => 
                  setAddForm({ ...addForm, status: value })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pending">Oczekujący</SelectItem>
                  <SelectItem value="approved">Zatwierdzony</SelectItem>
                  <SelectItem value="rejected">Odrzucony</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => setIsAddDialogOpen(false)}>
              Anuluj
            </Button>
            <Button onClick={handleAddShop} disabled={addShop.isPending || !addForm.title || !addForm.url}>
              {addShop.isPending ? "Dodawanie..." : "Dodaj"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

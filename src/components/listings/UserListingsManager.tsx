import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { Edit2, Trash2, Eye, EyeOff, ExternalLink, Plus, Car, Cog, Loader2, Phone } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { useToast } from "@/hooks/use-toast";
import { formatDistanceToNow } from "date-fns";
import { pl } from "date-fns/locale";

interface UserListing {
  id: string;
  title: string;
  price: number | null;
  currency: string | null;
  category: string;
  status: string;
  image_url: string | null;
  phone_number: string | null;
  created_at: string;
}

export function UserListingsManager() {
  const { user } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [processingId, setProcessingId] = useState<string | null>(null);

  const { data: listings, isLoading } = useQuery({
    queryKey: ["user-listings", user?.id],
    queryFn: async () => {
      if (!user) return [];
      
      const { data, error } = await supabase
        .from("listings")
        .select("id, title, price, currency, category, status, image_url, phone_number, created_at")
        .eq("user_id", user.id)
        .eq("source_type", "user")
        .order("created_at", { ascending: false });

      if (error) throw error;
      return data as UserListing[];
    },
    enabled: !!user,
  });

  const archiveMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("listings")
        .update({ status: "archived" })
        .eq("id", id)
        .eq("user_id", user?.id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["user-listings"] });
      toast({ title: "Ogłoszenie dezaktywowane" });
      setProcessingId(null);
    },
    onError: () => {
      toast({ title: "Błąd", variant: "destructive" });
      setProcessingId(null);
    },
  });

  const reactivateMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("listings")
        .update({ status: "pending" })
        .eq("id", id)
        .eq("user_id", user?.id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["user-listings"] });
      toast({ title: "Ogłoszenie wysłane do moderacji" });
      setProcessingId(null);
    },
    onError: () => {
      toast({ title: "Błąd", variant: "destructive" });
      setProcessingId(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("listings")
        .delete()
        .eq("id", id)
        .eq("user_id", user?.id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["user-listings"] });
      toast({ title: "Ogłoszenie usunięte" });
      setProcessingId(null);
    },
    onError: () => {
      toast({ title: "Błąd usuwania", variant: "destructive" });
      setProcessingId(null);
    },
  });

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "pending":
        return <Badge variant="secondary" className="bg-yellow-500/20 text-yellow-600 border-yellow-500/30">Oczekuje</Badge>;
      case "approved":
        return <Badge variant="secondary" className="bg-green-500/20 text-green-600 border-green-500/30">Aktywne</Badge>;
      case "rejected":
        return <Badge variant="destructive">Odrzucone</Badge>;
      case "archived":
        return <Badge variant="outline" className="text-muted-foreground">Nieaktywne</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-heading text-xl font-semibold text-foreground">
            Moje ogłoszenia
          </h2>
          <p className="text-sm text-muted-foreground">
            Zarządzaj swoimi ogłoszeniami
          </p>
        </div>
        <Link to="/ogloszenia/dodaj">
          <Button className="gap-2">
            <Plus className="h-4 w-4" />
            Dodaj ogłoszenie
          </Button>
        </Link>
      </div>

      {!listings || listings.length === 0 ? (
        <div className="card-automotive p-8 text-center">
          <Car className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-foreground mb-2">
            Brak ogłoszeń
          </h3>
          <p className="text-muted-foreground mb-4">
            Nie masz jeszcze żadnych ogłoszeń
          </p>
          <Link to="/ogloszenia/dodaj">
            <Button>Dodaj pierwsze ogłoszenie</Button>
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          {listings.map((listing) => (
            <div
              key={listing.id}
              className="card-automotive p-4 flex flex-col sm:flex-row gap-4"
            >
              {/* Image */}
              <div className="w-full sm:w-24 h-24 flex-shrink-0">
                {listing.image_url ? (
                  <img
                    src={listing.image_url}
                    alt={listing.title}
                    className="w-full h-full object-cover rounded-lg"
                  />
                ) : (
                  <div className="w-full h-full bg-muted rounded-lg flex items-center justify-center">
                    {listing.category === "pojazd" ? (
                      <Car className="h-8 w-8 text-muted-foreground" />
                    ) : (
                      <Cog className="h-8 w-8 text-muted-foreground" />
                    )}
                  </div>
                )}
              </div>

              {/* Content */}
              <div className="flex-1 min-w-0">
                <div className="flex flex-wrap items-start gap-2 mb-2">
                  <h3 className="font-semibold text-foreground truncate">
                    {listing.title}
                  </h3>
                  {getStatusBadge(listing.status)}
                </div>
                
                <div className="flex flex-wrap gap-3 text-sm text-muted-foreground mb-2">
                  <span className="font-semibold text-primary">
                    {listing.price 
                      ? `${listing.price.toLocaleString("pl-PL")} ${listing.currency || "PLN"}`
                      : "Cena do uzgodnienia"
                    }
                  </span>
                  <span>•</span>
                  <span>
                    {formatDistanceToNow(new Date(listing.created_at), {
                      addSuffix: true,
                      locale: pl,
                    })}
                  </span>
                  {listing.phone_number && (
                    <>
                      <span>•</span>
                      <span className="flex items-center gap-1">
                        <Phone className="h-3 w-3" />
                        {listing.phone_number}
                      </span>
                    </>
                  )}
                </div>
              </div>

              {/* Actions */}
              <div className="flex flex-wrap gap-2 sm:flex-col sm:items-end">
                <Link to={`/ogloszenia/edytuj/${listing.id}`}>
                  <Button size="sm" variant="outline" className="gap-1">
                    <Edit2 className="h-3 w-3" />
                    Edytuj
                  </Button>
                </Link>

                {listing.status === "approved" && (
                  <Button
                    size="sm"
                    variant="outline"
                    className="gap-1"
                    onClick={() => {
                      setProcessingId(listing.id);
                      archiveMutation.mutate(listing.id);
                    }}
                    disabled={processingId === listing.id}
                  >
                    <EyeOff className="h-3 w-3" />
                    Dezaktywuj
                  </Button>
                )}

                {listing.status === "archived" && (
                  <Button
                    size="sm"
                    variant="outline"
                    className="gap-1"
                    onClick={() => {
                      setProcessingId(listing.id);
                      reactivateMutation.mutate(listing.id);
                    }}
                    disabled={processingId === listing.id}
                  >
                    <Eye className="h-3 w-3" />
                    Aktywuj
                  </Button>
                )}

                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <Button size="sm" variant="destructive" className="gap-1">
                      <Trash2 className="h-3 w-3" />
                      Usuń
                    </Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>Czy na pewno chcesz usunąć?</AlertDialogTitle>
                      <AlertDialogDescription>
                        Ta operacja jest nieodwracalna. Ogłoszenie zostanie trwale usunięte.
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>Anuluj</AlertDialogCancel>
                      <AlertDialogAction
                        onClick={() => {
                          setProcessingId(listing.id);
                          deleteMutation.mutate(listing.id);
                        }}
                        className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                      >
                        Usuń
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Check, X, ExternalLink, Image, Calendar, User, Tag } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useToast } from "@/hooks/use-toast";
import { formatDistanceToNow } from "date-fns";
import { pl } from "date-fns/locale";
import type { Tables } from "@/integrations/supabase/types";

type Listing = Tables<"listings"> & {
  profile?: { display_name: string | null; email: string } | null;
};

export function ListingsApproval() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [processingId, setProcessingId] = useState<string | null>(null);

  const { data: pendingListings, isLoading } = useQuery({
    queryKey: ["admin-pending-listings"],
    queryFn: async () => {
      const { data: listings, error } = await supabase
        .from("listings")
        .select("*")
        .eq("status", "pending")
        .order("created_at", { ascending: false });

      if (error) throw error;
      if (!listings || listings.length === 0) return [];

      // Fetch profiles for user listings
      const userIds = listings
        .filter(l => l.user_id)
        .map(l => l.user_id as string);
      
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

      return listings.map(listing => ({
        ...listing,
        profile: listing.user_id ? profilesMap[listing.user_id] || null : null,
      })) as Listing[];
    },
  });

  const updateStatus = useMutation({
    mutationFn: async ({ id, status }: { id: string; status: "approved" | "rejected" }) => {
      const { error } = await supabase
        .from("listings")
        .update({ status, published_at: status === "approved" ? new Date().toISOString() : null })
        .eq("id", id);

      if (error) throw error;

      // Send notification email if approved
      if (status === "approved") {
        try {
          await supabase.functions.invoke("send-notification-email", {
            body: { type: "listing_approved", listingId: id },
          });
        } catch (e) {
          console.error("Failed to send notification email:", e);
        }
      }
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["admin-pending-listings"] });
      toast({
        title: variables.status === "approved" ? "Ogłoszenie zatwierdzone" : "Ogłoszenie odrzucone",
        description: variables.status === "approved" 
          ? "Ogłoszenie jest teraz widoczne publicznie."
          : "Ogłoszenie zostało odrzucone.",
      });
      setProcessingId(null);
    },
    onError: (error: any) => {
      toast({
        title: "Błąd",
        description: error.message || "Nie udało się zaktualizować ogłoszenia.",
        variant: "destructive",
      });
      setProcessingId(null);
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

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!pendingListings || pendingListings.length === 0) {
    return (
      <div className="card-automotive p-12 text-center">
        <Check className="h-12 w-12 text-green-500 mx-auto mb-4" />
        <h2 className="text-xl font-semibold text-foreground mb-2">
          Wszystko zatwierdzone!
        </h2>
        <p className="text-muted-foreground">
          Nie ma ogłoszeń oczekujących na zatwierdzenie.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="font-heading text-2xl font-bold text-foreground flex items-center gap-3">
          <Tag className="h-6 w-6 text-primary" />
          Oczekujące ogłoszenia
          <Badge variant="secondary" className="ml-2">
            {pendingListings.length}
          </Badge>
        </h2>
        <p className="text-muted-foreground mt-1">
          Zatwierdź lub odrzuć ogłoszenia dodane przez użytkowników
        </p>
      </div>

      <div className="card-automotive overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow className="border-border/50 hover:bg-transparent">
              <TableHead className="text-foreground font-semibold w-16">Zdjęcie</TableHead>
              <TableHead className="text-foreground font-semibold">Tytuł</TableHead>
              <TableHead className="text-foreground font-semibold">Kategoria</TableHead>
              <TableHead className="text-foreground font-semibold">Cena</TableHead>
              <TableHead className="text-foreground font-semibold">Użytkownik</TableHead>
              <TableHead className="text-foreground font-semibold">Dodano</TableHead>
              <TableHead className="text-foreground font-semibold text-right">Akcje</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {pendingListings.map((listing) => (
              <TableRow key={listing.id} className="border-border/30">
                <TableCell>
                  {listing.image_url ? (
                    <img
                      src={listing.image_url}
                      alt={listing.title}
                      className="w-12 h-12 object-cover rounded"
                    />
                  ) : (
                    <div className="w-12 h-12 bg-muted rounded flex items-center justify-center">
                      <Image className="h-5 w-5 text-muted-foreground" />
                    </div>
                  )}
                </TableCell>
                <TableCell>
                  <div className="max-w-[200px]">
                    <p className="font-medium text-foreground truncate" title={listing.title}>
                      {listing.title}
                    </p>
                    {listing.url && (
                      <a
                        href={listing.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-xs text-primary hover:underline flex items-center gap-1 mt-1"
                      >
                        <ExternalLink className="h-3 w-3" />
                        Zobacz ogłoszenie
                      </a>
                    )}
                  </div>
                </TableCell>
                <TableCell>
                  <Badge variant="outline">
                    {listing.category === "pojazd" ? "Pojazd" : "Część"}
                  </Badge>
                </TableCell>
                <TableCell>
                  {listing.price ? (
                    <span className="font-semibold text-primary">
                      {listing.price.toLocaleString("pl-PL")} {listing.currency || "EUR"}
                    </span>
                  ) : (
                    <span className="text-muted-foreground">—</span>
                  )}
                </TableCell>
                <TableCell>
                  <div className="flex items-center gap-2">
                    <User className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm text-muted-foreground">
                      {listing.profile?.display_name || listing.profile?.email || "Anonimowy"}
                    </span>
                  </div>
                </TableCell>
                <TableCell>
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Calendar className="h-4 w-4" />
                    {formatDistanceToNow(new Date(listing.created_at), {
                      addSuffix: true,
                      locale: pl,
                    })}
                  </div>
                </TableCell>
                <TableCell>
                  <div className="flex items-center justify-end gap-2">
                    <Button
                      size="sm"
                      onClick={() => handleApprove(listing.id)}
                      disabled={processingId === listing.id}
                      className="gap-1"
                    >
                      <Check className="h-4 w-4" />
                      Zatwierdź
                    </Button>
                    <Button
                      size="sm"
                      variant="destructive"
                      onClick={() => handleReject(listing.id)}
                      disabled={processingId === listing.id}
                      className="gap-1"
                    >
                      <X className="h-4 w-4" />
                      Odrzuć
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}

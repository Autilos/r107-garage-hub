import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
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
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog";
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
import {
    Rss,
    Plus,
    Trash2,
    ExternalLink,
    Check,
    X,
    RefreshCw,
    AlertCircle,
    Pencil,
} from "lucide-react";

interface RssSource {
    id: string;
    name: string;
    url?: string; // Production uses 'url'
    feed_url?: string; // Local dev uses 'feed_url'
    active?: boolean; // Production uses 'active'
    enabled?: boolean; // Local dev uses 'enabled'
    country?: string; // Production uses 'country'
    country_default?: string; // Local dev uses 'country_default'
    created_at: string;
}

interface RssSourceWithStats extends RssSource {
    listings_count: number;
    last_listing_at: string | null;
}

export function RssSourcesManager() {
    const { toast } = useToast();
    const queryClient = useQueryClient();
    const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
    const [editingSource, setEditingSource] = useState<RssSource | null>(null);
    const [formData, setFormData] = useState({
        name: "",
        feed_url: "",
        country_default: "PL",
        enabled: true,
    });

    const { data: rssSources, isLoading, refetch } = useQuery({
        queryKey: ["admin-rss-sources"],
        queryFn: async () => {
            const { data: sources, error: sourcesError } = await supabase
                .from("rss_sources")
                .select("*")
                .order("name");

            if (sourcesError) throw sourcesError;

            const sourcesWithStats: RssSourceWithStats[] = await Promise.all(
                (sources || []).map(async (source) => {
                    const { count } = await supabase
                        .from("listings")
                        .select("*", { count: "exact", head: true })
                        .eq("rss_source_id", source.id)
                        .eq("status", "approved");

                    const { data: lastListing } = await supabase
                        .from("listings")
                        .select("created_at")
                        .eq("rss_source_id", source.id)
                        .order("created_at", { ascending: false })
                        .limit(1)
                        .maybeSingle();

                    return {
                        ...source,
                        listings_count: count || 0,
                        last_listing_at: lastListing?.created_at || null,
                    };
                })
            );

            return sourcesWithStats;
        },
    });

    const addMutation = useMutation({
        mutationFn: async (data: typeof formData) => {
            const { error } = await supabase.from("rss_sources").insert({
                name: data.name,
                feed_url: data.feed_url,
                country_default: data.country_default,
                enabled: data.enabled,
            });
            if (error) throw error;
        },
        onSuccess: () => {
            toast({ title: "Źródło RSS dodane" });
            setIsAddDialogOpen(false);
            resetForm();
            queryClient.invalidateQueries({ queryKey: ["admin-rss-sources"] });
        },
        onError: (error: any) => {
            toast({
                title: "Błąd",
                description: error.message,
                variant: "destructive",
            });
        },
    });

    const updateMutation = useMutation({
        mutationFn: async ({ id, data }: { id: string; data: Partial<typeof formData> }) => {
            const { error } = await supabase
                .from("rss_sources")
                .update(data)
                .eq("id", id);
            if (error) throw error;
        },
        onSuccess: () => {
            toast({ title: "Źródło RSS zaktualizowane" });
            setEditingSource(null);
            resetForm();
            queryClient.invalidateQueries({ queryKey: ["admin-rss-sources"] });
        },
        onError: (error: any) => {
            toast({
                title: "Błąd",
                description: error.message,
                variant: "destructive",
            });
        },
    });

    const deleteMutation = useMutation({
        mutationFn: async (id: string) => {
            const { error } = await supabase.from("rss_sources").delete().eq("id", id);
            if (error) throw error;
        },
        onSuccess: () => {
            toast({ title: "Źródło RSS usunięte" });
            queryClient.invalidateQueries({ queryKey: ["admin-rss-sources"] });
        },
        onError: (error: any) => {
            toast({
                title: "Błąd",
                description: error.message,
                variant: "destructive",
            });
        },
    });

    const toggleEnabledMutation = useMutation({
        mutationFn: async ({ id, enabled }: { id: string; enabled: boolean }) => {
            const { error } = await supabase
                .from("rss_sources")
                .update({ enabled })
                .eq("id", id);
            if (error) throw error;
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ["admin-rss-sources"] });
        },
        onError: (error: any) => {
            toast({
                title: "Błąd",
                description: error.message,
                variant: "destructive",
            });
        },
    });

    const handleRunIngest = async () => {
        toast({
            title: "Uruchamiam pobieranie RSS...",
            description: "To może potrwać kilka sekund.",
        });

        try {
            // Get current session to ensure we have a valid token
            const { data: { session }, error: sessionError } = await supabase.auth.getSession();

            if (sessionError || !session) {
                throw new Error("Brak aktywnej sesji. Zaloguj się ponownie.");
            }

            const { data, error } = await supabase.functions.invoke("ingest-rss", {
                headers: {
                    Authorization: `Bearer ${session.access_token}`,
                },
            });

            if (error) {
                console.error("Edge function error:", error);
                throw error;
            }

            console.log("Ingest results:", data);

            toast({
                title: "Pobieranie zakończone",
                description: data?.results ?
                    `Przetworzono: ${data.results.processed}, Zaakceptowano: ${data.results.allowed}, Odrzucono: ${data.results.rejected}` :
                    "Przetworzono źródła RSS. Sprawdź wyniki.",
            });
            refetch();
        } catch (error: any) {
            console.error("Ingest error:", error);
            toast({
                title: "Błąd podczas pobierania",
                description: error.message || "Spróbuj ponownie później.",
                variant: "destructive",
            });
        }
    };

    const resetForm = () => {
        setFormData({
            name: "",
            feed_url: "",
            country_default: "PL",
            enabled: true,
        });
    };

    const openEditDialog = (source: RssSource) => {
        setEditingSource(source);
        setFormData({
            name: source.name,
            feed_url: source.url || source.feed_url || "", // Support both column names
            country_default: source.country || source.country_default || "PL", // Support both column names
            enabled: source.active ?? source.enabled ?? true, // Support both column names
        });
    };

    const handleSubmit = () => {
        if (!formData.name || !formData.feed_url) {
            toast({
                title: "Uzupełnij wymagane pola",
                variant: "destructive",
            });
            return;
        }

        if (editingSource) {
            updateMutation.mutate({ id: editingSource.id, data: formData });
        } else {
            addMutation.mutate(formData);
        }
    };

    const FormContent = () => (
        <div className="space-y-4">
            <div className="space-y-2">
                <Label htmlFor="name">Nazwa źródła *</Label>
                <Input
                    id="name"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="np. Otomoto R107"
                />
            </div>
            <div className="space-y-2">
                <Label htmlFor="feed_url">URL kanału RSS *</Label>
                <Input
                    id="feed_url"
                    value={formData.feed_url}
                    onChange={(e) => setFormData({ ...formData, feed_url: e.target.value })}
                    placeholder="https://rss.app/feeds/..."
                />
            </div>
            <div className="space-y-2">
                <Label htmlFor="country">Domyślny kraj</Label>
                <Input
                    id="country"
                    value={formData.country_default}
                    onChange={(e) => setFormData({ ...formData, country_default: e.target.value })}
                    placeholder="PL"
                    maxLength={2}
                />
            </div>
            <div className="flex items-center gap-3">
                <Switch
                    id="enabled"
                    checked={formData.enabled}
                    onCheckedChange={(checked) => setFormData({ ...formData, enabled: checked })}
                />
                <Label htmlFor="enabled">Aktywne</Label>
            </div>
        </div>
    );

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between flex-wrap gap-4">
                <div>
                    <h2 className="font-heading text-2xl font-bold text-foreground flex items-center gap-3">
                        <Rss className="h-6 w-6 text-primary" />
                        Źródła RSS
                    </h2>
                    <p className="text-muted-foreground mt-1">
                        Zarządzanie źródłami ogłoszeń RSS
                    </p>
                </div>
                <div className="flex gap-2">
                    <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
                        <DialogTrigger asChild>
                            <Button variant="outline" className="gap-2" onClick={resetForm}>
                                <Plus className="h-4 w-4" />
                                Dodaj źródło
                            </Button>
                        </DialogTrigger>
                        <DialogContent>
                            <DialogHeader>
                                <DialogTitle>Dodaj nowe źródło RSS</DialogTitle>
                                <DialogDescription>
                                    Wprowadź dane nowego kanału RSS do pobierania ogłoszeń.
                                </DialogDescription>
                            </DialogHeader>
                            <FormContent />
                            <DialogFooter>
                                <Button
                                    variant="outline"
                                    onClick={() => setIsAddDialogOpen(false)}
                                >
                                    Anuluj
                                </Button>
                                <Button
                                    onClick={handleSubmit}
                                    disabled={addMutation.isPending}
                                >
                                    {addMutation.isPending ? "Dodawanie..." : "Dodaj"}
                                </Button>
                            </DialogFooter>
                        </DialogContent>
                    </Dialog>

                    <Button onClick={handleRunIngest} className="gap-2">
                        <RefreshCw className="h-4 w-4" />
                        Uruchom pobieranie
                    </Button>
                </div>
            </div>

            {/* Edit Dialog */}
            <Dialog open={!!editingSource} onOpenChange={(open) => !open && setEditingSource(null)}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Edytuj źródło RSS</DialogTitle>
                        <DialogDescription>
                            Zmień dane kanału RSS.
                        </DialogDescription>
                    </DialogHeader>
                    <FormContent />
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setEditingSource(null)}>
                            Anuluj
                        </Button>
                        <Button
                            onClick={handleSubmit}
                            disabled={updateMutation.isPending}
                        >
                            {updateMutation.isPending ? "Zapisywanie..." : "Zapisz"}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {isLoading ? (
                <div className="flex items-center justify-center py-12">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                </div>
            ) : rssSources && rssSources.length > 0 ? (
                <div className="card-automotive overflow-hidden">
                    <Table>
                        <TableHeader>
                            <TableRow className="border-border/50 hover:bg-transparent">
                                <TableHead className="text-foreground font-semibold">Nazwa</TableHead>
                                <TableHead className="text-foreground font-semibold">Status</TableHead>
                                <TableHead className="text-foreground font-semibold">Kraj</TableHead>
                                <TableHead className="text-foreground font-semibold text-center">Ogłoszenia</TableHead>
                                <TableHead className="text-foreground font-semibold">Ostatnie</TableHead>
                                <TableHead className="text-foreground font-semibold">Feed URL</TableHead>
                                <TableHead className="text-foreground font-semibold text-right">Akcje</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {rssSources.map((source) => (
                                <TableRow key={source.id} className="border-border/30">
                                    <TableCell className="font-medium text-foreground">
                                        {source.name}
                                    </TableCell>
                                    <TableCell>
                                        <Switch
                                            checked={source.active ?? source.enabled ?? false}
                                            onCheckedChange={(checked) =>
                                                toggleEnabledMutation.mutate({ id: source.id, enabled: checked })
                                            }
                                        />
                                    </TableCell>
                                    <TableCell>
                                        <Badge variant="outline" className="text-muted-foreground">
                                            {source.country || source.country_default}
                                        </Badge>
                                    </TableCell>
                                    <TableCell className="text-center">
                                        <span className="text-lg font-bold text-primary">
                                            {source.listings_count}
                                        </span>
                                    </TableCell>
                                    <TableCell className="text-muted-foreground text-sm">
                                        {source.last_listing_at ? (
                                            <span title={new Date(source.last_listing_at).toLocaleString("pl-PL")}>
                                                {formatDistanceToNow(new Date(source.last_listing_at), {
                                                    addSuffix: true,
                                                    locale: pl,
                                                })}
                                            </span>
                                        ) : (
                                            <span className="text-muted-foreground/50 flex items-center gap-1">
                                                <AlertCircle className="h-3 w-3" />
                                                Brak
                                            </span>
                                        )}
                                    </TableCell>
                                    <TableCell>
                                        {(source.url || source.feed_url) && (
                                            <a
                                                href={source.url || source.feed_url}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className="text-primary hover:underline flex items-center gap-1 text-sm truncate max-w-[180px]"
                                                title={source.url || source.feed_url}
                                            >
                                                <ExternalLink className="h-3 w-3 flex-shrink-0" />
                                                {(source.url || source.feed_url)!.replace(/^https?:\/\//, "").slice(0, 25)}...
                                            </a>
                                        )}
                                    </TableCell>
                                    <TableCell className="text-right">
                                        <div className="flex items-center justify-end gap-1">
                                            <Button
                                                variant="ghost"
                                                size="icon"
                                                onClick={() => openEditDialog(source)}
                                                title="Edytuj"
                                            >
                                                <Pencil className="h-4 w-4" />
                                            </Button>

                                            <AlertDialog>
                                                <AlertDialogTrigger asChild>
                                                    <Button
                                                        variant="ghost"
                                                        size="icon"
                                                        className="text-destructive hover:text-destructive"
                                                        title="Usuń"
                                                    >
                                                        <Trash2 className="h-4 w-4" />
                                                    </Button>
                                                </AlertDialogTrigger>
                                                <AlertDialogContent>
                                                    <AlertDialogHeader>
                                                        <AlertDialogTitle>Usunąć źródło RSS?</AlertDialogTitle>
                                                        <AlertDialogDescription>
                                                            Czy na pewno chcesz usunąć źródło "{source.name}"?
                                                            Ta operacja jest nieodwracalna. Ogłoszenia z tego źródła
                                                            pozostaną w bazie.
                                                        </AlertDialogDescription>
                                                    </AlertDialogHeader>
                                                    <AlertDialogFooter>
                                                        <AlertDialogCancel>Anuluj</AlertDialogCancel>
                                                        <AlertDialogAction
                                                            onClick={() => deleteMutation.mutate(source.id)}
                                                            className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                                                        >
                                                            Usuń
                                                        </AlertDialogAction>
                                                    </AlertDialogFooter>
                                                </AlertDialogContent>
                                            </AlertDialog>
                                        </div>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </div>
            ) : (
                <div className="card-automotive p-12 text-center">
                    <Rss className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                    <h2 className="text-xl font-semibold text-foreground mb-2">
                        Brak źródeł RSS
                    </h2>
                    <p className="text-muted-foreground mb-4">
                        Nie skonfigurowano jeszcze żadnych źródeł RSS.
                    </p>
                    <Button onClick={() => setIsAddDialogOpen(true)} className="gap-2">
                        <Plus className="h-4 w-4" />
                        Dodaj pierwsze źródło
                    </Button>
                </div>
            )}

            <div className="p-4 bg-muted/30 rounded-lg border border-border/50">
                <h3 className="font-semibold text-foreground mb-2">Informacje o cron</h3>
                <p className="text-sm text-muted-foreground">
                    Funkcja <code className="bg-muted px-1 py-0.5 rounded">ingest-rss</code> może być uruchamiana
                    automatycznie przez cron job lub ręcznie przyciskiem powyżej.
                </p>
            </div>
        </div>
    );
}

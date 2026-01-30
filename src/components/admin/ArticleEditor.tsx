import { useState, useRef } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { useToast } from "@/hooks/use-toast";
import { Loader2, Save, Eye, Edit, Image as ImageIcon, Plus, Trash2, Upload } from "lucide-react";
import { RichTextEditor } from "./RichTextEditor";
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

interface Article {
    id: string;
    slug: string;
    title: string;
    description: string | null;
    content: string | null;
    image_url: string | null;
    seo_title: string | null;
    seo_description: string | null;
    is_published: boolean;
}

export function ArticleEditor() {
    const { toast } = useToast();
    const queryClient = useQueryClient();
    const [editingId, setEditingId] = useState<string | null>(null);
    const [isAddingNew, setIsAddingNew] = useState(false);
    const [formData, setFormData] = useState<Partial<Article>>({});
    const [previewMode, setPreviewMode] = useState(false);
    const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
    const [isUploadingCover, setIsUploadingCover] = useState(false);
    const coverInputRef = useRef<HTMLInputElement>(null);

    const handleCoverUpload = async (file: File) => {
        if (!file.type.startsWith('image/')) {
            toast({
                title: 'Błędny typ pliku',
                description: 'Dozwolone są tylko pliki graficzne.',
                variant: 'destructive'
            });
            return;
        }

        if (file.size > 5 * 1024 * 1024) {
            toast({
                title: 'Plik za duży',
                description: 'Maksymalny rozmiar pliku to 5MB.',
                variant: 'destructive'
            });
            return;
        }

        setIsUploadingCover(true);

        try {
            // Use edge function to convert to WebP
            const formData = new FormData();
            formData.append('file', file);
            formData.append('bucket', 'article-images');
            formData.append('folder', 'covers');

            const { data, error } = await supabase.functions.invoke('convert-to-webp', {
                body: formData,
            });

            if (error) throw error;
            if (!data?.url) throw new Error('Brak URL w odpowiedzi');

            setFormData(prev => ({ ...prev, image_url: data.url }));

            const savings = data.savings || '';
            toast({
                title: 'Zdjęcie zostało przekonwertowane do WebP',
                description: savings ? `Oszczędność: ${savings}` : undefined
            });
        } catch (error: any) {
            console.error('Upload error:', error);
            toast({
                title: 'Błąd uploadu',
                description: error.message,
                variant: 'destructive'
            });
        } finally {
            setIsUploadingCover(false);
        }
    };

    const { data: articles, isLoading } = useQuery({
        queryKey: ["admin-articles"],
        queryFn: async () => {
            const { data, error } = await supabase
                .from("articles" as any)
                .select("*")
                .order("created_at", { ascending: false });

            if (error) throw error;
            return (data || []) as unknown as Article[];
        },
    });

    const createMutation = useMutation({
        mutationFn: async (newArticle: Partial<Article>) => {
            const { error } = await supabase
                .from("articles" as any)
                .insert([newArticle]);

            if (error) throw error;
        },
        onSuccess: () => {
            toast({ title: "Dodano nowy artykuł" });
            queryClient.invalidateQueries({ queryKey: ["admin-articles"] });
            setIsAddingNew(false);
            setFormData({});
        },
        onError: (error: any) => {
            toast({
                title: "Błąd dodawania",
                description: error.message,
                variant: "destructive"
            });
        },
    });

    const updateMutation = useMutation({
        mutationFn: async (data: Partial<Article> & { id: string }) => {
            const { id, ...updates } = data;
            const { error } = await supabase
                .from("articles" as any)
                .update(updates)
                .eq("id", id);

            if (error) throw error;
        },
        onSuccess: () => {
            toast({ title: "Zapisano zmiany" });
            queryClient.invalidateQueries({ queryKey: ["admin-articles"] });
            setEditingId(null);
            setFormData({});
        },
        onError: (error: any) => {
            toast({
                title: "Błąd zapisu",
                description: error.message,
                variant: "destructive"
            });
        },
    });

    const deleteMutation = useMutation({
        mutationFn: async (id: string) => {
            const { error } = await supabase
                .from("articles" as any)
                .delete()
                .eq("id", id);

            if (error) throw error;
        },
        onSuccess: () => {
            toast({ title: "Artykuł został usunięty" });
            queryClient.invalidateQueries({ queryKey: ["admin-articles"] });
            setDeleteConfirmId(null);
        },
        onError: (error: any) => {
            toast({
                title: "Błąd usuwania",
                description: error.message,
                variant: "destructive"
            });
        },
    });

    const handleEdit = (article: Article) => {
        setEditingId(article.id);
        setIsAddingNew(false);
        setFormData(article);
        setPreviewMode(false);
    };

    const handleAddNew = () => {
        setEditingId(null);
        setIsAddingNew(true);
        setFormData({
            title: "",
            slug: "",
            description: "",
            content: "",
            is_published: false,
            image_url: "",
            seo_title: "",
            seo_description: ""
        });
        setPreviewMode(false);
    };

    const handleSave = () => {
        if (isAddingNew) {
            if (!formData.title || !formData.slug) {
                toast({
                    title: "Brak danych",
                    description: "Tytuł i slug są wymagane.",
                    variant: "destructive"
                });
                return;
            }
            createMutation.mutate(formData);
        } else if (editingId) {
            updateMutation.mutate({ ...formData, id: editingId } as Article & { id: string });
        }
    };

    const handleCancel = () => {
        setEditingId(null);
        setIsAddingNew(false);
        setFormData({});
    };

    const handleDelete = (id: string) => {
        setDeleteConfirmId(id);
    };

    if (isLoading) {
        return <div className="flex justify-center p-8"><Loader2 className="animate-spin" /></div>;
    }

    if (editingId || isAddingNew) {
        return (
            <div className="space-y-6 bg-card p-6 rounded-lg border shadow-sm">
                <div className="flex items-center justify-between">
                    <h2 className="text-2xl font-bold">{isAddingNew ? "Nowy artykuł" : "Edycja artykułu"}</h2>
                    <div className="flex gap-2">
                        <Button variant="outline" onClick={() => setPreviewMode(!previewMode)}>
                            {previewMode ? <><Edit className="mr-2 h-4 w-4" /> Edytuj</> : <><Eye className="mr-2 h-4 w-4" /> Podgląd</>}
                        </Button>
                        <Button variant="outline" onClick={handleCancel}>Anuluj</Button>
                        <Button onClick={handleSave} disabled={updateMutation.isPending || createMutation.isPending}>
                            {(updateMutation.isPending || createMutation.isPending) && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            <Save className="mr-2 h-4 w-4" /> Zapisz
                        </Button>
                    </div>
                </div>

                {previewMode ? (
                    <div className="border rounded-lg p-8 bg-background min-h-[500px]">
                        <div className="relative h-[40vh] w-full mb-8 rounded-lg overflow-hidden">
                            {formData.image_url ? (
                                <img src={formData.image_url} alt="Cover" className="w-full h-full object-cover" />
                            ) : (
                                <div className="flex items-center justify-center h-full bg-muted text-muted-foreground">Brak zdjęcia</div>
                            )}
                            <div className="absolute bottom-0 left-0 p-8 bg-gradient-to-t from-black/80 to-transparent w-full">
                                <h1 className="text-4xl font-bold text-white mb-2">{formData.title}</h1>
                                <p className="text-xl text-white/80">{formData.description}</p>
                            </div>
                        </div>
                        <div className="prose prose-lg dark:prose-invert max-w-none" dangerouslySetInnerHTML={{ __html: formData.content || "" }} />
                    </div>
                ) : (
                    <div className="grid gap-6">
                        <div className="grid gap-2">
                            <Label>Tytuł</Label>
                            <Input
                                value={formData.title || ""}
                                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                placeholder="Np. Historia Mercedes R107"
                            />
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div className="grid gap-2">
                                <Label>Slug (URL)</Label>
                                <Input
                                    value={formData.slug || ""}
                                    onChange={(e) => setFormData({ ...formData, slug: e.target.value })}
                                    placeholder="np-historia-mercedes-r107"
                                />
                            </div>
                            <div className="grid gap-2">
                                <Label className="flex items-center gap-2">
                                    Opublikowany
                                    <Switch
                                        checked={formData.is_published}
                                        onCheckedChange={(checked) => setFormData({ ...formData, is_published: checked })}
                                    />
                                </Label>
                            </div>
                        </div>

                        <div className="grid gap-2">
                            <Label>Krótki opis (Hero & SEO)</Label>
                            <Textarea
                                value={formData.description || ""}
                                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                placeholder="Krótki wstęp widoczny na liście artykułów..."
                            />
                        </div>

                        <div className="grid gap-2">
                            <Label>Zdjęcie główne</Label>
                            <div className="flex gap-2">
                                <div className="relative flex-1">
                                    <ImageIcon className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                                    <Input
                                        className="pl-9"
                                        value={formData.image_url || ""}
                                        onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
                                        placeholder="https://images.unsplash.com/... lub załaduj z dysku"
                                    />
                                </div>
                                <Button
                                    type="button"
                                    variant="outline"
                                    onClick={() => coverInputRef.current?.click()}
                                    disabled={isUploadingCover}
                                >
                                    {isUploadingCover ? (
                                        <Loader2 className="h-4 w-4 animate-spin" />
                                    ) : (
                                        <Upload className="h-4 w-4" />
                                    )}
                                </Button>
                                <input
                                    ref={coverInputRef}
                                    type="file"
                                    accept="image/*"
                                    onChange={(e) => {
                                        const file = e.target.files?.[0];
                                        if (file) handleCoverUpload(file);
                                        e.target.value = '';
                                    }}
                                    className="hidden"
                                />
                            </div>
                            {formData.image_url && (
                                <div className="mt-2">
                                    <img
                                        src={formData.image_url}
                                        alt="Podgląd"
                                        className="w-full max-w-md h-32 object-cover rounded-lg border"
                                    />
                                </div>
                            )}
                        </div>

                        <div className="grid gap-2">
                            <Label>Treść</Label>
                            <RichTextEditor
                                content={formData.content || ""}
                                onChange={(content) => setFormData({ ...formData, content })}
                            />
                        </div>

                        <div className="border rounded-lg p-4 space-y-4">
                            <h3 className="font-semibold">Ustawienia SEO</h3>
                            <div className="grid gap-2">
                                <Label>SEO Title (opcjonalny)</Label>
                                <Input
                                    value={formData.seo_title || ""}
                                    onChange={(e) => setFormData({ ...formData, seo_title: e.target.value })}
                                    placeholder={formData.title || ""}
                                />
                            </div>
                            <div className="grid gap-2">
                                <Label>SEO Description (opcjonalny)</Label>
                                <Input
                                    value={formData.seo_description || ""}
                                    onChange={(e) => setFormData({ ...formData, seo_description: e.target.value })}
                                    placeholder={formData.description || ""}
                                />
                            </div>
                        </div>
                    </div>
                )}
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div className="flex justify-between items-center">
                <div>
                    <h2 className="text-2xl font-bold tracking-tight">Artykuły</h2>
                    <p className="text-muted-foreground">Zarządzaj treściami na stronie Bloga.</p>
                </div>
                <Button onClick={handleAddNew} className="gap-2">
                    <Plus className="h-4 w-4" /> Dodaj artykuł
                </Button>
            </div>

            <div className="grid gap-4">
                {articles?.map((article) => (
                    <div key={article.id} className="flex items-center justify-between p-4 border rounded-lg bg-card">
                        <div className="flex-1">
                            <h3 className="font-semibold">{article.title}</h3>
                            <p className="text-sm text-muted-foreground">/{article.slug}</p>
                        </div>
                        <div className="flex items-center gap-4">
                            <div className="flex items-center gap-2">
                                <span className={`h-2 w-2 rounded-full ${article.is_published ? 'bg-green-500' : 'bg-gray-300'}`} />
                                <span className="text-sm text-muted-foreground">{article.is_published ? 'Opublikowany' : 'Szkic'}</span>
                            </div>
                            <div className="flex gap-2">
                                <Button variant="outline" size="sm" onClick={() => handleEdit(article)}>
                                    <Edit className="h-4 w-4 mr-2" /> Edytuj
                                </Button>
                                <Button variant="destructive" size="sm" onClick={() => handleDelete(article.id)}>
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            </div>
                        </div>
                    </div>
                ))}

                {articles?.length === 0 && (
                    <div className="text-center p-12 text-muted-foreground border rounded-lg border-dashed">
                        Brak artykułów. Kliknij "Dodaj artykuł", aby stworzyć pierwszy wpis.
                    </div>
                )}
            </div>

            <AlertDialog open={!!deleteConfirmId} onOpenChange={(open) => !open && setDeleteConfirmId(null)}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>Czy na pewno chcesz usunąć ten artykuł?</AlertDialogTitle>
                        <AlertDialogDescription>
                            Ta operacja jest nieodwracalna. Artykuł zostanie trwale usunięty z bazy danych.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel disabled={deleteMutation.isPending}>Anuluj</AlertDialogCancel>
                        <AlertDialogAction
                            onClick={(e) => {
                                e.preventDefault();
                                deleteMutation.mutate(deleteConfirmId!);
                            }}
                            className="bg-destructive hover:bg-destructive/90 text-destructive-foreground"
                            disabled={deleteMutation.isPending}
                        >
                            {deleteMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Usuń artykuł
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </div>
    );
}


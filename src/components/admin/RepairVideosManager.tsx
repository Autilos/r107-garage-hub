import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Youtube, Plus, Trash2, Film, Pencil } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useToast } from "@/hooks/use-toast";
import { repairCategories } from "@/data/repairCategories";

interface RepairVideo {
  id: string;
  category_slug: string;
  video_id: string;
  title: string;
  subcategory: string | null;
  sort_order: number;
  created_at: string;
}

interface VideoFormData {
  category_slug: string;
  video_id: string;
  title: string;
  subcategory: string;
}

export function RepairVideosManager() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<string>("all");
  const [editingVideo, setEditingVideo] = useState<RepairVideo | null>(null);
  
  const [newVideo, setNewVideo] = useState<VideoFormData>({
    category_slug: "",
    video_id: "",
    title: "",
    subcategory: "",
  });

  const [editForm, setEditForm] = useState<VideoFormData>({
    category_slug: "",
    video_id: "",
    title: "",
    subcategory: "",
  });

  const { data: videos, isLoading } = useQuery({
    queryKey: ["admin-repair-videos"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("repair_videos")
        .select("*")
        .order("category_slug")
        .order("sort_order");

      if (error) throw error;
      return data as RepairVideo[];
    },
  });

  const addVideoMutation = useMutation({
    mutationFn: async (video: Omit<RepairVideo, "id" | "created_at" | "sort_order">) => {
      // Get max sort_order for this category
      const { data: existing } = await supabase
        .from("repair_videos")
        .select("sort_order")
        .eq("category_slug", video.category_slug)
        .order("sort_order", { ascending: false })
        .limit(1);

      const nextOrder = existing && existing.length > 0 ? existing[0].sort_order + 1 : 0;

      const { error } = await supabase.from("repair_videos").insert({
        ...video,
        subcategory: video.subcategory || null,
        sort_order: nextOrder,
      });

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-repair-videos"] });
      toast({ title: "Film dodany" });
      setIsDialogOpen(false);
      setNewVideo({ category_slug: "", video_id: "", title: "", subcategory: "" });
    },
    onError: (error: Error) => {
      toast({ title: "Błąd", description: error.message, variant: "destructive" });
    },
  });

  const deleteVideoMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("repair_videos").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-repair-videos"] });
      toast({ title: "Film usunięty" });
    },
    onError: (error: Error) => {
      toast({ title: "Błąd", description: error.message, variant: "destructive" });
    },
  });

  const updateVideoMutation = useMutation({
    mutationFn: async ({ id, data }: { id: string; data: Partial<VideoFormData> }) => {
      let videoId = data.video_id;
      if (videoId && (videoId.includes("youtube.com") || videoId.includes("youtu.be"))) {
        const match = videoId.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/);
        if (match) videoId = match[1];
      }

      const { error } = await supabase
        .from("repair_videos")
        .update({
          category_slug: data.category_slug,
          video_id: videoId,
          title: data.title,
          subcategory: data.subcategory || null,
        })
        .eq("id", id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-repair-videos"] });
      toast({ title: "Film zaktualizowany" });
      setIsEditDialogOpen(false);
      setEditingVideo(null);
    },
    onError: (error: Error) => {
      toast({ title: "Błąd", description: error.message, variant: "destructive" });
    },
  });

  const handleEditClick = (video: RepairVideo) => {
    setEditingVideo(video);
    setEditForm({
      category_slug: video.category_slug,
      video_id: video.video_id,
      title: video.title,
      subcategory: video.subcategory || "",
    });
    setIsEditDialogOpen(true);
  };

  const handleUpdateVideo = () => {
    if (!editingVideo || !editForm.category_slug || !editForm.video_id || !editForm.title) {
      toast({ title: "Wypełnij wymagane pola", variant: "destructive" });
      return;
    }

    updateVideoMutation.mutate({
      id: editingVideo.id,
      data: editForm,
    });
  };

  const handleAddVideo = () => {
    if (!newVideo.category_slug || !newVideo.video_id || !newVideo.title) {
      toast({ title: "Wypełnij wymagane pola", variant: "destructive" });
      return;
    }

    // Extract video ID from URL if pasted full URL
    let videoId = newVideo.video_id;
    if (videoId.includes("youtube.com") || videoId.includes("youtu.be")) {
      const match = videoId.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/);
      if (match) videoId = match[1];
    }

    addVideoMutation.mutate({
      category_slug: newVideo.category_slug,
      video_id: videoId,
      title: newVideo.title,
      subcategory: newVideo.subcategory,
    });
  };

  const filteredVideos = videos?.filter(
    (v) => selectedCategory === "all" || v.category_slug === selectedCategory
  );

  const getCategoryTitle = (slug: string) => {
    const cat = repairCategories.find((c) => c.slug === slug);
    return cat?.title || slug;
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-heading text-2xl font-bold text-foreground flex items-center gap-3">
            <Youtube className="h-6 w-6 text-primary" />
            Filmy napraw
          </h2>
          <p className="text-muted-foreground mt-1">
            Zarządzanie filmami YouTube w kategoriach napraw
          </p>
        </div>

        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button className="gap-2">
              <Plus className="h-4 w-4" />
              Dodaj film
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Dodaj nowy film</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label>Kategoria *</Label>
                <Select
                  value={newVideo.category_slug}
                  onValueChange={(v) => setNewVideo({ ...newVideo, category_slug: v })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Wybierz kategorię" />
                  </SelectTrigger>
                  <SelectContent>
                    {repairCategories.map((cat) => (
                      <SelectItem key={cat.slug} value={cat.slug}>
                        {cat.title}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>ID filmu YouTube lub URL *</Label>
                <Input
                  placeholder="np. dQw4w9WgXcQ lub https://youtube.com/watch?v=..."
                  value={newVideo.video_id}
                  onChange={(e) => setNewVideo({ ...newVideo, video_id: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label>Tytuł filmu *</Label>
                <Input
                  placeholder="np. Naprawa anteny R107"
                  value={newVideo.title}
                  onChange={(e) => setNewVideo({ ...newVideo, title: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label>Podkategoria (opcjonalnie)</Label>
                <Input
                  placeholder="np. Antena, Głośniki"
                  value={newVideo.subcategory}
                  onChange={(e) => setNewVideo({ ...newVideo, subcategory: e.target.value })}
                />
                <p className="text-xs text-muted-foreground">
                  Filmy z tą samą podkategorią będą grupowane razem
                </p>
              </div>

              <Button
                className="w-full"
                onClick={handleAddVideo}
                disabled={addVideoMutation.isPending}
              >
                {addVideoMutation.isPending ? "Dodawanie..." : "Dodaj film"}
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      <div className="flex items-center gap-4">
        <Label>Filtruj po kategorii:</Label>
        <Select value={selectedCategory} onValueChange={setSelectedCategory}>
          <SelectTrigger className="w-[200px]">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Wszystkie kategorie</SelectItem>
            {repairCategories.map((cat) => (
              <SelectItem key={cat.slug} value={cat.slug}>
                {cat.title}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        </div>
      ) : filteredVideos && filteredVideos.length > 0 ? (
        <div className="card-automotive overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow className="border-border/50 hover:bg-transparent">
                <TableHead className="w-[120px]">Miniatura</TableHead>
                <TableHead>Tytuł</TableHead>
                <TableHead>Kategoria</TableHead>
                <TableHead>Podkategoria</TableHead>
                <TableHead className="w-[80px]">Akcje</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredVideos.map((video) => (
                <TableRow key={video.id} className="border-border/30">
                  <TableCell>
                    <a
                      href={`https://youtube.com/watch?v=${video.video_id}`}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      <img
                        src={`https://img.youtube.com/vi/${video.video_id}/default.jpg`}
                        alt={video.title}
                        className="w-24 h-auto rounded"
                      />
                    </a>
                  </TableCell>
                  <TableCell className="font-medium text-foreground">
                    <a
                      href={`https://youtube.com/watch?v=${video.video_id}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="hover:text-primary transition-colors"
                    >
                      {video.title}
                    </a>
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {getCategoryTitle(video.category_slug)}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {video.subcategory || "-"}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1">
                      <Button
                        variant="ghost"
                        size="icon"
                        className="text-muted-foreground hover:text-primary hover:bg-primary/10"
                        onClick={() => handleEditClick(video)}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="text-destructive hover:text-destructive hover:bg-destructive/10"
                        onClick={() => deleteVideoMutation.mutate(video.id)}
                        disabled={deleteVideoMutation.isPending}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      ) : (
        <div className="card-automotive p-12 text-center">
          <Film className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-foreground mb-2">
            Brak filmów
          </h3>
          <p className="text-muted-foreground">
            Dodaj pierwszy film klikając przycisk powyżej.
          </p>
        </div>
      )}

      {/* Edit Dialog */}
      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edytuj film</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 pt-4">
            <div className="space-y-2">
              <Label>Kategoria *</Label>
              <Select
                value={editForm.category_slug}
                onValueChange={(v) => setEditForm({ ...editForm, category_slug: v })}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Wybierz kategorię" />
                </SelectTrigger>
                <SelectContent>
                  {repairCategories.map((cat) => (
                    <SelectItem key={cat.slug} value={cat.slug}>
                      {cat.title}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>ID filmu YouTube lub URL *</Label>
              <Input
                placeholder="np. dQw4w9WgXcQ lub https://youtube.com/watch?v=..."
                value={editForm.video_id}
                onChange={(e) => setEditForm({ ...editForm, video_id: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label>Tytuł filmu *</Label>
              <Input
                placeholder="np. Naprawa anteny R107"
                value={editForm.title}
                onChange={(e) => setEditForm({ ...editForm, title: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label>Podkategoria (opcjonalnie)</Label>
              <Input
                placeholder="np. Antena, Głośniki"
                value={editForm.subcategory}
                onChange={(e) => setEditForm({ ...editForm, subcategory: e.target.value })}
              />
              <p className="text-xs text-muted-foreground">
                Filmy z tą samą podkategorią będą grupowane razem
              </p>
            </div>

            <Button
              className="w-full"
              onClick={handleUpdateVideo}
              disabled={updateVideoMutation.isPending}
            >
              {updateVideoMutation.isPending ? "Zapisywanie..." : "Zapisz zmiany"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

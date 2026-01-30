import { useState, useRef, useCallback } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Wrench, Save, Plus, Bold, Italic, List, Link, Code, Eye, Palette } from "lucide-react";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Toggle } from "@/components/ui/toggle";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { repairCategories } from "@/data/repairCategories";

interface RepairPart {
  id: string;
  category_slug: string;
  content_html: string;
  created_at: string;
  updated_at: string;
}

export function RepairPartsManager() {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [selectedCategory, setSelectedCategory] = useState<string>("lusterka");
  const [content, setContent] = useState<string>("");
  const [isEditing, setIsEditing] = useState(false);
  const [editorMode, setEditorMode] = useState<"visual" | "html">("visual");
  const editorRef = useRef<HTMLDivElement>(null);

  const { data: parts, isLoading } = useQuery({
    queryKey: ["repair-parts"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("repair_parts")
        .select("*")
        .order("category_slug");

      if (error) throw error;
      return data as RepairPart[];
    },
  });

  const currentPart = parts?.find((p) => p.category_slug === selectedCategory);

  const saveMutation = useMutation({
    mutationFn: async (htmlContent: string) => {
      if (currentPart) {
        const { error } = await supabase
          .from("repair_parts")
          .update({ content_html: htmlContent })
          .eq("id", currentPart.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from("repair_parts").insert({
          category_slug: selectedCategory,
          content_html: htmlContent,
        });
        if (error) throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["repair-parts"] });
      toast({
        title: "Zapisano",
        description: "Części zamienne zostały zaktualizowane.",
      });
      setIsEditing(false);
    },
    onError: (error: any) => {
      toast({
        title: "Błąd",
        description: error.message || "Nie udało się zapisać.",
        variant: "destructive",
      });
    },
  });

  const handleCategoryChange = (slug: string) => {
    setSelectedCategory(slug);
    const part = parts?.find((p) => p.category_slug === slug);
    setContent(part?.content_html || "");
    setIsEditing(false);
  };

  const handleEdit = () => {
    const initialContent = currentPart?.content_html || "";
    setContent(initialContent);
    setIsEditing(true);
    // Set initial content to visual editor after a short delay
    setTimeout(() => {
      if (editorRef.current) {
        editorRef.current.innerHTML = initialContent;
      }
    }, 0);
  };

  const handleSave = () => {
    let htmlContent = content;
    if (editorMode === "visual" && editorRef.current) {
      htmlContent = editorRef.current.innerHTML;
    }
    saveMutation.mutate(htmlContent);
  };

  const syncFromVisual = useCallback(() => {
    if (editorRef.current) {
      setContent(editorRef.current.innerHTML);
    }
  }, []);

  const syncToVisual = useCallback(() => {
    if (editorRef.current) {
      editorRef.current.innerHTML = content;
    }
  }, [content]);

  const handleModeChange = (mode: string) => {
    if (mode === "html" && editorRef.current) {
      // Switching to HTML - get content from visual editor
      setContent(editorRef.current.innerHTML);
    } else if (mode === "visual") {
      // Switching to visual - set content to visual editor
      setTimeout(() => {
        if (editorRef.current) {
          editorRef.current.innerHTML = content;
        }
      }, 0);
    }
    setEditorMode(mode as "visual" | "html");
  };

  const execCommand = (command: string, value?: string) => {
    document.execCommand(command, false, value);
    editorRef.current?.focus();
  };

  const insertLink = () => {
    const url = prompt("Podaj URL linku:");
    if (url) {
      execCommand("createLink", url);
    }
  };

  const insertList = () => {
    execCommand("insertUnorderedList");
  };

  const setFontColor = (color: string) => {
    execCommand("foreColor", color);
  };

  const fontColors = [
    { name: "Czarny", value: "#000000" },
    { name: "Biały", value: "#FFFFFF" },
    { name: "Czerwony", value: "#DC2626" },
    { name: "Zielony", value: "#16A34A" },
    { name: "Niebieski", value: "#2563EB" },
    { name: "Żółty", value: "#CA8A04" },
    { name: "Pomarańczowy", value: "#EA580C" },
    { name: "Fioletowy", value: "#9333EA" },
    { name: "Różowy", value: "#DB2777" },
    { name: "Szary", value: "#6B7280" },
  ];

  const getCategoryTitle = (slug: string) => {
    return repairCategories.find((c) => c.slug === slug)?.title || slug;
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-heading text-2xl font-bold text-foreground flex items-center gap-3">
            <Wrench className="h-6 w-6 text-primary" />
            Części zamienne
          </h2>
          <p className="text-muted-foreground mt-1">
            Edytuj listę części zamiennych dla każdej kategorii napraw
          </p>
        </div>
      </div>

      <div className="flex flex-col sm:flex-row gap-4">
        <Select value={selectedCategory} onValueChange={handleCategoryChange}>
          <SelectTrigger className="w-full sm:w-[250px]">
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

        {!isEditing && (
          <Button onClick={handleEdit} variant="outline" className="gap-2">
            <Plus className="h-4 w-4" />
            {currentPart ? "Edytuj części" : "Dodaj części"}
          </Button>
        )}
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        </div>
      ) : isEditing ? (
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">
              Treść dla kategorii: {getCategoryTitle(selectedCategory)}
            </label>
            
            <Tabs value={editorMode} onValueChange={handleModeChange} className="w-full">
              <TabsList className="mb-2">
                <TabsTrigger value="visual" className="gap-2">
                  <Eye className="h-4 w-4" />
                  Edytor wizualny
                </TabsTrigger>
                <TabsTrigger value="html" className="gap-2">
                  <Code className="h-4 w-4" />
                  HTML
                </TabsTrigger>
              </TabsList>

              <TabsContent value="visual" className="mt-0">
                {/* Toolbar */}
                <div className="flex flex-wrap gap-1 p-2 border border-border rounded-t-lg bg-muted/50">
                  <Toggle
                    size="sm"
                    onClick={() => execCommand("bold")}
                    aria-label="Pogrubienie"
                  >
                    <Bold className="h-4 w-4" />
                  </Toggle>
                  <Toggle
                    size="sm"
                    onClick={() => execCommand("italic")}
                    aria-label="Kursywa"
                  >
                    <Italic className="h-4 w-4" />
                  </Toggle>
                  <Toggle
                    size="sm"
                    onClick={insertList}
                    aria-label="Lista punktowana"
                  >
                    <List className="h-4 w-4" />
                  </Toggle>
                  <Toggle
                    size="sm"
                    onClick={insertLink}
                    aria-label="Wstaw link"
                  >
                    <Link className="h-4 w-4" />
                  </Toggle>
                  
                  <Popover>
                    <PopoverTrigger asChild>
                      <Toggle size="sm" aria-label="Kolor czcionki">
                        <Palette className="h-4 w-4" />
                      </Toggle>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-2">
                      <div className="grid grid-cols-5 gap-1">
                        {fontColors.map((color) => (
                          <button
                            key={color.value}
                            onClick={() => setFontColor(color.value)}
                            className="w-6 h-6 rounded border border-border hover:scale-110 transition-transform"
                            style={{ backgroundColor: color.value }}
                            title={color.name}
                          />
                        ))}
                      </div>
                    </PopoverContent>
                  </Popover>
                </div>

                {/* Contenteditable editor */}
                <div
                  ref={editorRef}
                  contentEditable
                  className="min-h-[300px] p-4 border border-t-0 border-border rounded-b-lg bg-background focus:outline-none focus:ring-2 focus:ring-ring prose prose-sm dark:prose-invert max-w-none"
                  onBlur={syncFromVisual}
                  suppressContentEditableWarning
                />
              </TabsContent>

              <TabsContent value="html" className="mt-0">
                <Textarea
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder={`Wpisz listę części zamiennych w formacie HTML...\n\nPrzykład:\n<ul>\n  <li><strong>2 × śruby M3 × 12 mm</strong> - Symbol SFE-M3-12-A2</li>\n  <li><strong>8 × pierścienie osadcze</strong> - HETC-3.2-A2</li>\n</ul>`}
                  className="min-h-[300px] font-mono text-sm"
                />
              </TabsContent>
            </Tabs>
          </div>

          <div className="flex gap-2">
            <Button onClick={handleSave} disabled={saveMutation.isPending} className="gap-2">
              <Save className="h-4 w-4" />
              {saveMutation.isPending ? "Zapisuję..." : "Zapisz"}
            </Button>
            <Button variant="outline" onClick={() => setIsEditing(false)}>
              Anuluj
            </Button>
          </div>
        </div>
      ) : currentPart ? (
        <div className="card-automotive p-6">
          <h3 className="font-semibold text-foreground mb-4">
            Aktualna treść dla: {getCategoryTitle(selectedCategory)}
          </h3>
          <div
            className="prose prose-sm dark:prose-invert max-w-none"
            dangerouslySetInnerHTML={{ __html: currentPart.content_html }}
          />
        </div>
      ) : (
        <div className="card-automotive p-8 text-center">
          <Wrench className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-foreground mb-2">
            Brak części dla tej kategorii
          </h3>
          <p className="text-muted-foreground mb-4">
            Kliknij "Dodaj części" aby dodać listę części zamiennych dla kategorii{" "}
            {getCategoryTitle(selectedCategory)}.
          </p>
        </div>
      )}

      {isEditing && editorMode === "html" && (
        <div className="p-4 bg-muted/30 rounded-lg border border-border/50">
          <h3 className="font-semibold text-foreground mb-2">Wskazówki formatowania HTML</h3>
          <ul className="text-sm text-muted-foreground list-disc list-inside space-y-1">
            <li><code className="bg-muted px-1 py-0.5 rounded">&lt;strong&gt;tekst&lt;/strong&gt;</code> - pogrubienie</li>
            <li><code className="bg-muted px-1 py-0.5 rounded">&lt;ul&gt;&lt;li&gt;...&lt;/li&gt;&lt;/ul&gt;</code> - lista punktowana</li>
            <li><code className="bg-muted px-1 py-0.5 rounded">&lt;a href="..."&gt;link&lt;/a&gt;</code> - linki</li>
            <li><code className="bg-muted px-1 py-0.5 rounded">&lt;br&gt;</code> - nowa linia</li>
          </ul>
        </div>
      )}
    </div>
  );
}
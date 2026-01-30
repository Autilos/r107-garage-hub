import { useQuery } from "@tanstack/react-query";
import { Wrench } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";

interface RepairPartsSectionProps {
  categorySlug: string;
}

export function RepairPartsSection({ categorySlug }: RepairPartsSectionProps) {
  const { data: part, isLoading } = useQuery({
    queryKey: ["repair-parts", categorySlug],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("repair_parts")
        .select("*")
        .eq("category_slug", categorySlug)
        .maybeSingle();

      if (error) throw error;
      return data;
    },
    enabled: !!categorySlug,
  });

  if (isLoading) {
    return (
      <div className="bg-card border border-border rounded-lg p-6 mb-8">
        <div className="flex items-center gap-3 mb-4">
          <Wrench className="h-5 w-5 text-primary" />
          <h2 className="font-heading text-lg font-semibold text-foreground">
            Części zamienne
          </h2>
        </div>
        <div className="animate-pulse space-y-2">
          <div className="h-4 bg-muted rounded w-3/4"></div>
          <div className="h-4 bg-muted rounded w-1/2"></div>
          <div className="h-4 bg-muted rounded w-2/3"></div>
        </div>
      </div>
    );
  }

  if (!part) {
    return null;
  }

  return (
    <div className="bg-card border border-border rounded-lg p-6 mb-8">
      <div className="flex items-center gap-3 mb-4">
        <Wrench className="h-5 w-5 text-primary" />
        <h2 className="font-heading text-lg font-semibold text-foreground">
          Części zamienne
        </h2>
      </div>
      <div
        className="prose prose-sm dark:prose-invert max-w-none text-muted-foreground"
        dangerouslySetInnerHTML={{ __html: part.content_html }}
      />
    </div>
  );
}
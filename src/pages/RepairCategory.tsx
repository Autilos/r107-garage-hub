import { useParams, Navigate, Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft } from "lucide-react";
import { YouTubeCard } from "@/components/repairs/YouTubeCard";
import { RepairPartsSection } from "@/components/repairs/RepairPartsSection";
import { repairCategories } from "@/data/repairCategories";
import { supabase } from "@/integrations/supabase/client";
interface RepairVideo {
  id: string;
  category_slug: string;
  video_id: string;
  title: string;
  subcategory: string | null;
  sort_order: number;
}

const RepairCategory = () => {
  const { slug } = useParams<{ slug: string }>();
  const category = repairCategories.find((c) => c.slug === slug);

  const { data: videos = [], isLoading } = useQuery({
    queryKey: ["repair-videos", slug],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("repair_videos")
        .select("*")
        .eq("category_slug", slug)
        .order("sort_order");

      if (error) throw error;
      return data as RepairVideo[];
    },
    enabled: !!slug,
  });

  if (!category) {
    return <Navigate to="/naprawy" replace />;
  }

  return (
    <div className="min-h-screen py-12 md:py-20">
      <div className="container">
        <div className="mb-6">
          <Link
            to="/naprawy"
            className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            Powrót do kategorii
          </Link>
        </div>

        <main>
          <div className="mb-8">
            <h1 className="font-heading text-3xl md:text-4xl font-bold text-foreground">
              {category.title}
            </h1>
          </div>

            <div className="bg-card border border-border rounded-lg p-6 mb-8">
              <div className="flex flex-col md:flex-row gap-6">
                <div className="w-full md:w-48 shrink-0">
                  <div className="aspect-square bg-muted/30 rounded-lg p-4 flex items-center justify-center">
                    <img
                      src={category.image}
                      alt={category.title}
                      className="w-full h-full object-contain"
                    />
                  </div>
                </div>
                <div className="flex-1">
                  <h2 className="font-heading text-lg font-semibold mb-3 text-foreground">
                    Opis
                  </h2>
                  <p className="text-muted-foreground leading-relaxed">
                    {category.description}
                  </p>
                </div>
              </div>
            </div>

            <RepairPartsSection categorySlug={slug!} />

            {isLoading ? (
              <div className="flex items-center justify-center py-12">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
              </div>
            ) : videos.length > 0 ? (
              <section>
                <h2 className="font-heading text-xl font-semibold mb-4 text-foreground">
                  Filmy instruktażowe
                </h2>
                {(() => {
                  const videoCategories = [...new Set(videos.map(v => v.subcategory).filter(Boolean))];
                  
                  if (videoCategories.length > 0) {
                    return (
                      <div className="space-y-8">
                        {videoCategories.map((videoCategory) => (
                          <div key={videoCategory}>
                            <h3 className="font-heading text-lg font-medium mb-3 text-foreground border-b border-border pb-2">
                              {videoCategory}
                            </h3>
                            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                              {videos
                                .filter((v) => v.subcategory === videoCategory)
                                .map((video) => (
                                  <YouTubeCard
                                    key={video.id}
                                    videoId={video.video_id}
                                    title={video.title}
                                  />
                                ))}
                            </div>
                          </div>
                        ))}
                        {/* Videos without subcategory */}
                        {videos.filter(v => !v.subcategory).length > 0 && (
                          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                            {videos
                              .filter((v) => !v.subcategory)
                              .map((video) => (
                                <YouTubeCard
                                  key={video.id}
                                  videoId={video.video_id}
                                  title={video.title}
                                />
                              ))}
                          </div>
                        )}
                      </div>
                    );
                  }
                  
                  return (
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                      {videos.map((video) => (
                        <YouTubeCard
                          key={video.id}
                          videoId={video.video_id}
                          title={video.title}
                        />
                      ))}
                    </div>
                  );
                })()}
              </section>
            ) : (
              <div className="bg-muted/30 border border-border rounded-lg p-8 text-center">
                <p className="text-muted-foreground">
                  Wkrótce pojawią się tutaj filmy instruktażowe.
                </p>
              </div>
            )}
        </main>
      </div>
    </div>
  );
};

export default RepairCategory;

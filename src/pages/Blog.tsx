import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Skeleton } from "@/components/ui/skeleton";
import { Card, CardContent } from "@/components/ui/card";

// Interface for the article structure
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
    created_at: string;
}

export default function Blog() {
    const navigate = useNavigate();

    const { data: articles, isLoading } = useQuery({
        queryKey: ["blog-articles"],
        queryFn: async () => {
            const { data, error } = await supabase
                .from("articles" as any)
                .select("*")
                .eq("is_published", true)
                .order("created_at", { ascending: false });

            if (error) throw error;
            return (data as unknown) as Article[];
        },
    });

    return (
        <div className="min-h-screen bg-background flex flex-col">
            <main className="flex-1">
                {/* Hero Section */}
                <div className="bg-gradient-to-b from-primary/10 via-primary/5 to-background py-20 md:py-32">
                    <div className="container mx-auto px-4 text-center">
                        <h1 className="font-heading text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-4">
                            Blog R107 Garage
                        </h1>
                        <p className="text-xl md:text-2xl text-muted-foreground max-w-3xl mx-auto font-light">
                            Historia, porady i wszystko o legendarnych Mercedes-Benz R107 i C107
                        </p>
                    </div>
                </div>

                {/* Articles Grid */}
                <div className="container mx-auto px-4 py-12 md:py-16">
                    {isLoading ? (
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 md:gap-8">
                            {[1, 2, 3, 4, 5, 6].map((i) => (
                                <Card key={i} className="overflow-hidden">
                                    <Skeleton className="w-full h-64" />
                                    <CardContent className="p-6">
                                        <Skeleton className="h-6 w-3/4 mb-3" />
                                        <Skeleton className="h-4 w-full mb-2" />
                                        <Skeleton className="h-4 w-2/3" />
                                    </CardContent>
                                </Card>
                            ))}
                        </div>
                    ) : articles && articles.length > 0 ? (
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 md:gap-8">
                            {articles.map((article) => (
                                <Card
                                    key={article.id}
                                    className="group overflow-hidden hover:shadow-xl transition-all duration-300 cursor-pointer border-border"
                                    onClick={() => navigate(`/blog/${article.slug}`)}
                                >
                                    {/* Article Image */}
                                    <div className="relative h-64 overflow-hidden bg-muted">
                                        {article.image_url ? (
                                            <img
                                                src={article.image_url}
                                                alt={article.title}
                                                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                                            />
                                        ) : (
                                            <div className="w-full h-full flex items-center justify-center text-muted-foreground">
                                                <svg
                                                    className="w-16 h-16"
                                                    fill="none"
                                                    stroke="currentColor"
                                                    viewBox="0 0 24 24"
                                                >
                                                    <path
                                                        strokeLinecap="round"
                                                        strokeLinejoin="round"
                                                        strokeWidth={1.5}
                                                        d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                                                    />
                                                </svg>
                                            </div>
                                        )}
                                        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                                    </div>

                                    {/* Article Content */}
                                    <CardContent className="p-6">
                                        <h2 className="font-heading text-xl font-bold text-foreground mb-3 line-clamp-2 group-hover:text-primary transition-colors">
                                            {article.title}
                                        </h2>
                                        {article.description && (
                                            <p className="text-muted-foreground text-sm line-clamp-3 leading-relaxed">
                                                {article.description}
                                            </p>
                                        )}
                                    </CardContent>
                                </Card>
                            ))}
                        </div>
                    ) : (
                        <div className="text-center py-20">
                            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-muted mb-4">
                                <svg
                                    className="w-8 h-8 text-muted-foreground"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        strokeLinecap="round"
                                        strokeLinejoin="round"
                                        strokeWidth={1.5}
                                        d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"
                                    />
                                </svg>
                            </div>
                            <h3 className="text-xl font-semibold text-foreground mb-2">
                                Brak artykułów
                            </h3>
                            <p className="text-muted-foreground">
                                Wkrótce pojawią się tutaj nowe artykuły o Mercedes R107 i C107.
                            </p>
                        </div>
                    )}
                </div>
            </main>
        </div>
    );
}

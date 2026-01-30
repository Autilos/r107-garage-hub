import { useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Search } from "lucide-react";
import { interiorColors } from "@/data/interior-colors-data";
import { useState, useMemo } from "react";

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
    updated_at?: string;
}


// Table data for models
const modelsData = [
    {
        model: "Mercedes-Benz 280 SL",
        years: "1974–1985",
        body: "Roadster (R107)",
        engine: "R6 M110, 2746 cm³",
        power: "185 KM (EU)",
        injection: "Bosch K-Jetronic",
        features: "Wersja ekonomiczna, 14-calowe felgi Barock",
        safety: "Strefy zgniotu Béla Barényi, wzmocnione słupki A",
        produced: "25 436"
    },
    {
        model: "Mercedes-Benz 350 SL",
        years: "1971–1980",
        body: "Roadster (R107)",
        engine: "V8 M116, 3499 cm³",
        power: "200 KM (EU)",
        injection: "Bosch D/K-Jetronic",
        features: "Pierwszy model R107, opcjonalny hardtop",
        safety: "Wklejana szyba przednia, bezpieczna kolumna kierownicy",
        produced: "15 304"
    },
    {
        model: "Mercedes-Benz 350 SLC",
        years: "1971–1980",
        body: "Coupé (C107)",
        engine: "V8 M116, 3499 cm³",
        power: "200 KM (EU)",
        injection: "Bosch D/K-Jetronic",
        features: "5-osobowe nadwozie, zastąpił W111 Coupé",
        safety: "Apteczka pod tylną szybą, strefy zgniotu",
        produced: "13 925"
    },
    {
        model: "Mercedes-Benz 450 SL",
        years: "1971–1980",
        body: "Roadster (R107)",
        engine: "V8 M117, 4520 cm³",
        power: "225 KM (EU)",
        injection: "Bosch D/K-Jetronic",
        features: "Wersja USA z reflektorami sealed beam",
        safety: "Zbiornik paliwa nad tylną osią, zderzaki 5 mph (USA)",
        produced: "222 298"
    },
    {
        model: "Mercedes-Benz 450 SLC",
        years: "1972–1981",
        body: "Coupé (C107)",
        engine: "V8 M117, 4520 cm³",
        power: "225 KM (EU)",
        injection: "Bosch K-Jetronic",
        features: "Rozstaw osi +360 mm, żaluzje w oknach bocznych",
        safety: "Sztywna klatka pasażerska",
        produced: "62 888"
    },
    {
        model: "Mercedes-Benz 380 SL",
        years: "1980–1985",
        body: "Roadster (R107)",
        engine: "V8 M116, 3839 cm³",
        power: "218 KM (EU)",
        injection: "Bosch K-Jetronic",
        features: "Aluminiowy blok silnika, wskaźnik economizer",
        safety: "ABS opcjonalny od 1980, poduszka od 1982",
        produced: "53 200"
    },
    {
        model: "Mercedes-Benz 450 SLC 5.0",
        years: "1977–1981",
        body: "Coupé (C107)",
        engine: "V8 M117, 5025 cm³",
        power: "240 KM (EU)",
        injection: "Bosch K-Jetronic",
        features: "Model rajdowy, aluminiowe panele nadwozia",
        safety: "Wzmocniona konstrukcja rajdowa",
        produced: "4 405"
    },
    {
        model: "Mercedes-Benz 500 SL",
        years: "1980–1989",
        body: "Roadster (R107)",
        engine: "V8 M117, 4973 cm³",
        power: "240–245 KM (EU)",
        injection: "Bosch K/KE-Jetronic",
        features: "Topowy model europejski, aluminiowa maska",
        safety: "ABS od 1986, Side Impact Protection",
        produced: "11 812"
    },
    {
        model: "Mercedes-Benz 560 SL",
        years: "1985–1989",
        body: "Roadster (R107)",
        engine: "V8 M117, 5547 cm³",
        power: "231 KM (EU)",
        injection: "Bosch KE-Jetronic",
        features: "Model eksportowy, felgi Gullideckel 15\"",
        safety: "Knee bolster, ABS i poduszka standardowo",
        produced: "49 347"
    }
];

export default function Article() {
    const { slug } = useParams<{ slug: string }>();
    const navigate = useNavigate();

    const { data: article, isLoading } = useQuery({
        queryKey: ["article", slug],
        queryFn: async () => {
            if (!slug) throw new Error("No slug provided");

            const { data, error } = await supabase
                .from("articles" as any)
                .select("*")
                .eq("slug", slug)
                .eq("is_published", true)
                .maybeSingle();

            if (error) throw error;
            return (data as unknown) as Article;
        },
        enabled: !!slug,
    });

    const [materialFilter, setMaterialFilter] = useState<string>("Wszystkie");
    const [searchQuery, setSearchQuery] = useState("");

    const filteredColors = useMemo(() => {
        return interiorColors.filter(color => {
            const matchesMaterial = materialFilter === "Wszystkie" || color.material === materialFilter;
            const matchesSearch = color.code.includes(searchQuery) ||
                color.colorName.toLowerCase().includes(searchQuery.toLowerCase());
            return matchesMaterial && matchesSearch;
        });
    }, [materialFilter, searchQuery]);

    const materials = ["Wszystkie", "Materiał", "MB-Tex", "Skóra", "Welur"];

    // Handle SEO title and meta description
    useEffect(() => {
        if (article) {
            document.title = `${article.seo_title || article.title} | R107 Garage`;

            const metaDescription = document.querySelector('meta[name="description"]');
            if (metaDescription) {
                metaDescription.setAttribute("content", article.seo_description || article.description || "R107 Garage Blog");
            } else {
                const meta = document.createElement('meta');
                meta.name = "description";
                meta.content = article.seo_description || article.description || "R107 Garage Blog";
                document.head.appendChild(meta);
            }
        }

        return () => {
            document.title = "R107 Garage";
        };
    }, [article]);

    if (isLoading) {
        return (
            <div className="min-h-screen bg-background">
                <div className="container py-20 mx-auto px-4">
                    <Skeleton className="h-12 w-3/4 mb-4" />
                    <Skeleton className="h-6 w-1/2 mb-8" />
                    <Skeleton className="h-[400px] w-full mb-8" />
                    <div className="space-y-4">
                        <Skeleton className="h-4 w-full" />
                        <Skeleton className="h-4 w-full" />
                        <Skeleton className="h-4 w-5/6" />
                    </div>
                </div>
            </div>
        );
    }

    if (!article) {
        return (
            <div className="min-h-screen bg-background flex flex-col">
                <div className="flex-1 container py-20 mx-auto px-4 flex flex-col items-center justify-center text-center">
                    <p className="text-xl text-muted-foreground mb-6">Artykuł nie został znaleziony.</p>
                    <Button onClick={() => navigate("/blog")} variant="default">
                        <ArrowLeft className="mr-2 h-4 w-4" />
                        Wróć do bloga
                    </Button>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-background flex flex-col">
            <main className="flex-1">
                {/* Back to Blog Button */}
                <div className="container mx-auto px-4 pt-20 pb-4">
                    <Button
                        onClick={() => navigate("/blog")}
                        variant="ghost"
                        className="gap-2"
                    >
                        <ArrowLeft className="h-4 w-4" />
                        Wróć do bloga
                    </Button>
                </div>

                {/* Hero Section */}
                <div className="relative h-[60vh] min-h-[500px] overflow-hidden">
                    <div className="absolute inset-0">
                        {article.image_url || slug === "kolorystyka-wnetrz-mercedes-r107" ? (
                            <img
                                src={article.image_url || "/mercedes-r107-hero.jpg"}
                                alt={article.title}
                                className="w-full h-full object-cover scale-105"
                            />
                        ) : (
                            <div className="w-full h-full bg-muted/30 flex items-center justify-center text-muted-foreground">
                                Brak zdjęcia głównego
                            </div>
                        )}
                        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/40 to-transparent" />
                    </div>

                    <div className="absolute bottom-0 left-0 right-0 py-12 px-4">
                        <div className="container mx-auto">
                            <h1 className="font-heading text-5xl md:text-7xl font-extrabold text-foreground mb-6 leading-tight max-w-4xl tracking-tight">
                                {article.title}
                            </h1>
                            {article.description && (
                                <p className="text-xl md:text-2xl text-muted-foreground max-w-3xl font-light leading-relaxed">
                                    {article.description}
                                </p>
                            )}
                        </div>
                    </div>
                </div>

                {/* Content Section */}
                <div className="container mx-auto px-4 pt-12 pb-6">
                    <article
                        className="prose prose-lg dark:prose-invert max-w-4xl mx-auto prose-img:rounded-xl prose-headings:font-heading prose-a:text-primary hover:prose-a:text-primary/80 prose-p:leading-relaxed prose-headings:text-foreground/90 prose-p:text-muted-foreground prose-li:text-muted-foreground prose-strong:text-muted-foreground"
                        dangerouslySetInnerHTML={{ __html: article.content || "" }}
                    />
                </div>

                {/* Elegant Models Table - only show for history article */}
                {slug === "mercedes-r107-c107-historia" && (
                    <div className="max-w-6xl mx-auto mt-16 px-4">
                        <h2 className="font-heading text-3xl md:text-4xl font-bold text-center mb-8">
                            Modele serii 107 – pełne zestawienie
                        </h2>

                        <div className="overflow-x-auto rounded-2xl border border-border shadow-lg">
                            <table className="w-full text-sm">
                                <thead>
                                    <tr className="bg-gradient-to-r from-primary/20 via-primary/10 to-primary/20">
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Model</th>
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Lata</th>
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Nadwozie</th>
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Silnik</th>
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Moc</th>
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Wtrysk</th>
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Cechy</th>
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Bezpieczeństwo</th>
                                        <th className="px-4 py-4 text-right font-heading font-bold text-foreground border-b border-border">Produkcja</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {modelsData.map((row, index) => (
                                        <tr
                                            key={row.model}
                                            className={`
                                                    transition-colors hover:bg-muted/50
                                                    ${index % 2 === 0 ? 'bg-background' : 'bg-muted/20'}
                                                    ${row.body.includes('C107') ? 'border-l-4 border-l-amber-500/50' : 'border-l-4 border-l-primary/50'}
                                                `}
                                        >
                                            <td className="px-4 py-3 font-semibold text-foreground whitespace-nowrap">
                                                {row.model}
                                            </td>
                                            <td className="px-4 py-3 text-muted-foreground whitespace-nowrap">
                                                {row.years}
                                            </td>
                                            <td className="px-4 py-3">
                                                <span className={`
                                                        inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
                                                        ${row.body.includes('C107')
                                                        ? 'bg-amber-500/10 text-amber-600 dark:text-amber-400'
                                                        : 'bg-primary/10 text-primary'}
                                                    `}>
                                                    {row.body}
                                                </span>
                                            </td>
                                            <td className="px-4 py-3 text-muted-foreground text-xs">
                                                {row.engine}
                                            </td>
                                            <td className="px-4 py-3 text-foreground font-medium whitespace-nowrap">
                                                {row.power}
                                            </td>
                                            <td className="px-4 py-3 text-muted-foreground text-xs">
                                                {row.injection}
                                            </td>
                                            <td className="px-4 py-3 text-muted-foreground text-xs max-w-[200px]">
                                                {row.features}
                                            </td>
                                            <td className="px-4 py-3 text-muted-foreground text-xs max-w-[200px]">
                                                {row.safety}
                                            </td>
                                            <td className="px-4 py-3 text-right font-bold text-foreground whitespace-nowrap">
                                                {row.produced}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                                <tfoot>
                                    <tr className="bg-gradient-to-r from-primary/10 via-primary/5 to-primary/10 border-t-2 border-primary/20">
                                        <td colSpan={8} className="px-4 py-4 text-right font-heading font-bold text-foreground">
                                            Łączna produkcja serii 107:
                                        </td>
                                        <td className="px-4 py-4 text-right font-heading font-bold text-xl text-primary">
                                            300 175
                                        </td>
                                    </tr>
                                </tfoot>
                            </table>
                        </div>

                        {/* Legend */}
                        <div className="flex flex-wrap gap-4 justify-center mt-6 text-sm text-muted-foreground pb-12 border-b border-border">
                            <div className="flex items-center gap-2">
                                <span className="w-4 h-4 rounded border-l-4 border-l-primary/50 bg-muted/30"></span>
                                <span>Roadster (R107)</span>
                            </div>
                            <div className="flex items-center gap-2">
                                <span className="w-4 h-4 rounded border-l-4 border-l-amber-500/50 bg-muted/30"></span>
                                <span>Coupé (C107)</span>
                            </div>
                        </div>
                    </div>
                )}

                {/* Interior Colors Table - only show for interior colors article */}
                {slug === "kolorystyka-wnetrz-mercedes-r107" && (
                    <div className="max-w-6xl mx-auto mt-16 px-4 mb-20">

                        {/* Filters and Search */}
                        <div className="sticky top-20 z-10 bg-background/80 backdrop-blur-md p-4 mb-8 rounded-2xl border border-border shadow-sm">
                            <div className="flex flex-col md:flex-row gap-4">
                                <div className="relative flex-1">
                                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                                    <input
                                        type="text"
                                        placeholder="Szukaj po kodzie lub nazwie koloru..."
                                        value={searchQuery}
                                        onChange={(e) => setSearchQuery(e.target.value)}
                                        className="w-full bg-muted/20 border border-border rounded-xl py-3 pl-12 pr-4 text-base focus:outline-none focus:ring-2 focus:ring-primary/50 transition-all font-medium"
                                    />
                                </div>
                                <div className="flex gap-2 overflow-x-auto pb-2 md:pb-0 scrollbar-hide">
                                    {materials.map((m) => (
                                        <button
                                            key={m}
                                            onClick={() => setMaterialFilter(m)}
                                            className={`
                                                px-5 py-3 rounded-xl text-sm font-bold whitespace-nowrap transition-all
                                                ${materialFilter === m
                                                    ? 'bg-primary text-primary-foreground shadow-lg'
                                                    : 'bg-muted/50 text-muted-foreground hover:bg-muted'}
                                            `}
                                        >
                                            {m}
                                        </button>
                                    ))}
                                </div>
                            </div>
                        </div>

                        {/* Results Count */}
                        <div className="mb-4 flex items-center justify-between">
                            <p className="text-sm text-muted-foreground">
                                Znaleziono: <span className="font-bold text-foreground">{filteredColors.length}</span> kolorów
                            </p>
                            {(materialFilter !== "Wszystkie" || searchQuery) && (
                                <button
                                    onClick={() => { setMaterialFilter("Wszystkie"); setSearchQuery(""); }}
                                    className="text-xs text-primary hover:underline font-bold"
                                >
                                    Resetuj filtry
                                </button>
                            )}
                        </div>

                        {/* Colors Table */}
                        <div className="overflow-x-auto rounded-2xl border border-border shadow-lg">
                            <table className="w-full text-sm">
                                <thead>
                                    <tr className="bg-gradient-to-r from-primary/20 via-primary/10 to-primary/20">
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Kolor</th>
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Kod</th>
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Opis</th>
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Materiał</th>
                                        <th className="px-4 py-4 text-left font-heading font-bold text-foreground border-b border-border">Lata produkcji</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {filteredColors.length > 0 ? (
                                        filteredColors.map((color, index) => (
                                            <tr
                                                key={`${color.code}-${color.material}`}
                                                className={`
                                                    transition-colors hover:bg-muted/50
                                                    ${index % 2 === 0 ? 'bg-background' : 'bg-muted/20'}
                                                `}
                                            >
                                                <td className="px-4 py-3">
                                                    <div
                                                        className="w-10 h-10 rounded-full border-2 border-border shadow-inner"
                                                        style={{ backgroundColor: color.colorHex }}
                                                        title={color.colorName}
                                                    />
                                                </td>
                                                <td className="px-4 py-3 font-mono text-lg font-bold text-primary whitespace-nowrap">
                                                    {color.code}
                                                </td>
                                                <td className="px-4 py-3 font-medium text-foreground">
                                                    {color.colorName}
                                                </td>
                                                <td className="px-4 py-3">
                                                    <span className={`
                                                        inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold uppercase tracking-wider
                                                        ${color.material === 'Skóra' ? 'bg-amber-500/10 text-amber-600 dark:text-amber-400' :
                                                            color.material === 'MB-Tex' ? 'bg-blue-500/10 text-blue-600 dark:text-blue-400' :
                                                                color.material === 'Welur' ? 'bg-purple-500/10 text-purple-600 dark:text-purple-400' :
                                                                    'bg-green-500/10 text-green-600 dark:text-green-400'}
                                                    `}>
                                                        {color.material}
                                                    </span>
                                                </td>
                                                <td className="px-4 py-3 text-muted-foreground whitespace-nowrap">
                                                    {color.years}
                                                </td>
                                            </tr>
                                        ))
                                    ) : (
                                        <tr>
                                            <td colSpan={5} className="px-4 py-12 text-center">
                                                <Search className="mx-auto h-10 w-10 text-muted-foreground mb-4 opacity-20" />
                                                <p className="text-lg font-medium text-foreground mb-1">Brak wyników</p>
                                                <p className="text-muted-foreground text-sm">
                                                    Nie znaleziono koloru pasującego do "{searchQuery}"
                                                </p>
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>

                        {/* Legend */}
                        <div className="flex flex-wrap gap-4 justify-center mt-6 text-sm text-muted-foreground">
                            <div className="flex items-center gap-2">
                                <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-amber-500/10 text-amber-600 dark:text-amber-400">SKÓRA</span>
                                <span>Skóra naturalna</span>
                            </div>
                            <div className="flex items-center gap-2">
                                <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-blue-500/10 text-blue-600 dark:text-blue-400">MB-TEX</span>
                                <span>Winyl premium</span>
                            </div>
                            <div className="flex items-center gap-2">
                                <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-purple-500/10 text-purple-600 dark:text-purple-400">WELUR</span>
                                <span>Welur tekstylny</span>
                            </div>
                            <div className="flex items-center gap-2">
                                <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-green-500/10 text-green-600 dark:text-green-400">MATERIAŁ</span>
                                <span>Tkanina</span>
                            </div>
                        </div>
                    </div>
                )}
            </main>
        </div>
    );
}

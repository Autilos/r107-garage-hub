import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import {
  Search,
  Filter,
  Plus,
  ExternalLink,
  Car,
  Cog,
  MapPin,
  Calendar,
  Rss,
  User,
  ChevronDown,
  Phone,
  ChevronUp,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import {
  Pagination,
  PaginationContent,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from "@/components/ui/pagination";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";

interface Listing {
  id: string;
  title: string;
  description: string | null;
  price: number | null;
  currency: string | null;
  country: string | null;
  category: string;
  source_type: string;
  url: string | null;
  image_url: string | null;
  model_tag: string | null;
  variant_tag: string | null;
  year_from: number | null;
  year_to: number | null;
  phone_number: string | null;
  created_at: string;
  published_at: string | null;
}

const ITEMS_PER_PAGE = 9;

const countries = [
  { value: "all", label: "Kraj" },
  { value: "PL", label: "Polska" },
  { value: "US", label: "USA" },
];

const sortOptions = [
  { value: "date_desc", label: "Najnowsze" },
  { value: "date_asc", label: "Najstarsze" },
  { value: "price_asc", label: "Cena: rosnąco" },
  { value: "price_desc", label: "Cena: malejąco" },
];

// Component for listing card content with expandable description
function ListingCardContent({ 
  listing, 
  formatPrice, 
  formatDate 
}: { 
  listing: Listing; 
  formatPrice: (price: number | null, currency: string | null) => string;
  formatDate: (dateString: string | null) => string;
}) {
  const [isExpanded, setIsExpanded] = useState(false);
  const hasLongDescription = listing.description && listing.description.length > 100;

  return (
    <div className="p-4">
      <h3 className="font-heading font-semibold text-foreground mb-2 line-clamp-2 group-hover:text-primary transition-colors">
        {listing.title}
      </h3>
      
      {/* Description */}
      {listing.description && (
        <div className="mb-3">
          <p className={`text-sm text-muted-foreground ${!isExpanded ? 'line-clamp-2' : ''}`}>
            {listing.description}
          </p>
          {hasLongDescription && (
            <button
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                setIsExpanded(!isExpanded);
              }}
              className="text-xs text-primary hover:underline mt-1 flex items-center gap-1"
            >
              {isExpanded ? (
                <>
                  <ChevronUp className="h-3 w-3" />
                  Zwiń
                </>
              ) : (
                <>
                  <ChevronDown className="h-3 w-3" />
                  Czytaj więcej
                </>
              )}
            </button>
          )}
        </div>
      )}
      
      <div className="flex items-center gap-2 text-lg font-bold text-primary mb-3">
        {formatPrice(listing.price, listing.currency)}
      </div>
      <div className="flex flex-wrap items-center gap-3 text-sm text-muted-foreground">
        {listing.country && (
          <span className="flex items-center gap-1">
            <MapPin className="h-3.5 w-3.5" />
            {listing.country}
          </span>
        )}
        {listing.year_from && (
          <span className="flex items-center gap-1">
            <Calendar className="h-3.5 w-3.5" />
            {listing.year_from}
            {listing.year_to && listing.year_to !== listing.year_from
              ? `-${listing.year_to}`
              : ""}
          </span>
        )}
        <span className="flex items-center gap-1">
          <Calendar className="h-3.5 w-3.5" />
          {formatDate(listing.published_at || listing.created_at)}
        </span>
      </div>
      {listing.phone_number && listing.source_type === "user" && (
        <div className="mt-3 flex items-center gap-2 text-sm font-medium text-foreground">
          <Phone className="h-4 w-4 text-primary" />
          <a href={`tel:${listing.phone_number}`} className="hover:text-primary">
            {listing.phone_number}
          </a>
        </div>
      )}
      <div className="mt-4 flex items-center justify-between">
        {listing.url ? (
          <a
            href={listing.url}
            target="_blank"
            rel="noopener noreferrer nofollow"
            className="inline-flex items-center gap-1.5 text-sm text-secondary hover:underline"
          >
            <ExternalLink className="h-3.5 w-3.5" />
            Zobacz źródło
          </a>
        ) : (
          <span />
        )}
        {listing.country === "US" && (
          <span className="text-3xl" title="USA">🇺🇸</span>
        )}
        {listing.country === "PL" && (
          <span className="text-3xl" title="Polska">🇵🇱</span>
        )}
      </div>
    </div>
  );
}

export default function Listings() {
  const [listings, setListings] = useState<Listing[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [countryFilter, setCountryFilter] = useState("all");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [sourceFilter, setSourceFilter] = useState("all");
  const [sortBy, setSortBy] = useState("date_desc");
  const [currentPage, setCurrentPage] = useState(1);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const { user } = useAuth();

  useEffect(() => {
    fetchListings();
  }, [countryFilter, categoryFilter, sourceFilter, sortBy]);

  const fetchListings = async () => {
    setIsLoading(true);
    try {
      let query = supabase
        .from("listings")
        .select("*")
        .eq("status", "approved");

      if (countryFilter !== "all") {
        query = query.eq("country", countryFilter);
      }
      if (categoryFilter === "pojazd" || categoryFilter === "czesc") {
        query = query.eq("category", categoryFilter);
      }
      if (sourceFilter === "rss" || sourceFilter === "user") {
        query = query.eq("source_type", sourceFilter);
      }

      // Sorting - use created_at as fallback when published_at is null
      if (sortBy === "date_desc") {
        query = query.order("created_at", { ascending: false });
      } else if (sortBy === "date_asc") {
        query = query.order("created_at", { ascending: true });
      } else if (sortBy === "price_asc") {
        query = query.order("price", { ascending: true, nullsFirst: false });
      } else if (sortBy === "price_desc") {
        query = query.order("price", { ascending: false, nullsFirst: false });
      }

      const { data, error } = await query.limit(50);

      if (error) throw error;
      setListings(data || []);
    } catch (error) {
      console.error("Error fetching listings:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const filteredListings = listings.filter((listing) =>
    listing.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const totalPages = Math.ceil(filteredListings.length / ITEMS_PER_PAGE);
  const paginatedListings = filteredListings.slice(
    (currentPage - 1) * ITEMS_PER_PAGE,
    currentPage * ITEMS_PER_PAGE
  );

  // Reset to page 1 when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, countryFilter, categoryFilter, sourceFilter, sortBy]);

  const formatPrice = (price: number | null, currency: string | null) => {
    if (!price) return "Cena do uzgodnienia";
    return new Intl.NumberFormat("pl-PL", {
      style: "currency",
      currency: currency || "EUR",
      maximumFractionDigits: 0,
    }).format(price);
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return "";
    return new Date(dateString).toLocaleDateString("pl-PL", {
      day: "numeric",
      month: "short",
      year: "numeric",
    });
  };

  return (
    <div className="min-h-screen py-20">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="mb-8">
          <h1 className="font-heading text-3xl md:text-4xl font-bold text-foreground mb-2">
            Ogłoszenia
          </h1>
          <p className="text-muted-foreground">
            Pojazdy i części do Mercedes R107/C107 SL/SLC 1970-1986
          </p>
        </div>

        {/* Filters */}
        <div className="card-automotive p-4 mb-6">
          {/* Search - always visible */}
          <div className="w-full relative mb-4 lg:mb-0">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Szukaj w tytule..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>

          {/* Mobile: Collapsible Filters */}
          <div className="lg:hidden">
            <Collapsible open={filtersOpen} onOpenChange={setFiltersOpen}>
              {/* Filtry + Dodaj ogłoszenie in one row */}
              <div className="flex gap-2 mt-3">
                <CollapsibleTrigger asChild>
                  <Button 
                    variant="outline" 
                    className="flex-[2] justify-between"
                  >
                    <span className="flex items-center gap-2">
                      <Filter className="h-4 w-4" />
                      Filtry
                    </span>
                    <ChevronDown className={`h-4 w-4 transition-transform duration-200 ${filtersOpen ? 'rotate-180' : ''}`} />
                  </Button>
                </CollapsibleTrigger>
                <Link to="/ogloszenia/dodaj" className="flex-1">
                  <Button className="w-full gap-1 bg-red-600 hover:bg-red-700 text-white">
                    <Plus className="h-4 w-4" />
                    <span className="hidden xs:inline">Dodaj</span>
                  </Button>
                </Link>
              </div>
              
              <CollapsibleContent className="pt-4 space-y-3">
                <Select value={countryFilter} onValueChange={setCountryFilter}>
                  <SelectTrigger className="w-full">
                    <MapPin className="h-4 w-4 mr-2 text-muted-foreground" />
                    <SelectValue placeholder="Kraj" />
                  </SelectTrigger>
                  <SelectContent>
                    {countries.map((c) => (
                      <SelectItem key={c.value} value={c.value}>
                        {c.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>

                <Select value={categoryFilter} onValueChange={setCategoryFilter}>
                  <SelectTrigger className="w-full">
                    <Filter className="h-4 w-4 mr-2 text-muted-foreground" />
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Kategoria</SelectItem>
                    <SelectItem value="pojazd">Pojazdy</SelectItem>
                    <SelectItem value="czesc">Części</SelectItem>
                  </SelectContent>
                </Select>

                <Select value={sourceFilter} onValueChange={setSourceFilter}>
                  <SelectTrigger className="w-full">
                    <Rss className="h-4 w-4 mr-2 text-muted-foreground" />
                    <SelectValue placeholder="Źródło" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Źródło</SelectItem>
                    <SelectItem value="rss">RSS</SelectItem>
                    <SelectItem value="user">Użytkownicy</SelectItem>
                  </SelectContent>
                </Select>

                <Select value={sortBy} onValueChange={setSortBy}>
                  <SelectTrigger className="w-full">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {sortOptions.map((opt) => (
                      <SelectItem key={opt.value} value={opt.value}>
                        {opt.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </CollapsibleContent>
            </Collapsible>
          </div>

          {/* Desktop: Inline Filters */}
          <div className="hidden lg:flex flex-row gap-4 items-center mt-4">
            <div className="flex flex-wrap gap-3 flex-1">
              <Select value={countryFilter} onValueChange={setCountryFilter}>
                <SelectTrigger className="w-[140px]">
                  <MapPin className="h-4 w-4 mr-2 text-muted-foreground" />
                  <SelectValue placeholder="Kraj" />
                </SelectTrigger>
                <SelectContent>
                  {countries.map((c) => (
                    <SelectItem key={c.value} value={c.value}>
                      {c.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>

              <Select value={categoryFilter} onValueChange={setCategoryFilter}>
                <SelectTrigger className="w-[140px]">
                  <Filter className="h-4 w-4 mr-2 text-muted-foreground" />
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Kategoria</SelectItem>
                  <SelectItem value="pojazd">Pojazdy</SelectItem>
                  <SelectItem value="czesc">Części</SelectItem>
                </SelectContent>
              </Select>

              <Select value={sourceFilter} onValueChange={setSourceFilter}>
                <SelectTrigger className="w-[160px]">
                  <Rss className="h-4 w-4 mr-2 text-muted-foreground" />
                  <SelectValue placeholder="Źródło" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Źródło</SelectItem>
                  <SelectItem value="rss">RSS</SelectItem>
                  <SelectItem value="user">Użytkownicy</SelectItem>
                </SelectContent>
              </Select>

              <Select value={sortBy} onValueChange={setSortBy}>
                <SelectTrigger className="w-[160px]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {sortOptions.map((opt) => (
                    <SelectItem key={opt.value} value={opt.value}>
                      {opt.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <Link to="/ogloszenia/dodaj">
              <Button className="gap-2 bg-red-600 hover:bg-red-700 text-white shrink-0">
                <Plus className="h-4 w-4" />
                Dodaj ogłoszenie
              </Button>
            </Link>
          </div>
        </div>

        {/* Listings Grid */}
        {isLoading ? (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="card-automotive overflow-hidden">
                <div className="aspect-video skeleton-automotive" />
                <div className="p-4 space-y-3">
                  <div className="h-5 skeleton-automotive w-3/4" />
                  <div className="h-4 skeleton-automotive w-1/2" />
                  <div className="h-4 skeleton-automotive w-1/4" />
                </div>
              </div>
            ))}
          </div>
        ) : filteredListings.length === 0 ? (
          <div className="text-center py-20">
            <Car className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
            <h3 className="font-heading text-xl font-semibold text-foreground mb-2">
              Brak ogłoszeń
            </h3>
            <p className="text-muted-foreground mb-6">
              Nie znaleziono ogłoszeń spełniających kryteria.
            </p>
            {user && (
              <Link to="/ogloszenia/dodaj">
                <Button>Dodaj pierwsze ogłoszenie</Button>
              </Link>
            )}
          </div>
        ) : (
          <>
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
              {paginatedListings.map((listing) => (
                <article
                  key={listing.id}
                  className="card-automotive card-hover overflow-hidden group"
                >
                  {/* Image */}
                  <div className="aspect-video relative overflow-hidden bg-muted">
                    {listing.image_url ? (
                      <img
                        src={listing.image_url}
                        alt={listing.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <Car className="h-12 w-12 text-muted-foreground" />
                      </div>
                    )}
                    {/* Badges */}
                    <div className="absolute top-3 left-3 flex gap-2">
                      <Badge
                        variant="secondary"
                        className={
                          listing.source_type === "rss"
                            ? "badge-rss"
                            : "badge-user"
                        }
                      >
                        {listing.source_type === "rss" ? (
                          <Rss className="h-3 w-3 mr-1" />
                        ) : (
                          <User className="h-3 w-3 mr-1" />
                        )}
                        {listing.source_type === "rss" ? "RSS" : "Użytkownik"}
                      </Badge>
                      <Badge variant="outline" className="bg-background/80">
                        {listing.category === "pojazd" ? (
                          <Car className="h-3 w-3 mr-1" />
                        ) : (
                          <Cog className="h-3 w-3 mr-1" />
                        )}
                        {listing.category === "pojazd" ? "Pojazd" : "Część"}
                      </Badge>
                    </div>
                    {listing.model_tag && (
                      <Badge
                        variant="default"
                        className="absolute top-3 right-3 bg-red-600 text-white font-bold"
                      >
                        {listing.model_tag}
                      </Badge>
                    )}
                  </div>

                  {/* Content */}
                  <ListingCardContent listing={listing} formatPrice={formatPrice} formatDate={formatDate} />
                </article>
              ))}
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <Pagination className="mt-8">
                <PaginationContent>
                  <PaginationItem>
                    <PaginationPrevious
                      onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                      className={currentPage === 1 ? "pointer-events-none opacity-50" : "cursor-pointer"}
                    />
                  </PaginationItem>
                  {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
                    <PaginationItem key={page}>
                      <PaginationLink
                        onClick={() => setCurrentPage(page)}
                        isActive={currentPage === page}
                        className="cursor-pointer"
                      >
                        {page}
                      </PaginationLink>
                    </PaginationItem>
                  ))}
                  <PaginationItem>
                    <PaginationNext
                      onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                      className={currentPage === totalPages ? "pointer-events-none opacity-50" : "cursor-pointer"}
                    />
                  </PaginationItem>
                </PaginationContent>
              </Pagination>
            )}
          </>
        )}
      </div>
    </div>
  );
}

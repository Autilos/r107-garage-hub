import { useState } from "react";
import { ExternalLink, Store, Wrench, BookOpen, Plus, Clock, CheckCircle, XCircle, Loader2 } from "lucide-react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { toast } from "sonner";
import { z } from "zod";
import shopsHero from "@/assets/shops-hero.png";
import type { Tables } from "@/integrations/supabase/types";

type ShopLink = Tables<"shops_links">;

// Static links (fallback/defaults)
const defaultShops = [
  { title: "Parts Geek (1973 Mercedes)", url: "https://www.partsgeek.com/ym/1973/mercedes.html" },
  { title: "RockAuto (Mercedes 450SLC 1973)", url: "https://www.rockauto.com/en/catalog/mercedes-benz" },
  { title: "MBZ Classic Parts", url: "https://mbzclassicparts.com/" },
  { title: "The SL Shop - Strona główna", url: "https://parts.theslshop.com/" },
  { title: "Mercedes Classic Parts", url: "https://mercedes-classic-parts.com/" },
  { title: "MB Classics", url: "https://www.mbclassics.de/W107-R107-SL-C107-SLC" },
  { title: "Niemöller", url: "https://www.niemoeller.de/de/catalog-sl/w107" },
  { title: "SLS", url: "https://www.sls-hh-shop.de/de/mercedes-280-560sl-w107" },
  { title: "Oldtimer Ersatzteile 24", url: "https://oldtimer-ersatzteile24.de/" },
  { title: "URO Parts & Autotecnica (APA Industries)", url: "https://apaindustries.com/catalog" },
];

const defaultServices = [
  { title: "Galwanizacja, chromy", url: "https://www.kanonik.com.pl/" },
  { title: "Naprawa desek rozdzielczych", url: "https://naprawadeski.pl/" },
];

const defaultCatalogs = [
  { title: "Nemiga Parts (Katalog Mercedes)", url: "https://nemigaparts.com/cat_spares/epc/mercedes/1/" },
  { title: "MBRC107 Club - Schematy elektryczne W107", url: "https://mbrc107club.nl/techn/schemas.html" },
  { title: "Scribd - Manual Mercedes-Benz W107/R107/C107", url: "https://www.scribd.com/document/358008317/Mercedes-Benz-280-500SL-SLC-W107-R107-C107" },
  { title: "MB107 - Zbiór dokumentów PDF", url: "https://mb107.com/guides/pdf-docs.htm" },
  { title: "Mercedes Club CZ - Manuale W107", url: "https://en.mercedesclub.cz/manuals.php?ddlb_category=11&ddlb_model=105" },
  { title: "Stare Broszury Mercedes-Benz", url: "https://oudemercedesbrochures.nl/index.html" },
];

const formSchema = z.object({
  title: z.string().trim().min(3, "Nazwa musi mieć min. 3 znaki").max(100, "Nazwa max. 100 znaków"),
  url: z.string().trim().url("Nieprawidłowy adres URL"),
  type: z.enum(["sklep", "usluga", "katalog"]),
});

function LinkCard({ link }: { link: { title: string; url: string } }) {
  return (
    <a
      href={link.url}
      target="_blank"
      rel="noopener noreferrer nofollow"
      className="group flex items-center justify-between gap-4 p-4 rounded-xl bg-card border border-border hover:border-primary/50 hover:bg-primary/5 transition-all duration-300"
    >
      <span className="font-medium text-foreground group-hover:text-primary transition-colors">
        {link.title}
      </span>
      <ExternalLink className="h-4 w-4 text-muted-foreground group-hover:text-primary transition-colors shrink-0" />
    </a>
  );
}

function StatusBadge({ status }: { status: ShopLink["status"] }) {
  if (status === "pending") {
    return (
      <span className="inline-flex items-center gap-1 text-xs px-2 py-1 rounded-full bg-yellow-500/10 text-yellow-600">
        <Clock className="h-3 w-3" /> Oczekuje
      </span>
    );
  }
  if (status === "approved") {
    return (
      <span className="inline-flex items-center gap-1 text-xs px-2 py-1 rounded-full bg-green-500/10 text-green-600">
        <CheckCircle className="h-3 w-3" /> Zatwierdzony
      </span>
    );
  }
  return (
    <span className="inline-flex items-center gap-1 text-xs px-2 py-1 rounded-full bg-red-500/10 text-red-600">
      <XCircle className="h-3 w-3" /> Odrzucony
    </span>
  );
}

function Section({
  title,
  icon: Icon,
  links,
  description,
}: {
  title: string;
  icon: React.ElementType;
  links: { title: string; url: string }[];
  description: string;
}) {
  if (links.length === 0) return null;
  
  return (
    <section className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-3 rounded-xl bg-primary/10">
          <Icon className="h-6 w-6 text-primary" />
        </div>
        <div>
          <h2 className="font-heading text-2xl font-bold text-foreground">{title}</h2>
          <p className="text-muted-foreground text-sm">{description}</p>
        </div>
      </div>
      <div className="grid gap-3 sm:grid-cols-2">
        {links.map((link) => (
          <LinkCard key={link.url} link={link} />
        ))}
      </div>
    </section>
  );
}

function SubmitShopForm({ onSuccess }: { onSuccess: () => void }) {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const [title, setTitle] = useState("");
  const [url, setUrl] = useState("");
  const [type, setType] = useState<"sklep" | "usluga" | "katalog">("sklep");
  const [errors, setErrors] = useState<Record<string, string>>({});

  const mutation = useMutation({
    mutationFn: async (data: { title: string; url: string; type: "sklep" | "usluga" | "katalog" }) => {
      if (!user) throw new Error("Musisz być zalogowany");
      
      const { error } = await supabase.from("shops_links").insert({
        title: data.title,
        url: data.url,
        type: data.type,
        user_id: user.id,
        status: "pending",
      });
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["shops_links"] });
      queryClient.invalidateQueries({ queryKey: ["my_shops_links"] });
      toast.success("Zgłoszenie wysłane! Czeka na moderację.");
      setTitle("");
      setUrl("");
      setType("sklep");
      setErrors({});
      onSuccess();
    },
    onError: (error) => {
      toast.error("Błąd: " + error.message);
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setErrors({});
    
    const parsed = formSchema.safeParse({ title, url, type });
    if (!parsed.success) {
      const fieldErrors: Record<string, string> = {};
      parsed.error.errors.forEach((err) => {
        if (err.path[0]) {
          fieldErrors[err.path[0] as string] = err.message;
        }
      });
      setErrors(fieldErrors);
      return;
    }
    
    mutation.mutate({ title: parsed.data.title, url: parsed.data.url, type: parsed.data.type });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="title">Nazwa</Label>
        <Input
          id="title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="np. Mercedes Parts Shop"
          maxLength={100}
        />
        {errors.title && <p className="text-sm text-destructive">{errors.title}</p>}
      </div>
      
      <div className="space-y-2">
        <Label htmlFor="url">Adres URL</Label>
        <Input
          id="url"
          type="url"
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          placeholder="https://example.com"
        />
        {errors.url && <p className="text-sm text-destructive">{errors.url}</p>}
      </div>
      
      <div className="space-y-2">
        <Label htmlFor="type">Kategoria</Label>
        <Select value={type} onValueChange={(v) => setType(v as typeof type)}>
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="sklep">Sklep z częściami</SelectItem>
            <SelectItem value="usluga">Usługa</SelectItem>
            <SelectItem value="katalog">Katalog / Dokumentacja</SelectItem>
          </SelectContent>
        </Select>
        {errors.type && <p className="text-sm text-destructive">{errors.type}</p>}
      </div>
      
      <Button type="submit" className="w-full" disabled={mutation.isPending}>
        {mutation.isPending && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
        Wyślij zgłoszenie
      </Button>
    </form>
  );
}

export default function Shops() {
  const { user } = useAuth();
  const [dialogOpen, setDialogOpen] = useState(false);

  // Fetch approved shop links from database
  const { data: dbLinks = [] } = useQuery({
    queryKey: ["shops_links"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("shops_links")
        .select("*")
        .eq("status", "approved")
        .order("created_at", { ascending: false });
      
      if (error) throw error;
      return data as ShopLink[];
    },
  });

  // Fetch user's own submissions
  const { data: myLinks = [] } = useQuery({
    queryKey: ["my_shops_links", user?.id],
    queryFn: async () => {
      if (!user) return [];
      const { data, error } = await supabase
        .from("shops_links")
        .select("*")
        .eq("user_id", user.id)
        .order("created_at", { ascending: false });
      
      if (error) throw error;
      return data as ShopLink[];
    },
    enabled: !!user,
  });

  // Combine default + approved DB links
  const allShops = [
    ...defaultShops,
    ...dbLinks.filter((l) => l.type === "sklep").map((l) => ({ title: l.title, url: l.url })),
  ];
  
  const allServices = [
    ...defaultServices,
    ...dbLinks.filter((l) => l.type === "usluga").map((l) => ({ title: l.title, url: l.url })),
  ];
  
  const allCatalogs = [
    ...defaultCatalogs,
    ...dbLinks.filter((l) => l.type === "katalog").map((l) => ({ title: l.title, url: l.url })),
  ];

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <div className="relative h-[210px] md:h-[280px] overflow-hidden">
        <img
          src={shopsHero}
          alt="Mercedes R107 SL"
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/60 to-transparent" />
        <div className="absolute bottom-0 left-0 right-0 p-6 md:p-12">
          <div className="container mx-auto flex flex-col md:flex-row md:items-end md:justify-between gap-4">
            <div>
              <h1 className="font-heading text-4xl md:text-5xl font-bold text-foreground mb-2">
                Sklepy & Zasoby
              </h1>
              <p className="text-lg text-muted-foreground max-w-2xl">
                Sprawdzone źródła części, usług i dokumentacji technicznej dla Mercedes R107/C107
              </p>
            </div>
            
            {user && (
              <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
                <DialogTrigger asChild>
                  <Button className="gap-2 shrink-0">
                    <Plus className="h-4 w-4" />
                    Zgłoś nowy link
                  </Button>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Zgłoś nowy sklep / usługę</DialogTitle>
                  </DialogHeader>
                  <SubmitShopForm onSuccess={() => setDialogOpen(false)} />
                </DialogContent>
              </Dialog>
            )}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="container mx-auto px-4 py-12 space-y-16">
        {/* User's submissions */}
        {user && myLinks.length > 0 && (
          <section className="space-y-4">
            <h2 className="font-heading text-xl font-bold text-foreground">Twoje zgłoszenia</h2>
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {myLinks.map((link) => (
                <div
                  key={link.id}
                  className="flex flex-col gap-2 p-4 rounded-xl bg-card border border-border"
                >
                  <div className="flex items-start justify-between gap-2">
                    <span className="font-medium text-foreground">{link.title}</span>
                    <StatusBadge status={link.status} />
                  </div>
                  <a
                    href={link.url}
                    target="_blank"
                    rel="noopener noreferrer nofollow"
                    className="text-sm text-muted-foreground hover:text-primary truncate"
                  >
                    {link.url}
                  </a>
                </div>
              ))}
            </div>
          </section>
        )}

        <Section
          title="Sklepy z częściami"
          icon={Store}
          links={allShops}
          description="Sprawdzeni dostawcy części zamiennych do R107 i C107"
        />

        <Section
          title="Usługi"
          icon={Wrench}
          links={allServices}
          description="Specjaliści w renowacji i naprawach klasycznych Mercedesów"
        />

        <Section
          title="Katalogi i dokumentacja"
          icon={BookOpen}
          links={allCatalogs}
          description="Schematy, instrukcje i materiały techniczne"
        />
        
        {!user && (
          <div className="text-center py-8 px-4 rounded-xl bg-muted/30 border border-border">
            <p className="text-muted-foreground mb-3">
              Chcesz dodać sklep lub usługę do listy?
            </p>
            <Button variant="outline" asChild>
              <a href="/konto">Zaloguj się</a>
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}

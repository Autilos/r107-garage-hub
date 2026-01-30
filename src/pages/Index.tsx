import { Link } from "react-router-dom";
import { ArrowRight, BookOpen, ShieldCheck, Zap } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Carousel,
  CarouselContent,
  CarouselItem,
} from "@/components/ui/carousel";
import heroCar from "@/assets/hero-car.png";
import carsLineup from "@/assets/cars-lineup.png";
import listingsIcon from "@/assets/listings-home.png";
import repairsIcon from "@/assets/repairs-home.png";
import shopsIcon from "@/assets/shops-home.png";

const features = [
  {
    href: "/ogloszenia",
    image: listingsIcon,
    title: "Giełda Klasyków",
    description:
      "Wyselekcjonowane ogłoszenia z najlepszych światowych portali. Inteligentne filtrowanie modeli R107 i C107.",
    cta: "Zobacz ogłoszenia",
    color: "primary",
    bgClass: "bg-primary/5",
    hoverBgClass: "group-hover:bg-primary/10",
  },
  {
    href: "/naprawy",
    image: repairsIcon,
    title: "Centrum Serwisowe",
    description:
      "Kompletne instrukcje napraw, numery części i tutoriale wideo. Wszystko, czego potrzebujesz do renowacji.",
    cta: "Przeglądaj naprawy",
    color: "secondary",
    bgClass: "bg-secondary/5",
    hoverBgClass: "group-hover:bg-secondary/10",
  },
  {
    href: "/sklepy",
    image: shopsIcon,
    title: "Części i Usługi",
    description:
      "Baza sprawdzonych dostawców części i warsztatów specjalizujących się w klasycznych Mercedesach.",
    cta: "Znajdź sklep",
    color: "amber-500",
    bgClass: "bg-amber-500/5",
    hoverBgClass: "group-hover:bg-amber-500/10",
  },
];

export default function Index() {
  return (
    <div className="min-h-screen bg-background">
      {/* Hero Section */}
      <section className="relative min-h-screen flex items-center overflow-hidden">
        {/* Background image with overlay */}
        <div
          className="absolute inset-0 bg-cover bg-center bg-no-repeat scale-105"
          style={{ backgroundImage: `url(${heroCar})` }}
        />
        <div className="absolute inset-0 bg-gradient-to-r from-background via-background/95 to-transparent" />
        <div className="absolute inset-x-0 bottom-0 h-32 bg-gradient-to-t from-background to-transparent" />

        <div className="container relative z-10 mx-auto px-4 py-20">
          <div className="max-w-3xl animate-slide-up">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 border border-primary/20 text-primary text-sm font-bold mb-6">
              <ShieldCheck className="h-4 w-4" />
              Legendarna Seria 107
            </div>
            <h1 className="font-heading text-5xl md:text-7xl lg:text-8xl font-black leading-[1.1] mb-8 tracking-tighter">
              PASJA DO<br />
              <span className="text-gradient-red uppercase">Perfekcji</span>
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground mb-10 max-w-xl font-light leading-relaxed">
              Kompleksowe kompendium wiedzy dla właścicieli Mercedesów R107 i C107. Od historii, przez naprawy, aż po rynek wtórny.
            </p>
            <div className="flex flex-wrap gap-6">
              <Link to="/ogloszenia">
                <Button size="lg" className="h-14 px-8 text-lg font-bold gap-2 btn-primary-glow">
                  Przeglądaj rynek
                  <ArrowRight className="h-5 w-5" />
                </Button>
              </Link>
              <Link to="/naprawy">
                <Button size="lg" variant="outline" className="h-14 px-8 text-lg font-bold gap-2 border-2 hover:bg-muted/50 transition-all">
                  Dokumentacja DIY
                </Button>
              </Link>
            </div>
          </div>
        </div>

        {/* Floating Stat/Note */}
        <div className="absolute bottom-20 right-10 hidden lg:block animate-bounce-slow">
          <div className="glass-morphism p-6 rounded-2xl border border-white/10 shadow-2xl">
            <p className="text-xs font-bold uppercase tracking-widest text-primary mb-1">Status Projektu</p>
            <p className="text-2xl font-black text-foreground">300,175</p>
            <p className="text-sm text-muted-foreground">Wyprodukowanych egzemplarzy</p>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-32 relative">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row md:items-end justify-between mb-16 gap-8">
            <div className="max-w-2xl">
              <h2 className="font-heading text-4xl md:text-5xl font-black text-foreground mb-6 tracking-tight">
                EKOSYSTEM R107 GARAGE
              </h2>
              <p className="text-xl text-muted-foreground leading-relaxed">
                Stworzyliśmy przestrzeń, która łączy historyczną pasję z nowoczesną technologią, wspierając utrzymanie legendy w doskonałej kondycji.
              </p>
            </div>
            <div className="flex items-center gap-4 py-2 border-b-2 border-primary/20">
              <Zap className="h-6 w-6 text-primary" />
              <span className="font-bold tracking-widest text-sm uppercase">Wszystko w jednym miejscu</span>
            </div>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {features.map((feature) => (
              <Link
                key={feature.href}
                to={feature.href}
                className={`group relative overflow-hidden rounded-3xl border border-border p-8 transition-all hover:shadow-2xl hover:-translate-y-2 ${feature.bgClass}`}
              >
                <div className="aspect-square w-full mb-8 overflow-hidden rounded-2xl bg-black border border-white/5">
                  <img
                    src={feature.image}
                    alt={feature.title}
                    className="w-full h-full object-contain p-4 group-hover:scale-110 transition-transform duration-500"
                  />
                </div>
                <h3 className="font-heading text-2xl font-bold text-foreground mb-4">
                  {feature.title}
                </h3>
                <p className="text-muted-foreground leading-relaxed mb-6">
                  {feature.description}
                </p>
                <div className="flex items-center gap-2 font-bold text-sm uppercase tracking-wider group-hover:gap-4 transition-all" style={{ color: `var(--${feature.color})` }}>
                  {feature.cta}
                  <ArrowRight className="h-4 w-4" />
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Blog & History Section - NEW */}
      <section className="py-32 bg-muted/30 relative overflow-hidden">
        <div className="container mx-auto px-4">
          <div className="grid lg:grid-cols-2 gap-20 items-center">
            <div className="order-2 lg:order-1">
              <div className="relative rounded-3xl overflow-hidden shadow-2xl aspect-video md:aspect-auto md:h-[600px]">
                <img
                  src={carsLineup}
                  alt="Historia Mercedes R107"
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent" />
                <div className="absolute bottom-10 left-10 p-2 glass-morphism rounded-xl border border-white/10">
                  <p className="text-sm font-bold text-white px-3 flex items-center gap-2">
                    <BookOpen className="h-4 w-4 text-primary" />
                    KULTOWY DESIGN
                  </p>
                </div>
              </div>
            </div>
            <div className="order-1 lg:order-2 space-y-8">
              <div className="space-y-4">
                <h2 className="font-heading text-4xl md:text-6xl font-black text-foreground tracking-tighter">
                  HISTORIA I<br />
                  <span className="text-primary">Ewolucja</span>
                </h2>
                <div className="h-1 w-24 bg-primary" />
              </div>
              <p className="text-xl text-muted-foreground leading-relaxed">
                Od debiutu w 1971 roku po ostatnie egzemplarze z 1989 roku. Odkryj fascynującą historię modelu, który zdefiniował pojęcie luksusowego roadstera dla całego pokolenia.
              </p>
              <div className="grid gap-6">
                <div className="flex gap-4 items-start">
                  <div className="p-2 rounded-lg bg-primary/10 text-primary font-bold">01</div>
                  <div>
                    <h4 className="font-bold text-foreground">Modele i Specyfikacje</h4>
                    <p className="text-sm text-muted-foreground">Szczegółowe zestawienie silników, wersji wyposażenia i ewolucji modelu.</p>
                  </div>
                </div>
                <div className="flex gap-4 items-start">
                  <div className="p-2 rounded-lg bg-primary/10 text-primary font-bold">02</div>
                  <div>
                    <h4 className="font-bold text-foreground">Kolorystyka Wnętrz</h4>
                    <p className="text-sm text-muted-foreground">Przewodnik po oryginalnych materiałach i kodach kolorów MB-Tex, skóry i tkanin.</p>
                  </div>
                </div>
              </div>
              <Link to="/blog">
                <Button size="lg" variant="default" className="h-14 px-10 text-lg font-bold gap-2">
                  Czytaj Bloga
                  <ArrowRight className="h-5 w-5" />
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Community CTA Section */}
      <section className="py-40 relative overflow-hidden bg-black">
        <div className="absolute inset-0 opacity-20 bg-[url('https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&q=80')] bg-cover bg-center" />
        <div className="absolute inset-0 bg-gradient-to-b from-black via-black/80 to-black" />

        <div className="container relative z-10 mx-auto px-4 text-center space-y-12">
          <h2 className="font-heading text-5xl md:text-7xl font-black text-white tracking-tighter max-w-4xl mx-auto uppercase">
            Stań się częścią<br />
            <span className="text-primary">legendy</span>
          </h2>
          <p className="text-xl md:text-2xl text-white/60 max-w-2xl mx-auto font-light leading-relaxed">
            Dołącz do społeczności właścicieli i pasjonatów R107. Dziel się wiedzą, znajduj unikalne ogłoszenia i buduj razem z nami największą bazę o modelu.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-6">
            <Link to="/konto">
              <Button size="lg" className="h-16 px-12 text-xl font-bold gap-2 btn-primary-glow w-full sm:w-auto">
                Dołącz teraz
                <ArrowRight className="h-6 w-6" />
              </Button>
            </Link>
            <Link to="/blog/mercedes-r107-c107-historia">
              <Button size="lg" variant="ghost" className="h-16 px-10 text-xl font-bold text-white hover:bg-white/10 w-full sm:w-auto">
                Poznaj Historię
              </Button>
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
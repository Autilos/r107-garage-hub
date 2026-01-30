import kokpitImg from "@/assets/repairs/kokpit.png";
import silnikImg from "@/assets/repairs/silnik.png";
import radioImg from "@/assets/repairs/radio.png";
import lusterkaImg from "@/assets/repairs/lusterka.png";
import zaworPowietrzaImg from "@/assets/repairs/zawor-powietrza.png";
import dekorImg from "@/assets/repairs/dekor.png";
import drzwiImg from "@/assets/repairs/drzwi.png";
import ukladPaliwowyImg from "@/assets/repairs/uklad-paliwowy.png";
import hamulceImg from "@/assets/repairs/hamulce.png";
import zawieszenieImg from "@/assets/repairs/zawieszenie.png";
import elektrykaImg from "@/assets/repairs/elektryka.png";
import nadwozieImg from "@/assets/repairs/nadwozie.png";
import wnetrzeImg from "@/assets/repairs/wnetrze.png";
import serwisImg from "@/assets/repairs/serwis.png";
import ogolneImg from "@/assets/repairs/ogolne.png";
import napedImg from "@/assets/repairs/naped.png";
import skrzyniaImg from "@/assets/repairs/skrzynia-biegow.png";
import podzespolyImg from "@/assets/repairs/podzespoly.png";

export interface YouTubeVideo {
  id: string;
  title: string;
  category?: string;
}

export interface RepairCategory {
  slug: string;
  title: string;
  image: string;
  description: string;
  videos: YouTubeVideo[];
}

export const repairCategories: RepairCategory[] = [
  {
    slug: "kokpit",
    title: "Kokpit",
    image: kokpitImg,
    description: "Wszystko o kokpicie Mercedes R107/C107 - deska rozdzielcza, zegary, przełączniki i elementy wykończeniowe. Poradniki dotyczące renowacji i naprawy elementów wnętrza.",
    videos: [],
  },
  {
    slug: "radio",
    title: "Radio",
    image: radioImg,
    description: "Radia Becker i inne systemy audio stosowane w R107/C107. Naprawa, modernizacja i wymiana na nowoczesne jednostki z zachowaniem klasycznego wyglądu.",
    videos: [],
  },
  {
    slug: "lusterka",
    title: "Lusterka",
    image: lusterkaImg,
    description: "Lusterka boczne i wsteczne Mercedes R107/C107. Demontaż, naprawa mechanizmów regulacji i wymiana szkieł.",
    videos: [],
  },
  {
    slug: "silnik",
    title: "Silnik",
    image: silnikImg,
    description: "Silniki M110, M116, M117 stosowane w R107/C107. Serwis, diagnostyka i naprawy główne jednostek napędowych.",
    videos: [],
  },
  {
    slug: "naped",
    title: "Napęd",
    image: napedImg,
    description: "Wał napędowy, mosty i półosie. Diagnostyka i naprawa układu przeniesienia napędu.",
    videos: [],
  },
  {
    slug: "skrzynia-biegow",
    title: "Skrzynia Biegów",
    image: skrzyniaImg,
    description: "Automatyczne i manualne skrzynie biegów. Obsługa, naprawa i regulacja.",
    videos: [],
  },
  {
    slug: "podzespoly",
    title: "Podzespoły i Klimatyzacja",
    image: podzespolyImg,
    description: "Osprzęt silnika, klimatyzacja (ACC), ogrzewanie i inne kluczowe podzespoły.",
    videos: [],
  },
  {
    slug: "zawor-powietrza",
    title: "Zawór powietrza",
    image: zaworPowietrzaImg,
    description: "Zawory powietrza i regulacji dopalania w silnikach R107/C107. Diagnostyka, naprawa i wymiana zaworów.",
    videos: [],
  },
  {
    slug: "dekor",
    title: "Dekor",
    image: dekorImg,
    description: "Elementy dekoracyjne i wykończeniowe Mercedes R107/C107. Listwy, emblematy, nakładki i detale wizualne.",
    videos: [],
  },
  {
    slug: "drzwi",
    title: "Drzwi",
    image: drzwiImg,
    description: "Drzwi Mercedes R107/C107 - naprawa, demontaż, renowacja i konserwacja. Poradniki dotyczące mechanizmów zamków, regulacji i blacharki.",
    videos: [],
  },
  {
    slug: "uklad-paliwowy",
    title: "Układ paliwowy",
    image: ukladPaliwowyImg,
    description: "Systemy wtryskowe (K/KE/D-Jetronic), pompy paliwa, zbiorniki i przewody. Kompleksowa diagnostyka i regulacja układu zasilania.",
    videos: [],
  },
  {
    slug: "hamulce",
    title: "Hamulce",
    image: hamulceImg,
    description: "Układ hamulcowy, serwo, pompa hamulcowa oraz system ABS. Wymiana tarcz, klocków i regeneracja zacisków.",
    videos: [],
  },
  {
    slug: "zawieszenie",
    title: "Zawieszenie",
    image: zawieszenieImg,
    description: "Zawieszenie przednie i tylne, układ kierowniczy, amortyzatory i tuleje. Ustawianie geometrii i renowacja wózków podwozia.",
    videos: [],
  },
  {
    slug: "elektryka",
    title: "Elektryka",
    image: elektrykaImg,
    description: "Instalacja elektryczna, przekaźniki, bezpieczniki, zapłon oraz oświetlenie. Rozwiązywanie problemów z prądem w klasycznym SL.",
    videos: [],
  },
  {
    slug: "nadwozie",
    title: "Nadwozie i Dach",
    image: nadwozieImg,
    description: "Karoseria, blacharka, usuwanie rdzy oraz obsługa dachów (Soft Top i Hardtop). Uszczelki i elementy wizualne.",
    videos: [],
  },
  {
    slug: "wnetrze",
    title: "Wnętrze",
    image: wnetrzeImg,
    description: "Tapicerka, fotele, dywany oraz renowacja wnętrza. Komfort i detale w kabinie R107.",
    videos: [],
  },
  {
    slug: "serwis",
    title: "Serwis i Konserwacja",
    image: serwisImg,
    description: "Okresowe przeglądy, wymiana płynów, detailing oraz czyszczenie suchym lodem. Jak dbać o klasyka na co dzień.",
    videos: [],
  },
  {
    slug: "ogolne",
    title: "Ogólne i Zakup",
    image: ogolneImg,
    description: "Poradniki zakupowe, historia modelu, numery seryjne oraz relacje z wydarzeń i zlotów Mercedes SL.",
    videos: [],
  },
];

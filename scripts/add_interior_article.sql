-- Insert Mercedes R107/C107 Interior Article
-- Run this in Supabase SQL Editor

INSERT INTO articles (
  slug,
  title,
  description,
  seo_title,
  seo_description,
  content,
  is_published,
  image_url
) VALUES (
  'mercedes-r107-c107-kolorystyka-wnetrza-specyfikacja',
  'Mercedes R107 & C107: Przewodnik po Kolorystyce i Materiałach Wnętrza (1971–1989)',
  'Kompletna analiza wnętrz Mercedesa R107 i C107. Poznaj kody kolorów, ewolucję materiałów (MB-Tex, skóra, welur) oraz różnice między generacjami SL i SLC. Niezbędnik dla kolekcjonera i renowatora.',
  'Mercedes R107 & C107: Przewodnik po Kolorystyce i Materiałach Wnętrza (1971–1989)',
  'Kompletna analiza wnętrz Mercedesa R107 i C107. Poznaj kody kolorów, ewolucję materiałów (MB-Tex, skóra, welur) oraz różnice między generacjami SL i SLC. Niezbędnik dla kolekcjonera i renowatora.',
  '<h1>Ewolucja i Specyfikacja Wnętrza Mercedes-Benz R107 oraz C107 (1971–1989)</h1>
    
    <p>Seria 107, obejmująca roadstera (R107) oraz coupé (C107), to jeden z najdłużej produkowanych modeli w historii Mercedes-Benz. Przez 18 lat produkcji wnętrze tych aut przeszło fascynującą ewolucję – od surowego, technicznego stylu wczesnych lat 70., po luksusowe, naszpikowane elektroniką wykończenia z końcówki lat 80.</p>

    <h2>1. Architektura Wnętrza: R107 vs. C107</h2>
    <p>Choć oba modele dzielą ten sam język projektowy, ich wnętrza różnią się przeznaczeniem:</p>
    <ul>
        <li><strong>R107 (SL):</strong> Klasyczny dwuosobowy roadster. Opcjonalnie wyposażany w małą, składaną kanapę tylną (tzw. Kinderseats), która jednak w praktyce służyła jako dodatkowa przestrzeń na bagaż.</li>
        <li><strong>C107 (SLC):</strong> Pełnowartościowe, czteroosobowe coupé o rozstawie osi dłuższym o 36 cm. Wnętrze SLC oferowało znacznie więcej miejsca z tyłu, z charakterystycznymi żebrowanymi panelami bocznymi przy tylnych oknach.</li>
    </ul>

    <h2>2. Trzy Ery Wykończenia (Ewolucja Stylu)</h2>
    
    <h3>I. Wczesna faza (1971–1980): Era Chromu i „Karo"</h3>
    <p>Wczesne modele (np. 350 SL, 450 SL) charakteryzowały się dużą ilością chromowanych detali (np. klamki, obwódki zegarów).</p>
    <ul>
        <li><strong>Materiały:</strong> Królowała tapicerka materiałowa w kratę (tzw. <span class="highlight">Karo</span>) oraz wczesne wersje MB-Tex (skóra syntetyczna).</li>
        <li><strong>Detale:</strong> Kierownice miały dużą średnicę i wąskie wieńce. Deska rozdzielcza była bardziej kanciasta, a przełączniki miały charakterystyczny, „ciężki" klik.</li>
    </ul>

    <h3>II. Faza przejściowa (1980–1985): Modernizacja Techniczna</h3>
    <p>W 1980 roku wprowadzono znaczące zmiany w ergonomii:</p>
    <ul>
        <li><strong>Kierownica:</strong> Pojawiła się nowsza, cztero-ramienna kierownica z miękkim środkiem, bardziej zbliżona do modelu W126.</li>
        <li><strong>Konsola środkowa:</strong> Zaktualizowano panel sterowania nawiewami (wprowadzenie suwaków i pokręteł o nowym designie).</li>
        <li><strong>Drewno:</strong> Standardem stało się drewno orzechowe (<span class="highlight">Zebrano</span>), które zdobiło konsolę środkową i pas przed pasażerem.</li>
    </ul>

    <h3>III. Faza późna (1985–1989): Szczyt Luksusu (300SL, 420SL, 500SL, 560SL)</h3>
    <p>Ostatnie lata produkcji to czas, w którym R107 stał się ikoną statusu.</p>
    <ul>
        <li><strong>Fotele:</strong> Zmieniono konstrukcję foteli na bardziej ergonomiczną, z charakterystycznym, gęstszym przeszyciem.</li>
        <li><strong>Elektronika:</strong> Pojawiły się opcjonalne poduszki powietrzne dla kierowcy (Airbag) oraz zaawansowane systemy audio.</li>
        <li><strong>Burl Wood:</strong> W topowych modelach (szczególnie 560SL) częściej spotykany był luksusowy czeczot orzechowy (<span class="highlight">Burl Walnut</span>) zamiast standardowego Zebrano.</li>
    </ul>

    <h2>3. Specyfikacja Materiałowa i Kolorystyczna</h2>
    <p>Mercedes oferował trzy główne typy wykończenia siedzeń:</p>
    <ul>
        <li><strong>MB-Tex (Vinyl):</strong> Niezwykle trwała skóra syntetyczna, niemal niezniszczalna, często mylona z naturalną skórą ze względu na fakturę.</li>
        <li><strong>Skóra (Leather):</strong> Naturalna, perforowana w centralnej części siedziska. Wymagała regularnej pielęgnacji, ale oferowała najwyższy komfort.</li>
        <li><strong>Welur:</strong> Bardzo prestiżowy w latach 70. i 80., oferowany w bogatej gamie kolorystycznej.</li>
    </ul>

    <div class="spec-list bg-muted/30 p-6 rounded-lg border border-border my-6">
        <strong class="text-lg">Kluczowe kody kolorystyczne wnętrz:</strong>
        <ul class="mt-4 space-y-2">
            <li><span class="highlight font-bold text-primary">001 / 101 / 201:</span> Black (Czarny) – ponadczasowy.</li>
            <li><span class="highlight font-bold text-primary">234 / 254:</span> Palomino / Saffron / Date – ciepłe odcienie beżu (popularne w USA).</li>
            <li><span class="highlight font-bold text-primary">275:</span> Cream Beige – jasny, luksusowy odcień (późne modele).</li>
            <li><span class="highlight font-bold text-primary">257:</span> Henna Red – głęboka czerwień.</li>
            <li><span class="highlight font-bold text-primary">252:</span> Blue – ciemny granat (popularny w Europie).</li>
        </ul>
    </div>

    <h2>4. Unikalne Cechy i Wyposażenie Opcjonalne</h2>
    <ul>
        <li><strong>Zestaw wskaźników:</strong> Trzy duże tuby z zegarami VDO. W wersjach USA prędkościomierz w milach, a temperatura w Fahrenheitach.</li>
        <li><strong>Klimatyzacja (ACC):</strong> W późnych modelach amerykańskich montowano automatyczną klimatyzację z pionowymi przyciskami.</li>
        <li><strong>Schowki:</strong> Kieszenie w drzwiach wyłożone wykładziną, a w SLC – dodatkowe schowki w tylnych panelach.</li>
    </ul>

    <h2>5. Podsumowanie dla Kolekcjonera</h2>
    <p>Wnętrze Mercedesa 107 jest świadectwem jakości „over-engineered". Przy zakupie warto zwrócić uwagę na:</p>
    <ul>
        <li><strong>Stan drewna:</strong> Pęknięcia lakieru na drewnie Zebrano są częste, ale możliwe do renowacji.</li>
        <li><strong>Górna część deski:</strong> Narażona na słońce często pęka – kolory Blue i Black są najbardziej podatne na uszkodzenia UV.</li>
        <li><strong>Zgodność kodów:</strong> Warto sprawdzić kartę danych (Data Card), czy kolor tapicerki zgadza się ze specyfikacją fabryczną.</li>
    </ul>',
  true,
  null
);

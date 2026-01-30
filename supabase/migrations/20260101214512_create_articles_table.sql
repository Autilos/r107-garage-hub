drop table if exists articles cascade;

create table if not exists articles (

  id uuid default gen_random_uuid() primary key,
  slug text not null unique,
  title text not null,
  description text,
  content text,
  image_url text,
  seo_title text,
  seo_description text,
  is_published boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add RLS policies
alter table articles enable row level security;

-- Grant access to the table
grant select on table articles to anon, authenticated;
grant insert, update, delete on table articles to service_role;


create policy "Articles are viewable by everyone if published"
  on articles for select
  using (is_published = true or (auth.jwt() ->> 'email') in (select email from auth.users where is_admin(auth.uid())));

create policy "Articles are insertable by admins only"
  on articles for insert
  with check (is_admin(auth.uid()));

create policy "Articles are updatable by admins only"
  on articles for update
  using (is_admin(auth.uid()));

create policy "Articles are deletable by admins only"
  on articles for delete
  using (is_admin(auth.uid()));

-- Add initial content
insert into articles (slug, title, description, content, seo_title, seo_description, is_published, image_url)
values (
  'historia-mercedes-r107-c107',
  'Pancerna elegancja – Historia Mercedes R107 i C107',
  'Jak Mercedes R107 i C107 zdefiniowały luksus na dwie dekady. Poznaj historię ikony lat 70. i 80.',
  '<h2>Jak Mercedes R107 i C107 zdefiniowały luksus na dwie dekady</h2>
<p>Kiedy w kwietniu 1971 roku Mercedes-Benz zaprezentował następcę legendarnej „Pagody” (W113), świat motoryzacji na chwilę wstrzymał oddech. Nowy model oznaczony kodem R107 zrywał z lekką, filigranową sylwetką poprzednika na rzecz masywnej, bardziej surowej stylistyki. Był cięższy, solidniejszy i zdecydowanie bardziej „pancerny”.</p>

<p>Nikt wtedy nie przypuszczał, że ten roadster pozostanie w produkcji aż 18 lat (1971–1989), stając się drugim najdłużej produkowanym modelem osobowym w historii marki Mercedes-Benz, ustępując jedynie Klasie G. R107 szybko stał się ikoną sukcesu lat 70. i 80. – symbolem luksusu, statusu i trwałości, regularnie pojawiającym się w filmach i serialach epoki.</p>

<h2>Inżynieria bezpieczeństwa – dziedzictwo Béli Barényiego</h2>
<p>R107 był pierwszym modelu SL zaprojektowanym w czasach, gdy bezpieczeństwo bierne przestało być dodatkiem, a stało się fundamentem konstrukcji. Kluczową rolę odegrał Béla Barényi – inżynier Mercedesa, uznawany za „ojca bezpieczeństwa biernego”.</p>

<p>W modelu R107 w pełni wdrożono jego koncepcję sztywnej celi pasażerskiej otoczonej strefami kontrolowanego zgniotu. Szczególnym wyzwaniem było stworzenie bezpiecznego kabrioletu bez pałąka typu Targa. Mercedes rozwiązał ten problem poprzez ekstremalnie wzmocnione słupki A, które były o około 50% wytrzymalsze niż w poprzedniku, a także poprzez wklejaną szybę przednią zwiększającą sztywność nadwozia.</p>

<p>Istotną innowacją było także przeniesienie zbiornika paliwa nad tylną oś, co znacząco poprawiało bezpieczeństwo przy uderzeniach w tył pojazdu. Nawet tylne lampy miały funkcję praktyczną – ich żebrowany kształt ograniczał osadzanie się brudu i poprawiał widoczność w trudnych warunkach pogodowych.</p>

<h2>Dwie twarze serii 107 – Roadster R107 i Coupé C107</h2>
<p>Choć dziś to roadster SL jest najbardziej rozpoznawalny, wersja C107 SLC stanowi jeden z najbardziej nietypowych rozdziałów w historii Mercedesa. Było to luksusowe coupé bazujące na roadsterze, a nie – jak zwykle – na limuzynie klasy S.</p>

<p>Aby zmieścić pełnowymiarową tylną kanapę, inżynierowie wydłużyli rozstaw osi o 360 mm. Spowodowało to jednak problem z opuszczaniem tylnych szyb. Rozwiązaniem stały się charakterystyczne żaluzje w tylnych oknach, które dzieliły szybę na część stałą i ruchomą. Element ten stał się jednym z najbardziej rozpoznawalnych detali stylistycznych modelu SLC.</p>

<h2>Amerykański sen – wpływ rynku USA na R107</h2>
<p>Około dwie trzecie całej produkcji serii 107 trafiło do Ameryki Północnej, co miało ogromny wpływ na wygląd i charakter auta. Od 1974 roku wersje amerykańskie otrzymały masywne zderzaki spełniające normy „5 mph”, które wydłużyły nadwozie o ponad 20 cm.</p>

<p>Zmieniono również oświetlenie – eleganckie europejskie reflektory zastąpiono okrągłymi lampami typu sealed beam. Największym problemem okazały się jednak normy emisji spalin, które znacząco ograniczyły moc silników V8. Przykładowo, amerykański 380 SL oferował około 155 KM, podczas gdy europejska wersja osiągała 218 KM.</p>

<p>Doprowadziło to do rozkwitu tzw. „szarego rynku”, gdzie amerykańscy klienci masowo importowali europejskie wersje 500 SL. Odpowiedzią Mercedesa był model 560 SL, dostępny oficjalnie w USA, Japonii i Australii, który przywrócił godne osiągi i stał się najbardziej dopracowaną wersją eksportową R107.</p>

<h2>Niespodziewany rozdział – SLC w rajdach WRC</h2>
<p>Choć seria 107 kojarzy się głównie z luksusem i autostradami, model SLC zapisał się także w historii sportów motorowych. Pod kierownictwem Ericha Waxenbergera Mercedes wystawił luksusowe coupé do ekstremalnych rajdów długodystansowych.</p>

<p>W 1978 roku 450 SLC zdominowały rajd Vuelta a la América del Sur, pokonując około 30 000 km i zajmując dwa pierwsze miejsca. Rok później w Rajdzie Bandama Mercedesy zajęły cztery pierwsze pozycje. Kluczem do sukcesu był homologacyjny model 450 SLC 5.0 / 500 SLC, wyposażony w aluminiowe panele nadwozia i lekki aluminiowy blok silnika V8.</p>

<p>Ciekawostką pozostaje anulowany projekt 500 SL Rally przygotowany dla Waltera Röhrla. Mimo obiecujących testów, zarząd Mercedesa obawiał się ryzyka wizerunkowego i ostatecznie skasował program.</p>

<h2>Ewolucja silników – od V8 do ery katalizatorów</h2>
<p>Na przestrzeni niemal dwóch dekad pod maską serii 107 pracowała szeroka gama jednostek napędowych. Początkowo dominowały silniki V8 o pojemnościach 3.5 i 4.5 litra. Kryzys paliwowy lat 70. wymusił powrót do rzędowych szóstek, takich jak M110 w modelu 280 SL.</p>

<p>Przełom nastąpił w 1980 roku wraz z wprowadzeniem nowej generacji aluminiowych silników V8, które były lżejsze i bardziej efektywne. Ostatnia modernizacja z 1985 roku przyniosła silnik M103 w modelu 300 SL oraz topowy wariant 560 SL, będący szczytowym osiągnięciem eksportowym serii.</p>

<div class="overflow-x-auto my-8">
  <table id="r107_artickle" class="w-full text-left border-collapse border border-gray-300 dark:border-gray-700">
    <thead class="bg-gray-100 dark:bg-gray-800">
      <tr>
        <th class="p-3 border border-gray-300 dark:border-gray-700 font-semibold">Model i Oznaczenie</th>
        <th class="p-3 border border-gray-300 dark:border-gray-700 font-semibold">Lata Produkcji</th>
        <th class="p-3 border border-gray-300 dark:border-gray-700 font-semibold">Typ Nadwozia</th>
        <th class="p-3 border border-gray-300 dark:border-gray-700 font-semibold">Silnik i Pojemność</th>
        <th class="p-3 border border-gray-300 dark:border-gray-700 font-semibold">Moc (KM/HP)</th>
        <th class="p-3 border border-gray-300 dark:border-gray-700 font-semibold">Układ Wtryskowy</th>
        <th class="p-3 border border-gray-300 dark:border-gray-700 font-semibold">Cechy Charakterystyczne i Wyposażenie</th>
        <th class="p-3 border border-gray-300 dark:border-gray-700 font-semibold">Bezpieczeństwo i Innowacje</th>
        <th class="p-3 border border-gray-300 dark:border-gray-700 font-semibold">Liczba Wyprodukowanych Egzemplarzy</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Mercedes-Benz 280 SL</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">1974–1985</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Roadster (R107)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">R6 M110, 2746 cm³</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">185 KM (EU) / 177 KM (EU, 1976-1978)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Bosch D-Jetronic (do 1976), Bosch K-Jetronic (od 1976)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Wersja ekonomiczna wprowadzona w odpowiedzi na kryzys naftowy, 14-calowe felgi aluminiowe typu Barock lub stalowe z kołpakami</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Strefy zgniotu wg projektu Béla Barényi, sztywna cela pasażerska, wzmocnione słupki A dla ochrony przy dachowaniu</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">25436</td>
      </tr>
      <tr class="bg-gray-50 dark:bg-gray-900/50">
        <td class="p-3 border border-gray-300 dark:border-gray-700">Mercedes-Benz 350 SL</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">1971–1980</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Roadster (R107)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">V8 M116, 3499 cm³</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">200 KM (EU)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Bosch D-Jetronic (do 1976), Bosch K-Jetronic (od 1976)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Pierwszy model serii R107, zastąpił W113 "Pagoda", dostępny z 4-biegową manualną skrzynią biegów, opcjonalny hardtop, chromowane klamki</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Wklejana przednia szyba zwiększająca sztywność strukturalną, teleskopowa bezpieczna kolumna kierownicy, zbiornik paliwa nad tylną osią</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">15304</td>
      </tr>
      <tr>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Mercedes-Benz 350 SLC</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">1971–1980</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Coupe (C107)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">V8 M116, 3499 cm³</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">200 KM (EU)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Bosch D-Jetronic / K-Jetronic</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Debiut na Salonie w Paryżu (X 1971), 5-osobowe nadwozie oparte na podwoziu SL, zastąpił model W111 Coupe</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Pierwszy model z apteczką w specjalnej wnęce pod tylną szybą, strefy zgniotu projektu Béla Barényi</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">13925</td>
      </tr>
      <tr class="bg-gray-50 dark:bg-gray-900/50">
        <td class="p-3 border border-gray-300 dark:border-gray-700">Mercedes-Benz 450 SL</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">1971–1980</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Roadster (R107)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">V8 M117, 4520 cm³</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">225 KM (EU) / 190-192 HP (USA, 1972) / 160-187 HP (USA, późniejsze)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Bosch D-Jetronic (do 1975/76), Bosch K-Jetronic (od 1976)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Wersja USA z czterema okrągłymi reflektorami (sealed beam), zderzakami 5 mph (od 1974), katalizatorami (od 1977) i akumulatorem w bagażniku</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Zbiornik paliwa przeniesiony nad tylną oś, zderzaki absorbujące energię (USA), projekt stref zgniotu Béla Barényi</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">222298</td>
      </tr>
      <tr>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Mercedes-Benz 450 SLC</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">1972–1981</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Coupe (C107)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">V8 M117, 4520 cm³</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">225 KM (EU)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Bosch K-Jetronic</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Wydłużony rozstaw osi (+360 mm względem SL), charakterystyczne żaluzje w oknach bocznych, nadwozie 4-osobowe</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Sztywna klatka pasażerska, projekt stref zgniotu Béla Barényi</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">62888</td>
      </tr>
      <tr class="bg-gray-50 dark:bg-gray-900/50">
        <td class="p-3 border border-gray-300 dark:border-gray-700">Mercedes-Benz 380 SL</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">1980–1985</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Roadster (R107)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">V8 M116, 3818-3839 cm³</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">218 KM (EU) / 155-157 HP (USA)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Bosch K-Jetronic</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Lekki blok silnika ze stopu aluminium, wskaźnik jazdy ekonomicznej (economizer), 4-biegowa skrzynia automatyczna, aluminiowe koła</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">ABS dostępny jako opcja od 1980 r. (standard w USA od 1985), poduszka powietrzna kierowcy dostępna od 1982 r.</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">53200</td>
      </tr>
      <tr>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Mercedes-Benz 450 SLC 5.0 / 500 SLC</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">1977–1981</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Coupe (C107)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">V8 M117, 4973-5025 cm³</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">240 KM (EU)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Bosch K-Jetronic</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Model homologacyjny do rajdów, aluminiowe maski i klapy bagażnika, gumowy spojler tylny, sukcesy w rajdach Bandama i South American Rally</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Lamelowe żaluzje w tylnych oknach, wzmocniona konstrukcja na potrzeby rajdów długodystansowych</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">4405</td>
      </tr>
      <tr class="bg-gray-50 dark:bg-gray-900/50">
        <td class="p-3 border border-gray-300 dark:border-gray-700">Mercedes-Benz 500 SL</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">1980–1989</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Roadster (R107)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">V8 M117, 4973 cm³</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">240-245 KM (EU) / 223 KM (EU z kat.)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Bosch K-Jetronic / KE-Jetronic (od 1985)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Topowy model europejski, niedostępny oficjalnie w USA (szary rynek), aluminiowa maska i klapa bagażnika</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Standardowy ABS od 1986 r., opcjonalny Side Impact Protection (ochrona przed uderzeniem bocznym)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">11812</td>
      </tr>
      <tr>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Mercedes-Benz 560 SL</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">1985–1989</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Roadster (R107)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">V8 M117, 5547 cm³</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">231 KM (EU) / 227-238 HP (USA/AUS/JAP)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Bosch KE-Jetronic</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Model eksportowy, 15-calowe felgi "Gullideckel", spojler pod przednim zderzakiem, bogate wyposażenie (skóra, klimatyzacja, alarm)</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">Knee bolster (ochrona kolan), Side Impact Protection oraz standardowy ABS i poduszka powietrzna kierowcy</td>
        <td class="p-3 border border-gray-300 dark:border-gray-700">49347</td>
      </tr>
    </tbody>
  </table>
</div>


<h2>Poradnik współczesnego kolekcjonera</h2>
<p>Dziś modele R107 i C107 są pełnoprawnymi klasykami. Przy zakupie kluczowe znaczenie ma stan blacharski, zwłaszcza grodź czołowa, gdzie gromadząca się woda może prowadzić do bardzo kosztownej korozji. Warto dokładnie sprawdzić również progi, nadkola i podłogę.</p>

<p>Od strony mechanicznej szczególną ostrożność należy zachować przy wczesnych silnikach 3.8 V8 z pojedynczym łańcuchem rozrządu, podatnym na zerwanie. Najbardziej cenione są dziś późne modele 560 SL oraz europejskie wersje 500 SL, choć SLC coraz częściej wraca do łask jako rzadsza i ciekawsza alternatywa inwestycyjna.</p>

<h2>Produkcja i dane historyczne</h2>
<p>Produkcja modelu Mercedes-Benz SL serii R107 trwała od kwietnia 1971 roku do 4 sierpnia 1989 roku. Ostatni egzemplarz – 500 SL w kolorze Astral Silver – trafił bezpośrednio do Muzeum Mercedes-Benz w Stuttgarcie.</p>

<p>Łącznie wyprodukowano:</p>
<ul>
    <li>R107 SL (Roadster): 237 287 egzemplarzy</li>
    <li>C107 SLC (Coupé): 62 888 egzemplarzy</li>
    <li>Cała seria 107: 300 175 pojazdów</li>
</ul>

<p>Co ciekawe, najwyższą roczną produkcję odnotowano dopiero w 1986 roku, czyli w piętnastym roku obecności modelu na rynku. Prace nad następcą (R129) były opóźniane ze względu na niesłabnący popyt.</p>

<h2>Zakończenie</h2>
<p>Mercedes R107 to symbol epoki over-engineeringu – czasów, gdy trwałość, jakość wykonania i bezpieczeństwo były ważniejsze niż księgowość. Model ten przetrwał zmiany trendów, kryzysy paliwowe i zaostrzające się normy emisji, zachowując swój prestiż i charakter.</p>

<p>Jego następca, R129, był już samochodem nowoczesnym i naszpikowanym elektroniką. Jednak to właśnie R107 pozostaje definicją klasycznego Mercedesa SL – solidnego, eleganckiego i zbudowanego na dekady.</p>',
  'Pancerna elegancja – Historia Mercedes R107 i C107',
  'Jak Mercedes R107 i C107 zdefiniowały luksus na dwie dekady. Poznaj historię ikony lat 70. i 80.',
  true,
  '/images/pancerna-elegancja.png'

);


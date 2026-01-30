-- Create custom types
CREATE TYPE public.source_type AS ENUM ('rss', 'user');
CREATE TYPE public.listing_status AS ENUM ('pending', 'approved', 'rejected', 'archived');
CREATE TYPE public.listing_category AS ENUM ('pojazd', 'czesc');
CREATE TYPE public.repair_status AS ENUM ('draft', 'pending', 'published');
CREATE TYPE public.repair_module_type AS ENUM ('objawy', 'czesci', 'narzedzia', 'instrukcja', 'foto_video');
CREATE TYPE public.repair_media_kind AS ENUM ('image', 'youtube');
CREATE TYPE public.shop_link_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE public.shop_link_type AS ENUM ('sklep', 'usluga', 'katalog');
CREATE TYPE public.app_role AS ENUM ('admin', 'user');

-- Profiles table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- User roles table (for RBAC - admin detection)
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(user_id, role)
);

-- RSS Sources table
CREATE TABLE public.rss_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  feed_url TEXT NOT NULL,
  country_default TEXT DEFAULT 'US',
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Listings table (RSS + user listings)
CREATE TABLE public.listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_type source_type NOT NULL DEFAULT 'user',
  status listing_status NOT NULL DEFAULT 'pending',
  title TEXT NOT NULL,
  description TEXT,
  price NUMERIC,
  currency TEXT DEFAULT 'EUR',
  country TEXT DEFAULT 'PL',
  category listing_category NOT NULL DEFAULT 'pojazd',
  url TEXT,
  image_url TEXT,
  rss_source_id UUID REFERENCES public.rss_sources(id) ON DELETE SET NULL,
  rss_guid TEXT,
  llm_ok BOOLEAN,
  llm_reason TEXT,
  model_tag TEXT,
  variant_tag TEXT,
  year_from INTEGER,
  year_to INTEGER,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  published_at TIMESTAMP WITH TIME ZONE
);

-- Listing images (for user uploads, max 6)
CREATE TABLE public.listing_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Repairs table
CREATE TABLE public.repairs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status repair_status NOT NULL DEFAULT 'draft',
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  meta_title TEXT,
  meta_description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Repair modules (5 types)
CREATE TABLE public.repair_modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  repair_id UUID NOT NULL REFERENCES public.repairs(id) ON DELETE CASCADE,
  type repair_module_type NOT NULL,
  content_html TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(repair_id, type)
);

-- Repair media (gallery + youtube)
CREATE TABLE public.repair_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  repair_id UUID NOT NULL REFERENCES public.repairs(id) ON DELETE CASCADE,
  kind repair_media_kind NOT NULL,
  value TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Comments (on repairs)
CREATE TABLE public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  repair_id UUID NOT NULL REFERENCES public.repairs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Shop links
CREATE TABLE public.shops_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status shop_link_status NOT NULL DEFAULT 'pending',
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  country TEXT DEFAULT 'PL',
  type shop_link_type NOT NULL DEFAULT 'sklep',
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rss_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listing_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repair_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repair_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops_links ENABLE ROW LEVEL SECURITY;

-- Security definer function to check admin role
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.has_role(auth.uid(), 'admin')
$$;

-- Profiles policies
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- User roles policies (only admin can manage)
CREATE POLICY "Admins can view all roles" ON public.user_roles
  FOR SELECT USING (public.is_admin() OR auth.uid() = user_id);

CREATE POLICY "Admins can manage roles" ON public.user_roles
  FOR ALL USING (public.is_admin());

-- RSS sources policies (admin only for write, public read)
CREATE POLICY "Anyone can view enabled RSS sources" ON public.rss_sources
  FOR SELECT USING (enabled = true OR public.is_admin());

CREATE POLICY "Admins can manage RSS sources" ON public.rss_sources
  FOR ALL USING (public.is_admin());

-- Listings policies
CREATE POLICY "Anyone can view approved listings" ON public.listings
  FOR SELECT USING (status = 'approved' OR public.is_admin() OR (user_id = auth.uid()));

CREATE POLICY "Users can create own listings" ON public.listings
  FOR INSERT WITH CHECK (auth.uid() = user_id AND source_type = 'user');

CREATE POLICY "Users can update own pending listings" ON public.listings
  FOR UPDATE USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users can delete own listings" ON public.listings
  FOR DELETE USING (auth.uid() = user_id OR public.is_admin());

-- Listing images policies
CREATE POLICY "Anyone can view listing images" ON public.listing_images
  FOR SELECT USING (true);

CREATE POLICY "Users can manage own listing images" ON public.listing_images
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.listings 
      WHERE listings.id = listing_images.listing_id 
      AND (listings.user_id = auth.uid() OR public.is_admin())
    )
  );

-- Repairs policies
CREATE POLICY "Anyone can view published repairs" ON public.repairs
  FOR SELECT USING (status = 'published' OR public.is_admin());

CREATE POLICY "Admins can manage repairs" ON public.repairs
  FOR ALL USING (public.is_admin());

-- Repair modules policies
CREATE POLICY "Anyone can view repair modules" ON public.repair_modules
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.repairs 
      WHERE repairs.id = repair_modules.repair_id 
      AND (repairs.status = 'published' OR public.is_admin())
    )
  );

CREATE POLICY "Admins can manage repair modules" ON public.repair_modules
  FOR ALL USING (public.is_admin());

-- Repair media policies
CREATE POLICY "Anyone can view repair media" ON public.repair_media
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.repairs 
      WHERE repairs.id = repair_media.repair_id 
      AND (repairs.status = 'published' OR public.is_admin())
    )
  );

CREATE POLICY "Admins can manage repair media" ON public.repair_media
  FOR ALL USING (public.is_admin());

-- Comments policies
CREATE POLICY "Anyone can view comments" ON public.comments
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create comments" ON public.comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments" ON public.comments
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments or admin" ON public.comments
  FOR DELETE USING (auth.uid() = user_id OR public.is_admin());

-- Shop links policies
CREATE POLICY "Anyone can view approved shop links" ON public.shops_links
  FOR SELECT USING (status = 'approved' OR public.is_admin() OR user_id = auth.uid());

CREATE POLICY "Authenticated users can create shop links" ON public.shops_links
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own shop links" ON public.shops_links
  FOR UPDATE USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users can delete own shop links or admin" ON public.shops_links
  FOR DELETE USING (auth.uid() = user_id OR public.is_admin());

-- Trigger to create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)));
  
  -- Auto-assign admin role if email matches
  IF NEW.email = 'wnowak@autilo.eu' THEN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'admin');
  ELSE
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'user');
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Triggers for updated_at
CREATE TRIGGER update_repairs_updated_at
  BEFORE UPDATE ON public.repairs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_repair_modules_updated_at
  BEFORE UPDATE ON public.repair_modules
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Indexes for performance
CREATE INDEX idx_listings_status ON public.listings(status);
CREATE INDEX idx_listings_source_type ON public.listings(source_type);
CREATE INDEX idx_listings_category ON public.listings(category);
CREATE INDEX idx_listings_country ON public.listings(country);
CREATE INDEX idx_listings_rss_guid ON public.listings(rss_source_id, rss_guid);
CREATE INDEX idx_repairs_status ON public.repairs(status);
CREATE INDEX idx_repairs_slug ON public.repairs(slug);
CREATE INDEX idx_shops_links_status ON public.shops_links(status);

-- Insert default RSS sources
INSERT INTO public.rss_sources (name, feed_url, country_default, enabled) VALUES
  ('Bring a Trailer R107', 'https://rss.app/feed/S7nzC0tge0CZbieb', 'US', true),
  ('eBay Motors R107', 'https://rss.app/feed/2Z5EiTzlfry3bqFK', 'US', true),
  ('Dodatkowy Feed R107', 'https://rss.app/feed/GdyKzGIfWkzs4rBm', 'PL', true);drop table if exists articles cascade;

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

-- Automated import of 428 categorized R107 videos

-- 1. Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.repair_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_slug TEXT NOT NULL,
    video_id TEXT NOT NULL,
    title TEXT NOT NULL,
    subcategory TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enable RLS and setup public read policy
ALTER TABLE public.repair_videos ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_policies 
        WHERE tablename = 'repair_videos' 
        AND policyname = 'Allow public read access'
    ) THEN
        CREATE POLICY "Allow public read access" ON public.repair_videos
            FOR SELECT USING (true);
    END IF;
END $$;

-- 3. Cleanup and Insert Data

DELETE FROM public.repair_videos WHERE sort_order = 0; -- Cleanup previous auto-imports if any

INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '8-nnjT62soE', '1000Miglia 2022 in Buonconvento Toscana - Mille Miglia R107 mechanic', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'N6LNKa0QBq4', '1972 to 1989 Mercedes R107 350SL 450SL 380SL 560SL Rear Hood Seal Challenges', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'N6LNKa0QBq4', '1972 to 1989 Mercedes R107 350SL 450SL 380SL 560SL Rear Hood Seal Challenges', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'DAjeLE7OvT0', '1972 to 1989 R107 Mercedes SL Convertible Hood Design Flaw: How to Avoid Injury', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '2ROwcOeThbg', '1977 to 1980 Mercedes Fuel Injection Delivery System Overhaul on the Bench: Before and After', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'BwZwle6xMvU', '1977 to 1985 Mercedes Diesel Rolling Restoration 2: Fix or Upgrade Lighting', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'BwZwle6xMvU', '1977 to 1985 Mercedes Diesel Rolling Restoration 2: Fix or Upgrade Lighting', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'eiwLgQkMQsY', '1981 to 1991 Mercedes Best Upgrade for the Automatic Climate Control', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'eiwLgQkMQsY', '1981 to 1991 Mercedes Best Upgrade for the Automatic Climate Control', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ZEL9ZW5KqpA', '1981 to 1991 Mercedes Spasmodic Cabin Heat Troubleshooting Tips W123, R107 and W126 models', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'ZEL9ZW5KqpA', '1981 to 1991 Mercedes Spasmodic Cabin Heat Troubleshooting Tips W123, R107 and W126 models', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Eo1z4ISfRp4', '220S 220SE 230SL 250SL 250SE 280SL 280SE Front Crank Seal Easy Install Tools', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Eo1z4ISfRp4', '220S 220SE 230SL 250SL 250SE 280SL 280SE Front Crank Seal Easy Install Tools', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'PLtUryA42n8', '280 SL R107 in the paint shop', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'e0EanAZAZyc', '350 SLC Mercedes C107 S-Class Coupe - predecessor of the C126', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'e0EanAZAZyc', '350 SLC Mercedes C107 S-Class Coupe - predecessor of the C126', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'lk2XlBeKBvY', '560 SEC Mercedes C126 - barn find R107 screwdriver offside', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'aA-y9WxAVdo', 'ATG Nano paint sealant - car care', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'F0N5bMujtZI', 'Adjusting the baffle plate - KE-Jetronic Mercedes 560SL R107', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '_kvOoXK_24A', 'Barrett Jackson Scottsdale Fall Oct 2025 Mercedes SL auction. USA prices holding up better than UK!!', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '_kvOoXK_24A', 'Barrett Jackson Scottsdale Fall Oct 2025 Mercedes SL auction. USA prices holding up better than UK!!', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ULqR69RC_qQ', 'Bleed the cooling system of the Mercedes Benz W114 (M110) - /8 engine is getting too hot!!! #Mercedes Benz', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ULqR69RC_qQ', 'Bleed the cooling system of the Mercedes Benz W114 (M110) - /8 engine is getting too hot!!! #Mercedes Benz', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'ULqR69RC_qQ', 'Bleed the cooling system of the Mercedes Benz W114 (M110) - /8 engine is getting too hot!!! #Mercedes Benz', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'YZ4Zx6SPlMU', 'Bosch K-Jetronic Performance: Why Change Fuel Injectors? New DIY Kits Available Now', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'YZ4Zx6SPlMU', 'Bosch K-Jetronic Performance: Why Change Fuel Injectors? New DIY Kits Available Now', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'AqKHZuYNjTY', 'Bosch KE-JETRONIC - Changing the baffle pot - Mercedes R107, W126, W201, W124', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'AqKHZuYNjTY', 'Bosch KE-JETRONIC - Changing the baffle pot - Mercedes R107, W126, W201, W124', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '3gFz2RA3Xs8', 'Can''t Decide Which Color LED Dash Bulb for your Old Benz? This Should Help!', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '3gFz2RA3Xs8', 'Can''t Decide Which Color LED Dash Bulb for your Old Benz? This Should Help!', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'wdgC9sYAe5k', 'Change and adjust electro-hydraulic actuator. KE-Jetronic from Bosch pressure actuator', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'wdgC9sYAe5k', 'Change and adjust electro-hydraulic actuator. KE-Jetronic from Bosch pressure actuator', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'wdgC9sYAe5k', 'Change and adjust electro-hydraulic actuator. KE-Jetronic from Bosch pressure actuator', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'wdgC9sYAe5k', 'Change and adjust electro-hydraulic actuator. KE-Jetronic from Bosch pressure actuator', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'BqAjKxtFy40', 'Change front shock absorber - Mercedes R107', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'BqAjKxtFy40', 'Change front shock absorber - Mercedes R107', 'Zawieszenie Przód', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'BqAjKxtFy40', 'Change front shock absorber - Mercedes R107', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Zawieszenie Przód', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'opz_tyiCt8A', 'Changing the coolant pump - Mercedes R107 C107 on the 350 SLC - Remove the water pump', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'opz_tyiCt8A', 'Changing the coolant pump - Mercedes R107 C107 on the 350 SLC - Remove the water pump', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'opz_tyiCt8A', 'Changing the coolant pump - Mercedes R107 C107 on the 350 SLC - Remove the water pump', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'dvBGe_ZadHQ', 'Check Bosch D-Jetronic pressure sensor - Mercedes W114 with M110 engine', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'dvBGe_ZadHQ', 'Check Bosch D-Jetronic pressure sensor - Mercedes W114 with M110 engine', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'dvBGe_ZadHQ', 'Check Bosch D-Jetronic pressure sensor - Mercedes W114 with M110 engine', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'MCzw_a_oTGo', 'Check KE-Jetronic from Bosch flow divider - system pressure and lower chamber pressure-Mercedes, Porsche, BMW', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'MCzw_a_oTGo', 'Check KE-Jetronic from Bosch flow divider - system pressure and lower chamber pressure-Mercedes, Porsche, BMW', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'MCzw_a_oTGo', 'Check KE-Jetronic from Bosch flow divider - system pressure and lower chamber pressure-Mercedes, Porsche, BMW', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'IRTDMHjsfqY', 'Check Mercedes KE-Jetronic acceleration enrichment on the flow divider. W126, R107, W124, W201', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'IRTDMHjsfqY', 'Check Mercedes KE-Jetronic acceleration enrichment on the flow divider. W126, R107, W124, W201', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'viqmCn07sgI', 'Check and adjust Bosch D-Jetronic pressure regulator - TN 0280 161 001', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'viqmCn07sgI', 'Check and adjust Bosch D-Jetronic pressure regulator - TN 0280 161 001', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'viqmCn07sgI', 'Check and adjust Bosch D-Jetronic pressure regulator - TN 0280 161 001', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '-zWRAX3BkfU', 'Check and adjust KE-Jetronic accumulation slide - Mercedes Bosch W201, W124, R107, W126, R129', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'uEQjpowC7Gk', 'Check cold start valve', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'uEQjpowC7Gk', 'Check cold start valve', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'uEQjpowC7Gk', 'Check cold start valve', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '8Yop_3mSP1I', 'Check fuel pump - K-Jetronic - M110 Mercedes W126', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '8Yop_3mSP1I', 'Check fuel pump - K-Jetronic - M110 Mercedes W126', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '8Yop_3mSP1I', 'Check fuel pump - K-Jetronic - M110 Mercedes W126', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '8Yop_3mSP1I', 'Check fuel pump - K-Jetronic - M110 Mercedes W126', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'E4IFr4MU4Pg', 'Classic R107 SL Repair Series Part 10: How to fix a Loose Rattling Transmission Shift Lever', 'Automatyczna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'E4IFr4MU4Pg', 'Classic R107 SL Repair Series Part 10: How to fix a Loose Rattling Transmission Shift Lever', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'jkulIEJ8jjo', 'Control pressure in the flow divider Mercedes R107 W126 W123 K-Jetronic system pressure regulator', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'jkulIEJ8jjo', 'Control pressure in the flow divider Mercedes R107 W126 W123 K-Jetronic system pressure regulator', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'JZd0SMJelZ0', 'Crank no start  - what to do if your Audi, VW, classic Mercedes or Fiat won''t start. FIX', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'JZd0SMJelZ0', 'Crank no start  - what to do if your Audi, VW, classic Mercedes or Fiat won''t start. FIX', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'JZd0SMJelZ0', 'Crank no start  - what to do if your Audi, VW, classic Mercedes or Fiat won''t start. FIX', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'JZd0SMJelZ0', 'Crank no start  - what to do if your Audi, VW, classic Mercedes or Fiat won''t start. FIX', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'LPZTK02NLTU', 'Cutting open a Mercedes R107 fuel tank…and modifying a non OEM tank', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'Xmgwmx62yFs', 'D Jetronic trigger points and pulse generator - removal, repair. Symptoms of faulty and worn points.', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '_LJh7L-ivsw', 'Determine idle speed with multimeter - Mercedes R107 560SL with X test socket', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '_LJh7L-ivsw', 'Determine idle speed with multimeter - Mercedes R107 560SL with X test socket', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', '_LJh7L-ivsw', 'Determine idle speed with multimeter - Mercedes R107 560SL with X test socket', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '_LJh7L-ivsw', 'Determine idle speed with multimeter - Mercedes R107 560SL with X test socket', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'WwLl0rUtxfQ', 'EGR - check exhaust gas recirculation on KE-Jetronic - rough engine running', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '3pPqYKtfdFY', 'Early Bosch Fuel Injectors - different types +how to remove without damaging. Part 0280150024', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'hiKasKuWDE4', 'Early Mercedes R107 carpets and rear bench seat + floor pan cross members', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'sFHLTdajV4g', 'Gathering of Mercedes SL Convertibles Representing 48 years of Production: A Big Generation Gap.', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Ta0AO9jDWk8', 'How to Avoid and Repair Damaged Spark Plug Threads', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Ta0AO9jDWk8', 'How to Avoid and Repair Damaged Spark Plug Threads', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'z9SFrbiy-7M', 'How to Remove the 1974 to 1989 Mercedes R107 Fuel Tank Screen with Kent''s Special Tool', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Rk9jer8UAkw', 'How to Replace a 380SL Thermostat and Short Coolant Hose', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Rk9jer8UAkw', 'How to Replace a 380SL Thermostat and Short Coolant Hose', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'JILMQc7GHas', 'How to bench bleed (and disassemble) an ATE brake master cylinder. Mercedes R107 280SL.', 'Hydraulika i ABS', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'JILMQc7GHas', 'How to bench bleed (and disassemble) an ATE brake master cylinder. Mercedes R107 280SL.', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '--8WUYjuOCU', 'How to disassemble and repair the Auxiliary Air Slide valve on a classic Mercedes, Porsche & BMW etc', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '--8WUYjuOCU', 'How to disassemble and repair the Auxiliary Air Slide valve on a classic Mercedes, Porsche & BMW etc', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '--8WUYjuOCU', 'How to disassemble and repair the Auxiliary Air Slide valve on a classic Mercedes, Porsche & BMW etc', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '9BgOQa50Zes', 'How to remove D Jetronic fuel-injectors and flow test Mercedes M110 engine', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Ezmmbm7QYzc', 'How to remove a REALLY stuck brake piston when it is rusted and siezed in the caliper.', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'Ezmmbm7QYzc', 'How to remove a REALLY stuck brake piston when it is rusted and siezed in the caliper.', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Ezmmbm7QYzc', 'How to remove a REALLY stuck brake piston when it is rusted and siezed in the caliper.', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'hCaCt00HlTA', 'How to remove the soft top hood on a R107 Mercedes SL. Detailed guide prior to fitting a new one.', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'R3F7qIHRRp4', 'How to test fuel injectors and trigger points using homemade NOID lights.', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '7qIvciCFsoY', 'Ice blasting - car cleaning with dry ice on a 300SL', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Układ kierowniczy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'q5MB83SI8nM', 'Installing the exhaust manifold on the Mercedes M117 V8 engine', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '3d8gqtNlzOo', 'K-JETRONIC basic setting of the STORAGE DISC', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '3d8gqtNlzOo', 'K-JETRONIC basic setting of the STORAGE DISC', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '3d8gqtNlzOo', 'K-JETRONIC basic setting of the STORAGE DISC', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'jhL6-v2irjc', 'K-Jetronic, KA-Jetronic warm-up regulator check control pressure, Mercedes #W116, #W126, #W123, #R107, #W460', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'jhL6-v2irjc', 'K-Jetronic, KA-Jetronic warm-up regulator check control pressure, Mercedes #W116, #W126, #W123, #R107, #W460', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '_CzTF9w7iOM', 'K-Jetronic, warm-up regulator check control pressure, Mercedes #W116, #W126, #W123, #R107', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '_CzTF9w7iOM', 'K-Jetronic, warm-up regulator check control pressure, Mercedes #W116, #W126, #W123, #R107', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'BnWtM7NAhQM', 'KE-JETRONIC Pressure accumulator replacement for warm start problems Mercedes R107, W124, W201, W126', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'BnWtM7NAhQM', 'KE-JETRONIC Pressure accumulator replacement for warm start problems Mercedes R107, W124, W201, W126', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'BnWtM7NAhQM', 'KE-JETRONIC Pressure accumulator replacement for warm start problems Mercedes R107, W124, W201, W126', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'BnWtM7NAhQM', 'KE-JETRONIC Pressure accumulator replacement for warm start problems Mercedes R107, W124, W201, W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'BnWtM7NAhQM', 'KE-JETRONIC Pressure accumulator replacement for warm start problems Mercedes R107, W124, W201, W126', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'BnWtM7NAhQM', 'KE-JETRONIC Pressure accumulator replacement for warm start problems Mercedes R107, W124, W201, W126', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'BnWtM7NAhQM', 'KE-JETRONIC Pressure accumulator replacement for warm start problems Mercedes R107, W124, W201, W126', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'BnWtM7NAhQM', 'KE-JETRONIC Pressure accumulator replacement for warm start problems Mercedes R107, W124, W201, W126', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'cjqw5EGn3bw', 'KE-JETRONIC pressure accumulator replacement for warm start problems - R107, W124, W201, W126', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'cjqw5EGn3bw', 'KE-JETRONIC pressure accumulator replacement for warm start problems - R107, W124, W201, W126', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '8vshtqVcBwQ', 'KE-Jetronic - Changing the sealing ring on the control piston flow divider - Mercedes R107, W126, W461, R129', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '8vshtqVcBwQ', 'KE-Jetronic - Changing the sealing ring on the control piston flow divider - Mercedes R107, W126, W461, R129', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'QcS2-UJjito', 'KE-Jetronic - Check flow divider🚗 - Mercedes, Porsche, BMW', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'QcS2-UJjito', 'KE-Jetronic - Check flow divider🚗 - Mercedes, Porsche, BMW', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'QcS2-UJjito', 'KE-Jetronic - Check flow divider🚗 - Mercedes, Porsche, BMW', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'QcS2-UJjito', 'KE-Jetronic - Check flow divider🚗 - Mercedes, Porsche, BMW', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'QcS2-UJjito', 'KE-Jetronic - Check flow divider🚗 - Mercedes, Porsche, BMW', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'QcS2-UJjito', 'KE-Jetronic - Check flow divider🚗 - Mercedes, Porsche, BMW', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'QcS2-UJjito', 'KE-Jetronic - Check flow divider🚗 - Mercedes, Porsche, BMW', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'xHlXa7T4XUE', 'KE-Jetronic - Check throttle valve switch - Mercedes R107 560SL', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'xHlXa7T4XUE', 'KE-Jetronic - Check throttle valve switch - Mercedes R107 560SL', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'xHlXa7T4XUE', 'KE-Jetronic - Check throttle valve switch - Mercedes R107 560SL', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'DHZkZUtmpj0', 'KE-Jetronic 560SL Fuel Pressure Test: How to Bypass the Fuel Pump Relay?', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'DHZkZUtmpj0', 'KE-Jetronic 560SL Fuel Pressure Test: How to Bypass the Fuel Pump Relay?', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'DHZkZUtmpj0', 'KE-Jetronic 560SL Fuel Pressure Test: How to Bypass the Fuel Pump Relay?', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'LHZD_fJoeJM', 'KE-Jetronic Checking Adjusting Ram Slide/ baffle plate-Mercedes Bosch W201, W124, R107, W126, R129', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'LHZD_fJoeJM', 'KE-Jetronic Checking Adjusting Ram Slide/ baffle plate-Mercedes Bosch W201, W124, R107, W126, R129', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'LHZD_fJoeJM', 'KE-Jetronic Checking Adjusting Ram Slide/ baffle plate-Mercedes Bosch W201, W124, R107, W126, R129', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'LHZD_fJoeJM', 'KE-Jetronic Checking Adjusting Ram Slide/ baffle plate-Mercedes Bosch W201, W124, R107, W126, R129', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'iL2gr0w9Hpk', 'KE-Jetronic Electro-hydraulic actuator Change and adjust pressure actuator', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'iL2gr0w9Hpk', 'KE-Jetronic Electro-hydraulic actuator Change and adjust pressure actuator', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'iL2gr0w9Hpk', 'KE-Jetronic Electro-hydraulic actuator Change and adjust pressure actuator', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'iL2gr0w9Hpk', 'KE-Jetronic Electro-hydraulic actuator Change and adjust pressure actuator', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'iL2gr0w9Hpk', 'KE-Jetronic Electro-hydraulic actuator Change and adjust pressure actuator', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'iL2gr0w9Hpk', 'KE-Jetronic Electro-hydraulic actuator Change and adjust pressure actuator', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'iL2gr0w9Hpk', 'KE-Jetronic Electro-hydraulic actuator Change and adjust pressure actuator', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '7d-Li8DXRgc', 'KE-Jetronic Interaction Potentiometer and idle speed controller - shown on Mercedes R107 560SL DIY', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '7d-Li8DXRgc', 'KE-Jetronic Interaction Potentiometer and idle speed controller - shown on Mercedes R107 560SL DIY', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '7d-Li8DXRgc', 'KE-Jetronic Interaction Potentiometer and idle speed controller - shown on Mercedes R107 560SL DIY', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '7d-Li8DXRgc', 'KE-Jetronic Interaction Potentiometer and idle speed controller - shown on Mercedes R107 560SL DIY', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'kHXzL_g4IHU', 'KE-Jetronic idle problems? Testing the Mercedes 560SL baffle pot', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'mFsi_qYGJw8', 'KE-Jetronic throttle switch - Check Mercedes 560SL #throttleswitch', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'mFsi_qYGJw8', 'KE-Jetronic throttle switch - Check Mercedes 560SL #throttleswitch', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'mFsi_qYGJw8', 'KE-Jetronic throttle switch - Check Mercedes 560SL #throttleswitch', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'mFsi_qYGJw8', 'KE-Jetronic throttle switch - Check Mercedes 560SL #throttleswitch', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'mFsi_qYGJw8', 'KE-Jetronic throttle switch - Check Mercedes 560SL #throttleswitch', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'mFsi_qYGJw8', 'KE-Jetronic throttle switch - Check Mercedes 560SL #throttleswitch', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'mFsi_qYGJw8', 'KE-Jetronic throttle switch - Check Mercedes 560SL #throttleswitch', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'mFsi_qYGJw8', 'KE-Jetronic throttle switch - Check Mercedes 560SL #throttleswitch', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'zLJ1IR7msHw', 'KE-Jetronic troubleshooting for irregular engine running, fluctuating speeds Mercedes R107, W126, W201..', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'zLJ1IR7msHw', 'KE-Jetronic troubleshooting for irregular engine running, fluctuating speeds Mercedes R107, W126, W201..', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'zLJ1IR7msHw', 'KE-Jetronic troubleshooting for irregular engine running, fluctuating speeds Mercedes R107, W126, W201..', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'zLJ1IR7msHw', 'KE-Jetronic troubleshooting for irregular engine running, fluctuating speeds Mercedes R107, W126, W201..', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'waRlv1DoCI0', 'LED Dash Instrument Light Testing: Mercedes W123 W126 W201 W124- Always Looking for Better.!', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'waRlv1DoCI0', 'LED Dash Instrument Light Testing: Mercedes W123 W126 W201 W124- Always Looking for Better.!', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'slthaPTbpDY', 'Lambda sensor check - KE-Jetronic Mercedes with catalytic converter R107, W126 and W124', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'slthaPTbpDY', 'Lambda sensor check - KE-Jetronic Mercedes with catalytic converter R107, W126 and W124', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'uGgnNnfhfyc', 'Level control - Mercedes #W116, #W126, #W123, R107', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'uFVnh0NDymk', 'Lubricating Old Mercedes Manual Seat Tracks. What a Difference!', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'uFVnh0NDymk', 'Lubricating Old Mercedes Manual Seat Tracks. What a Difference!', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'rk6yBOr5648', 'M110 Engine WUR Relocation: A Winner + Final Decision on Making it Adjustable', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'rk6yBOr5648', 'M110 Engine WUR Relocation: A Winner + Final Decision on Making it Adjustable', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ZeIPTe2z6rk', 'M116 M117 V8 Valve Cover Gasket Replacement Tip', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '2GaFmJ4zKww', 'MAP sensor - the heart of DJetronic fuel injection. Mercedes R107.', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '2GaFmJ4zKww', 'MAP sensor - the heart of DJetronic fuel injection. Mercedes R107.', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '7LjpKjhuUtc', 'Making a complicated steel radiator pipe with end beads & bracket', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', '853MRRC6jQg', 'Mercedes - Changing the front rubber bearing of the rear axle - R107, W114, W115, W116 and W123', 'Zawieszenie Przód', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', '853MRRC6jQg', 'Mercedes - Changing the front rubber bearing of the rear axle - R107, W114, W115, W116 and W123', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '853MRRC6jQg', 'Mercedes - Changing the front rubber bearing of the rear axle - R107, W114, W115, W116 and W123', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'h1CSfcyVGrs', 'Mercedes - R107, W124, W126 - Check ABS sensors - Anti-lock braking system', 'Hydraulika i ABS', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'RkK7xC5XoZc', 'Mercedes - R107, W124, W126 - Checking ABS sensors - Anti-lock braking system #R107, #W124, #W126', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'RkK7xC5XoZc', 'Mercedes - R107, W124, W126 - Checking ABS sensors - Anti-lock braking system #R107, #W124, #W126', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'RkK7xC5XoZc', 'Mercedes - R107, W124, W126 - Checking ABS sensors - Anti-lock braking system #R107, #W124, #W126', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'RkK7xC5XoZc', 'Mercedes - R107, W124, W126 - Checking ABS sensors - Anti-lock braking system #R107, #W124, #W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'RkK7xC5XoZc', 'Mercedes - R107, W124, W126 - Checking ABS sensors - Anti-lock braking system #R107, #W124, #W126', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'RkK7xC5XoZc', 'Mercedes - R107, W124, W126 - Checking ABS sensors - Anti-lock braking system #R107, #W124, #W126', 'Hydraulika i ABS', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'RkK7xC5XoZc', 'Mercedes - R107, W124, W126 - Checking ABS sensors - Anti-lock braking system #R107, #W124, #W126', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'RkK7xC5XoZc', 'Mercedes - R107, W124, W126 - Checking ABS sensors - Anti-lock braking system #R107, #W124, #W126', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'RkK7xC5XoZc', 'Mercedes - R107, W124, W126 - Checking ABS sensors - Anti-lock braking system #R107, #W124, #W126', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '67kF57uEYXg', 'Mercedes - Supplement to warm-up regulator - Correct assembly warm-up regulator Mercedes restomod', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '67kF57uEYXg', 'Mercedes - Supplement to warm-up regulator - Correct assembly warm-up regulator Mercedes restomod', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '67kF57uEYXg', 'Mercedes - Supplement to warm-up regulator - Correct assembly warm-up regulator Mercedes restomod', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '67kF57uEYXg', 'Mercedes - Supplement to warm-up regulator - Correct assembly warm-up regulator Mercedes restomod', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '67kF57uEYXg', 'Mercedes - Supplement to warm-up regulator - Correct assembly warm-up regulator Mercedes restomod', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '67kF57uEYXg', 'Mercedes - Supplement to warm-up regulator - Correct assembly warm-up regulator Mercedes restomod', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '67kF57uEYXg', 'Mercedes - Supplement to warm-up regulator - Correct assembly warm-up regulator Mercedes restomod', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '67kF57uEYXg', 'Mercedes - Supplement to warm-up regulator - Correct assembly warm-up regulator Mercedes restomod', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '67kF57uEYXg', 'Mercedes - Supplement to warm-up regulator - Correct assembly warm-up regulator Mercedes restomod', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'DlMtnGxtwX8', 'Mercedes -Hard but warm - Benz #R107 560SL', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'DlMtnGxtwX8', 'Mercedes -Hard but warm - Benz #R107 560SL', 'Automatyczna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'DlMtnGxtwX8', 'Mercedes -Hard but warm - Benz #R107 560SL', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'q-54H4-0eQs', 'Mercedes 107 280SL driveshaft installation and rear diff oil', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'q-54H4-0eQs', 'Mercedes 107 280SL driveshaft installation and rear diff oil', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'q-54H4-0eQs', 'Mercedes 107 280SL driveshaft installation and rear diff oil', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'a2n8_Hs1mWk', 'Mercedes 107 280SL radiator coolant leak fixed', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'qCBp27wXkvA', 'Mercedes 107 280sl underside rattle missing gear shift bushings', 'Automatyczna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'qCBp27wXkvA', 'Mercedes 107 280sl underside rattle missing gear shift bushings', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', '9z7SPIlcpiA', 'Mercedes 107 Rear Diff Pinion Seal', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '9z7SPIlcpiA', 'Mercedes 107 Rear Diff Pinion Seal', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'mjB09r1ybf0', 'Mercedes 107 SL brake dust covers', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'W_G4CTBYap8', 'Mercedes 107 SL change V belts without removing fan', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'oxuOMCaluz0', 'Mercedes 107 SL drive shaft and centre bearing removal', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'oxuOMCaluz0', 'Mercedes 107 SL drive shaft and centre bearing removal', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'h7AWJ7ZT8d0', 'Mercedes 107 SL exhaust removal and refurbishment', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'ltj-O00UkBc', 'Mercedes 107 SL hazard and window switches', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'dbJZYI-RHr8', 'Mercedes 107 SL prop shaft drive shaft refurb', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'dbJZYI-RHr8', 'Mercedes 107 SL prop shaft drive shaft refurb', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', '62g_w9V-Er0', 'Mercedes 107 SL rear differential and axle shafts', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '62g_w9V-Er0', 'Mercedes 107 SL rear differential and axle shafts', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'csxIF232gqc', 'Mercedes 107 SL rear drop links and stabiliser bar', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'csxIF232gqc', 'Mercedes 107 SL rear drop links and stabiliser bar', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'KJZg8LXFhBE', 'Mercedes 107 SL rear hub, subframe mounts and control arm bush removal', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'yOzOO9LqjkQ', 'Mercedes 107 SL recurring fuel leak fixed', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '0yb-q4qu6vw', 'Mercedes 107 SL stuck brake disc + shock absorber removal', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '0yb-q4qu6vw', 'Mercedes 107 SL stuck brake disc + shock absorber removal', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', '0yb-q4qu6vw', 'Mercedes 107 SL stuck brake disc + shock absorber removal', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'jtOJGD5tdhk', 'Mercedes 107 SL subframe and mount removal', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'ky1ETGZzQ-Y', 'Mercedes 107 SL transmission mount', 'Automatyczna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'NuwfDdU4PmE', 'Mercedes 107 SL windscreen washer reservoir leak fixed', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'xCDde8Zs3jQ', 'Mercedes 107 clutch leak fixed', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'xCDde8Zs3jQ', 'Mercedes 107 clutch leak fixed', 'Hydraulika i ABS', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'xCDde8Zs3jQ', 'Mercedes 107 clutch leak fixed', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'xCDde8Zs3jQ', 'Mercedes 107 clutch leak fixed', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'yz_v0ECY5iw', 'Mercedes 280SL - check YOUR insurance and avoid this pain', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'U87V1fgvhTk', 'Mercedes 300SEL - M116 water pump change', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'U87V1fgvhTk', 'Mercedes 300SEL - M116 water pump change', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'aT7TYhj7yqI', 'Mercedes 350SL 450SL 380SL 500SL 560SL Smooth Ride Restoration Kit', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'v3cilQPohII', 'Mercedes 420 560 V8 Engine V-Belts and Front Engine Accessories', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '1MO_DKnUbxQ', 'Mercedes 450SL 380SL 560SL Hidden Rust Area Inspection', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '1MO_DKnUbxQ', 'Mercedes 450SL 380SL 560SL Hidden Rust Area Inspection', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '1MO_DKnUbxQ', 'Mercedes 450SL 380SL 560SL Hidden Rust Area Inspection', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '1MO_DKnUbxQ', 'Mercedes 450SL 380SL 560SL Hidden Rust Area Inspection', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '1MO_DKnUbxQ', 'Mercedes 450SL 380SL 560SL Hidden Rust Area Inspection', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'Z1eho8WnNRs', 'Mercedes 450SL 380SL 560SL Water Leaks: How to Isolate the Source', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'v6qQXZ35S_o', 'Mercedes ABS system - Mercedes classic cars R107, W126, W123, W124 and W201 - complete test', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'v6qQXZ35S_o', 'Mercedes ABS system - Mercedes classic cars R107, W126, W123, W124 and W201 - complete test', 'Hydraulika i ABS', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'cP6Vezdcqcs', 'Mercedes AMG GT fails to meet reserve at CoPart Auction. Too cheap....or a money pit?', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'cP6Vezdcqcs', 'Mercedes AMG GT fails to meet reserve at CoPart Auction. Too cheap....or a money pit?', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'NCynrf_6Eig', 'Mercedes AMG GTS - worth buying at auction? Where are Classic Mercedes prices heading up or down??….', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'NCynrf_6Eig', 'Mercedes AMG GTS - worth buying at auction? Where are Classic Mercedes prices heading up or down??….', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'NCynrf_6Eig', 'Mercedes AMG GTS - worth buying at auction? Where are Classic Mercedes prices heading up or down??….', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'beHHreF-PiA', 'Mercedes AMG GTS sets a new record! ......but not in a good way+classic Mercedes prices at auction.', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'xxr9XqoRad8', 'Mercedes ARF - Check exhaust gas recirculation with KE-Jetronic - uneven engine running', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'xxr9XqoRad8', 'Mercedes ARF - Check exhaust gas recirculation with KE-Jetronic - uneven engine running', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'xxr9XqoRad8', 'Mercedes ARF - Check exhaust gas recirculation with KE-Jetronic - uneven engine running', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'xxr9XqoRad8', 'Mercedes ARF - Check exhaust gas recirculation with KE-Jetronic - uneven engine running', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'xxr9XqoRad8', 'Mercedes ARF - Check exhaust gas recirculation with KE-Jetronic - uneven engine running', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'xxr9XqoRad8', 'Mercedes ARF - Check exhaust gas recirculation with KE-Jetronic - uneven engine running', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'xxr9XqoRad8', 'Mercedes ARF - Check exhaust gas recirculation with KE-Jetronic - uneven engine running', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'xxr9XqoRad8', 'Mercedes ARF - Check exhaust gas recirculation with KE-Jetronic - uneven engine running', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'wm-vhZGF5Gs', 'Mercedes Benz #R107, #W126, #W116, #W201 Check fuel pump relay - 280SE', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'wm-vhZGF5Gs', 'Mercedes Benz #R107, #W126, #W116, #W201 Check fuel pump relay - 280SE', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '7CmHsnJL7kg', 'Mercedes Benz - Supplement to the warm-up controller - Assemble the K-Jetronic warm-up controller correctly', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'LS0MJIm4aJc', 'Mercedes Benz Exterior temperature display Mercedes W126 Check', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'LS0MJIm4aJc', 'Mercedes Benz Exterior temperature display Mercedes W126 Check', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'LS0MJIm4aJc', 'Mercedes Benz Exterior temperature display Mercedes W126 Check', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'LS0MJIm4aJc', 'Mercedes Benz Exterior temperature display Mercedes W126 Check', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'LS0MJIm4aJc', 'Mercedes Benz Exterior temperature display Mercedes W126 Check', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'LS0MJIm4aJc', 'Mercedes Benz Exterior temperature display Mercedes W126 Check', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'LS0MJIm4aJc', 'Mercedes Benz Exterior temperature display Mercedes W126 Check', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'vrBoqK63hnY', 'Mercedes Benz KE-Jetronic - change mixture controller, air mass meter and flow divider #R107 #W126', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'G8auhs7zLEQ', 'Mercedes Benz M110 Engine - compression test and special features', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'SLFLdXeNQhg', 'Mercedes Benz R107 - Opening and closing the top #Mercedes #R107', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Yo8fj6sjGes', 'Mercedes Benz R107 Cabrio - Adjust the side window pane - Adjust the window pane on the soft top', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Yo8fj6sjGes', 'Mercedes Benz R107 Cabrio - Adjust the side window pane - Adjust the window pane on the soft top', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Yo8fj6sjGes', 'Mercedes Benz R107 Cabrio - Adjust the side window pane - Adjust the window pane on the soft top', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'rlwaYCFZx3k', 'Mercedes Benz R107 and R129 - 2nd generations SL', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'rlwaYCFZx3k', 'Mercedes Benz R107 and R129 - 2nd generations SL', 'Automatyczna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'A4RSCXWG6XE', 'Mercedes Benz W113 - Pagoda - 280SL 250SL 230SL - VDO analogue clock', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'A4RSCXWG6XE', 'Mercedes Benz W113 - Pagoda - 280SL 250SL 230SL - VDO analogue clock', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'yYBlm7FzVuc', 'Mercedes Benz W126 - 560SE level control - changing the pressure accumulator.', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'iHX5NPa45QY', 'Mercedes Benz W126 - 560SE one of only 1252 copies!', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 's6eFaNBaAB8', 'Mercedes Benz W126 Check Fuel Pump Relay - 280SE', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 's6eFaNBaAB8', 'Mercedes Benz W126 Check Fuel Pump Relay - 280SE', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 's6eFaNBaAB8', 'Mercedes Benz W126 Check Fuel Pump Relay - 280SE', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 's6eFaNBaAB8', 'Mercedes Benz W126 Check Fuel Pump Relay - 280SE', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 's6eFaNBaAB8', 'Mercedes Benz W126 Check Fuel Pump Relay - 280SE', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 's6eFaNBaAB8', 'Mercedes Benz W126 Check Fuel Pump Relay - 280SE', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 's6eFaNBaAB8', 'Mercedes Benz W126 Check Fuel Pump Relay - 280SE', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 's6eFaNBaAB8', 'Mercedes Benz W126 Check Fuel Pump Relay - 280SE', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 's6eFaNBaAB8', 'Mercedes Benz W126 Check Fuel Pump Relay - 280SE', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '2tWmu-pEcmw', 'Mercedes Benz W126 Check outside temperature display on 420 SEL - S-Class #W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '2tWmu-pEcmw', 'Mercedes Benz W126 Check outside temperature display on 420 SEL - S-Class #W126', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '2tWmu-pEcmw', 'Mercedes Benz W126 Check outside temperature display on 420 SEL - S-Class #W126', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '1tvNmMm7vB4', 'Mercedes Benz central locking system - ZV Old Benz W108, W116, R107, W126, W123, W124, C107', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '1tvNmMm7vB4', 'Mercedes Benz central locking system - ZV Old Benz W108, W116, R107, W126, W123, W124, C107', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '1tvNmMm7vB4', 'Mercedes Benz central locking system - ZV Old Benz W108, W116, R107, W126, W123, W124, C107', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '1tvNmMm7vB4', 'Mercedes Benz central locking system - ZV Old Benz W108, W116, R107, W126, W123, W124, C107', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '1tvNmMm7vB4', 'Mercedes Benz central locking system - ZV Old Benz W108, W116, R107, W126, W123, W124, C107', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '1tvNmMm7vB4', 'Mercedes Benz central locking system - ZV Old Benz W108, W116, R107, W126, W123, W124, C107', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '1tvNmMm7vB4', 'Mercedes Benz central locking system - ZV Old Benz W108, W116, R107, W126, W123, W124, C107', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '1tvNmMm7vB4', 'Mercedes Benz central locking system - ZV Old Benz W108, W116, R107, W126, W123, W124, C107', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'CJ3C008oAEE', 'Mercedes D-Jetronic - healthy engine running - air temperature sensor W109 300SEL', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'CJ3C008oAEE', 'Mercedes D-Jetronic - healthy engine running - air temperature sensor W109 300SEL', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'wS7v_i4Ql4o', 'Mercedes D-Jetronic pressure sensor check', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'wS7v_i4Ql4o', 'Mercedes D-Jetronic pressure sensor check', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'wS7v_i4Ql4o', 'Mercedes D-Jetronic pressure sensor check', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'wS7v_i4Ql4o', 'Mercedes D-Jetronic pressure sensor check', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'wS7v_i4Ql4o', 'Mercedes D-Jetronic pressure sensor check', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'wS7v_i4Ql4o', 'Mercedes D-Jetronic pressure sensor check', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'wS7v_i4Ql4o', 'Mercedes D-Jetronic pressure sensor check', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'wS7v_i4Ql4o', 'Mercedes D-Jetronic pressure sensor check', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'wS7v_i4Ql4o', 'Mercedes D-Jetronic pressure sensor check', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'wS7v_i4Ql4o', 'Mercedes D-Jetronic pressure sensor check', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'eg1oezckIiI', 'Mercedes ECONOMY ad - economical driving - Old Benz', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'eg1oezckIiI', 'Mercedes ECONOMY ad - economical driving - Old Benz', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'eg1oezckIiI', 'Mercedes ECONOMY ad - economical driving - Old Benz', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'eg1oezckIiI', 'Mercedes ECONOMY ad - economical driving - Old Benz', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'eg1oezckIiI', 'Mercedes ECONOMY ad - economical driving - Old Benz', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'eg1oezckIiI', 'Mercedes ECONOMY ad - economical driving - Old Benz', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'eg1oezckIiI', 'Mercedes ECONOMY ad - economical driving - Old Benz', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'eg1oezckIiI', 'Mercedes ECONOMY ad - economical driving - Old Benz', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'eg1oezckIiI', 'Mercedes ECONOMY ad - economical driving - Old Benz', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'jER6spzkmNE', 'Mercedes KE-JETRONIC - Change the lower part of the bottled air flow meter', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'jER6spzkmNE', 'Mercedes KE-JETRONIC - Change the lower part of the bottled air flow meter', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'dwZiYxfOsrU', 'Mercedes KE-Jetronic (Bosch) function - errors and the causes', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'dwZiYxfOsrU', 'Mercedes KE-Jetronic (Bosch) function - errors and the causes', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'dwZiYxfOsrU', 'Mercedes KE-Jetronic (Bosch) function - errors and the causes', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'dwZiYxfOsrU', 'Mercedes KE-Jetronic (Bosch) function - errors and the causes', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'dwZiYxfOsrU', 'Mercedes KE-Jetronic (Bosch) function - errors and the causes', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'dwZiYxfOsrU', 'Mercedes KE-Jetronic (Bosch) function - errors and the causes', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'dwZiYxfOsrU', 'Mercedes KE-Jetronic (Bosch) function - errors and the causes', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'syow63qHAlk', 'Mercedes KE-Jetronic and K-Jetronic - Warm Start Problems - Mercedes restoration', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'syow63qHAlk', 'Mercedes KE-Jetronic and K-Jetronic - Warm Start Problems - Mercedes restoration', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'syow63qHAlk', 'Mercedes KE-Jetronic and K-Jetronic - Warm Start Problems - Mercedes restoration', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'syow63qHAlk', 'Mercedes KE-Jetronic and K-Jetronic - Warm Start Problems - Mercedes restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'syow63qHAlk', 'Mercedes KE-Jetronic and K-Jetronic - Warm Start Problems - Mercedes restoration', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'syow63qHAlk', 'Mercedes KE-Jetronic and K-Jetronic - Warm Start Problems - Mercedes restoration', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'syow63qHAlk', 'Mercedes KE-Jetronic and K-Jetronic - Warm Start Problems - Mercedes restoration', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'syow63qHAlk', 'Mercedes KE-Jetronic and K-Jetronic - Warm Start Problems - Mercedes restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'syow63qHAlk', 'Mercedes KE-Jetronic and K-Jetronic - Warm Start Problems - Mercedes restoration', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'aJizaJIOcNg', 'Mercedes KE-Jetronic injection - check and adjust EHS #R107 #W126 #W201 #W124 #w463', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'aJizaJIOcNg', 'Mercedes KE-Jetronic injection - check and adjust EHS #R107 #W126 #W201 #W124 #w463', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'c-u50Z0nU-s', 'Mercedes KE-Jetronic mixture control, flow divider and air flow meter change - Mercedes restoration', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'c-u50Z0nU-s', 'Mercedes KE-Jetronic mixture control, flow divider and air flow meter change - Mercedes restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ZYnv6ARMVWQ', 'Mercedes M103 engine cuts out while driving', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'ZYnv6ARMVWQ', 'Mercedes M103 engine cuts out while driving', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'eqpq3dgRSE0', 'Mercedes M110 engine - coin balance whilst engine is running + diagnose and fix a misfire', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'eqpq3dgRSE0', 'Mercedes M110 engine - coin balance whilst engine is running + diagnose and fix a misfire', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'eqpq3dgRSE0', 'Mercedes M110 engine - coin balance whilst engine is running + diagnose and fix a misfire', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'rKbViyhqwxg', 'Mercedes M116-M117 W108 - W109 ignition distributor', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'rKbViyhqwxg', 'Mercedes M116-M117 W108 - W109 ignition distributor', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'rKbViyhqwxg', 'Mercedes M116-M117 W108 - W109 ignition distributor', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'rKbViyhqwxg', 'Mercedes M116-M117 W108 - W109 ignition distributor', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'rKbViyhqwxg', 'Mercedes M116-M117 W108 - W109 ignition distributor', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'rKbViyhqwxg', 'Mercedes M116-M117 W108 - W109 ignition distributor', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'rKbViyhqwxg', 'Mercedes M116-M117 W108 - W109 ignition distributor', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'rKbViyhqwxg', 'Mercedes M116-M117 W108 - W109 ignition distributor', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'rKbViyhqwxg', 'Mercedes M116-M117 W108 - W109 ignition distributor', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '32OM5dGC4bM', 'Mercedes OM 603 engine - Check and replace glow plugs - without breaking!', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '32OM5dGC4bM', 'Mercedes OM 603 engine - Check and replace glow plugs - without breaking!', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '32OM5dGC4bM', 'Mercedes OM 603 engine - Check and replace glow plugs - without breaking!', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '32OM5dGC4bM', 'Mercedes OM 603 engine - Check and replace glow plugs - without breaking!', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '32OM5dGC4bM', 'Mercedes OM 603 engine - Check and replace glow plugs - without breaking!', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '32OM5dGC4bM', 'Mercedes OM 603 engine - Check and replace glow plugs - without breaking!', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '32OM5dGC4bM', 'Mercedes OM 603 engine - Check and replace glow plugs - without breaking!', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '32OM5dGC4bM', 'Mercedes OM 603 engine - Check and replace glow plugs - without breaking!', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'SUPXghTqDyA', 'Mercedes Pagoda’s unsold as classic car auction prices struggle to meet reserve….w113 and w121.', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'SUPXghTqDyA', 'Mercedes Pagoda’s unsold as classic car auction prices struggle to meet reserve….w113 and w121.', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'aY5MPNzWi1I', 'Mercedes Plate adjustment K-Jetronic', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'aY5MPNzWi1I', 'Mercedes Plate adjustment K-Jetronic', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'aY5MPNzWi1I', 'Mercedes Plate adjustment K-Jetronic', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'aY5MPNzWi1I', 'Mercedes Plate adjustment K-Jetronic', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'aY5MPNzWi1I', 'Mercedes Plate adjustment K-Jetronic', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'aY5MPNzWi1I', 'Mercedes Plate adjustment K-Jetronic', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'aY5MPNzWi1I', 'Mercedes Plate adjustment K-Jetronic', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'aY5MPNzWi1I', 'Mercedes Plate adjustment K-Jetronic', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', '8ebmu1h8lB4', 'Mercedes Power Steering Pump Fluid Leak Diagnosis and Repair', 'Układ kierowniczy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '_JrQOYwWlrQ', 'Mercedes R/C 107 - 350SL D-Jetronic - Ignition distributor plug connection', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '_JrQOYwWlrQ', 'Mercedes R/C 107 - 350SL D-Jetronic - Ignition distributor plug connection', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '_JrQOYwWlrQ', 'Mercedes R/C 107 - 350SL D-Jetronic - Ignition distributor plug connection', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'LBpoQReG4Bs', 'Mercedes R/C 107 - Market prices 2024 - Classic car market value', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'LBpoQReG4Bs', 'Mercedes R/C 107 - Market prices 2024 - Classic car market value', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'LBpoQReG4Bs', 'Mercedes R/C 107 - Market prices 2024 - Classic car market value', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'LBpoQReG4Bs', 'Mercedes R/C 107 - Market prices 2024 - Classic car market value', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'LBpoQReG4Bs', 'Mercedes R/C 107 - Market prices 2024 - Classic car market value', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'LBpoQReG4Bs', 'Mercedes R/C 107 - Market prices 2024 - Classic car market value', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'LBpoQReG4Bs', 'Mercedes R/C 107 - Market prices 2024 - Classic car market value', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'LBpoQReG4Bs', 'Mercedes R/C 107 - Market prices 2024 - Classic car market value', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'qUL6mb0vWNY', 'Mercedes R107  Klippan seat belts', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'KsNOkz8Waew', 'Mercedes R107 +W123 accelerator pedal assembly + how to attach', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'KsNOkz8Waew', 'Mercedes R107 +W123 accelerator pedal assembly + how to attach', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ZYn9P0j1nJc', 'Mercedes R107 - 1st drive in 10 years! Neutral safety switch + gear shift bushings', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ZYn9P0j1nJc', 'Mercedes R107 - 1st drive in 10 years! Neutral safety switch + gear shift bushings', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'ZYn9P0j1nJc', 'Mercedes R107 - 1st drive in 10 years! Neutral safety switch + gear shift bushings', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'ZYn9P0j1nJc', 'Mercedes R107 - 1st drive in 10 years! Neutral safety switch + gear shift bushings', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'ZYn9P0j1nJc', 'Mercedes R107 - 1st drive in 10 years! Neutral safety switch + gear shift bushings', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '2weoZJO7MF0', 'Mercedes R107 - 1st start after cooling system rebuild', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'rcqHA4vRCZI', 'Mercedes R107 - 3M 08115 panel bond crossmembers and carpet sills', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'rcqHA4vRCZI', 'Mercedes R107 - 3M 08115 panel bond crossmembers and carpet sills', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '1CDqocKX3LI', 'Mercedes R107 - Eastwood 2K Epoxy Primer +3M panel bond for inner wheel arch repair', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '1CDqocKX3LI', 'Mercedes R107 - Eastwood 2K Epoxy Primer +3M panel bond for inner wheel arch repair', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '1CDqocKX3LI', 'Mercedes R107 - Eastwood 2K Epoxy Primer +3M panel bond for inner wheel arch repair', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'nquhnXMe_o0', 'Mercedes R107 - How to fit new soft top and remove old glue. Step by step guide with useful tips.', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'nquhnXMe_o0', 'Mercedes R107 - How to fit new soft top and remove old glue. Step by step guide with useful tips.', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'nquhnXMe_o0', 'Mercedes R107 - How to fit new soft top and remove old glue. Step by step guide with useful tips.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'dOOnLigwvFk', 'Mercedes R107 - How to rebuild brake calipers + pros and cons of powder coating vs painting.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'aKT_1eUQHfY', 'Mercedes R107 - Remove and repair windshield wiper relay.', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'aKT_1eUQHfY', 'Mercedes R107 - Remove and repair windshield wiper relay.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '32uiNpfMDkY', 'Mercedes R107 - SL - Door Panel Door Trim Removal', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '32uiNpfMDkY', 'Mercedes R107 - SL - Door Panel Door Trim Removal', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '32uiNpfMDkY', 'Mercedes R107 - SL - Door Panel Door Trim Removal', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '32uiNpfMDkY', 'Mercedes R107 - SL - Door Panel Door Trim Removal', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '32uiNpfMDkY', 'Mercedes R107 - SL - Door Panel Door Trim Removal', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '32uiNpfMDkY', 'Mercedes R107 - SL - Door Panel Door Trim Removal', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '32uiNpfMDkY', 'Mercedes R107 - SL - Door Panel Door Trim Removal', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '32uiNpfMDkY', 'Mercedes R107 - SL - Door Panel Door Trim Removal', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'GRFLk16aQ_Y', 'Mercedes R107 - SL - Remove door cardboard door panel', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'GRFLk16aQ_Y', 'Mercedes R107 - SL - Remove door cardboard door panel', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '4IkLxYQ-Pgg', 'Mercedes R107 - Setting the ignition timing #R107 #Oldtimer', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '15xVHXvubwE', 'Mercedes R107 - Window regulator restoration using Eastwood Golden Cad system', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '15xVHXvubwE', 'Mercedes R107 - Window regulator restoration using Eastwood Golden Cad system', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '15xVHXvubwE', 'Mercedes R107 - Window regulator restoration using Eastwood Golden Cad system', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'dbema0mIfyU', 'Mercedes R107 - door card refurb, door alignment tips. Major milestone reached.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '7saThWDUalw', 'Mercedes R107 - door pockets. How to refurbish and fix broken plastic.', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '7saThWDUalw', 'Mercedes R107 - door pockets. How to refurbish and fix broken plastic.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '0HrFZ1ObJAE', 'Mercedes R107 - expansion tank. Why they go yellow and how to clean them.', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'ejwYa5QwNK4', 'Mercedes R107 - fitting THE cheapest ‘ leather’ seat covers with surprising results.', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'ejwYa5QwNK4', 'Mercedes R107 - fitting THE cheapest ‘ leather’ seat covers with surprising results.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'GQZzzbGnyt4', 'Mercedes R107 - front bumper bubbling chrome', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'JPQi6XyQKuM', 'Mercedes R107 - grommets and why you should check yours', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'JPQi6XyQKuM', 'Mercedes R107 - grommets and why you should check yours', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'uzy1u8FrFQ4', 'Mercedes R107 - headlight fitting, bonnet stops, windscreen washer reservoir +  1st motorway drive!', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'uzy1u8FrFQ4', 'Mercedes R107 - headlight fitting, bonnet stops, windscreen washer reservoir +  1st motorway drive!', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Rw3HGorHYUI', 'Mercedes R107 - how to align the window and fit the door card', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Rw3HGorHYUI', 'Mercedes R107 - how to align the window and fit the door card', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'Rw3HGorHYUI', 'Mercedes R107 - how to align the window and fit the door card', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Qdfi47GQ4Dg', 'Mercedes R107 - how to fix pinhole in metal coolant pipe using a Durafix braising rod and MAP torch.', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Qdfi47GQ4Dg', 'Mercedes R107 - how to fix pinhole in metal coolant pipe using a Durafix braising rod and MAP torch.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'DlPvoFFQAWk', 'Mercedes R107 - how to replace door card vinyl', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'DlPvoFFQAWk', 'Mercedes R107 - how to replace door card vinyl', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'bG7fYWw661w', 'Mercedes R107 - re chroming the rustiest headlight bowl', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '5Xen-OG0mUM', 'Mercedes R107 - seats are in + tips on reproducing OEM looking under carpet mats', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '5Xen-OG0mUM', 'Mercedes R107 - seats are in + tips on reproducing OEM looking under carpet mats', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '_FD5BbvhxGU', 'Mercedes R107 - throttle linkage refurb with zinc plating + how to make a gasket', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'Gnv0mrqavno', 'Mercedes R107 - what to look for when buying at auction. Low mileage desirable 1989 Mercedes 300SL', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'Gnv0mrqavno', 'Mercedes R107 - what to look for when buying at auction. Low mileage desirable 1989 Mercedes 300SL', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'ieGfYEL6tGg', 'Mercedes R107 280SL 1985 - one of the last 280s of the R107 model series', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'ieGfYEL6tGg', 'Mercedes R107 280SL 1985 - one of the last 280s of the R107 model series', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'kZOLlWwyQr4', 'Mercedes R107 280SL air filter housing refurb using 3M 08115 panel bond', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'kZOLlWwyQr4', 'Mercedes R107 280SL air filter housing refurb using 3M 08115 panel bond', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'vKQvlFHIIeQ', 'Mercedes R107 280SL full respray', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'C5w7gFZScW4', 'Mercedes R107 280sl Fuel pump fuel filter and accumulator change - Part 1', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'C5w7gFZScW4', 'Mercedes R107 280sl Fuel pump fuel filter and accumulator change - Part 1', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'TOF_AZM3b5I', 'Mercedes R107 300SL - poor engine running - fluctuating speeds', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'TOF_AZM3b5I', 'Mercedes R107 300SL - poor engine running - fluctuating speeds', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'fEmh9TZcvbY', 'Mercedes R107 450SL V8 (1979) - first delivery Canada - Roadster', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'fEmh9TZcvbY', 'Mercedes R107 450SL V8 (1979) - first delivery Canada - Roadster', 'Automatyczna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'Gh1LOA7brq4', 'Mercedes R107 50th anniversary The SLShop', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'ga-XnXD6QZ8', 'Mercedes R107 560SL changing automatic selector lever - Toscana', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'GIjr2XUEsss', 'Mercedes R107 560SL 🚘 - Cooling water temperature sensor 2nd series - KE-Jetronic Toscana', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'GIjr2XUEsss', 'Mercedes R107 560SL 🚘 - Cooling water temperature sensor 2nd series - KE-Jetronic Toscana', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '4TevKiAeV5U', 'Mercedes R107 Alternator and voltage regulator putting out less than 14v. Fix.', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'ZqEqTt3xs8Q', 'Mercedes R107 Bosch fuel pump +fuel pump relay+first start in years', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'ZqEqTt3xs8Q', 'Mercedes R107 Bosch fuel pump +fuel pump relay+first start in years', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'ZqEqTt3xs8Q', 'Mercedes R107 Bosch fuel pump +fuel pump relay+first start in years', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '07N9ME6Uhx0', 'Mercedes R107 D Jetronic  wiring harness. How to make your own.', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '07N9ME6Uhx0', 'Mercedes R107 D Jetronic  wiring harness. How to make your own.', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'srvBSoYbUK8', 'Mercedes R107 D Jetronic fuel pump refurb and install', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '7FAdn9hsa54', 'Mercedes R107 ECU bracket+central console installation', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '7FAdn9hsa54', 'Mercedes R107 ECU bracket+central console installation', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'yqYU8sZzb3w', 'Mercedes R107 Heater Blower Fan behaving strangely - intermittent fault and switching to full blast.', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'yqYU8sZzb3w', 'Mercedes R107 Heater Blower Fan behaving strangely - intermittent fault and switching to full blast.', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'HHrtzzLN7PU', 'Mercedes R107 Heater Blower Motor installation + how to repair snapped studs & cracked plastic', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'HHrtzzLN7PU', 'Mercedes R107 Heater Blower Motor installation + how to repair snapped studs & cracked plastic', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'zjYELZ4b128', 'Mercedes R107 Ignition barrel bezel escutcheon', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'zjYELZ4b128', 'Mercedes R107 Ignition barrel bezel escutcheon', 'Układ kierowniczy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'R-bZszNhelI', 'Mercedes R107 SL - Changing the rear axle spring pad', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'xt12OoLyJks', 'Mercedes R107 SL - How to remove fuel tank, header tank + locking fuel cap', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'xt12OoLyJks', 'Mercedes R107 SL - How to remove fuel tank, header tank + locking fuel cap', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'ljqEZ4cbSoo', 'Mercedes R107 SL - clutch slave cylinder replacement', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'tlvDeUqpm1Y', 'Mercedes R107 SL - how to make your own door card', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '7RB7cF3SL50', 'Mercedes R107 SL - how to remove and refurb central console.', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '7RB7cF3SL50', 'Mercedes R107 SL - how to remove and refurb central console.', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '7RB7cF3SL50', 'Mercedes R107 SL - how to remove and refurb central console.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'TXt4_JN0iEk', 'Mercedes R107 SL - repairing and recovering rear side trim panels', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'plaLatGA6YM', 'Mercedes R107 SL Adjusting the side windows on the soft top', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'plaLatGA6YM', 'Mercedes R107 SL Adjusting the side windows on the soft top', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'plaLatGA6YM', 'Mercedes R107 SL Adjusting the side windows on the soft top', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'plaLatGA6YM', 'Mercedes R107 SL Adjusting the side windows on the soft top', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'plaLatGA6YM', 'Mercedes R107 SL Adjusting the side windows on the soft top', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'plaLatGA6YM', 'Mercedes R107 SL Adjusting the side windows on the soft top', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'plaLatGA6YM', 'Mercedes R107 SL Adjusting the side windows on the soft top', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'plaLatGA6YM', 'Mercedes R107 SL Adjusting the side windows on the soft top', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'plaLatGA6YM', 'Mercedes R107 SL Adjusting the side windows on the soft top', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'plaLatGA6YM', 'Mercedes R107 SL Adjusting the side windows on the soft top', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'S35eedIQWKc', 'Mercedes R107 SL Instrument Cluster Speedometer - Replace Gears', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'S35eedIQWKc', 'Mercedes R107 SL Instrument Cluster Speedometer - Replace Gears', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'S35eedIQWKc', 'Mercedes R107 SL Instrument Cluster Speedometer - Replace Gears', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'S35eedIQWKc', 'Mercedes R107 SL Instrument Cluster Speedometer - Replace Gears', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'S35eedIQWKc', 'Mercedes R107 SL Instrument Cluster Speedometer - Replace Gears', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'S35eedIQWKc', 'Mercedes R107 SL Instrument Cluster Speedometer - Replace Gears', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'S35eedIQWKc', 'Mercedes R107 SL Instrument Cluster Speedometer - Replace Gears', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'S35eedIQWKc', 'Mercedes R107 SL Instrument Cluster Speedometer - Replace Gears', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'QCD2Ot2ZnI0', 'Mercedes R107 SL bonnet alignment, fuel pump issues and steering wheel fitment problem.', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'QCD2Ot2ZnI0', 'Mercedes R107 SL bonnet alignment, fuel pump issues and steering wheel fitment problem.', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'QCD2Ot2ZnI0', 'Mercedes R107 SL bonnet alignment, fuel pump issues and steering wheel fitment problem.', 'Układ kierowniczy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'QCD2Ot2ZnI0', 'Mercedes R107 SL bonnet alignment, fuel pump issues and steering wheel fitment problem.', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '-KtSobpadCo', 'Mercedes R107 SL brake booster, brake pedal restoration and installation', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'm7vdZPVzOy4', 'Mercedes R107 SL chrome sill trim', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'l07UKiOXq5w', 'Mercedes R107 SL coolant change and radiator hose', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'l07UKiOXq5w', 'Mercedes R107 SL coolant change and radiator hose', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'l07UKiOXq5w', 'Mercedes R107 SL coolant change and radiator hose', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'wLISaxdlewo', 'Mercedes R107 SL differential, axles, springs, shocks & sway bay', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'wLISaxdlewo', 'Mercedes R107 SL differential, axles, springs, shocks & sway bay', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '0eSaiivi0aw', 'Mercedes R107 SL door check  - A1077200016', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'eG3Sb-Yj6UQ', 'Mercedes R107 SL door lock & ignition lock - key wont turn. FIX.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'FOHQUobhnOI', 'Mercedes R107 SL drain holes and common rust areas', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'FOHQUobhnOI', 'Mercedes R107 SL drain holes and common rust areas', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'fabdhbx6eqw', 'Mercedes R107 SL front bumper centre section', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '9W9HDIys63o', 'Mercedes R107 SL hardtop repair - Part 1', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '9W9HDIys63o', 'Mercedes R107 SL hardtop repair - Part 1', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Jzktcr0dtpg', 'Mercedes R107 SL how to fit door seals and sill trim', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'PDj8gQYDKxM', 'Mercedes R107 SL how to replace trunk or boot lid torsion springs - horrible job!!', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'AYdcNubJHP4', 'Mercedes R107 SL ignition barrel, turn signal indicator and steering column removal', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'AYdcNubJHP4', 'Mercedes R107 SL ignition barrel, turn signal indicator and steering column removal', 'Układ kierowniczy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'ZnbanwRVvko', 'Mercedes R107 SL instrument cluster speedometer - replacing gears', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'WRmk7a2G3pA', 'Mercedes R107 SL rear view mirror, sun visor rods and A pillar trims', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'RnPu0w2r6cs', 'Mercedes R107 SL repairing cracked plastic on central console', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'RnPu0w2r6cs', 'Mercedes R107 SL repairing cracked plastic on central console', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'RnPu0w2r6cs', 'Mercedes R107 SL repairing cracked plastic on central console', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Hu1hKwfohOI', 'Mercedes R107 SL rusty front bumper repair and installation+tips.', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Hu1hKwfohOI', 'Mercedes R107 SL rusty front bumper repair and installation+tips.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'rKTRvL647pw', 'Mercedes R107 SL sun visor refurb', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'rKTRvL647pw', 'Mercedes R107 SL sun visor refurb', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '0_L0vXNATmA', 'Mercedes R107 SL welding & fabricating battery tray bracket', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'NmZwyxj79kg', 'Mercedes R107 SL window rails and door rattle', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'NmZwyxj79kg', 'Mercedes R107 SL window rails and door rattle', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'A5gtr3XVkEo', 'Mercedes R107 SL- rusty seat base restoration', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'A5gtr3XVkEo', 'Mercedes R107 SL- rusty seat base restoration', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'A5gtr3XVkEo', 'Mercedes R107 SL- rusty seat base restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'bvfO-krwbsI', 'Mercedes R107 W126 W124 - heating valves - mono valve - duo valve does not heat!!!', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'bvfO-krwbsI', 'Mercedes R107 W126 W124 - heating valves - mono valve - duo valve does not heat!!!', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'FhDbjRjHPjo', 'Mercedes R107 W126 fuel pump - changing fuel pump package', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'FhDbjRjHPjo', 'Mercedes R107 W126 fuel pump - changing fuel pump package', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'FhDbjRjHPjo', 'Mercedes R107 W126 fuel pump - changing fuel pump package', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'FhDbjRjHPjo', 'Mercedes R107 W126 fuel pump - changing fuel pump package', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '1iBHHa2d1u0', 'Mercedes R107 air con tensioner pulley removal + air filter housing install', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'B9ykDi_VzkE', 'Mercedes R107 and W126 - Check cruise control - cruise control system', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'B9ykDi_VzkE', 'Mercedes R107 and W126 - Check cruise control - cruise control system', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'B9ykDi_VzkE', 'Mercedes R107 and W126 - Check cruise control - cruise control system', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'B9ykDi_VzkE', 'Mercedes R107 and W126 - Check cruise control - cruise control system', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'B9ykDi_VzkE', 'Mercedes R107 and W126 - Check cruise control - cruise control system', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'B9ykDi_VzkE', 'Mercedes R107 and W126 - Check cruise control - cruise control system', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'B9ykDi_VzkE', 'Mercedes R107 and W126 - Check cruise control - cruise control system', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'zPiLAKyRW6M', 'Mercedes R107 and W126 Check additional fan and temperature switch', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'zPiLAKyRW6M', 'Mercedes R107 and W126 Check additional fan and temperature switch', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'OxOS1Gh9gj8', 'Mercedes R107 ashtray, gear shift surround and climate control panel', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'OxOS1Gh9gj8', 'Mercedes R107 ashtray, gear shift surround and climate control panel', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'OxOS1Gh9gj8', 'Mercedes R107 ashtray, gear shift surround and climate control panel', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'yY7TnOLw0Kc', 'Mercedes R107 axle shaft spacers - careful! Don''t make this mistake!', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'TKzse3HCCiE', 'Mercedes R107 battery tray restoration opens can of worms', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'bv-LFG88a2g', 'Mercedes R107 body panels + how to prep for paint', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'bv-LFG88a2g', 'Mercedes R107 body panels + how to prep for paint', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'Z9HtZmUfvQM', 'Mercedes R107 brake master cylinder and brake fluid reservoir - everything your need to know', 'Hydraulika i ABS', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'rfDUDW6hjP4', 'Mercedes R107 bulk head front footwell leak repair', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'zmenoFts07o', 'Mercedes R107 bulkhead repair 3M panel bond vs welding', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'zmenoFts07o', 'Mercedes R107 bulkhead repair 3M panel bond vs welding', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'qeajAVI32vE', 'Mercedes R107 bulkhead strut fabrication using basic tools', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'Vc1Z91s8x6I', 'Mercedes R107 carpet underlay - make your own to look OEM.', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'G_NGn7J2_bY', 'Mercedes R107 coolant flush  - see what happens if you don''t change coolant regularly + fitting AAV', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'G_NGn7J2_bY', 'Mercedes R107 coolant flush  - see what happens if you don''t change coolant regularly + fitting AAV', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'G_NGn7J2_bY', 'Mercedes R107 coolant flush  - see what happens if you don''t change coolant regularly + fitting AAV', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'G_NGn7J2_bY', 'Mercedes R107 coolant flush  - see what happens if you don''t change coolant regularly + fitting AAV', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'G_NGn7J2_bY', 'Mercedes R107 coolant flush  - see what happens if you don''t change coolant regularly + fitting AAV', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'G_NGn7J2_bY', 'Mercedes R107 coolant flush  - see what happens if you don''t change coolant regularly + fitting AAV', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'OPEKBHSQUcs', 'Mercedes R107 data card + VIN number decoding', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'OPEKBHSQUcs', 'Mercedes R107 data card + VIN number decoding', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'oahZ59pJTOU', 'Mercedes R107 deck chrome', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'oahZ59pJTOU', 'Mercedes R107 deck chrome', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'QAq24HtsRNI', 'Mercedes R107 door alignment, fix broken door stop, door seal+replace backing plate', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'QAq24HtsRNI', 'Mercedes R107 door alignment, fix broken door stop, door seal+replace backing plate', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'QAq24HtsRNI', 'Mercedes R107 door alignment, fix broken door stop, door seal+replace backing plate', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'KcxJbZ7Jv-o', 'Mercedes R107 door assembly - rods, door catch, regulator and guide rails', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Tu3G0g0EF2A', 'Mercedes R107 electrics - dimmer & hazard switch + fan blower motor and lights', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'Tu3G0g0EF2A', 'Mercedes R107 electrics - dimmer & hazard switch + fan blower motor and lights', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'Tu3G0g0EF2A', 'Mercedes R107 electrics - dimmer & hazard switch + fan blower motor and lights', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '76hhuW5X7to', 'Mercedes R107 exhaust manifold & steel water pipe refurb', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'TyE_tOV-ETQ', 'Mercedes R107 faulty cold start injector causes no end of problems! 450sl, 280sl, 350sl and 380sl', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'TyE_tOV-ETQ', 'Mercedes R107 faulty cold start injector causes no end of problems! 450sl, 280sl, 350sl and 380sl', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '-SsrA6y4PJE', 'Mercedes R107 front suspension spring - removal/ installation - changing the rubber pad', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '-SsrA6y4PJE', 'Mercedes R107 front suspension spring - removal/ installation - changing the rubber pad', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '-SsrA6y4PJE', 'Mercedes R107 front suspension spring - removal/ installation - changing the rubber pad', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '-SsrA6y4PJE', 'Mercedes R107 front suspension spring - removal/ installation - changing the rubber pad', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', '-SsrA6y4PJE', 'Mercedes R107 front suspension spring - removal/ installation - changing the rubber pad', 'Zawieszenie Przód', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '-SsrA6y4PJE', 'Mercedes R107 front suspension spring - removal/ installation - changing the rubber pad', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '-SsrA6y4PJE', 'Mercedes R107 front suspension spring - removal/ installation - changing the rubber pad', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '-SsrA6y4PJE', 'Mercedes R107 front suspension spring - removal/ installation - changing the rubber pad', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '-SsrA6y4PJE', 'Mercedes R107 front suspension spring - removal/ installation - changing the rubber pad', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'DRiFAYBlylY', 'Mercedes R107 fuel guage fix + cluster lights intermittent fault', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'DRiFAYBlylY', 'Mercedes R107 fuel guage fix + cluster lights intermittent fault', 'Hydraulika i ABS', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'DRiFAYBlylY', 'Mercedes R107 fuel guage fix + cluster lights intermittent fault', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'JMlUFGDJRvc', 'Mercedes R107 fuel pump assembly refurb and Bosch fuel pump disassembly', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'JMlUFGDJRvc', 'Mercedes R107 fuel pump assembly refurb and Bosch fuel pump disassembly', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'mNOKYOe7yFE', 'Mercedes R107 glovebox torch refurb using conductive glue instead of solder.', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '-7NJ_9x5NpI', 'Mercedes R107 handbrake adjustment rear fog light fix', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '-7NJ_9x5NpI', 'Mercedes R107 handbrake adjustment rear fog light fix', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'BAYfFzxj-pc', 'Mercedes R107 headlight fitting problem solved', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '0G2gkw26Ugo', 'Mercedes R107 headlight rebuild + modifying LH reflector to fit RHS.', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '8_7lIKDOzJU', 'Mercedes R107 how to change water pump + radiator removal', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'vRRbB6NDnmU', 'Mercedes R107 how to glue in the boot seal or trunk seal - 3M, E6000 or both?', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'vRRbB6NDnmU', 'Mercedes R107 how to glue in the boot seal or trunk seal - 3M, E6000 or both?', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'qP35yhTfP14', 'Mercedes R107 how to remove door card, window glass, regulator and locking mechanism', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'qP35yhTfP14', 'Mercedes R107 how to remove door card, window glass, regulator and locking mechanism', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'XOjgvaIT3Bw', 'Mercedes R107 ignition control module + ballast resistors', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'XOjgvaIT3Bw', 'Mercedes R107 ignition control module + ballast resistors', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'XOjgvaIT3Bw', 'Mercedes R107 ignition control module + ballast resistors', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'KPQ3QYWtK0I', 'Mercedes R107 inner wheel arch removal using spot weld drill bit', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'JGVi3O4o1bQ', 'Mercedes R107 instrument cluster repair, circuit board, needles and gauges', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'JGVi3O4o1bQ', 'Mercedes R107 instrument cluster repair, circuit board, needles and gauges', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'JGVi3O4o1bQ', 'Mercedes R107 instrument cluster repair, circuit board, needles and gauges', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'Nt9Z8PXp7ac', 'Mercedes R107 lap weld vs butt weld for frame rails', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Nt9Z8PXp7ac', 'Mercedes R107 lap weld vs butt weld for frame rails', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Nt9Z8PXp7ac', 'Mercedes R107 lap weld vs butt weld for frame rails', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'N-DhBnJ4Ie8', 'Mercedes R107 lock and key refurb…+ glove box discovery', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Rshhhh9nU34', 'Mercedes R107 lower valance powder coating vs painting', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Rshhhh9nU34', 'Mercedes R107 lower valance powder coating vs painting', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'esqCE6eqW8I', 'Mercedes R107 mechanic in Tuscany - Olaf''s R107 560', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '7NeR_849k8M', 'Mercedes R107 new fuel tank installation+modification to fit older SL', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '7NeR_849k8M', 'Mercedes R107 new fuel tank installation+modification to fit older SL', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '7NeR_849k8M', 'Mercedes R107 new fuel tank installation+modification to fit older SL', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '7NeR_849k8M', 'Mercedes R107 new fuel tank installation+modification to fit older SL', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '65BqIls9uTQ', 'Mercedes R107 number plate light fix and restoration', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '65BqIls9uTQ', 'Mercedes R107 number plate light fix and restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'bqMG_F-UIm8', 'Mercedes R107 park brake switch repair & installation - A0015450211', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'bqMG_F-UIm8', 'Mercedes R107 park brake switch repair & installation - A0015450211', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'UeDGAwbm-3I', 'Mercedes R107 power steering fluid + difference in filters + replace  a leaking  hose', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'UeDGAwbm-3I', 'Mercedes R107 power steering fluid + difference in filters + replace  a leaking  hose', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'UeDGAwbm-3I', 'Mercedes R107 power steering fluid + difference in filters + replace  a leaking  hose', 'Układ kierowniczy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'UeDGAwbm-3I', 'Mercedes R107 power steering fluid + difference in filters + replace  a leaking  hose', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '5WfZGYYCy4o', 'Mercedes R107 radiator flush+snapping a thermostat housing bolt', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'mFJgr6BxpWU', 'Mercedes R107 rear bearing, races and oil seal installation', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'mFJgr6BxpWU', 'Mercedes R107 rear bearing, races and oil seal installation', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'mFJgr6BxpWU', 'Mercedes R107 rear bearing, races and oil seal installation', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '2ISIWwqBsQU', 'Mercedes R107 rear brake caliper replacement', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'B8zGjOFGHrk', 'Mercedes R107 rear bumper and valance', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'B8zGjOFGHrk', 'Mercedes R107 rear bumper and valance', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'fqmixb4Nx8Q', 'Mercedes R107 rear bumper refurb - powder coating, rust encapsulator+stainless steel hardware', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'TaGROTamT38', 'Mercedes R107 rear mount and control arm bush installation', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'tdVSNyqkiWs', 'Mercedes R107 removing water pump - snapped 4 out of 5 bolts!', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'tdVSNyqkiWs', 'Mercedes R107 removing water pump - snapped 4 out of 5 bolts!', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'pLDZHALgJlc', 'Mercedes R107 restoration - unboxing parts that came with car', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'XHXM_P5WIM4', 'Mercedes R107 scuttle panels - check for corrosion. Tips on fitting rear shocks and front grill.', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'XHXM_P5WIM4', 'Mercedes R107 scuttle panels - check for corrosion. Tips on fitting rear shocks and front grill.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'izjz65WVsoE', 'Mercedes R107 seat covers - where NOT to buy - Lseat.com', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'WZoJ2FBqXIQ', 'Mercedes R107 seat removal and disassembly', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '4DWmJrWvIaI', 'Mercedes R107 seatbelts - sewing on the buckles', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '-Zg_owQ2GqA', 'Mercedes R107 soft top roof mechanism + how to release stuck hardtop + replace broken cable', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '-Zg_owQ2GqA', 'Mercedes R107 soft top roof mechanism + how to release stuck hardtop + replace broken cable', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'v17Je2UF_Uo', 'Mercedes R107 spare wheel well refurb - are your bolts rusty?', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'v17Je2UF_Uo', 'Mercedes R107 spare wheel well refurb - are your bolts rusty?', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'v17Je2UF_Uo', 'Mercedes R107 spare wheel well refurb - are your bolts rusty?', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'kqregJ2RQVk', 'Mercedes R107 speaker cover refurb + how to fit new pioneer speakers.', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'UoQ4qTv_gJE', 'Mercedes R107 starter motor+ ignition wiring+neutral safety switch', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'UoQ4qTv_gJE', 'Mercedes R107 starter motor+ ignition wiring+neutral safety switch', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'iTX4KsyDL-w', 'Mercedes R107 tail light refurb - best source for new seals and lenses', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'C0thWv58yRI', 'Mercedes R107 trims - how to fit (correctly!) and where to buy…..', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'C0thWv58yRI', 'Mercedes R107 trims - how to fit (correctly!) and where to buy…..', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'C0thWv58yRI', 'Mercedes R107 trims - how to fit (correctly!) and where to buy…..', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'C0thWv58yRI', 'Mercedes R107 trims - how to fit (correctly!) and where to buy…..', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'C0thWv58yRI', 'Mercedes R107 trims - how to fit (correctly!) and where to buy…..', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'otESS4GZFj0', 'Mercedes R107 under bonnet insulation, windscreen washer hose, pump and foot switch repair.', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'otESS4GZFj0', 'Mercedes R107 under bonnet insulation, windscreen washer hose, pump and foot switch repair.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'otESS4GZFj0', 'Mercedes R107 under bonnet insulation, windscreen washer hose, pump and foot switch repair.', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'RPRKOYbTVtQ', 'Mercedes R107 using Dremmel tool to cut out rust', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'vsm5yQbcnL8', 'Mercedes R107 water pump housing, thermostat and hose clamp sizes', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'vsm5yQbcnL8', 'Mercedes R107 water pump housing, thermostat and hose clamp sizes', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '6ogMqxFV2gg', 'Mercedes R107 welding using Ecoflow Delta battery', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'Of8UqWYwAL8', 'Mercedes R107 wheel bearing - how to pack with grease - no mess or waste', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', '2eI_oAstiWA', 'Mercedes R107 wing mirrors. How to restore your wing mirror so that is moves as it should.', 'Zawieszenie Przód', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '2eI_oAstiWA', 'Mercedes R107 wing mirrors. How to restore your wing mirror so that is moves as it should.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', '5YMkeHzE31M', 'Mercedes R107 🚘 - tension spring - change spring pad - inner spring tensioner', 'Zawieszenie Przód', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '5YMkeHzE31M', 'Mercedes R107 🚘 - tension spring - change spring pad - inner spring tensioner', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'z8HFOQtZeEI', 'Mercedes R230 - what to look for when buying a 350sl at auction.  CoPart bargain or risky money pit?', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'z8HFOQtZeEI', 'Mercedes R230 - what to look for when buying a 350sl at auction.  CoPart bargain or risky money pit?', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'R7fbQBPaTPk', 'Mercedes R230 Electric consumer offline message. How to avoid ruining your consumer battery.', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'mWnumGNrOIs', 'Mercedes SL - Ignition control unit at KE', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'mWnumGNrOIs', 'Mercedes SL - Ignition control unit at KE', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'mWnumGNrOIs', 'Mercedes SL - Ignition control unit at KE', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'mWnumGNrOIs', 'Mercedes SL - Ignition control unit at KE', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'mWnumGNrOIs', 'Mercedes SL - Ignition control unit at KE', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'mWnumGNrOIs', 'Mercedes SL - Ignition control unit at KE', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'mWnumGNrOIs', 'Mercedes SL - Ignition control unit at KE', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'mWnumGNrOIs', 'Mercedes SL - Ignition control unit at KE', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'uyPh4fGrQrM', 'Mercedes SL Auction Prices - Historics Pace of Ascot Auction 20th Sept 2025. R107, R129, R230 & w113', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'QfEnRTdzAIQ', 'Mercedes SL Auction Prices in September - Manor Park Classics, Mathewsons & Bonhams', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '6g3tdwbhvow', 'Mercedes SL Auction prices - Historics Brooklands Velocity Auction at Mercedes World. 29th Nov 25.', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'FggDEfhof4Y', 'Mercedes SL Auction prices - Nov 25 Anglia Classic Car Auction. Low prices for R129''s and R230''s.', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'FggDEfhof4Y', 'Mercedes SL Auction prices - Nov 25 Anglia Classic Car Auction. Low prices for R129''s and R230''s.', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'FggDEfhof4Y', 'Mercedes SL Auction prices - Nov 25 Anglia Classic Car Auction. Low prices for R129''s and R230''s.', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'akM1MxCIm6c', 'Mercedes SL R107 and W113 steering wheel play - coupler replacement', 'Układ kierowniczy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'akM1MxCIm6c', 'Mercedes SL R107 and W113 steering wheel play - coupler replacement', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'x3Ni5WwEDLg', 'Mercedes SL R107 and w113 windscreen washer pump.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '6LfDhGYvPn8', 'Mercedes SL R107 fog light restoration', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '6LfDhGYvPn8', 'Mercedes SL R107 fog light restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'RdLo1yuXIrA', 'Mercedes SL auction prices  - Silverstone Iconic even the VERY best cars struggle to meet reserve', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '81204UDs7Gw', 'Mercedes SL auction prices - 20th July 2024. Pagoda, 190sl, R107 and R129.', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'ro3u0-ZcLF4', 'Mercedes SL auction prices - Historics ‘Summer Serenade’ classic car auction 19th July 2025', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'f4b8_JStzbQ', 'Mercedes SL auction prices - Worldwide Auctioneers Auburn. The risk of selling a car with no reserve', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'f4b8_JStzbQ', 'Mercedes SL auction prices - Worldwide Auctioneers Auburn. The risk of selling a car with no reserve', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'NkyKiWl9u-s', 'Mercedes SL prices at auction tumble as markets peak. R230 and R107 prices.', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'tXPOGnaM4rY', 'Mercedes SL prices at this weekends Iconic Auction - the good, bad and the ugly NEC Classic Car Show', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'yj7AT7CHJM4', 'Mercedes SL''s still struggling at auction - Mathewsons Oct 11th auction+Bonhams ''The Zoute Sale''', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '6a3smavt7Bo', 'Mercedes V8 Engines from 1970 to 2012: Quick Overview.', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'diAzIgO1NSo', 'Mercedes VDO cruise control - control unit - brake pedal switch - check connections R107 W126', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'diAzIgO1NSo', 'Mercedes VDO cruise control - control unit - brake pedal switch - check connections R107 W126', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'diAzIgO1NSo', 'Mercedes VDO cruise control - control unit - brake pedal switch - check connections R107 W126', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'diAzIgO1NSo', 'Mercedes VDO cruise control - control unit - brake pedal switch - check connections R107 W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'diAzIgO1NSo', 'Mercedes VDO cruise control - control unit - brake pedal switch - check connections R107 W126', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'diAzIgO1NSo', 'Mercedes VDO cruise control - control unit - brake pedal switch - check connections R107 W126', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'diAzIgO1NSo', 'Mercedes VDO cruise control - control unit - brake pedal switch - check connections R107 W126', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'diAzIgO1NSo', 'Mercedes VDO cruise control - control unit - brake pedal switch - check connections R107 W126', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'ZiHVNwj6n8M', 'Mercedes VDO cruise control unit - actuator - brake pedal switch - check connections R107 W126', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'ZiHVNwj6n8M', 'Mercedes VDO cruise control unit - actuator - brake pedal switch - check connections R107 W126', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'eqY2W77R1TA', 'Mercedes W108 3.5 V8 Compression test Cleaning the injection nozzles and Fuel pressure measurement', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'eqY2W77R1TA', 'Mercedes W108 3.5 V8 Compression test Cleaning the injection nozzles and Fuel pressure measurement', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'eqY2W77R1TA', 'Mercedes W108 3.5 V8 Compression test Cleaning the injection nozzles and Fuel pressure measurement', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'eqY2W77R1TA', 'Mercedes W108 3.5 V8 Compression test Cleaning the injection nozzles and Fuel pressure measurement', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'eqY2W77R1TA', 'Mercedes W108 3.5 V8 Compression test Cleaning the injection nozzles and Fuel pressure measurement', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'eqY2W77R1TA', 'Mercedes W108 3.5 V8 Compression test Cleaning the injection nozzles and Fuel pressure measurement', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'eqY2W77R1TA', 'Mercedes W108 3.5 V8 Compression test Cleaning the injection nozzles and Fuel pressure measurement', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'eqY2W77R1TA', 'Mercedes W108 3.5 V8 Compression test Cleaning the injection nozzles and Fuel pressure measurement', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'QoqZQ8xjziw', 'Mercedes W113 - 280 SL #Pagoda VDO clock repair', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'QoqZQ8xjziw', 'Mercedes W113 - 280 SL #Pagoda VDO clock repair', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'QoqZQ8xjziw', 'Mercedes W113 - 280 SL #Pagoda VDO clock repair', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'QoqZQ8xjziw', 'Mercedes W113 - 280 SL #Pagoda VDO clock repair', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'QoqZQ8xjziw', 'Mercedes W113 - 280 SL #Pagoda VDO clock repair', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'QoqZQ8xjziw', 'Mercedes W113 - 280 SL #Pagoda VDO clock repair', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'QoqZQ8xjziw', 'Mercedes W113 - 280 SL #Pagoda VDO clock repair', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'QoqZQ8xjziw', 'Mercedes W113 - 280 SL #Pagoda VDO clock repair', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '9Rh04FfF8x8', 'Mercedes W114 D-Jetronic adjusting fuel pressure on the M110 engine', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '9Rh04FfF8x8', 'Mercedes W114 D-Jetronic adjusting fuel pressure on the M110 engine', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '95uivJnWOTw', 'Mercedes W114 D-Jetronic fuel pressure adjustment on M110 engine', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '95uivJnWOTw', 'Mercedes W114 D-Jetronic fuel pressure adjustment on M110 engine', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '95uivJnWOTw', 'Mercedes W114 D-Jetronic fuel pressure adjustment on M110 engine', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '95uivJnWOTw', 'Mercedes W114 D-Jetronic fuel pressure adjustment on M110 engine', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '95uivJnWOTw', 'Mercedes W114 D-Jetronic fuel pressure adjustment on M110 engine', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '95uivJnWOTw', 'Mercedes W114 D-Jetronic fuel pressure adjustment on M110 engine', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '95uivJnWOTw', 'Mercedes W114 D-Jetronic fuel pressure adjustment on M110 engine', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '95uivJnWOTw', 'Mercedes W114 D-Jetronic fuel pressure adjustment on M110 engine', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '95uivJnWOTw', 'Mercedes W114 D-Jetronic fuel pressure adjustment on M110 engine', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '_CrsySVCAuM', 'Mercedes W124 - KPR fuel pump relay bypass - fuel supply', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '_CrsySVCAuM', 'Mercedes W124 - KPR fuel pump relay bypass - fuel supply', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '_CrsySVCAuM', 'Mercedes W124 - KPR fuel pump relay bypass - fuel supply', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '_CrsySVCAuM', 'Mercedes W124 - KPR fuel pump relay bypass - fuel supply', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ru_XHnDcL1E', 'Mercedes W124 - KPR fuel pump relay bypass - fuel supply', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'ru_XHnDcL1E', 'Mercedes W124 - KPR fuel pump relay bypass - fuel supply', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'ru_XHnDcL1E', 'Mercedes W124 - KPR fuel pump relay bypass - fuel supply', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'ru_XHnDcL1E', 'Mercedes W124 - KPR fuel pump relay bypass - fuel supply', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ZGScw6e6c4Q', 'Mercedes W124 - THAT CAN BE EXPENSIVE!!! Air filter box - Bad for the M102 engine', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'ZGScw6e6c4Q', 'Mercedes W124 - THAT CAN BE EXPENSIVE!!! Air filter box - Bad for the M102 engine', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'TRr68Oi2yWU', 'Mercedes W124 - The E-Class presentation and weak points', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'fsv5fKopxzk', 'Mercedes W126 VDO cruise control not working - repair control unit #w126 #w124 #w116 #r107 #w123', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Z28oGMhfM9c', 'Mercedes W126, R107 - changing the rear rubber mount - suspension Mercedes classic car', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'lDBDV7xKI2s', 'Mercedes W126, R107, W123 and W124 climate control panel', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'lDBDV7xKI2s', 'Mercedes W126, R107, W123 and W124 climate control panel', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'lDBDV7xKI2s', 'Mercedes W126, R107, W123 and W124 climate control panel', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'lDBDV7xKI2s', 'Mercedes W126, R107, W123 and W124 climate control panel', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'W3IPjKgC5AQ', 'Mercedes W201 W124 W129 Mono Wiper Drive Maintenance Tips', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'W3IPjKgC5AQ', 'Mercedes W201 W124 W129 Mono Wiper Drive Maintenance Tips', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'gJ0govuhwwI', 'Mercedes air conditioning - YORK 210 air conditioning compressor W114, W116, W123, R107', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'gJ0govuhwwI', 'Mercedes air conditioning - YORK 210 air conditioning compressor W114, W116, W123, R107', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'dPIEOMROS9c', 'Mercedes classic car - Determine engine speed with a multimeter', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'dPIEOMROS9c', 'Mercedes classic car - Determine engine speed with a multimeter', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'dPIEOMROS9c', 'Mercedes classic car - Determine engine speed with a multimeter', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'dPIEOMROS9c', 'Mercedes classic car - Determine engine speed with a multimeter', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'dPIEOMROS9c', 'Mercedes classic car - Determine engine speed with a multimeter', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'dPIEOMROS9c', 'Mercedes classic car - Determine engine speed with a multimeter', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'dPIEOMROS9c', 'Mercedes classic car - Determine engine speed with a multimeter', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'dPIEOMROS9c', 'Mercedes classic car - Determine engine speed with a multimeter', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'QRkyWmuSGv8', 'Mercedes classic car 12V relay check - R107 W126 W124 W116 W108 W109 W114 W115 W123', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'gjF-ur9pGno', 'Mercedes classic car water drains on the R107, W124, W123, W126, W201 and W140', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'gjF-ur9pGno', 'Mercedes classic car water drains on the R107, W124, W123, W126, W201 and W140', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'WIVY0Ogy3zQ', 'Mercedes cruise control control unit from VDO new soldering - control unit repair for R107 and W126', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'WIVY0Ogy3zQ', 'Mercedes cruise control control unit from VDO new soldering - control unit repair for R107 and W126', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'WIVY0Ogy3zQ', 'Mercedes cruise control control unit from VDO new soldering - control unit repair for R107 and W126', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'WIVY0Ogy3zQ', 'Mercedes cruise control control unit from VDO new soldering - control unit repair for R107 and W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'WIVY0Ogy3zQ', 'Mercedes cruise control control unit from VDO new soldering - control unit repair for R107 and W126', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'WIVY0Ogy3zQ', 'Mercedes cruise control control unit from VDO new soldering - control unit repair for R107 and W126', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'WIVY0Ogy3zQ', 'Mercedes cruise control control unit from VDO new soldering - control unit repair for R107 and W126', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'WIVY0Ogy3zQ', 'Mercedes cruise control control unit from VDO new soldering - control unit repair for R107 and W126', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'sVOlAq7t3aY', 'Mercedes dash wood trims - how to fit & where to buy', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'jR26P6E-2xU', 'Mercedes fuel pump relay (KPR) repair R107 W126 W123 W201 W124 W116', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'jR26P6E-2xU', 'Mercedes fuel pump relay (KPR) repair R107 W126 W123 W201 W124 W116', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'gHVvkV948zg', 'Mercedes headlight leveling system - W124, W140, W126, R107, W201', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'gHVvkV948zg', 'Mercedes headlight leveling system - W124, W140, W126, R107, W201', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'gHVvkV948zg', 'Mercedes headlight leveling system - W124, W140, W126, R107, W201', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'gHVvkV948zg', 'Mercedes headlight leveling system - W124, W140, W126, R107, W201', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'gHVvkV948zg', 'Mercedes headlight leveling system - W124, W140, W126, R107, W201', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'gHVvkV948zg', 'Mercedes headlight leveling system - W124, W140, W126, R107, W201', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'gHVvkV948zg', 'Mercedes headlight leveling system - W124, W140, W126, R107, W201', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'gHVvkV948zg', 'Mercedes headlight leveling system - W124, W140, W126, R107, W201', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'gHVvkV948zg', 'Mercedes headlight leveling system - W124, W140, W126, R107, W201', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Wj2ugkZzFfY', 'Mercedes overvoltage protection relay - KE-Jetronic from Bosch', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'Wj2ugkZzFfY', 'Mercedes overvoltage protection relay - KE-Jetronic from Bosch', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'Wj2ugkZzFfY', 'Mercedes overvoltage protection relay - KE-Jetronic from Bosch', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'Wj2ugkZzFfY', 'Mercedes overvoltage protection relay - KE-Jetronic from Bosch', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'Wj2ugkZzFfY', 'Mercedes overvoltage protection relay - KE-Jetronic from Bosch', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'Wj2ugkZzFfY', 'Mercedes overvoltage protection relay - KE-Jetronic from Bosch', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'Wj2ugkZzFfY', 'Mercedes overvoltage protection relay - KE-Jetronic from Bosch', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'Wj2ugkZzFfY', 'Mercedes overvoltage protection relay - KE-Jetronic from Bosch', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'pHja-hX9jFU', 'Mercedes overvoltage protection relay - ÜSR at KE-Jetronic, #W126, #W124, #W201, #R107', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'pHja-hX9jFU', 'Mercedes overvoltage protection relay - ÜSR at KE-Jetronic, #W126, #W124, #W201, #R107', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'pHja-hX9jFU', 'Mercedes overvoltage protection relay - ÜSR at KE-Jetronic, #W126, #W124, #W201, #R107', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'pHja-hX9jFU', 'Mercedes overvoltage protection relay - ÜSR at KE-Jetronic, #W126, #W124, #W201, #R107', 'Hydraulika i ABS', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'yM8Clgbv62o', 'Mercedes park brake and foot brake removal and restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'peaWZU9M6Hc', 'Mercedes r107 - how to get a mirror shine on rusty pitted chrome', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '67M-GX_y_3E', 'Mercedes r107 SL rescue', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'G8rtAy_pkaQ', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'G8rtAy_pkaQ', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'G8rtAy_pkaQ', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '-tDZO0OT1VA', 'Mercedes restoration - KE-Jetronic - Change the lower part of the air flow meter', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '-tDZO0OT1VA', 'Mercedes restoration - KE-Jetronic - Change the lower part of the air flow meter', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '-tDZO0OT1VA', 'Mercedes restoration - KE-Jetronic - Change the lower part of the air flow meter', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '-tDZO0OT1VA', 'Mercedes restoration - KE-Jetronic - Change the lower part of the air flow meter', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '-tDZO0OT1VA', 'Mercedes restoration - KE-Jetronic - Change the lower part of the air flow meter', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '-tDZO0OT1VA', 'Mercedes restoration - KE-Jetronic - Change the lower part of the air flow meter', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '-tDZO0OT1VA', 'Mercedes restoration - KE-Jetronic - Change the lower part of the air flow meter', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '-tDZO0OT1VA', 'Mercedes restoration - KE-Jetronic - Change the lower part of the air flow meter', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'XfXCOaHz0aQ', 'Mercedes surge protection relay - KE-Jetronic from Bosch', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'XfXCOaHz0aQ', 'Mercedes surge protection relay - KE-Jetronic from Bosch', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'XfXCOaHz0aQ', 'Mercedes surge protection relay - KE-Jetronic from Bosch', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Ed5e2okxGWQ', 'Mercedes vacuum system - KE-Jetronic for models W126, W116, W124, R107, W123, W114, W115', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'Ed5e2okxGWQ', 'Mercedes vacuum system - KE-Jetronic for models W126, W116, W124, R107, W123, W114, W115', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', '9acnY1-JRP8', 'Mercedes vintage car power steering - power steering pump W116, R107, W123, W126', 'Układ kierowniczy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'Xq-VLdPXqJs', 'Mercedes, Audi, VW - Check the flow divider on the K-Jetronic and KE-Jetronic', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'Xq-VLdPXqJs', 'Mercedes, Audi, VW - Check the flow divider on the K-Jetronic and KE-Jetronic', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '_00dX9El4ZA', 'Mercedes-Benz interior temperature sensor and lighting shift gate R107 and W126', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '_00dX9El4ZA', 'Mercedes-Benz interior temperature sensor and lighting shift gate R107 and W126', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '_00dX9El4ZA', 'Mercedes-Benz interior temperature sensor and lighting shift gate R107 and W126', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '_00dX9El4ZA', 'Mercedes-Benz interior temperature sensor and lighting shift gate R107 and W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '_00dX9El4ZA', 'Mercedes-Benz interior temperature sensor and lighting shift gate R107 and W126', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '_00dX9El4ZA', 'Mercedes-Benz interior temperature sensor and lighting shift gate R107 and W126', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '_00dX9El4ZA', 'Mercedes-Benz interior temperature sensor and lighting shift gate R107 and W126', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '_00dX9El4ZA', 'Mercedes-Benz interior temperature sensor and lighting shift gate R107 and W126', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'tbvo-nIuMIM', 'Mercedes-Benz interior temperature sensor and lighting switch gate R107 and W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'Układ kierowniczy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', '1jC9AIyi_M8', 'Oil level check automatic transmission - Mercedes R107', 'Automatyczna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'l9MKYSgOxMo', 'Preview 1000 Miglia 2022 - Toscana R107 mechanic', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'XWTkxyIflFI', 'R107 Mercedes M110 engine - reinstalling thermostat, water pump, harmonic balancer+torque specs', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'XWTkxyIflFI', 'R107 Mercedes M110 engine - reinstalling thermostat, water pump, harmonic balancer+torque specs', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'XWTkxyIflFI', 'R107 Mercedes M110 engine - reinstalling thermostat, water pump, harmonic balancer+torque specs', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'MNIM6IiKDas', 'Re-solder Mercedes cruise control control unit from VDO - repair control unit for R107 and W126', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'CxAv9MQ4AHk', 'Regulator linkage / throttle linkage Mercedes R107 - M103, M110, M116, M117 (severe accelerator pedal)', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'rI7JDOfUu3w', 'Removing the KE-Jetronic flow divider - Mercedes R107 560SL V8', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'rI7JDOfUu3w', 'Removing the KE-Jetronic flow divider - Mercedes R107 560SL V8', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'rI7JDOfUu3w', 'Removing the KE-Jetronic flow divider - Mercedes R107 560SL V8', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'xmbZj_g2Bb4', 'Removing the radiator from the Mercedes 560SL R107 M117 V8 engine - vintage car restoration', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'xmbZj_g2Bb4', 'Removing the radiator from the Mercedes 560SL R107 M117 V8 engine - vintage car restoration', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'xmbZj_g2Bb4', 'Removing the radiator from the Mercedes 560SL R107 M117 V8 engine - vintage car restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'DRvV2R3xeTA', 'Removing the steering wheel with airbag and dashboard from a Mercedes R107 - vintage car restoration', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'DRvV2R3xeTA', 'Removing the steering wheel with airbag and dashboard from a Mercedes R107 - vintage car restoration', 'Układ kierowniczy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'DRvV2R3xeTA', 'Removing the steering wheel with airbag and dashboard from a Mercedes R107 - vintage car restoration', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'DRvV2R3xeTA', 'Removing the steering wheel with airbag and dashboard from a Mercedes R107 - vintage car restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'DRvV2R3xeTA', 'Removing the steering wheel with airbag and dashboard from a Mercedes R107 - vintage car restoration', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'zq2JVMMcpvw', 'Repair Mercedes clock in the instrument cluster - R107 W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ZtHAocYDy58', 'Replace Mercedes W114/ W115 radiator - Replace viscous fan after broken impeller', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ZtHAocYDy58', 'Replace Mercedes W114/ W115 radiator - Replace viscous fan after broken impeller', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'ZtHAocYDy58', 'Replace Mercedes W114/ W115 radiator - Replace viscous fan after broken impeller', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'ZtHAocYDy58', 'Replace Mercedes W114/ W115 radiator - Replace viscous fan after broken impeller', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'ZtHAocYDy58', 'Replace Mercedes W114/ W115 radiator - Replace viscous fan after broken impeller', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'ZtHAocYDy58', 'Replace Mercedes W114/ W115 radiator - Replace viscous fan after broken impeller', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'ZtHAocYDy58', 'Replace Mercedes W114/ W115 radiator - Replace viscous fan after broken impeller', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'ZtHAocYDy58', 'Replace Mercedes W114/ W115 radiator - Replace viscous fan after broken impeller', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'ZtHAocYDy58', 'Replace Mercedes W114/ W115 radiator - Replace viscous fan after broken impeller', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'WeF6vJfPj-M', 'Replace the sealing ring on the control piston flow divider of the KE-Jetronic Mercedes W124, R107', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'WeF6vJfPj-M', 'Replace the sealing ring on the control piston flow divider of the KE-Jetronic Mercedes W124, R107', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'WeF6vJfPj-M', 'Replace the sealing ring on the control piston flow divider of the KE-Jetronic Mercedes W124, R107', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'WeF6vJfPj-M', 'Replace the sealing ring on the control piston flow divider of the KE-Jetronic Mercedes W124, R107', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'WeF6vJfPj-M', 'Replace the sealing ring on the control piston flow divider of the KE-Jetronic Mercedes W124, R107', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'WeF6vJfPj-M', 'Replace the sealing ring on the control piston flow divider of the KE-Jetronic Mercedes W124, R107', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'WeF6vJfPj-M', 'Replace the sealing ring on the control piston flow divider of the KE-Jetronic Mercedes W124, R107', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'WeF6vJfPj-M', 'Replace the sealing ring on the control piston flow divider of the KE-Jetronic Mercedes W124, R107', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ciN3WIMlDlA', 'Seat height adjustment for Mercedes SL R107 - Installation and function - Classic car restoration', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'ciN3WIMlDlA', 'Seat height adjustment for Mercedes SL R107 - Installation and function - Classic car restoration', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'ciN3WIMlDlA', 'Seat height adjustment for Mercedes SL R107 - Installation and function - Classic car restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'ciN3WIMlDlA', 'Seat height adjustment for Mercedes SL R107 - Installation and function - Classic car restoration', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'ciN3WIMlDlA', 'Seat height adjustment for Mercedes SL R107 - Installation and function - Classic car restoration', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'ciN3WIMlDlA', 'Seat height adjustment for Mercedes SL R107 - Installation and function - Classic car restoration', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'ciN3WIMlDlA', 'Seat height adjustment for Mercedes SL R107 - Installation and function - Classic car restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'ciN3WIMlDlA', 'Seat height adjustment for Mercedes SL R107 - Installation and function - Classic car restoration', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'gmRa1qVVtaQ', 'Secret water drain - Mercedes R107 - Prevent rust - New hall', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '58jAw6mBQOo', 'See what happens when we put new fuel injectors in our 1975 Mercedes 280SL....', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '58jAw6mBQOo', 'See what happens when we put new fuel injectors in our 1975 Mercedes 280SL....', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'qBrOJVN30XY', 'Spark Plugs Available for 1970 to 1991 Mercedes V8 Engines', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'rHTreXBOOTc', 'Sponsor My Channel w/ a $4 Video Purchase - How to Get Beautiful Aluminum Valve Covers!', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'mFbYpF2zvs0', 'Stolen Mercedes 280SL - UPDATE', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'BBuZGw_dxOQ', 'The Best Spark Plug Socket for Older Mercedes V8 Engines M116 and M117', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'BBuZGw_dxOQ', 'The Best Spark Plug Socket for Older Mercedes V8 Engines M116 and M117', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'Z8cPaRtB8RE', 'The Magic of Bosch KE-Jetronic Fuel Injection: Watch This', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'RifA79JQZOM', 'The SL Shop Open Day - 300SL Roadster just £1.3 million…Bosch injections pumps and R107 rust issues.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '5iqXQWB0oyo', 'This Old Benz with Kent Bergsma: How to Lubricate the Soft Top on a Mercedes SL Convertible', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'MKFYKnPUOtw', 'Throttle linkage on Mercedes R107 280SL - 50 hp more for the classic car', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'MKFYKnPUOtw', 'Throttle linkage on Mercedes R107 280SL - 50 hp more for the classic car', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'MKFYKnPUOtw', 'Throttle linkage on Mercedes R107 280SL - 50 hp more for the classic car', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'j-6Z1VYysME', 'Vacuum smoke test reveals massive throttle body leak...and other hidden problems on R107 Mercedes', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'j-6Z1VYysME', 'Vacuum smoke test reveals massive throttle body leak...and other hidden problems on R107 Mercedes', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'HEd1WRUbBic', 'Vehicle upgrade - polish valve cover', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'HEd1WRUbBic', 'Vehicle upgrade - polish valve cover', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'LzORIPCh9N8', 'Vintage and Classic Car Stereos modified to work wirelessly with your phone. Stream music + podcasts', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'mPChVALtfqI', 'Visco fan function test - Mercedes R107 W126 on V8 M117 engine', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'mPChVALtfqI', 'Visco fan function test - Mercedes R107 W126 on V8 M117 engine', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'mPChVALtfqI', 'Visco fan function test - Mercedes R107 W126 on V8 M117 engine', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'mPChVALtfqI', 'Visco fan function test - Mercedes R107 W126 on V8 M117 engine', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'Juh1zcPZ1ok', 'W123 Mercedes 240D Rolling Restoration: Week 6 Progress On the Road Again', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Juh1zcPZ1ok', 'W123 Mercedes 240D Rolling Restoration: Week 6 Progress On the Road Again', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'Juh1zcPZ1ok', 'W123 Mercedes 240D Rolling Restoration: Week 6 Progress On the Road Again', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'gLmEeixJFzQ', 'WARM START PROBLEMS??? - Mercedes #w201 KE-Jetronic', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Ts9r_O8dNVM', 'Which Mercedes R230 SL model to buy, and how to avoid a fire with CATASTROPHIC damage.....', 'Chłodzenie', 0);
-- Manually add missing videos for Lusterka and Radio that were previously hardcoded

-- Lusterka (Mirrors)
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', '2eI_oAstiWA', 'Naprawa lusterek bocznych R107', 'Lusterka', 10);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', '4qqCftr_kzg', 'Demontaż i montaż lusterek', 'Lusterka', 20);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', 'La_6nCFNiuc', 'Lusterka R107 - regulacja', 'Lusterka', 30);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', '1ZqN9TpU810', 'Lusterka R107 - renowacja', 'Lusterka', 40);

-- Radio & Antena (Missing Manual Entries)
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'L_rMTrwDcis', 'Antena R107 - naprawa', 'Antena', 10);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'H93IUJlB5R0', 'Antena R107 - demontaż', 'Antena', 20);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '-jG0uz1fA_g', 'Antena R107 - montaż', 'Antena', 30);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '4sEIf49E0KU', 'Głośniki R107 - wymiana', 'Głośniki', 40);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'DABVqcgAEOI', 'Radio Becker - serwis', 'Radio', 50);

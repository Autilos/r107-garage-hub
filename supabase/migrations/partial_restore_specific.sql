-- Create custom types if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'source_type') THEN
        CREATE TYPE public.source_type AS ENUM ('rss', 'user');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'listing_status') THEN
        CREATE TYPE public.listing_status AS ENUM ('pending', 'approved', 'rejected', 'archived');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'listing_category') THEN
        CREATE TYPE public.listing_category AS ENUM ('pojazd', 'czesc');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'repair_status') THEN
        CREATE TYPE public.repair_status AS ENUM ('draft', 'pending', 'published');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'repair_module_type') THEN
        CREATE TYPE public.repair_module_type AS ENUM ('objawy', 'czesci', 'narzedzia', 'instrukcja', 'foto_video');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'repair_media_kind') THEN
        CREATE TYPE public.repair_media_kind AS ENUM ('image', 'youtube');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'shop_link_status') THEN
        CREATE TYPE public.shop_link_status AS ENUM ('pending', 'approved', 'rejected');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'shop_link_type') THEN
        CREATE TYPE public.shop_link_type AS ENUM ('sklep', 'usluga', 'katalog');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
        CREATE TYPE public.app_role AS ENUM ('admin', 'user');
    END IF;
END$$;

-- Profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- User roles table (for RBAC - admin detection)
CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(user_id, role)
);

-- RSS Sources table
CREATE TABLE IF NOT EXISTS public.rss_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  feed_url TEXT NOT NULL,
  country_default TEXT DEFAULT 'US',
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Listings table (RSS + user listings)
CREATE TABLE IF NOT EXISTS public.listings (
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
CREATE TABLE IF NOT EXISTS public.listing_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Repairs table
CREATE TABLE IF NOT EXISTS public.repairs (
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
CREATE TABLE IF NOT EXISTS public.repair_modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  repair_id UUID NOT NULL REFERENCES public.repairs(id) ON DELETE CASCADE,
  type repair_module_type NOT NULL,
  content_html TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(repair_id, type)
);

-- Repair media (gallery + youtube)
CREATE TABLE IF NOT EXISTS public.repair_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  repair_id UUID NOT NULL REFERENCES public.repairs(id) ON DELETE CASCADE,
  kind repair_media_kind NOT NULL,
  value TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Comments (on repairs)
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  repair_id UUID NOT NULL REFERENCES public.repairs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Shop links
CREATE TABLE IF NOT EXISTS public.shops_links (
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
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'profiles' AND policyname = 'Profiles are viewable by everyone'
    ) THEN
        CREATE POLICY "Profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can update own profile'
    ) THEN
        CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can insert own profile'
    ) THEN
        CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
END $$;

-- User roles policies (only admin can manage)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'user_roles' AND policyname = 'Admins can view all roles'
    ) THEN
        CREATE POLICY "Admins can view all roles" ON public.user_roles FOR SELECT USING (public.is_admin() OR auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'user_roles' AND policyname = 'Admins can manage roles'
    ) THEN
        CREATE POLICY "Admins can manage roles" ON public.user_roles FOR ALL USING (public.is_admin());
    END IF;
END $$;

-- RSS sources policies (admin only for write, public read)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'rss_sources' AND policyname = 'Anyone can view enabled RSS sources'
    ) THEN
        CREATE POLICY "Anyone can view enabled RSS sources" ON public.rss_sources FOR SELECT USING (enabled = true OR public.is_admin());
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'rss_sources' AND policyname = 'Admins can manage RSS sources'
    ) THEN
        CREATE POLICY "Admins can manage RSS sources" ON public.rss_sources FOR ALL USING (public.is_admin());
    END IF;
END $$;

-- Listings policies
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'listings' AND policyname = 'Anyone can view approved listings'
    ) THEN
        CREATE POLICY "Anyone can view approved listings" ON public.listings FOR SELECT USING (status = 'approved' OR public.is_admin() OR (user_id = auth.uid()));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'listings' AND policyname = 'Users can create own listings'
    ) THEN
        CREATE POLICY "Users can create own listings" ON public.listings FOR INSERT WITH CHECK (auth.uid() = user_id AND source_type = 'user');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'listings' AND policyname = 'Users can update own pending listings'
    ) THEN
        CREATE POLICY "Users can update own pending listings" ON public.listings FOR UPDATE USING (auth.uid() = user_id OR public.is_admin());
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'listings' AND policyname = 'Users can delete own listings'
    ) THEN
        CREATE POLICY "Users can delete own listings" ON public.listings FOR DELETE USING (auth.uid() = user_id OR public.is_admin());
    END IF;
END $$;

-- Listing images policies
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'listing_images' AND policyname = 'Anyone can view listing images'
    ) THEN
        CREATE POLICY "Anyone can view listing images" ON public.listing_images FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'listing_images' AND policyname = 'Users can manage own listing images'
    ) THEN
        CREATE POLICY "Users can manage own listing images" ON public.listing_images FOR ALL USING (
            EXISTS (
              SELECT 1 FROM public.listings 
              WHERE listings.id = listing_images.listing_id 
              AND (listings.user_id = auth.uid() OR public.is_admin())
            )
        );
    END IF;
END $$;

-- Repairs policies
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'repairs' AND policyname = 'Anyone can view published repairs'
    ) THEN
        CREATE POLICY "Anyone can view published repairs" ON public.repairs FOR SELECT USING (status = 'published' OR public.is_admin());
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'repairs' AND policyname = 'Admins can manage repairs'
    ) THEN
        CREATE POLICY "Admins can manage repairs" ON public.repairs FOR ALL USING (public.is_admin());
    END IF;
END $$;

-- Repair modules policies
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'repair_modules' AND policyname = 'Anyone can view repair modules'
    ) THEN
        CREATE POLICY "Anyone can view repair modules" ON public.repair_modules FOR SELECT USING (
            EXISTS (
              SELECT 1 FROM public.repairs 
              WHERE repairs.id = repair_modules.repair_id 
              AND (repairs.status = 'published' OR public.is_admin())
            )
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'repair_modules' AND policyname = 'Admins can manage repair modules'
    ) THEN
        CREATE POLICY "Admins can manage repair modules" ON public.repair_modules FOR ALL USING (public.is_admin());
    END IF;
END $$;

-- Repair media policies
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'repair_media' AND policyname = 'Anyone can view repair media'
    ) THEN
        CREATE POLICY "Anyone can view repair media" ON public.repair_media FOR SELECT USING (
            EXISTS (
              SELECT 1 FROM public.repairs 
              WHERE repairs.id = repair_media.repair_id 
              AND (repairs.status = 'published' OR public.is_admin())
            )
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'repair_media' AND policyname = 'Admins can manage repair media'
    ) THEN
        CREATE POLICY "Admins can manage repair media" ON public.repair_media FOR ALL USING (public.is_admin());
    END IF;
END $$;

-- Comments policies
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'comments' AND policyname = 'Anyone can view comments'
    ) THEN
        CREATE POLICY "Anyone can view comments" ON public.comments FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'comments' AND policyname = 'Authenticated users can create comments'
    ) THEN
        CREATE POLICY "Authenticated users can create comments" ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'comments' AND policyname = 'Users can update own comments'
    ) THEN
        CREATE POLICY "Users can update own comments" ON public.comments FOR UPDATE USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'comments' AND policyname = 'Users can delete own comments or admin'
    ) THEN
        CREATE POLICY "Users can delete own comments or admin" ON public.comments FOR DELETE USING (auth.uid() = user_id OR public.is_admin());
    END IF;
END $$;

-- Shop links policies
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'shops_links' AND policyname = 'Anyone can view approved shop links'
    ) THEN
        CREATE POLICY "Anyone can view approved shop links" ON public.shops_links FOR SELECT USING (status = 'approved' OR public.is_admin() OR user_id = auth.uid());
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'shops_links' AND policyname = 'Authenticated users can create shop links'
    ) THEN
        CREATE POLICY "Authenticated users can create shop links" ON public.shops_links FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'shops_links' AND policyname = 'Users can update own shop links'
    ) THEN
        CREATE POLICY "Users can update own shop links" ON public.shops_links FOR UPDATE USING (auth.uid() = user_id OR public.is_admin());
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'shops_links' AND policyname = 'Users can delete own shop links or admin'
    ) THEN
        CREATE POLICY "Users can delete own shop links or admin" ON public.shops_links FOR DELETE USING (auth.uid() = user_id OR public.is_admin());
    END IF;
END $$;

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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
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
DROP TRIGGER IF EXISTS update_repairs_updated_at ON public.repairs;
CREATE TRIGGER update_repairs_updated_at
  BEFORE UPDATE ON public.repairs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_repair_modules_updated_at ON public.repair_modules;
CREATE TRIGGER update_repair_modules_updated_at
  BEFORE UPDATE ON public.repair_modules
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_listings_status ON public.listings(status);
CREATE INDEX IF NOT EXISTS idx_listings_source_type ON public.listings(source_type);
CREATE INDEX IF NOT EXISTS idx_listings_category ON public.listings(category);
CREATE INDEX IF NOT EXISTS idx_listings_country ON public.listings(country);
CREATE INDEX IF NOT EXISTS idx_listings_rss_guid ON public.listings(rss_source_id, rss_guid);
CREATE INDEX IF NOT EXISTS idx_repairs_status ON public.repairs(status);
CREATE INDEX IF NOT EXISTS idx_repairs_slug ON public.repairs(slug);
CREATE INDEX IF NOT EXISTS idx_shops_links_status ON public.shops_links(status);

-- Insert default RSS sources
INSERT INTO public.rss_sources (name, feed_url, country_default, enabled)
SELECT 'Bring a Trailer R107', 'https://rss.app/feed/S7nzC0tge0CZbieb', 'US', true
WHERE NOT EXISTS (SELECT 1 FROM public.rss_sources WHERE name = 'Bring a Trailer R107');

INSERT INTO public.rss_sources (name, feed_url, country_default, enabled)
SELECT 'eBay Motors R107', 'https://rss.app/feed/2Z5EiTzlfry3bqFK', 'US', true
WHERE NOT EXISTS (SELECT 1 FROM public.rss_sources WHERE name = 'eBay Motors R107');

INSERT INTO public.rss_sources (name, feed_url, country_default, enabled)
SELECT 'Dodatkowy Feed R107', 'https://rss.app/feed/GdyKzGIfWkzs4rBm', 'PL', true
WHERE NOT EXISTS (SELECT 1 FROM public.rss_sources WHERE name = 'Dodatkowy Feed R107');


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


DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'articles' AND policyname = 'Articles are viewable by everyone if published'
    ) THEN
        CREATE POLICY "Articles are viewable by everyone if published"
          on articles for select
          using (is_published = true or (auth.jwt() ->> 'email') in (select email from auth.users where is_admin(auth.uid())));
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'articles' AND policyname = 'Articles are insertable by admins only'
    ) THEN
        CREATE POLICY "Articles are insertable by admins only"
          on articles for insert
          with check (is_admin(auth.uid()));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'articles' AND policyname = 'Articles are updatable by admins only'
    ) THEN
        CREATE POLICY "Articles are updatable by admins only"
         on articles for update
         using (is_admin(auth.uid()));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_policies WHERE tablename = 'articles' AND policyname = 'Articles are deletable by admins only'
    ) THEN
        CREATE POLICY "Articles are deletable by admins only"
          on articles for delete
          using (is_admin(auth.uid()));
    END IF;
END $$;

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

INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'BwZwle6xMvU', '1977 to 1985 Mercedes Diesel Rolling Restoration 2: Fix or Upgrade Lighting', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '3gFz2RA3Xs8', 'Can''t Decide Which Color LED Dash Bulb for your Old Benz? This Should Help!', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '3gFz2RA3Xs8', 'Can''t Decide Which Color LED Dash Bulb for your Old Benz? This Should Help!', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'IRTDMHjsfqY', 'Check Mercedes KE-Jetronic acceleration enrichment on the flow divider. W126, R107, W124, W201', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'uEQjpowC7Gk', 'Check cold start valve', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'uEQjpowC7Gk', 'Check cold start valve', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'uEQjpowC7Gk', 'Check cold start valve', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '_LJh7L-ivsw', 'Determine idle speed with multimeter - Mercedes R107 560SL with X test socket', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '--8WUYjuOCU', 'How to disassemble and repair the Auxiliary Air Slide valve on a classic Mercedes, Porsche & BMW etc', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '--8WUYjuOCU', 'How to disassemble and repair the Auxiliary Air Slide valve on a classic Mercedes, Porsche & BMW etc', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '--8WUYjuOCU', 'How to disassemble and repair the Auxiliary Air Slide valve on a classic Mercedes, Porsche & BMW etc', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'BnWtM7NAhQM', 'KE-JETRONIC Pressure accumulator replacement for warm start problems Mercedes R107, W124, W201, W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'QcS2-UJjito', 'KE-Jetronic - Check flow divider🚗 - Mercedes, Porsche, BMW', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'xHlXa7T4XUE', 'KE-Jetronic - Check throttle valve switch - Mercedes R107 560SL', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'xHlXa7T4XUE', 'KE-Jetronic - Check throttle valve switch - Mercedes R107 560SL', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'xHlXa7T4XUE', 'KE-Jetronic - Check throttle valve switch - Mercedes R107 560SL', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'iL2gr0w9Hpk', 'KE-Jetronic Electro-hydraulic actuator Change and adjust pressure actuator', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'mFsi_qYGJw8', 'KE-Jetronic throttle switch - Check Mercedes 560SL #throttleswitch', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'zLJ1IR7msHw', 'KE-Jetronic troubleshooting for irregular engine running, fluctuating speeds Mercedes R107, W126, W201..', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'waRlv1DoCI0', 'LED Dash Instrument Light Testing: Mercedes W123 W126 W201 W124- Always Looking for Better.!', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'waRlv1DoCI0', 'LED Dash Instrument Light Testing: Mercedes W123 W126 W201 W124- Always Looking for Better.!', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ZeIPTe2z6rk', 'M116 M117 V8 Valve Cover Gasket Replacement Tip', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'RkK7xC5XoZc', 'Mercedes - R107, W124, W126 - Checking ABS sensors - Anti-lock braking system #R107, #W124, #W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '67kF57uEYXg', 'Mercedes - Supplement to warm-up regulator - Correct assembly warm-up regulator Mercedes restomod', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'ltj-O00UkBc', 'Mercedes 107 SL hazard and window switches', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'NCynrf_6Eig', 'Mercedes AMG GTS - worth buying at auction? Where are Classic Mercedes prices heading up or down??….', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'xxr9XqoRad8', 'Mercedes ARF - Check exhaust gas recirculation with KE-Jetronic - uneven engine running', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'LS0MJIm4aJc', 'Mercedes Benz Exterior temperature display Mercedes W126 Check', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'A4RSCXWG6XE', 'Mercedes Benz W113 - Pagoda - 280SL 250SL 230SL - VDO analogue clock', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 's6eFaNBaAB8', 'Mercedes Benz W126 Check Fuel Pump Relay - 280SE', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '2tWmu-pEcmw', 'Mercedes Benz W126 Check outside temperature display on 420 SEL - S-Class #W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '1tvNmMm7vB4', 'Mercedes Benz central locking system - ZV Old Benz W108, W116, R107, W126, W123, W124, C107', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'wS7v_i4Ql4o', 'Mercedes D-Jetronic pressure sensor check', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'eg1oezckIiI', 'Mercedes ECONOMY ad - economical driving - Old Benz', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'eg1oezckIiI', 'Mercedes ECONOMY ad - economical driving - Old Benz', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'syow63qHAlk', 'Mercedes KE-Jetronic and K-Jetronic - Warm Start Problems - Mercedes restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'rKbViyhqwxg', 'Mercedes M116-M117 W108 - W109 ignition distributor', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '32OM5dGC4bM', 'Mercedes OM 603 engine - Check and replace glow plugs - without breaking!', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'aY5MPNzWi1I', 'Mercedes Plate adjustment K-Jetronic', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'LBpoQReG4Bs', 'Mercedes R/C 107 - Market prices 2024 - Classic car market value', 'Wskaźniki', 0);
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
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'dbema0mIfyU', 'Mercedes R107 - door card refurb, door alignment tips. Major milestone reached.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '7saThWDUalw', 'Mercedes R107 - door pockets. How to refurbish and fix broken plastic.', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '7saThWDUalw', 'Mercedes R107 - door pockets. How to refurbish and fix broken plastic.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'uzy1u8FrFQ4', 'Mercedes R107 - headlight fitting, bonnet stops, windscreen washer reservoir +  1st motorway drive!', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Rw3HGorHYUI', 'Mercedes R107 - how to align the window and fit the door card', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Rw3HGorHYUI', 'Mercedes R107 - how to align the window and fit the door card', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'Rw3HGorHYUI', 'Mercedes R107 - how to align the window and fit the door card', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'DlPvoFFQAWk', 'Mercedes R107 - how to replace door card vinyl', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'DlPvoFFQAWk', 'Mercedes R107 - how to replace door card vinyl', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'bG7fYWw661w', 'Mercedes R107 - re chroming the rustiest headlight bowl', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'Gnv0mrqavno', 'Mercedes R107 - what to look for when buying at auction. Low mileage desirable 1989 Mercedes 300SL', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '4TevKiAeV5U', 'Mercedes R107 Alternator and voltage regulator putting out less than 14v. Fix.', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'zjYELZ4b128', 'Mercedes R107 Ignition barrel bezel escutcheon', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'tlvDeUqpm1Y', 'Mercedes R107 SL - how to make your own door card', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'TXt4_JN0iEk', 'Mercedes R107 SL - repairing and recovering rear side trim panels', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'plaLatGA6YM', 'Mercedes R107 SL Adjusting the side windows on the soft top', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'S35eedIQWKc', 'Mercedes R107 SL Instrument Cluster Speedometer - Replace Gears', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'm7vdZPVzOy4', 'Mercedes R107 SL chrome sill trim', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '0eSaiivi0aw', 'Mercedes R107 SL door check  - A1077200016', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'eG3Sb-Yj6UQ', 'Mercedes R107 SL door lock & ignition lock - key wont turn. FIX.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Jzktcr0dtpg', 'Mercedes R107 SL how to fit door seals and sill trim', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'AYdcNubJHP4', 'Mercedes R107 SL ignition barrel, turn signal indicator and steering column removal', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'ZnbanwRVvko', 'Mercedes R107 SL instrument cluster speedometer - replacing gears', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'WRmk7a2G3pA', 'Mercedes R107 SL rear view mirror, sun visor rods and A pillar trims', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'NmZwyxj79kg', 'Mercedes R107 SL window rails and door rattle', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'NmZwyxj79kg', 'Mercedes R107 SL window rails and door rattle', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'bvfO-krwbsI', 'Mercedes R107 W126 W124 - heating valves - mono valve - duo valve does not heat!!!', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'bvfO-krwbsI', 'Mercedes R107 W126 W124 - heating valves - mono valve - duo valve does not heat!!!', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'B9ykDi_VzkE', 'Mercedes R107 and W126 - Check cruise control - cruise control system', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '4qqCftr_kzg', 'Mercedes R107 classic car exterior mirrors - mirror glass replacement', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'QAq24HtsRNI', 'Mercedes R107 door alignment, fix broken door stop, door seal+replace backing plate', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'QAq24HtsRNI', 'Mercedes R107 door alignment, fix broken door stop, door seal+replace backing plate', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'QAq24HtsRNI', 'Mercedes R107 door alignment, fix broken door stop, door seal+replace backing plate', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'KcxJbZ7Jv-o', 'Mercedes R107 door assembly - rods, door catch, regulator and guide rails', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '-SsrA6y4PJE', 'Mercedes R107 front suspension spring - removal/ installation - changing the rubber pad', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'DRiFAYBlylY', 'Mercedes R107 fuel guage fix + cluster lights intermittent fault', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'mNOKYOe7yFE', 'Mercedes R107 glovebox torch refurb using conductive glue instead of solder.', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '-7NJ_9x5NpI', 'Mercedes R107 handbrake adjustment rear fog light fix', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'BAYfFzxj-pc', 'Mercedes R107 headlight fitting problem solved', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '0G2gkw26Ugo', 'Mercedes R107 headlight rebuild + modifying LH reflector to fit RHS.', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'qP35yhTfP14', 'Mercedes R107 how to remove door card, window glass, regulator and locking mechanism', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'qP35yhTfP14', 'Mercedes R107 how to remove door card, window glass, regulator and locking mechanism', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'JGVi3O4o1bQ', 'Mercedes R107 instrument cluster repair, circuit board, needles and gauges', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'JGVi3O4o1bQ', 'Mercedes R107 instrument cluster repair, circuit board, needles and gauges', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'bqMG_F-UIm8', 'Mercedes R107 park brake switch repair & installation - A0015450211', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'iTX4KsyDL-w', 'Mercedes R107 tail light refurb - best source for new seals and lenses', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'C0thWv58yRI', 'Mercedes R107 trims - how to fit (correctly!) and where to buy…..', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'C0thWv58yRI', 'Mercedes R107 trims - how to fit (correctly!) and where to buy…..', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'C0thWv58yRI', 'Mercedes R107 trims - how to fit (correctly!) and where to buy…..', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'C0thWv58yRI', 'Mercedes R107 trims - how to fit (correctly!) and where to buy…..', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'C0thWv58yRI', 'Mercedes R107 trims - how to fit (correctly!) and where to buy…..', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', '2eI_oAstiWA', 'Mercedes R107 wing mirrors. How to restore your wing mirror so that is moves as it should.', 'Zawieszenie Przód', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '2eI_oAstiWA', 'Mercedes R107 wing mirrors. How to restore your wing mirror so that is moves as it should.', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '9wKrfMkBFvY', 'Mercedes R107 wood trim + where to buy', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'mWnumGNrOIs', 'Mercedes SL - Ignition control unit at KE', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'diAzIgO1NSo', 'Mercedes VDO cruise control - control unit - brake pedal switch - check connections R107 W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'eqY2W77R1TA', 'Mercedes W108 3.5 V8 Compression test Cleaning the injection nozzles and Fuel pressure measurement', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'QoqZQ8xjziw', 'Mercedes W113 - 280 SL #Pagoda VDO clock repair', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '95uivJnWOTw', 'Mercedes W114 D-Jetronic fuel pressure adjustment on M110 engine', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'dPIEOMROS9c', 'Mercedes classic car - Determine engine speed with a multimeter', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'WIVY0Ogy3zQ', 'Mercedes cruise control control unit from VDO new soldering - control unit repair for R107 and W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'sVOlAq7t3aY', 'Mercedes dash wood trims - how to fit & where to buy', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'gHVvkV948zg', 'Mercedes headlight leveling system - W124, W140, W126, R107, W201', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'gHVvkV948zg', 'Mercedes headlight leveling system - W124, W140, W126, R107, W201', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'Wj2ugkZzFfY', 'Mercedes overvoltage protection relay - KE-Jetronic from Bosch', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'pHja-hX9jFU', 'Mercedes overvoltage protection relay - ÜSR at KE-Jetronic, #W126, #W124, #W201, #R107', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'peaWZU9M6Hc', 'Mercedes r107 - how to get a mirror shine on rusty pitted chrome', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'E7ROn5vS6PM', 'Mercedes rear axle - differential - oil change #Mercedes W124, W201, W116, W126, R107, W123', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '-tDZO0OT1VA', 'Mercedes restoration - KE-Jetronic - Change the lower part of the air flow meter', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '0GiXlYz1g3c', 'Mercedes restoration Dismantle monovalve/ duovalve change on Mercedes SL R107 W126 C126 W123 BMW', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'XfXCOaHz0aQ', 'Mercedes surge protection relay - KE-Jetronic from Bosch', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '_00dX9El4ZA', 'Mercedes-Benz interior temperature sensor and lighting shift gate R107 and W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'tbvo-nIuMIM', 'Mercedes-Benz interior temperature sensor and lighting switch gate R107 and W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'u6mpypYRvcM', 'Multifunction switch flasher unit Mercedes Benz R107 560SL🚘', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'BX0dhF5tmq8', 'Remove mono/duo valve and check function Part 1 - Mercedes R107, W126, W123 BMW E24 E38 Ferrari', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'zq2JVMMcpvw', 'Repair Mercedes clock in the instrument cluster - R107 W126', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'ZtHAocYDy58', 'Replace Mercedes W114/ W115 radiator - Replace viscous fan after broken impeller', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'WeF6vJfPj-M', 'Replace the sealing ring on the control piston flow divider of the KE-Jetronic Mercedes W124, R107', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'ciN3WIMlDlA', 'Seat height adjustment for Mercedes SL R107 - Installation and function - Classic car restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'rHTreXBOOTc', 'Sponsor My Channel w/ a $4 Video Purchase - How to Get Beautiful Aluminum Valve Covers!', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'HEd1WRUbBic', 'Vehicle upgrade - polish valve cover', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'HEd1WRUbBic', 'Vehicle upgrade - polish valve cover', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', '2eI_oAstiWA', 'Naprawa lusterek bocznych R107', 'Lusterka', 10);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', '4qqCftr_kzg', 'Demontaż i montaż lusterek', 'Lusterka', 20);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', 'La_6nCFNiuc', 'Lusterka R107 - regulacja', 'Lusterka', 30);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', '1ZqN9TpU810', 'Lusterka R107 - renowacja', 'Lusterka', 40);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'L_rMTrwDcis', 'Antena R107 - naprawa', 'Antena', 10);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'H93IUJlB5R0', 'Antena R107 - demontaż', 'Antena', 20);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '-jG0uz1fA_g', 'Antena R107 - montaż', 'Antena', 30);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '4sEIf49E0KU', 'Głośniki R107 - wymiana', 'Głośniki', 40);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'DABVqcgAEOI', 'Radio Becker - serwis', 'Radio', 50);

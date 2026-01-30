
-- 🛑 AGGRESSIVE CLEANUP: Drop everything to start fresh
DROP TABLE IF EXISTS public.listing_images CASCADE;
DROP TABLE IF EXISTS public.listings CASCADE;
DROP TABLE IF EXISTS public.rss_sources CASCADE;
DROP TABLE IF EXISTS public.repair_media CASCADE;
DROP TABLE IF EXISTS public.repair_modules CASCADE;
DROP TABLE IF EXISTS public.comments CASCADE;
DROP TABLE IF EXISTS public.repair_videos CASCADE;
DROP TABLE IF EXISTS public.repairs CASCADE;
DROP TABLE IF EXISTS public.shops_links CASCADE;
DROP TABLE IF EXISTS public.user_roles CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.articles CASCADE;

-- Drop types
DROP TYPE IF EXISTS public.source_type CASCADE;
DROP TYPE IF EXISTS public.listing_status CASCADE;
DROP TYPE IF EXISTS public.listing_category CASCADE;
DROP TYPE IF EXISTS public.repair_status CASCADE;
DROP TYPE IF EXISTS public.repair_module_type CASCADE;
DROP TYPE IF EXISTS public.repair_media_kind CASCADE;
DROP TYPE IF EXISTS public.shop_link_status CASCADE;
DROP TYPE IF EXISTS public.shop_link_type CASCADE;
DROP TYPE IF EXISTS public.app_role CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin(uuid) CASCADE; -- Drop incorrectly named one if it somehow exists
DROP FUNCTION IF EXISTS public.has_role(uuid, public.app_role) CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;


-- 🏗️ RECREATE STRUCTURE

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

-- Video Library Table (Restored)
CREATE TABLE public.repair_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_slug TEXT NOT NULL,
    video_id TEXT NOT NULL,
    title TEXT NOT NULL,
    subcategory TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Articles Table
CREATE TABLE public.articles (
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


-- 🔒 SECURITY & RLS

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
ALTER TABLE public.repair_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;

-- Security Functions

CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

-- FIXED: This function takes NO arguments, it checks the CURRENT user
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.has_role(auth.uid(), 'admin')
$$;

-- RLS Policies

-- Profiles
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- User Roles
CREATE POLICY "Admins can view all roles" ON public.user_roles FOR SELECT USING (public.is_admin() OR auth.uid() = user_id);
CREATE POLICY "Admins can manage roles" ON public.user_roles FOR ALL USING (public.is_admin());

-- RSS
CREATE POLICY "Anyone can view enabled RSS sources" ON public.rss_sources FOR SELECT USING (enabled = true OR public.is_admin());
CREATE POLICY "Admins can manage RSS sources" ON public.rss_sources FOR ALL USING (public.is_admin());

-- Listings
CREATE POLICY "Anyone can view approved listings" ON public.listings FOR SELECT USING (status = 'approved' OR public.is_admin() OR (user_id = auth.uid()));
CREATE POLICY "Users can create own listings" ON public.listings FOR INSERT WITH CHECK (auth.uid() = user_id AND source_type = 'user');
CREATE POLICY "Users can update own pending listings" ON public.listings FOR UPDATE USING (auth.uid() = user_id OR public.is_admin());
CREATE POLICY "Users can delete own listings" ON public.listings FOR DELETE USING (auth.uid() = user_id OR public.is_admin());

-- Listing Images
CREATE POLICY "Anyone can view listing images" ON public.listing_images FOR SELECT USING (true);
CREATE POLICY "Users can manage own listing images" ON public.listing_images FOR ALL USING (
    EXISTS (SELECT 1 FROM public.listings WHERE listings.id = listing_images.listing_id AND (listings.user_id = auth.uid() OR public.is_admin()))
);

-- Repairs
CREATE POLICY "Anyone can view published repairs" ON public.repairs FOR SELECT USING (status = 'published' OR public.is_admin());
CREATE POLICY "Admins can manage repairs" ON public.repairs FOR ALL USING (public.is_admin());

-- Repair Modules
CREATE POLICY "Anyone can view repair modules" ON public.repair_modules FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.repairs WHERE repairs.id = repair_modules.repair_id AND (repairs.status = 'published' OR public.is_admin()))
);
CREATE POLICY "Admins can manage repair modules" ON public.repair_modules FOR ALL USING (public.is_admin());

-- Repair Media
CREATE POLICY "Anyone can view repair media" ON public.repair_media FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.repairs WHERE repairs.id = repair_media.repair_id AND (repairs.status = 'published' OR public.is_admin()))
);
CREATE POLICY "Admins can manage repair media" ON public.repair_media FOR ALL USING (public.is_admin());

-- Comments
CREATE POLICY "Anyone can view comments" ON public.comments FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create comments" ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own comments" ON public.comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments or admin" ON public.comments FOR DELETE USING (auth.uid() = user_id OR public.is_admin());

-- Shop Links
CREATE POLICY "Anyone can view approved shop links" ON public.shops_links FOR SELECT USING (status = 'approved' OR public.is_admin() OR user_id = auth.uid());
CREATE POLICY "Authenticated users can create shop links" ON public.shops_links FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own shop links" ON public.shops_links FOR UPDATE USING (auth.uid() = user_id OR public.is_admin());
CREATE POLICY "Users can delete own shop links or admin" ON public.shops_links FOR DELETE USING (auth.uid() = user_id OR public.is_admin());

-- Video Library
CREATE POLICY "Allow public read access" ON public.repair_videos FOR SELECT USING (true);

-- Articles (FIXED: replaced is_admin(auth.uid()) with public.is_admin())
CREATE POLICY "Articles are viewable by everyone if published" ON public.articles FOR SELECT 
USING (is_published = true OR (auth.jwt() ->> 'email') IN (SELECT email FROM auth.users WHERE public.is_admin()));

CREATE POLICY "Articles are insertable by admins only" ON public.articles FOR INSERT 
WITH CHECK (public.is_admin());

CREATE POLICY "Articles are updatable by admins only" ON public.articles FOR UPDATE 
USING (public.is_admin());

CREATE POLICY "Articles are deletable by admins only" ON public.articles FOR DELETE 
USING (public.is_admin());

-- Triggers

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
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

-- Timestamp Trigger
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_repairs_updated_at BEFORE UPDATE ON public.repairs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_repair_modules_updated_at BEFORE UPDATE ON public.repair_modules
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Indexes

CREATE INDEX idx_listings_status ON public.listings(status);
CREATE INDEX idx_listings_source_type ON public.listings(source_type);
CREATE INDEX idx_listings_category ON public.listings(category);
CREATE INDEX idx_listings_country ON public.listings(country);
CREATE INDEX idx_listings_rss_guid ON public.listings(rss_source_id, rss_guid);
CREATE INDEX idx_repairs_status ON public.repairs(status);
CREATE INDEX idx_repairs_slug ON public.repairs(slug);
CREATE INDEX idx_shops_links_status ON public.shops_links(status);

-- DATA SEEDING

-- RSS Sources
INSERT INTO public.rss_sources (name, feed_url, country_default, enabled) VALUES
  ('Bring a Trailer R107', 'https://rss.app/feed/S7nzC0tge0CZbieb', 'US', true),
  ('eBay Motors R107', 'https://rss.app/feed/2Z5EiTzlfry3bqFK', 'US', true),
  ('Dodatkowy Feed R107', 'https://rss.app/feed/GdyKzGIfWkzs4rBm', 'PL', true);

-- Article
INSERT INTO public.articles (slug, title, description, content, seo_title, seo_description, is_published, image_url)
VALUES (
  'historia-mercedes-r107-c107',
  'Pancerna elegancja – Historia Mercedes R107 i C107',
  'Jak Mercedes R107 i C107 zdefiniowały luksus na dwie dekady. Poznaj historię ikony lat 70. i 80.',
  '<h2>Jak Mercedes R107 i C107 zdefiniowały luksus na dwie dekady</h2><p>...</p>', -- (Simplified for brevity, user has full content in other files if needed but this is enough for structure)
  'Pancerna elegancja – Historia Mercedes R107 i C107',
  'Jak Mercedes R107 i C107 zdefiniowały luksus na dwie dekady. Poznaj historię ikony lat 70. i 80.',
  true,
  '/images/pancerna-elegancja.png'
);

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

INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'b6ff89b4-4605-4996-aad8-3a1afd3b953d', 'rss', 'approved', 'Używany Mercedes-Benz SL 1970 - 476 000 PLN, 58 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            476000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6GBYum.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6Im1yZDEyNTluMGhnay1PVE9NT1RPUEwiLCJ3IjpbeyJmbiI6IndnNGducXA2eTFmLU9UT01PVE9QTCIsInMiOiIxNiIsImEiOiIwIiwicCI6IjEwLC0xMCJ9XX0.DiDDYaioMJIAT_UCpBy1u70mTNP9jxvQQbrKBvgXiL8/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '268421b019240ee83a3724638fe42bf7', true, 'Model SL z 1970 roku, cena w PLN', 
            'SL', NULL, 1970, 1970, 
            NULL, '2025-12-22T18:00:28.534888+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '2846d4da-3924-4809-950d-9b8b49f9cf7c', 'rss', 'approved', 'Używany Mercedes-Benz SL 1972 - 41 999 PLN, 67 462 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            41999, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HpqGX.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InVzZnEycW41emZ5bzItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.nxoC_9Kicnk47tEF0qV3Ucrb0AEA8Bw9cKABguLK0PQ/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'd8b7482be6142f1d64d989f0bdc1f3f4', true, 'Model R107 SL z lat 1970-1986, cena podana w PLN.', 
            'SL', 'R107', 1972, 1972, 
            NULL, '2025-12-22T18:00:31.797629+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'f100d57a-9a58-4d30-8a93-ccf6e47ca41c', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1973 - 47 900 PLN, 56 000 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            47900, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6HGGBL.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6Im4zdjVhY2hxeWo5cC1PVE9NT1RPUEwiLCJ3IjpbeyJmbiI6IndnNGducXA2eTFmLU9UT01PVE9QTCIsInMiOiIxNiIsImEiOiIwIiwicCI6IjEwLC0xMCJ9XX0.JAWC3B8ojq9O5DFnihZXxoMYeY6r_mWBOsMmk3gnN4w/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '0076588cbbcb79f885fea53d64fad73c', true, 'Model SLC z 1973 roku jest zgodny z wymaganiami.', 
            'SLC', 'C107', 1973, 1973, 
            NULL, '2025-12-22T18:00:34.887226+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'd994cbe4-631d-4cff-97ea-a207a41b1460', 'rss', 'approved', 'Używany Mercedes-Benz SL 1985 - 37 800 PLN, 87 112 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            37800, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HMDQ6.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6IndlMzlxNTRvaTlxdzEtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.a6lMRljBb6DtM0EUj0814DVzqhJO1vGBOvRvbz8KWkg/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '91a36cdb0660da41a8bd7a1ce3cf7311', true, 'Model to R107, cena w PLN', 
            'SL', 'R107', 1985, 1985, 
            NULL, '2025-12-22T18:00:37.852225+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'e4a17fc1-7d5d-4992-92a5-9c41d3141f1a', 'rss', 'approved', 'Używany Mercedes-Benz SL 1979 - 29 900 PLN, 112 800 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            29900, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HMUrF.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6ImMyZWJrejgyOWRodTMtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.c5XBivWAycfzvxSrIjAicyR2a-Du7VjcPI6ol7n64UY/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '0685cb045a386396c27f651f303f5b0c', true, 'Model R107 SL z lat 1970-1986, cena podana w PLN.', 
            'SL', 'R107', 1979, 1979, 
            NULL, '2025-12-22T18:00:40.929423+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'c7673de0-7a60-44b2-b0a3-59107107f9ab', 'rss', 'approved', 'Używany Mercedes-Benz SL 1974 - 128 800 PLN, 58 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            128800, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HN4ri.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InJvdzhnanM0em44NTMtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.2pNIJgKMYfeZ6GbqBU_M6xOjqUyNRM9OvfzPtDa2TjQ/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '6eb82864e5304e3e9e5081acb791e122', true, 'Model SL z 1974 roku, spełnia wymagania.', 
            'SL', 'R107', 1974, 1974, 
            NULL, '2025-12-22T18:00:46.455184+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'b9b5fee7-f856-4e11-aa33-6eeb17af2760', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1979 - 42 999 PLN, 167 710 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            42999, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6HCWJj.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6ImQ1ZXg5dXNiOHYycjItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.QtzjgFKQCoIL1AzIaQwJ4dHLXjw3LXQIJq4NZYoFTfU/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '10045306003318cb42b2301f12c8f8f3', true, 'Model SLC z 1979 roku, spełnia wymagania.', 
            'SLC', 'C107', 1979, 1979, 
            NULL, '2025-12-22T18:00:49.466992+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'eab7894b-b869-46d9-8214-8c7e92f55867', 'rss', 'approved', 'Używany Mercedes-Benz SL 1981 - 49 800 PLN, 168 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            49800, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HK08g.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InNrMDh3czV5enNiMDMtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.-8O7RKlQD7hmld9k-LNhezk7aULKfamLOfGAsq15E-I/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '6554f1416b85aea5b4c1af14ff9b2a21', true, 'Model SL z lat 1981, cena podana w PLN.', 
            'SL', 'R107', 1981, 1981, 
            NULL, '2025-12-22T18:01:03.049281+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '84059bb4-42ed-4fe8-ae6c-ae66229dda71', 'rss', 'approved', 'Używany Mercedes-Benz SL 1979 - 219 000 PLN, 84 234 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            219000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HwIL4.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6IjZteHJseHpxMHZ5bjItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.IwkreRC0avis_2ERzRmd99KWE-dynjc7rmQir2gdXdI/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'e5b9c2365f526bf417ce307ec69d0464', true, 'Model SL z 1979 roku, spełnia wymagania.', 
            'SL', 'R107', 1979, 1979, 
            NULL, '2025-12-22T18:01:09.712075+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '16b569e4-3dad-4acf-96a5-f62c1b4fd083', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1979 - 71 000 PLN, 272 509 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            71000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6HcWnY.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InB1dTFvMjlqaXNzcS1PVE9NT1RPUEwiLCJ3IjpbeyJmbiI6IndnNGducXA2eTFmLU9UT01PVE9QTCIsInMiOiIxNiIsImEiOiIwIiwicCI6IjEwLC0xMCJ9XX0.cYatquO_Kyjbu5KHUQEZkrhxs-0dgux8Jxdo-1Hx5QY/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '11f8b3cc3f98e07f444ff43ad1a560ad', true, 'Model SLC z lat 1970-1986, cena w PLN', 
            'SLC', 'C107', 1979, 1979, 
            NULL, '2025-12-22T18:01:12.451357+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '4445dc12-ce34-4876-bb29-d8f093b8ce19', 'rss', 'approved', 'Używany Mercedes-Benz SL 1983 - 71 000 PLN, 159 200 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            71000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HuSRU.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6Im9lYjU3M3ZzbDl4ZzItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.flbYQM3gPXB_lAZj5N_XSO7O_p76CLMR9PvCcKo0tFw/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '23085f73d932c7b942bc2b42ea80daf3', true, 'Model SL z lat 1980-1986, cena podana w PLN.', 
            'SL', 'R107', 1983, 1983, 
            NULL, '2025-12-22T18:01:21.225403+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'eb60289a-d567-4616-ba46-6db5d6827865', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1980 - 83 000 PLN, 110 820 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            83000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6HOLSF.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6Ino4Z2Zzdjdhc2M1ci1PVE9NT1RPUEwiLCJ3IjpbeyJmbiI6IndnNGducXA2eTFmLU9UT01PVE9QTCIsInMiOiIxNiIsImEiOiIwIiwicCI6IjEwLC0xMCJ9XX0.0gq1_u-6p_fBlknALZf4QEjmWoFytSvMH-JGF39lFs0/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '58563e180231957b21ad5daea4b4a2fa', true, 'Model SLC z lat 1980, cena podana w PLN.', 
            'SLC', 'C107', 1980, 1980, 
            NULL, '2025-12-22T18:01:24.192291+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '423b5705-3d6e-47f0-b778-ffd3129d1d33', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1975 - 85 000 PLN, 48 848 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            85000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6GIDIe.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6ImFhMW4xM2Z0c2kwdDEtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.2Nm_KlANQHQiayXNQb0wOEdh8yyjgugYupGtGMY-6pk/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '71abda0b0cdb9e7a0e3bf45378112868', true, 'Model SLC z lat 1970-1986, cena podana w PLN.', 
            'SLC', 'C107', 1975, 1975, 
            NULL, '2025-12-22T18:01:26.815785+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '3b5296af-73d4-4792-972a-6eb77bb7be49', 'rss', 'approved', 'Używany Mercedes-Benz SL 1972 - 74 900 PLN, 45 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            74900, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HuLXs.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6IjE5dGM3Mmlla2ZoZy1PVE9NT1RPUEwiLCJ3IjpbeyJmbiI6IndnNGducXA2eTFmLU9UT01PVE9QTCIsInMiOiIxNiIsImEiOiIwIiwicCI6IjEwLC0xMCJ9XX0.gQ56iRSpHkfuAkMEKZwh7ThCeIaWmVc8i1fu3Xjt-sI/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'd13d849ccda7ef30da09678d1be1b03a', true, 'Model SL z lat 1970-1986, cena podana w PLN.', 
            'SL', 'R107', 1972, 1972, 
            NULL, '2025-12-22T18:01:29.997096+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'cc31ab26-6de4-4f52-8721-4ff5f92a2b5e', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1980 - 99 000 PLN, 172 000 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            99000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6HIWrP.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InRzdDJqeWp0MzJsZi1PVE9NT1RPUEwiLCJ3IjpbeyJmbiI6IndnNGducXA2eTFmLU9UT01PVE9QTCIsInMiOiIxNiIsImEiOiIwIiwicCI6IjEwLC0xMCJ9XX0.2G67SlzAsEAUtdhE8mZbrpD0lgUQInJcg2bwbHiCrNg/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '55eb686914c1c64219ec982b8ca3d2ee', true, 'Model SLC z lat 1980, cena podana w PLN.', 
            'SLC', 'C107', 1980, 1980, 
            NULL, '2025-12-22T18:01:35.424975+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '4e34b737-5938-44bc-9325-6a4159eb5711', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1979 - 239 600 PLN, 142 000 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            239600, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6GRSJl.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6IngxeG44OTYxM29rZy1PVE9NT1RPUEwiLCJ3IjpbeyJmbiI6IndnNGducXA2eTFmLU9UT01PVE9QTCIsInMiOiIxNiIsImEiOiIwIiwicCI6IjEwLC0xMCJ9XX0.9W_INioiD2m6Fai9s6v_kDEWL9o0VeMbxIVUHKiGlgE/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'e24297061ac9c135f56bc206cf9c469f', true, 'Model SLC z 1979 roku, spełnia wymagania.', 
            'SLC', 'C107', 1979, 1979, 
            NULL, '2025-12-22T18:01:38.370028+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '7377f69d-69e2-4365-a3c1-415a243d3669', 'rss', 'approved', 'Używany Mercedes-Benz SL 1985 - 75 000 PLN, 1 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            75000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HEPpg.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InV0aHVhNHZ3NXZ6ajEtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.X_XmrdUkeKiHzcsrCummoCRDpM5rwE1ZEmxkw_sIHGg/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '1da5c641fda6e67422d59a17265e8af7', true, 'Model SL z 1985 roku, cena podana w PLN.', 
            'SL', NULL, 1985, 1985, 
            NULL, '2025-12-23T18:00:33.388559+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '8ecd9f97-cfed-4fea-aeb7-030235f165ea', 'rss', 'approved', 'Używany Mercedes-Benz SL 1977 - 119 900 PLN, 158 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            119900, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6H285j.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6Inhwb2xzeHBoYWJxZDEtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.kwoh6aQIPJkgAYVCN9HhRhPVgBQ8oUlY9PDDt9dOgaQ/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'cbf71719ac475caa61a6fd49c85edc2c', true, 'Model SL z lat 1970-1986, cena podana w PLN.', 
            'SL', 'R107', 1977, 1977, 
            NULL, '2025-12-23T18:00:51.607824+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'ea8aa287-b757-4d84-8c6f-602a06f9feee', 'rss', 'approved', 'Używany Mercedes-Benz SL 1971 - 424 000 PLN, 103 855 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            424000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HMTwx.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6ImpoenRqZDdsYWtoczMtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.Y7UzlGU4Mb95w5XfmfHzxn00Cr782UZTW1fwEt12K9I/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '8a11decb31bc03263a4658e4a835a0db', true, 'Model SL z lat 1970-1986, cena podana w PLN.', 
            'SL', 'R107', 1971, 1971, 
            NULL, '2025-12-23T18:00:58.541439+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '4c7385ad-ce64-46bc-879f-53a86f413e7f', 'rss', 'approved', 'No Reserve: 1989 Mercedes-Benz 560SL', 'Bid for the chance to own a No Reserve: 1989 Mercedes-Benz 560SL at auction with Bring a Trailer, the home of the best vintage and classic cars online. Lot #225,672.', 
            NULL, 'PLN', 'US', 'pojazd', 'https://bringatrailer.com/listing/1989-mercedes-benz-560sl-529/', 
            'https://bringatrailer.com/wp-content/uploads/2025/12/1989_mercedes-benz_560sl_004-07882.jpg?fit=1818,1212', 'eacd6bf7-1eac-4673-b307-7207d3e8d1b6', 'c454580e4ab94d2377dabc9b17338830', true, 'Model R107 560SL z lat 1981-1989', 
            '560SL', 'R107', 1989, 1989, 
            NULL, '2025-12-29T17:19:25.284401+00:00', '2025-12-20T15:36:17+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'dafda3ef-2c7c-4d48-8242-acaeb261d032', 'rss', 'approved', '1980 Mercedes Benz 450 convertible', '1980 Mercedes Benz 450 SL 2 door sports convertible loaded automatic V-8. Has 78k original miles. One owner in storage for 20 years. Runs and drives new just needs some tlc. Call for more info  show contact info', 
            NULL, 'PLN', 'US', 'pojazd', 'https://providence.craigslist.org/cto/d/providence-1980-mercedes-benz-450/7905522479.html', 
            'https://images.craigslist.org/00J0J_2de0jyYWqYX_04P06q_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', '20b1d90121297a7e33c34a1962f13998', true, 'Model R107 (450SL) i rok produkcji w zakresie 1971-1989', 
            '450SL', 'R107', 1980, 1980, 
            NULL, '2025-12-31T12:37:38.683354+00:00', '2025-12-30T18:38:54+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '085f890b-2c0e-4105-860a-142b12c3d72b', 'rss', 'approved', 'Merecedes 450SL', 'Have a 450SL not running for sale. Needs a lot of TLC. Brakes, Interior. S4,000

Ernie 508-377838 six.', 
            14357, 'PLN', 'US', 'pojazd', 'https://boston.craigslist.org/bmw/cto/d/holland-merecedes-450sl/7894430522.html', 
            'https://images.craigslist.org/00a0a_eb7A8U7zWXn_0t20t2_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', 'e7637a0bf58cd0003de16b693c0e34eb', true, 'Model 450SL należy do generacji R107.', 
            '450SL', 'R107', NULL, NULL, 
            NULL, '2025-12-19T09:52:17.100741+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '79d6c450-30ce-411b-8164-ae1626fc7f40', 'rss', 'approved', '1980 Mercedes Benz 450 convertible', '1980 Mercedes Benz 450 SL 2 door sports convertible loaded automatic V-8. Has 78k original miles. One owner in storage for 20 years. Runs and drives new just needs some tlc. Call for more info  show contact info', 
            NULL, 'PLN', 'US', 'pojazd', 'https://providence.craigslist.org/cto/d/providence-1980-mercedes-benz-450/7900660154.html', 
            'https://images.craigslist.org/00J0J_2de0jyYWqYX_04P06q_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', 'bbedffdc10a259f5e3e61b60a70258d5', true, 'Model R107 (450 SL) z lat 1980.', 
            '450SL', 'R107', 1980, 1980, 
            NULL, '2025-12-19T09:52:14.304296+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '2d7451a9-82a7-455f-8438-c3e82283644d', 'rss', 'approved', '1978 Mercedes Benz 450 SL', '• Rare Gray exterior over Red leather interior combo
 • Runs and drives – invested ~$6,500 in recent shop work (receipts in hand)
 • Includes removable hardtop + soft top frame (soft top needs replacement)
 • 4.5L V8, automatic transmission
 • Only 105k miles – low for age
 • Garage-stored for years before being revived

⸻

🛠️ Recent Work
 • Brought out of long-term storage
 • ~$6,500 in professional mechanical work to get it running and driving
 • Starts, runs, shifts, and drives under its own power

⸻

🔧 What It Still Needs
 • Exhaust system (current one has holes, car runs loud)
 • New tires
 • Soft top replacement
 • Cosmetic restoration (paint fade, rust spots, interior wear)

⸻

🎯 The Opportunity

This 450SL is a complete, running project. Perfect candidate for full restoration — this one already has the expensive work done to get it on the road again.

⸻

💵 Price: $6,400 OBO — Open to reasonable offers.
📞 Message me here on Marketplace if interested.', 
            NULL, 'PLN', 'US', 'pojazd', 'https://hartford.craigslist.org/cto/d/windsor-locks-1978-mercedes-benz-450-sl/7900858891.html', 
            'https://images.craigslist.org/01212_jDdW0MvYao7_0CI0t2_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', '42f0f8489e3301a415f0551a52888d30', true, 'Model R107 (450 SL) z lat 1970-1986', 
            '450SL', 'R107', 1978, 1978, 
            NULL, '2025-12-19T09:52:03.813372+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '7282105e-a16b-4fca-bdee-a751a6d10454', 'rss', 'approved', 'Mercedes 450SL', 'A real barn find here.
This is a 1978 Mercedes 450SL hardtop convertible with a soft top option. Having spent many years stored in a northern Vermont barn it’s now been taken out, dusted off and fired up, ready for a new owner. 
With some TLC this car should prove to be an appreciating asset for years to come, a true classic!  
Priced under market value at $11,900
Email questions or
Call Russ
Land line
80two- 5 three three - two 9 0 0', 
            42713, 'PLN', 'US', 'pojazd', 'https://vermont.craigslist.org/cto/d/greensboro-bend-mercedes-450sl/7902244640.html', 
            'https://images.craigslist.org/00p0p_1zwadntK551_0CI0m5_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', 'aac6bda700ad8f54a6e3cbff33cd9777', true, 'Model 450SL to R107, rocznik 1978 w opisie.', 
            '450SL', 'R107', 1978, 1978, 
            NULL, '2025-12-19T09:52:01.751697+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'f68cbf63-9ef7-4be1-b17f-e11a73a29adf', 'rss', 'approved', 'Używany Mercedes-Benz SL 1979 - 70 000 PLN, 10 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            70000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HOIPz.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InF2aHR4ZDU1M2x6YjMtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.IkCBvDY7AwwqKtDErQha486-g0vD_OFCC-m5o8ddqOM/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '2c8d7c383df78ca76fea9eb9bf732ed6', true, 'Model R107 SL z 1979 roku', 
            'SL', 'R107', 1979, 1979, 
            NULL, '2025-12-19T09:51:12.607336+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'fb2835fd-ad60-4ddb-94d7-cf2ccdf059e0', 'rss', 'approved', 'Używany Mercedes-Benz SL 1974 - 81 500 PLN, 148 800 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            81500, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HmGUD.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InBmaGx5ZXVwNmgyYjItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.5VMUKeLBVuiwKfAuBtrMQ-I4Rnm5xWLNKoKSM9cxHw4/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'a2aea47fd13a9313826056cdcbf81d63', true, 'Model SL z lat 1970-1986, cena podana w PLN.', 
            'SL', 'R107', 1974, 1974, 
            NULL, '2025-12-23T06:00:20.161872+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'd6894d80-2ad2-4fb8-9388-b26950451c30', 'rss', 'approved', 'Używany Mercedes-Benz SL 1971 - 78 900 PLN, 198 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            78900, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HqYhK.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InljZ2VlYTY1ZHFraTEtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.cxq9ZPRI31yW1T4MHvAs2cRPDCxc9fYBB5T8sPYhljc/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '79b959e4907d7665f3e0328b1172c597', true, 'Model SL z lat 1970-1986, cena podana w PLN.', 
            'SL', 'R107', 1971, 1971, 
            NULL, '2025-12-24T06:00:33.618032+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'd559aa63-e794-4808-9a06-eabd5866981f', 'rss', 'approved', 'No Reserve: 32k-Mile 1989 Mercedes-Benz 560SL', 'Bid for the chance to own a No Reserve: 32k-Mile 1989 Mercedes-Benz 560SL at auction with Bring a Trailer, the home of the best vintage and classic cars online. Lot #225,272.', 
            NULL, 'PLN', 'US', 'pojazd', 'https://bringatrailer.com/listing/1989-mercedes-benz-560sl-530/', 
            'https://bringatrailer.com/wp-content/uploads/2025/12/IMG_9714-01663-scaled.jpg?fit=2048,1366', 'eacd6bf7-1eac-4673-b307-7207d3e8d1b6', 'a1973c2cddbb8c084699671b00c8be6c', true, 'Model R107 (560SL) z lat 1981-1989', 
            '560SL', 'R107', 1989, 1989, 
            NULL, '2025-12-29T17:19:27.442707+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '77942f65-ca04-477e-864c-38117b5f6389', 'rss', 'approved', '38k-Mile 1988 Mercedes-Benz 560SL', 'Bid for the chance to own a 38k-Mile 1988 Mercedes-Benz 560SL at auction with Bring a Trailer, the home of the best vintage and classic cars online. Lot #225,484.', 
            NULL, 'PLN', 'US', 'pojazd', 'https://bringatrailer.com/listing/1988-mercedes-benz-560sl-545/', 
            'https://bringatrailer.com/wp-content/uploads/2025/12/DSC03343-85450-scaled.jpg?fit=2048,1368', 'eacd6bf7-1eac-4673-b307-7207d3e8d1b6', '242852ac1da5ca893ad983b24000f9be', true, 'Model 560SL jest zgodny z wymaganiami, a rocznik 1988 mieści się w dozwolonym zakresie.', 
            '560SL', 'R107', 1988, 1988, 
            NULL, '2025-12-29T17:19:30.097093+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'ac44298b-d4c5-4ac0-9f5a-6a16387c2e5f', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1980 - 99 000 PLN, 122 200 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            99000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6HwStx.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InY1cm5sZGtoZDNlMzEtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.Tm0GKFWDrKviGy0AcKEA9rx0bHBE6yrXImCe95r1UP4/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '962bbd171659184684911841b31dd40a', true, 'Model SLC z lat 1980, cena podana w tytule.', 
            'SLC', 'C107', 1980, 1980, 
            NULL, '2025-12-29T18:00:34.378857+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '14f6adae-4787-4d5e-83d1-5ba424325e7e', 'rss', 'approved', 'MERCEDES BENZ 450sl  for resto or parts', '1976 Mercedes Benz 450sl
84k miles
Auto 
Hard top
Convertible top
Original wheels and hub caps
4.5 liter V-8

Barn find.    I got a call from a car guy asking me to rescue this Iconic Mercedes 450.   The wheels rolled freely even after it had been sitting for awhile. Pretty impressive for a 50 year old car. It looks solid enough to restore.  Certainly enough parts here for the to more than compensate my asking price.  It comes with a key but not a title. Bill of sale only.   Bring a friend, bring a trailer, or send a flat bed but unless you are “that Guy” from the motor trend channel,,,,, you won’t be driving it home

$950  or next best idea…..
802/55773hundred', 
            3410, 'PLN', 'US', 'pojazd', 'https://vermont.craigslist.org/cto/d/south-burlington-mercedes-benz-450sl/7892910970.html', 
            'https://images.craigslist.org/01717_hwYWP3DrJnb_0CI0t2_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', 'afce33a7af18c9a38768a4e418c6e10e', true, 'Model R107 (450SL) z lat 1970-1986', 
            '450SL', 'R107', 1976, 1976, 
            NULL, '2025-12-19T09:52:23.81151+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '263bb0a1-3668-49ac-91ec-fa29a936f688', 'rss', 'approved', 'Używany Mercedes-Benz SL 1973 - 39 900 PLN, 93 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            39900, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HNPUh.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6ImN3bWRoY2drOTFseDItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.TZgCFVLaiqsoB4XahBE9dOSWyJLd5-Tbfe6374llTa8/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'f317e0effdd3d4f48d978643e92d12b0', true, 'Model R107 SL z 1973 roku, cena podana w PLN.', 
            '280SL', 'R107', 1973, 1973, 
            NULL, '2025-12-19T09:51:59.726686+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'b2006b62-2d63-432f-825e-1f5119237b94', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1981 - 215 000 PLN, 215 169 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            215000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6DW17Q.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6IndlZnk3OGc1NG0wei1PVE9NT1RPUEwiLCJ3IjpbeyJmbiI6IndnNGducXA2eTFmLU9UT01PVE9QTCIsInMiOiIxNiIsImEiOiIwIiwicCI6IjEwLC0xMCJ9XX0.RlM8dW8xxQZo1yLMv91MWTlKbdBNpdPM9le14ejqB7U/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '7f72bcfb8976e786c503ac5700a15b29', true, 'Model SLC z 1981 roku, spełnia wymagania.', 
            '380SLC', 'C107', 1981, 1981, 
            NULL, '2025-12-19T09:51:41.02927+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'fe885fc6-2d3d-4aa1-90b4-3c36c09c53b7', 'rss', 'approved', 'Używany Mercedes-Benz SL 1984 - 13 900 EUR, 126 787 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            58486, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HO8q6.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6ImwzM3VrNTdwd21qejItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.2OVWdXB1h0aN5EFd39v-62JIPLw8flaufrskNXbM1yw/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '717dcbcf39cdf17f3b5c2a561bcfdd61', true, 'Model SL z 1984 roku, spełnia wymagania.', 
            'SL', 'R107', 1984, 1984, 
            NULL, '2025-12-19T09:51:28.201212+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '45214b9a-4a2d-4634-955e-7ef06d457498', 'rss', 'approved', 'Mercedes 450SL', 'A real barn find here.
This is a 1978 Mercedes 450SL hardtop convertible with a soft top option. Having spent many years stored in a northern Vermont barn it’s now been taken out, dusted off and fired up, ready for a new owner. 
With some TLC this car should prove to be an appreciating asset for years to come, a true classic!  
Priced under market value at $11,900
Email questions or
Call Russ
Land line
80two- 5 three three - two 9 0 0', 
            42770, 'PLN', 'US', 'pojazd', 'https://vermont.craigslist.org/cto/d/greensboro-bend-mercedes-450sl/7894316024.html', 
            'https://images.craigslist.org/00p0p_1zwadntK551_0CI0m5_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', '99a86e5fe8883fd2cf0e9b855b3eb477', true, 'Model R107 (450SL) z lat 1970-1986, cena podana w tytule.', 
            '450SL', 'R107', 1978, 1978, 
            NULL, '2025-12-19T18:00:11.717221+00:00', '2025-11-08T05:50:42+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '2325a9fa-f8b9-4f92-934a-5fe52acf97af', 'rss', 'approved', '1978 Mercedes Benz 450 SL', '• Rare Gray exterior over Red leather interior combo
 • Runs and drives – invested ~$6,500 in recent shop work (receipts in hand)
 • Includes removable hardtop + soft top frame (soft top needs replacement)
 • 4.5L V8, automatic transmission
 • Only 105k miles – low for age
 • Garage-stored for years before being revived

⸻

🛠️ Recent Work
 • Brought out of long-term storage
 • ~$6,500 in professional mechanical work to get it running and driving
 • Starts, runs, shifts, and drives under its own power

⸻

🔧 What It Still Needs
 • Exhaust system (current one has holes, car runs loud)
 • New tires
 • Soft top replacement
 • Cosmetic restoration (paint fade, rust spots, interior wear)

⸻

🎯 The Opportunity

This 450SL is a complete, running project. Perfect candidate for full restoration — this one already has the expensive work done to get it on the road again.

⸻

💵 Price: $6,400 OBO — Open to reasonable offers.
📞 Message me here on Marketplace if interested.', 
            NULL, 'PLN', 'US', 'pojazd', 'https://hartford.craigslist.org/cto/d/windsor-locks-1978-mercedes-benz-450-sl/7894228245.html', 
            'https://images.craigslist.org/01212_jDdW0MvYao7_0CI0t2_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', 'ba9d5b987fe100842cb40bcba711de2d', true, 'Zgodny model R107, rocznik 1978, cena w tytule', 
            '450SL', 'R107', 1978, 1978, 
            NULL, '2025-12-19T18:00:14.736496+00:00', '2025-11-07T21:17:55+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '9bfff641-0168-49fd-82f9-82f287d1db6b', 'rss', 'approved', '1985 Mercedes Benz 380 SL', 'For sale is a 1985 Mercedes-Benz 380SL , convertible , with hard top . This Mercedes is 8 cylinder , 3.8 litre , automatic transmission , cruise control , and power windows . The miles are 29000 . This car is creme with a tan interior . The price is $29500.00 plus tax , title , and applicable fees . Call today for more information ! We are a used car dealer . 

M&M Inc of York 
2875 East Prospect Rd
York , Pa 17402

717-755-3841', 
            105917, 'PLN', 'DE', 'pojazd', 'https://york.craigslist.org/ctd/d/york-1985-mercedes-benz-380-sl/7901996758.html', 
            'https://images.craigslist.org/00m0m_90UqGfNKAzR_0pO0jm_600x450.jpg', 'f38285ab-dfdc-4464-85a4-f9a2a1dbe093', 'c72013c8b015cadab268bdc2c85e2f8d', true, 'Model R107 (380SL) z lat 1980-1986, cena podana w tytule.', 
            '380SL', 'R107', 1985, 1985, 
            NULL, '2025-12-22T18:00:10.877558+00:00', '2025-12-12T20:22:38+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '9a6ded70-7f55-4bd6-9a84-54ac3c51d76e', 'rss', 'approved', '1984 Mercedes 380 SL Convertible', '1984 Mercedes 380 SL hardtop convertible for sale. Garage kept, but as is, some TLC needed.', 
            NULL, 'PLN', 'DE', 'pojazd', 'https://newyork.craigslist.org/fct/cto/d/darien-1984-mercedes-380-sl-convertible/7900042269.html', 
            'https://images.craigslist.org/00k0k_jmXdLfwf1gU_0t20CI_600x450.jpg', 'f38285ab-dfdc-4464-85a4-f9a2a1dbe093', '8680dbe93b5e49b6a89476095505b813', true, 'Model R107 (380SL) z lat 1980-1986.', 
            '380SL', 'R107', 1984, 1984, 
            NULL, '2025-12-22T18:00:14.064833+00:00', '2025-12-04T01:18:22+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '13db9e4f-744d-49d4-91de-4be300e20383', 'rss', 'approved', '1983 Mercedes Benz 380 SL', 'Comes with removable Hardtop, good running condition, good tires and brakes. Odometer stopped working at 101k...speedo works. We maybe put 300 miles a year on her we''re the 2nd owner. Automatic Transmission, new stereo with Blue tooth, Euro Package (Rare) many new parts, Timing Chain, Battery, Garage kept. Negotiable', 
            NULL, 'PLN', 'DE', 'pojazd', 'https://longisland.craigslist.org/pts/d/wading-river-1983-mercedes-benz-380-sl/7894814982.html', 
            'https://images.craigslist.org/00z0z_8gVyQKdQ0aX_0CI0t2_600x450.jpg', 'f38285ab-dfdc-4464-85a4-f9a2a1dbe093', '6bdb57d3390a13517eb77c590acd8418', true, 'Model R107 380SL z lat 1970-1986, cena nie została podana.', 
            '380SL', 'R107', 1983, 1983, 
            NULL, '2025-12-22T18:00:21.108084+00:00', '2025-11-10T16:35:07+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '329ee301-07d0-4925-a95a-e63a614494da', 'rss', 'approved', '1981 Mercedes Benz 380SLC (1 Owner & Low Miles)', 'For sale,

Is this beautiful 1981 Mercedes Benz SLC380 in pristine, excellent condition.

This was an adult driven vehicle, driven by an older gentleman (my father) that recently passed away as of one year ago. He fell asleep while on vacation in Greece. 

Judging by the beautiful photos of the car, the Mercedes Benz was very well maintained under my father''s own two hands. He was the one that did all of the service and mechanical work to it. My father pretty much was the one that knew this car inside and out. To give you all a perspective as to what he recently did to it right before passing away was the timing chain (replaced w/ dual timing chains), timing chain guides, valve cover gaskets, spark plugs, hoses, distributor cap, fuel filter, oem radiator, new fan clutch/fan, new thermostat, brand new battery and various other parts, etc. He pretty much took the time to freshen the top end of the engine and while he was "IN" there, he decided that it was best to go the extra mile to change some other stuff now that he had the opportunity to do so.

There were no actual issues with the engine itself, but my father was aware that these engines were susceptible to the timing chains failing or going bad over time, so his logic was to replace them now rather than later and avoid any major damage happening to the engine. Also, at the time, my dad did not have intentions of actually selling the Mercedes Benz. He actually wanted to do it with the intention of keeping the car and having it run for many miles without any issues whatsoever. The car does run, drive and idle perfectly, it does not leak antifreeze, transmission fluid or any rear end fluid, etc. The transmission shifts smoothly and she rides great down the street and over the roads of the highway (turns heads everywhere). The car was never driven in bad weather such as the rain, sleet or snow only on beautiful, sunny warm days.

Some things to take note of, is that the car runs perfectly right around 80 to 85 degre', 
            NULL, 'PLN', 'US', 'pojazd', 'https://newyork.craigslist.org/que/cto/d/flushing-1981-mercedes-benz-380slc/7904148189.html', 
            'https://images.craigslist.org/00X0X_kgldbz5jeWl_1300CG_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', '214597a521759b5ff0329d358d314633', true, 'Model R107/C107 z lat 1980-1986, pełna nazwa modelu ustalona.', 
            '380SLC', 'C107', 1981, 1981, 
            NULL, '2025-12-24T18:00:12.835252+00:00', '2025-12-23T01:26:56+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'f6911b9d-193a-48da-a2c0-8a3182ca42fb', 'rss', 'approved', '1977 Mercedes 450 SL Convertible', '1977 Mercedes 450 SL Convertible

Garage kept, excellent condition
Low miles, collector maintained', 
            NULL, 'PLN', 'US', 'pojazd', 'https://delaware.craigslist.org/cto/d/wilmington-1977-mercedes-450-sl/7900442653.html', 
            'https://images.craigslist.org/00q0q_sC7RhBYs3M_0ak07K_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', 'a9d06252c46b46efe6a5e7443991883e', true, 'Model R107 450SL z lat 1970-1986', 
            '450SL', 'R107', 1977, 1977, 
            NULL, '2025-12-24T18:00:16.423848+00:00', '2025-12-05T20:40:11+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '2702b0e3-3996-40a1-bcc6-7dbb6a763ba8', 'rss', 'approved', '1979 Mercedes-Benz', '1979 Mercedes, 450 SL. $6,000
New brakes, new starter, new master cylinder, new battery, new radio. Recent tune up
Needs new tires.
Runs and drives.
Will accept trades.

If interested call Ralph @ show contact info

Please no text or questions if it''s available. If it''s still up, it''s available.', 
            21509, 'PLN', 'US', 'pojazd', 'https://hudsonvalley.craigslist.org/cto/d/greenwood-lake-1979-mercedes-benz/7899208488.html', 
            'https://images.craigslist.org/00T0T_dGMVIroBJAk_0ak06h_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', 'ba49a794dcbc9fba0d7e30051b2d4ba0', true, 'Znaleziono model R107 (450SL) oraz cenę w tytule.', 
            '450SL', 'R107', 1979, 1979, 
            NULL, '2025-12-24T18:01:07.948211+00:00', '2025-11-30T15:26:02+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'a6e3660d-0ddd-4422-b657-819a94b0f1a7', 'rss', 'approved', '450sl', 'I have for sale this 1976 Mercedes 450sl runs and drive well,Comes with additional color matched hardtop. 128k miles,Starts up and drive on the highway with no problem. Call Jeff for more information, Serious inquiries only.', 
            NULL, 'PLN', 'US', 'pojazd', 'https://philadelphia.craigslist.org/cto/d/philadelphia-450sl/7898393541.html', 
            'https://images.craigslist.org/00x0x_6lbmLW507a5_0t20CI_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', '2bfb4026ca3ba50df1fb329d3e45c974', true, 'Model R107 (450SL) z lat 1970-1986.', 
            '450SL', 'R107', 1976, 1976, 
            NULL, '2025-12-24T18:01:12.493447+00:00', '2025-11-26T04:13:08+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '5696a63c-524c-447e-be92-1eec198f4107', 'rss', 'approved', 'Używany Mercedes-Benz SL 1978 - 69 900 PLN, 140 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            69900, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HPpA2.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6IjJkYXV0YnBnY3g0MjItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.8XFdNFg8sOW1pCkVjH3zJQ33IwsaDoyJVXmaw2Agsts/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'dec99ca0856f8cd9fe5167d041ea108a', true, 'Model R107 SL z 1978 roku, cena podana w PLN.', 
            'SL', 'R107', 1978, 1978, 
            NULL, '2025-12-25T18:00:57.5347+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '5b06e5b1-1601-43de-97a6-504e3f2c4949', 'rss', 'approved', 'No Reserve: 1985 Mercedes-Benz 380SL', 'Bid for the chance to own a No Reserve: 1985 Mercedes-Benz 380SL at auction with Bring a Trailer, the home of the best vintage and classic cars online. Lot #225,356.', 
            NULL, 'PLN', 'US', 'pojazd', 'https://bringatrailer.com/listing/1985-mercedes-benz-380sl-238/', 
            'https://bringatrailer.com/wp-content/uploads/2025/11/1985_mercedes-benz_380sl_img_2654-46531.jpg?fit=1357,904', 'eacd6bf7-1eac-4673-b307-7207d3e8d1b6', 'c0a7a3910eec6471d0ce2a0a3043aad9', true, 'Model R107 i rocznik 1985 są zgodne z wymaganiami.', 
            '380SL', 'R107', 1985, 1985, 
            NULL, '2025-12-29T17:04:21.292457+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '655d0bae-4748-4c42-8642-42c26fd0ad13', 'rss', 'approved', 'Używany Mercedes-Benz SL 1986 - 179 000 PLN, 87 400 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            179000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HPx9l.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InFzOXdlZTc0d2UyMzItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.WiX8YOnpI6Hu4YGDUgr3WQ16YeWHKCWJ1aYATPeRApc/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'd5d703ee168ab6f75b35d8929eeb2914', true, 'Model SL z 1986 roku, cena podana w tytule.', 
            'SL', NULL, 1986, 1986, 
            NULL, '2025-12-29T17:18:43.410943+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'b86c6f6c-db7f-4666-afc1-fae899e07dfa', 'rss', 'approved', 'Używany Mercedes-Benz SL 1986 - 119 000 PLN, 166 240 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            119000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6Hdo8h.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InJ3Z3VmMXRyYWxxaDMtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.CHltAVucorMcfVpTDxl5X9fuzc31pMLK2l99HTBgDlQ/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'c419b344df9d5a35fabe9eca5db5234f', true, 'Model SL z 1986 roku, cena podana w tytule.', 
            'SL', NULL, 1986, 1986, 
            NULL, '2025-12-29T17:19:18.089259+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'e4c07f1b-7508-40bd-85ec-1051b520f095', 'rss', 'approved', 'Używany Mercedes-Benz SL 1986 - 179 000 PLN, 87 400 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            179000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HJMGF.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6IjB5eTltOGs4ZGtkcDMtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.ujnqEuy9NYDpqm73xxJ9Gv7fCZMa3disIuGH4w9xyAs/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'b5912bd8529ecafeb9deeaa9ec52d379', true, 'Model SL z 1986 roku, cena w tytule.', 
            'SL', 'R107', 1986, 1986, 
            NULL, '2025-12-29T17:19:20.410454+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'e0d7b5ea-cada-4ffd-ab75-7da209296913', 'rss', 'approved', 'Używany Mercedes-Benz SL 1986 - 160 000 PLN, 197 900 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            160000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6GXEjv.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InAwcDB0cGt5YzNkNzItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.YPoaC0kWsuf9BFWzq5K6RNwqBy_6oUr_RNpLbZLDY00/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '18a1d60ed1df9b30fca4f06cedd6b486', true, 'Model SL z 1986 roku, cena podana w tytule.', 
            'SL', NULL, 1986, 1986, 
            NULL, '2025-12-29T17:19:22.590606+00:00', '2025-12-28T18:13:34+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '01a0af41-9068-4509-bbb8-3528c2630f34', 'rss', 'approved', 'Używany Mercedes-Benz SL 1974 - 128 800 PLN, 58 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            128800, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HPGTq.html', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6ImU4MGplMjN5azltMzEtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.I0KzvxjL2Vle5jZcQqFxxFE2085bTZukz0w9J8ti16U/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'f39f2de5792b3493d68f530d4f954e5f', true, 'Model to R107, cena w tytule', 
            'SL', 'R107', 1974, 1974, 
            NULL, '2025-12-31T12:38:11.806364+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '3c79e910-4a27-4d50-976d-952f91ba92c4', 'rss', 'approved', '1989 Mercedes-Benz 560SL', 'Bid for the chance to own a 1989 Mercedes-Benz 560SL at auction with Bring a Trailer, the home of the best vintage and classic cars online. Lot #226,014.', 
            NULL, 'USD', 'US', 'pojazd', 'https://bringatrailer.com/listing/1989-mercedes-benz-560sl-510/', 
            'https://bringatrailer.com/wp-content/uploads/2025/09/1989_mercedes-benz_560sl_39469197-db35-4097-814f-11abc89af58a-95515.jpeg?fit=1131,754', 'eacd6bf7-1eac-4673-b307-7207d3e8d1b6', '4638812162e718dc6f667d64cfb840bd', true, 'Model 560SL z lat 1981-1989, cena nie została podana.', 
            '560SL', 'R107', 1989, 1989, 
            NULL, '2026-01-01T21:48:43.578073+00:00', '2025-12-26T21:17:19+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'b32ebb68-1b00-4aae-8e7a-78c781e27e8e', 'rss', 'approved', '23k-Mile 1988 Mercedes-Benz 560SL', 'Bid for the chance to own a 23k-Mile 1988 Mercedes-Benz 560SL at auction with Bring a Trailer, the home of the best vintage and classic cars online. Lot #225,919.', 
            NULL, 'USD', 'US', 'pojazd', 'https://bringatrailer.com/listing/1988-mercedes-benz-560sl-547/', 
            'https://bringatrailer.com/wp-content/uploads/2025/12/1988_mercedes-benz_560sl_merc-50-21261.jpg?fit=2047,1365', 'eacd6bf7-1eac-4673-b307-7207d3e8d1b6', 'e6983806b14d898789a529df2f8a7fbd', true, 'Model R107 i rocznik 1988 są zgodne z wymaganiami.', 
            '560SL', 'R107', 1988, 1988, 
            NULL, '2026-01-01T21:48:46.498999+00:00', '2025-12-25T20:09:29+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'a51e37f5-7f71-4ab1-b9fd-fe041fd7c70c', 'rss', 'approved', 'No Reserve: 1978 Mercedes-Benz 450SL', 'Bid for the chance to own a No Reserve: 1978 Mercedes-Benz 450SL at auction with Bring a Trailer, the home of the best vintage and classic cars online. Lot #225,979.', 
            NULL, 'USD', 'US', 'pojazd', 'https://bringatrailer.com/listing/1978-mercedes-benz-450sl-113/', 
            'https://bringatrailer.com/wp-content/uploads/2025/11/1978_mercedes-benz_450sl_dsc02156-20427.jpg?fit=1816,1211', 'eacd6bf7-1eac-4673-b307-7207d3e8d1b6', 'f6be3e5a7d7b18dcfb784ab18fd5f05e', true, 'Model R107 450SL z lat 1971-1989, cena podana w tytule.', 
            '450SL', 'R107', 1978, 1978, 
            NULL, '2026-01-01T21:48:49.629038+00:00', '2025-12-25T15:14:56+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'd3f74509-6547-4fe9-8fda-1dfa85cba763', 'user', 'approved', 'Wkład lusterka do R107', 'Wkład lusterka do Mercedesa R107  - prawy lub lewy 

Lusterka nowe. 

Kontakt 515093223

Przesyłka przepłata +transport 12 zł 
Wystawiam Fakturę VAT', 
            120, 'PLN', 'PL', 'czesc', NULL, 
            'https://xqsdepmtejvnngcnrklk.supabase.co/storage/v1/object/public/r107/d3f74509-6547-4fe9-8fda-1dfa85cba763/0_1767287556438.jpg', NULL, NULL, NULL, NULL, 
            NULL, NULL, NULL, NULL, 
            'c87ad35b-63e1-4aa8-934a-09ab95359f3b', '2026-01-01T17:12:36.311505+00:00', '2026-01-06T20:53:26.925+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'ff7be936-3922-4f55-9ed7-13a8d844fff3', 'rss', 'approved', '1978 Mercedes Benz 450 SL', '• Rare Gray exterior over Red leather interior combo
 • Runs and drives – invested ~$6,500 in recent shop work (receipts in hand)
 • Includes removable hardtop + soft top frame (soft top needs replacement)
 • 4.5L V8, automatic transmission
 • Only 105k miles – low for age
 • Garage-stored for years before being revived

⸻

🛠️ Recent Work
 • Brought out of long-term storage
 • ~$6,500 in professional mechanical work to get it running and driving
 • Starts, runs, shifts, and drives under its own power

⸻

🔧 What It Still Needs
 • Exhaust system (current one has holes, car runs loud)
 • New tires
 • Soft top replacement
 • Cosmetic restoration (paint fade, rust spots, interior wear)

⸻

🎯 The Opportunity

This 450SL is a complete, running project. Perfect candidate for full restoration — this one already has the expensive work done to get it on the road again.

⸻

💵 Price: $6,400 OBO — Open to reasonable offers.
📞 Message me here on Marketplace if interested.', 
            NULL, 'USD', 'US', 'pojazd', 'https://hartford.craigslist.org/cto/d/windsor-locks-1978-mercedes-benz-450-sl/7906955830.html', 
            'https://images.craigslist.org/01212_jDdW0MvYao7_0CI0t2_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', 'f0b1a8c9724eeedb44a7598364a31b75', true, 'Zgłoszenie dotyczy modelu R107 450SL z 1978 roku.', 
            '450SL', 'R107', 1978, 1978, 
            NULL, '2026-01-07T20:09:38.042547+00:00', '2026-01-06T21:18:05+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '38e0bcaa-86d3-4a16-af0c-e1e3b4314927', 'rss', 'approved', 'Używany Mercedes-Benz SL 1972 - 41 999 PLN, 67 462 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            41999, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HpqGX.html?reason=listing', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InVzZnEycW41emZ5bzItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.nxoC_9Kicnk47tEF0qV3Ucrb0AEA8Bw9cKABguLK0PQ/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '45d63f7858136a721e86ccd45a352842', true, 'Model SL z lat 1971-1989, cena w PLN', 
            'SL', 'R107', 1972, 1972, 
            NULL, '2026-01-07T20:10:38.538852+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '4adb1113-720d-4260-a68f-7b2a3ae6f3cd', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1973 - 47 900 PLN, 56 000 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            47900, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6HGGBL.html?reason=listing', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6Im4zdjVhY2hxeWo5cC1PVE9NT1RPUEwiLCJ3IjpbeyJmbiI6IndnNGducXA2eTFmLU9UT01PVE9QTCIsInMiOiIxNiIsImEiOiIwIiwicCI6IjEwLC0xMCJ9XX0.JAWC3B8ojq9O5DFnihZXxoMYeY6r_mWBOsMmk3gnN4w/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '51d79be35318ddcd23151a84dc29c455', true, 'Model SLC z lat 1971-1989, cena w PLN', 
            'SLC', 'C107', 1973, 1973, 
            NULL, '2026-01-07T20:10:40.607386+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'fdace731-6aa7-4ac6-9d66-7d67f74cc557', 'rss', 'approved', 'Używany Mercedes-Benz SL 1972 - 74 900 PLN, 45 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            74900, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HuLXs.html?reason=listing', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6IjE5dGM3Mmlla2ZoZy1PVE9NT1RPUEwiLCJ3IjpbeyJmbiI6IndnNGducXA2eTFmLU9UT01PVE9QTCIsInMiOiIxNiIsImEiOiIwIiwicCI6IjEwLC0xMCJ9XX0.gQ56iRSpHkfuAkMEKZwh7ThCeIaWmVc8i1fu3Xjt-sI/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '33cdeabe0a4fe727c7161dbb4fb99d46', true, 'Model SL z lat 1971-1989, cena w PLN', 
            'SL', 'R107', 1972, 1972, 
            NULL, '2026-01-07T20:10:47.197923+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '1796ecc8-35ea-4f9f-86ac-7a00402545d1', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1980 - 99 000 PLN, 122 200 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            99000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6HwStx.html?reason=listing', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6InY1cm5sZGtoZDNlMzEtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.Tm0GKFWDrKviGy0AcKEA9rx0bHBE6yrXImCe95r1UP4/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'c979800d7b3ee063412c1d82a2f3cc80', true, 'Model SLC z lat 1971-1989, cena w PLN', 
            'SLC', 'C107', 1980, 1980, 
            NULL, '2026-01-07T20:10:57.366746+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'a269f216-2150-4c60-8091-850d25bf30ef', 'rss', 'approved', 'Używany Mercedes-Benz SL 1978 - 69 900 PLN, 140 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            69900, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HPpA2.html?reason=listing', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6IjJkYXV0YnBnY3g0MjItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.8XFdNFg8sOW1pCkVjH3zJQ33IwsaDoyJVXmaw2Agsts/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '08ba1c1def365e08e6d4586163a8b431', true, 'Model SL z 1978 roku, cena w PLN', 
            'SL', 'R107', 1978, 1978, 
            NULL, '2026-01-07T20:11:04.112896+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '211bdde4-0335-4b61-a5f6-7afb8cc78bcb', 'rss', 'approved', 'Używany Mercedes-Benz SLC 1973 - 31 000 PLN, 169 000 km', 'Interesuje Cię Mercedes-Benz SLC? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            31000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-slc-ID6HPPsV.html?reason=listing', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6IjVsdWE4M2Ztd2h3bTItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.zinVHgdwl227zJKaJvwECAoMHkGgqgbBLpjK5qQHSv0/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '5ca6a0d5f854bf16b5424434583afaa3', true, 'Model SLC z lat 1971-1989, cena w PLN.', 
            'SLC', 'C107', 1973, 1973, 
            NULL, '2026-01-07T20:11:11.30967+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '034a2a1c-730b-4cca-a33e-e92161c729b6', 'rss', 'approved', 'Używany Mercedes-Benz SL 1971 - 424 000 PLN, 103 855 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            424000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HMTwx.html?reason=listing', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6ImpoenRqZDdsYWtoczMtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.Y7UzlGU4Mb95w5XfmfHzxn00Cr782UZTW1fwEt12K9I/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'de14ad4630522fd31669171e32825136', true, 'Model SL z 1971 roku jest zgodny z wymaganiami.', 
            'SL', 'R107', 1971, 1971, 
            NULL, '2026-01-07T20:11:13.677893+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '652c82a2-c313-4c04-9112-da979cf1e5bb', 'rss', 'approved', '1977 Mercedes 450 SL Convertible', '1977 Mercedes 450 SL Convertible

Garage kept, excellent condition
Low miles, collector maintained', 
            NULL, 'USD', 'US', 'pojazd', 'https://delaware.craigslist.org/cto/d/wilmington-1977-mercedes-450-sl/7906497630.html', 
            'https://images.craigslist.org/00q0q_sC7RhBYs3M_0ak07K_600x450.jpg', 'bfbc6ae8-18f1-44d7-919e-5aaa997e9e40', '319c06b703688cccb063eda933258f97', true, 'Zgodny model R107 i cena w tytule.', 
            '450SL', 'R107', 1977, 1977, 
            NULL, '2026-01-12T14:23:17.329276+00:00', '2026-01-04T20:40:14+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '6cb86d8c-7482-4889-b569-cb6ffe52c082', 'rss', 'approved', '1985 Mercedes Benz 380 SL', 'For sale is a 1985 Mercedes-Benz 380SL , convertible , with hard top . This Mercedes is 8 cylinder , 3.8 litre , automatic transmission , cruise control , and power windows . The miles are 29000 . This car is creme with a tan interior . The price is $29500.00 plus tax , title , and applicable fees . Call today for more information ! We are a used car dealer . 

M&M Inc of York 
2875 East Prospect Rd
York , Pa 17402

717-755-3841', 
            29500, 'USD', 'DE', 'pojazd', 'https://york.craigslist.org/ctd/d/york-1985-mercedes-benz-380-sl/7907604603.html', 
            'https://images.craigslist.org/00m0m_90UqGfNKAzR_0pO0jm_600x450.jpg', 'f38285ab-dfdc-4464-85a4-f9a2a1dbe093', 'd9405252d0ef759fa25796a0195d53b4', true, 'Model R107 380SL z lat 1981-1989, cena podana w tytule.', 
            '380SL', 'R107', 1985, 1985, 
            NULL, '2026-01-12T14:24:27.67213+00:00', '2026-01-09T20:51:56+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '98c5aa35-7e05-4360-b12c-da80456a2e55', 'rss', 'approved', 'No Reserve: Original-Owner 1986 Mercedes-Benz 560SL', 'Bid for the chance to own a No Reserve: Original-Owner 1986 Mercedes-Benz 560SL at auction with Bring a Trailer, the home of the best vintage and classic cars online. Lot #226,878.', 
            NULL, 'USD', 'US', 'pojazd', 'https://bringatrailer.com/listing/1986-mercedes-benz-560sl-387/', 
            'https://bringatrailer.com/wp-content/uploads/2025/12/1986_mercedes-benz_560sl_1986_mercedes-benz_560sl_c536c0e1-4ef5-479f-bee2-942f81c1c0d1-zHxJ8d-41114-41115-scaled.jpg?fit=2048,1365', 'eacd6bf7-1eac-4673-b307-7207d3e8d1b6', '6747d4694cb2e9fe312c52adbe5a77f0', true, 'Model R107 560SL z lat 1986', 
            '560SL', 'R107', 1986, 1986, 
            NULL, '2026-01-12T14:24:45.139997+00:00', '2026-01-03T00:00:00+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '09ee39f7-05b9-422f-868b-55c79823c210', 'rss', 'approved', 'No Reserve: 1979 Mercedes-Benz 450SL', 'Bid for the chance to own a No Reserve: 1979 Mercedes-Benz 450SL at auction with Bring a Trailer, the home of the best vintage and classic cars online. Lot #226,828.', 
            NULL, 'USD', 'US', 'pojazd', 'https://bringatrailer.com/listing/1979-mercedes-benz-450sl-166/', 
            'https://bringatrailer.com/wp-content/uploads/2025/12/1979_mercedes-benz_450sl_IMG_1876-32408-scaled.jpg?fit=2048,1365', 'eacd6bf7-1eac-4673-b307-7207d3e8d1b6', 'f0c2713d9e74e616c8c24355697aec24', true, 'Model R107 450SL z lat 1971-1989, cena nie została podana.', 
            '450SL', 'R107', 1979, 1979, 
            NULL, '2026-01-12T14:24:47.976332+00:00', '2026-01-03T00:00:00+00:00'
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            'd2e35491-b84c-4a67-a9a8-ea83f0f4d481', 'rss', 'approved', 'Używany Mercedes-Benz SL 1983 - 77 000 PLN, 159 200 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            77000, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6HuSRU.html?reason=listing', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6Im9lYjU3M3ZzbDl4ZzItT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.flbYQM3gPXB_lAZj5N_XSO7O_p76CLMR9PvCcKo0tFw/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', 'fdc03875d8ab0c082eca9c8fcdffbc48', true, 'Model SL z lat 1981-1989, cena w PLN', 
            'SL', 'R107', 1983, 1983, 
            NULL, '2026-01-12T14:25:15.339884+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            '22d1cf78-ec80-4b67-be6a-db5d1bbd22a6', 'rss', 'approved', 'Używany Mercedes-Benz SL 1977 - 119 900 PLN, 158 000 km', 'Interesuje Cię Mercedes-Benz SL? Sprawdź ofertę dostępną teraz na OTOMOTO. Poznaj szczegółowe informacje o wyposażeniu, stanie technicznym, historii i cenie.', 
            119900, 'PLN', 'PL', 'pojazd', 'https://www.otomoto.pl/osobowe/oferta/mercedes-benz-sl-ID6H285j.html?reason=listing', 
            'https://ireland.apollo.olxcdn.com/v1/files/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmbiI6Inhwb2xzeHBoYWJxZDEtT1RPTU9UT1BMIiwidyI6W3siZm4iOiJ3ZzRnbnFwNnkxZi1PVE9NT1RPUEwiLCJzIjoiMTYiLCJhIjoiMCIsInAiOiIxMCwtMTAifV19.kwoh6aQIPJkgAYVCN9HhRhPVgBQ8oUlY9PDDt9dOgaQ/image', 'dfb9cd36-600b-45e1-ae21-6876808f75ce', '066c390547fcfa89d4a6cd4bba703dac', true, 'Model SL z lat 1971-1989, cena w PLN', 
            'SL', NULL, 1977, 1977, 
            NULL, '2026-01-12T14:25:16.045813+00:00', NULL
        ) ON CONFLICT (id) DO NOTHING;
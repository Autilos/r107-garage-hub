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
  ('Dodatkowy Feed R107', 'https://rss.app/feed/GdyKzGIfWkzs4rBm', 'PL', true);
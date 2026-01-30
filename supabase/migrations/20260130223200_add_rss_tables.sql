-- Create RSS sources table
CREATE TABLE IF NOT EXISTS public.rss_sources (
    id uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    created_at timestamptz DEFAULT now(),
    name text NOT NULL,
    url text NOT NULL,
    country text DEFAULT 'US'::text,
    enabled boolean DEFAULT true,
    last_check timestamptz,
    error_count int DEFAULT 0,
    last_error text
);

-- Add RSS-specific columns to listings table
ALTER TABLE public.listings ADD COLUMN IF NOT EXISTS source_type text DEFAULT 'manual'::text;
ALTER TABLE public.listings ADD COLUMN IF NOT EXISTS rss_source_id uuid REFERENCES public.rss_sources(id);
ALTER TABLE public.listings ADD COLUMN IF NOT EXISTS rss_guid text;
ALTER TABLE public.listings ADD COLUMN IF NOT EXISTS llm_ok boolean;
ALTER TABLE public.listings ADD COLUMN IF NOT EXISTS llm_reason text;
ALTER TABLE public.listings ADD COLUMN IF NOT EXISTS published_at timestamptz;

-- Add default RSS source
INSERT INTO public.rss_sources (name, url, country, enabled)
VALUES ('RSS App Feed - R107/C107', 'https://rss.app/feeds/MLAHiY1CyylzVJHT.xml', 'US', true)
ON CONFLICT DO NOTHING;

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_listings_rss_guid ON public.listings(rss_source_id, rss_guid);
CREATE INDEX IF NOT EXISTS idx_listings_source_type ON public.listings(source_type);
CREATE INDEX IF NOT EXISTS idx_listings_published_at ON public.listings(published_at DESC);

-- Add RLS policies
ALTER TABLE public.rss_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read rss_sources" ON public.rss_sources
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Admin manage rss_sources" ON public.rss_sources
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid()
            AND ur.role = 'admin'
        )
    );
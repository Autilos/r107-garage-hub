-- Add default RSS source for R107/C107 listings
-- Production database schema: url, country, active (not feed_url, country_default, enabled)
INSERT INTO public.rss_sources (name, url, country, active)
VALUES ('RSS App Feed - R107/C107', 'https://rss.app/feeds/MLAHiY1CyylzVJHT', 'US', true)
ON CONFLICT DO NOTHING;

-- Create table for repair videos (YouTube links)
CREATE TABLE public.repair_videos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    category_slug text NOT NULL,
    video_id text NOT NULL,
    title text NOT NULL,
    subcategory text,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.repair_videos ENABLE ROW LEVEL SECURITY;

-- Anyone can view videos
CREATE POLICY "Anyone can view repair videos"
ON public.repair_videos
FOR SELECT
USING (true);

-- Only admins can manage videos
CREATE POLICY "Admins can manage repair videos"
ON public.repair_videos
FOR ALL
USING (is_admin());

-- Create index for faster lookups
CREATE INDEX idx_repair_videos_category ON public.repair_videos(category_slug);

-- Insert existing videos from static data
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES
-- Radio category
('radio', 'L_rMTrwDcis', 'Antena R107 - naprawa', 'Antena', 0),
('radio', 'H93IUJlB5R0', 'Antena R107 - demontaż', 'Antena', 1),
('radio', '-jG0uz1fA_g', 'Antena R107 - montaż', 'Antena', 2),
('radio', '4sEIf49E0KU', 'Głośniki R107 - wymiana', 'Głośniki', 3),
('radio', 'DABVqcgAEOI', 'Radio Becker - serwis', 'Radio', 4),
-- Lusterka category
('lusterka', '2eI_oAstiWA', 'Naprawa lusterek bocznych R107', NULL, 0),
('lusterka', '4qqCftr_kzg', 'Demontaż i montaż lusterek', NULL, 1),
('lusterka', 'La_6nCFNiuc', 'Lusterka R107 - regulacja', NULL, 2),
('lusterka', '1ZqN9TpU810', 'Lusterka R107 - renowacja', NULL, 3);
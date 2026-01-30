-- Create table for spare parts per repair category
CREATE TABLE public.repair_parts (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  category_slug TEXT NOT NULL,
  content_html TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add unique constraint on category_slug (one parts section per category)
ALTER TABLE public.repair_parts ADD CONSTRAINT repair_parts_category_slug_unique UNIQUE (category_slug);

-- Enable RLS
ALTER TABLE public.repair_parts ENABLE ROW LEVEL SECURITY;

-- Anyone can view parts
CREATE POLICY "Anyone can view repair parts"
ON public.repair_parts
FOR SELECT
USING (true);

-- Only admins can manage parts
CREATE POLICY "Admins can manage repair parts"
ON public.repair_parts
FOR ALL
USING (is_admin());

-- Create trigger for updated_at
CREATE TRIGGER update_repair_parts_updated_at
BEFORE UPDATE ON public.repair_parts
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
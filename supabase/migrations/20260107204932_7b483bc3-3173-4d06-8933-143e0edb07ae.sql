-- Rename articles table to articles_r107
ALTER TABLE public.articles RENAME TO articles_r107;

-- Update RLS policies (they are automatically renamed with the table, but we need to ensure they still work)
-- Drop and recreate policies with proper references
DROP POLICY IF EXISTS "Admins can manage articles" ON public.articles_r107;
DROP POLICY IF EXISTS "Anyone can view published articles" ON public.articles_r107;

CREATE POLICY "Admins can manage articles_r107"
ON public.articles_r107
FOR ALL
USING (is_admin());

CREATE POLICY "Anyone can view published articles_r107"
ON public.articles_r107
FOR SELECT
USING (is_published = true);
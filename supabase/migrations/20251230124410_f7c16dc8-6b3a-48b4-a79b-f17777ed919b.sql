-- Drop the permissive policy that allows anyone to view RSS sources
DROP POLICY IF EXISTS "Anyone can view enabled RSS sources" ON public.rss_sources;

-- Create new policy: only admins can view RSS sources
CREATE POLICY "Only admins can view RSS sources" ON public.rss_sources
FOR SELECT USING (is_admin());
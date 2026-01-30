-- Temporarily allow INSERT for anon role
CREATE POLICY "Allow anon insert for migration" ON public.repair_videos
    FOR INSERT 
    USING (true)
    WITH CHECK (true);

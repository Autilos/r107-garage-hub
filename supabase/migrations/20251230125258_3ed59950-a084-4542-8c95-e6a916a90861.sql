-- Drop the permissive policy that allows anyone to view all profiles
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;

-- Create new policy: users can only view their own profile, admins can view all
CREATE POLICY "Users can view own profile or admin" ON public.profiles
FOR SELECT USING (auth.uid() = id OR is_admin());
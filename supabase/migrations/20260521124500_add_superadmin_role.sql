-- 1. Update check constraint on profiles.role
ALTER TABLE public.profiles 
DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles 
ADD CONSTRAINT profiles_role_check 
CHECK (role IN ('superadmin', 'admin', 'kader'));

-- 2. Update reports policy to include superadmin
DROP POLICY IF EXISTS "Admins can view and update all reports." ON public.reports;
CREATE POLICY "Admins and superadmins can view and update all reports." ON public.reports FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'superadmin'))
);

-- 3. Update interventions policy to include superadmin
DROP POLICY IF EXISTS "Admins can manage interventions." ON public.interventions;
CREATE POLICY "Admins and superadmins can manage interventions." ON public.interventions FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'superadmin'))
);

-- 4. Add policy for superadmins to manage all profiles
DROP POLICY IF EXISTS "Superadmins can manage all profiles" ON public.profiles;
CREATE POLICY "Superadmins can manage all profiles" ON public.profiles FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'superadmin')
);

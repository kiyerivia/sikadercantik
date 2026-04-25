-- 1. Create Tables for Geographical Hierarchy
CREATE TABLE villages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE rws (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id UUID REFERENCES villages(id) ON DELETE CASCADE,
    rw_number VARCHAR(10) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE posyandus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rw_id UUID REFERENCES rws(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Profiles Table (Linked to Auth Users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'kader')),
    posyandu_id UUID REFERENCES posyandus(id),
    phone_number TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Master Data for Mosquito Breeding Places
CREATE TABLE mosquito_breeding_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create Reports Table
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kader_id UUID REFERENCES profiles(id) NOT NULL,
    posyandu_id UUID REFERENCES posyandus(id) NOT NULL,
    report_date DATE NOT NULL DEFAULT CURRENT_DATE,
    houses_inspected INTEGER NOT NULL CHECK (houses_inspected >= 0),
    houses_positive INTEGER NOT NULL CHECK (houses_positive <= houses_inspected),
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('draft', 'submitted', 'verified', 'need_intervention', 'completed')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Junction Table for Report and Breeding Places
CREATE TABLE report_breeding_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID REFERENCES reports(id) ON DELETE CASCADE,
    breeding_place_id UUID REFERENCES mosquito_breeding_places(id) ON DELETE CASCADE
);

-- 6. Create Interventions Table
CREATE TABLE interventions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID REFERENCES reports(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('kunjungan_rumah', 'psn_ulang', 'penyuluhan')),
    description TEXT NOT NULL,
    admin_id UUID REFERENCES profiles(id) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE villages ENABLE ROW LEVEL SECURITY;
ALTER TABLE rws ENABLE ROW LEVEL SECURITY;
ALTER TABLE posyandus ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE mosquito_breeding_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_breeding_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE interventions ENABLE ROW LEVEL SECURITY;

-- POLICIES
CREATE POLICY "Public villages are viewable by everyone." ON villages FOR SELECT USING (true);
CREATE POLICY "Public rws are viewable by everyone." ON rws FOR SELECT USING (true);
CREATE POLICY "Public posyandus are viewable by everyone." ON posyandus FOR SELECT USING (true);
CREATE POLICY "Public profiles are viewable by everyone." ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile." ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Kader can insert their own reports." ON reports FOR INSERT WITH CHECK (auth.uid() = kader_id);
CREATE POLICY "Kader can view their own reports." ON reports FOR SELECT USING (auth.uid() = kader_id);
CREATE POLICY "Admins can view and update all reports." ON reports FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Breeding places are viewable by everyone." ON mosquito_breeding_places FOR SELECT USING (true);
CREATE POLICY "Report junction viewable by everyone." ON report_breeding_places FOR SELECT USING (true);
CREATE POLICY "Admins can manage interventions." ON interventions FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

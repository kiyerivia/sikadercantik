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
    tahun_pendirian TEXT,
    alamat TEXT,
    nama_ketua TEXT,
    nomor_hp TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
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

-- POLICIES (Master Data)
CREATE POLICY "Public villages viewable by everyone." ON villages FOR SELECT USING (true);
CREATE POLICY "Public rws viewable by everyone." ON rws FOR SELECT USING (true);
CREATE POLICY "Public posyandus viewable by everyone." ON posyandus FOR SELECT USING (true);
CREATE POLICY "Public mosquito breeding places viewable by everyone." ON mosquito_breeding_places FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert villages." ON villages FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert rws." ON rws FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert posyandus." ON posyandus FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- POLICIES (Example: Profiles)
CREATE POLICY "Public profiles are viewable by everyone." ON profiles FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert profiles." ON profiles FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Users can update own profile." ON profiles FOR UPDATE USING (auth.uid() = id OR auth.role() = 'authenticated');

-- POLICIES (Example: Report Junctions)
CREATE POLICY "Report junction viewable by everyone." ON report_breeding_places FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert report junctions." ON report_breeding_places FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- POLICIES (Example: Reports)
CREATE POLICY "Public reports viewable by everyone." ON reports FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert reports." ON reports FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Kader can update their own reports." ON reports FOR UPDATE USING (auth.uid() = kader_id OR auth.role() = 'authenticated');
CREATE POLICY "Admins can view and update all reports." ON reports FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- POLICIES (Interventions)
CREATE POLICY "Admins can do everything with interventions." ON interventions FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Kader can view interventions for their reports." ON interventions FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM reports 
        WHERE reports.id = interventions.report_id 
        AND reports.kader_id = auth.uid()
    )
);

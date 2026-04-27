-- SQL Script to Populate Master Data based on Google Form
-- Execute this in your Supabase SQL Editor

-- 1. Clear existing master data (Optional, be careful with foreign keys)
-- TRUNCATE villages, mosquito_breeding_places CASCADE;

-- 2. Insert Villages (Desa)
INSERT INTO villages (name) VALUES 
('Cilangkap'),
('Cihonje'),
('Paningkaban'),
('Karangkemojing'),
('Gancang'),
('Kedungurang'),
('Gumelar'),
('Tlaga'),
('Samudra'),
('Samudra Kulon');

-- 3. Insert Breeding Places (Tempat Positif Jentik)
-- Clear existing first if needed
DELETE FROM mosquito_breeding_places;
INSERT INTO mosquito_breeding_places (name) VALUES
('Bak Kamar Mandi'),
('Tempayan'),
('Pecahan Botol/Air Kemasan'),
('Barang Bekas'),
('Kulkas/Dispenser'),
('Tandon Air'),
('Vas Bunga'),
('Pot Bunga'),
('Lain-lain');

-- 4. Insert Sample RWs and Posyandus for each Village
-- This part creates 1 RW and 2 Posyandus for every village inserted above
DO $$
DECLARE
    v_record RECORD;
    v_rw_id UUID;
BEGIN
    FOR v_record IN SELECT id, name FROM villages LOOP
        -- Create RW 01 for each village
        INSERT INTO rws (village_id, rw_number) 
        VALUES (v_record.id, '001') 
        RETURNING id INTO v_rw_id;

        -- Create 2 sample Posyandus for that RW
        INSERT INTO posyandus (rw_id, name) VALUES
        (v_rw_id, 'Posyandu ' || v_record.name || ' 1'),
        (v_rw_id, 'Posyandu ' || v_record.name || ' 2');
    END LOOP;
END $$;

-- SEED DATA FOR SIKADERCANTIK

-- 1. Seed Villages
INSERT INTO villages (id, name) VALUES 
('e00d753b-f633-4f10-9171-888878901234', 'Desa Sukamaju'),
('f11d753b-f633-4f10-9171-888878901234', 'Kelurahan Harapan Baru');

-- 2. Seed RWs
INSERT INTO rws (id, village_id, rw_number) VALUES
('a001753b-f633-4f10-9171-888878901234', 'e00d753b-f633-4f10-9171-888878901234', '001'),
('a002753b-f633-4f10-9171-888878901234', 'e00d753b-f633-4f10-9171-888878901234', '002'),
('b001753b-f633-4f10-9171-888878901234', 'f11d753b-f633-4f10-9171-888878901234', '005');

-- 3. Seed Posyandus
INSERT INTO posyandus (id, rw_id, name) VALUES
('p001753b-f633-4f10-9171-888878901234', 'a001753b-f633-4f10-9171-888878901234', 'Posyandu Mawar 1'),
('p002753b-f633-4f10-9171-888878901234', 'a001753b-f633-4f10-9171-888878901234', 'Posyandu Mawar 2'),
('p003753b-f633-4f10-9171-888878901234', 'a002753b-f633-4f10-9171-888878901234', 'Posyandu Melati'),
('p004753b-f633-4f10-9171-888878901234', 'b001753b-f633-4f10-9171-888878901234', 'Posyandu Anggrek');

-- 4. Seed Mosquito Breeding Places
INSERT INTO mosquito_breeding_places (name) VALUES
('Bak Mandi'),
('Vas Bunga'),
('Ban Bekas'),
('Tempayan'),
('Kaleng Bekas'),
('Dispenser'),
('Tatakan Kulkas'),
('Lubang Pohon'),
('Lainnya');

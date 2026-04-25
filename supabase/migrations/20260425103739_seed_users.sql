-- 1. Bersihkan data lama jika ada untuk UUID ini
DELETE FROM auth.users WHERE id IN ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380b22');

-- 2. Buat Akun Admin (admin@test.com / password123)
INSERT INTO auth.users (
    id, 
    aud, 
    role, 
    email, 
    encrypted_password, 
    email_confirmed_at, 
    raw_app_meta_data, 
    raw_user_meta_data, 
    created_at, 
    updated_at, 
    confirmation_token, 
    recovery_token, 
    email_change_token_new, 
    email_change
)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'authenticated',
    'authenticated',
    'admin@test.com',
    extensions.crypt('password123', extensions.gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    '{"full_name": "Admin Seeder"}',
    now(), now(), '', '', '', ''
);

-- 3. Buat Akun Kader (kader@test.com / password123)
INSERT INTO auth.users (
    id, 
    aud, 
    role, 
    email, 
    encrypted_password, 
    email_confirmed_at, 
    raw_app_meta_data, 
    raw_user_meta_data, 
    created_at, 
    updated_at, 
    confirmation_token, 
    recovery_token, 
    email_change_token_new, 
    email_change
)
VALUES (
    'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380b22',
    'authenticated',
    'authenticated',
    'kader@test.com',
    extensions.crypt('password123', extensions.gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    '{"full_name": "Kader Seeder"}',
    now(), now(), '', '', '', ''
);

-- 4. Pastikan Profile terhubung
INSERT INTO profiles (id, full_name, role)
VALUES 
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Admin Seeder', 'admin'),
('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380b22', 'Siti Kader', 'kader')
ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role;

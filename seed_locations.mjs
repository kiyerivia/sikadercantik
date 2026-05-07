import { getVillages } from 'idn-area-data';
import dotenv from 'dotenv';

// Load environment variables from .env
dotenv.config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('Error: SUPABASE_URL and SUPABASE_ANON_KEY must be defined in .env');
  process.exit(1);
}

/**
 * Script ini akan mengambil data Desa dari idn-area-data 
 * dan memasukkannya ke tabel 'villages' di Supabase.
 */
async function seedVillages() {
  // Default: Kecamatan Gumelar (Banyumas) = 33.02.21
  const districtCode = '33.02.21'; 
  
  console.log(`🔍 Mengambil data desa untuk Kecamatan dengan kode: ${districtCode}...`);
  
  try {
    const villages = await getVillages(districtCode);
    console.log(`✅ Berhasil mengambil ${villages.length} desa.`);

    for (const v of villages) {
      // Format nama dari package biasanya UPPERCASE, kita ubah jadi Title Case agar rapi
      const formattedName = v.name.split(' ').map(word => 
        word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
      ).join(' ');

      console.log(`🚀 Memasukkan desa: ${formattedName} (${v.code})...`);

      const response = await fetch(`${SUPABASE_URL}/rest/v1/villages`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates' // Memerlukan unique constraint di DB
        },
        body: JSON.stringify({ 
          name: formattedName,
          // code: v.code // Aktifkan jika Anda sudah menambah kolom 'code' di tabel villages
        })
      });

      if (!response.ok) {
        const error = await response.text();
        console.error(`❌ Gagal memasukkan ${formattedName}:`, error);
      } else {
        console.log(`✨ ${formattedName} berhasil diproses.`);
      }
    }

    console.log('\n🏁 Selesai! Semua desa telah diproses.');
  } catch (error) {
    console.error('💥 Terjadi kesalahan:', error);
  }
}

seedVillages();

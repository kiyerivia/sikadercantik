import 'dart:io';
import 'dart:convert';

void main() async {
  // 1. Baca .env secara manual
  print('📝 Membaca konfigurasi .env...');
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ Error: File .env tidak ditemukan!');
    return;
  }

  final envLines = envFile.readAsLinesSync();
  String? supabaseUrl;
  String? supabaseKey;

  for (var line in envLines) {
    if (line.contains('=')) {
      final parts = line.split('=');
      final key = parts[0].trim();
      final value = parts.sublist(1).join('=').trim();
      if (key == 'SUPABASE_URL') supabaseUrl = value;
      if (key == 'SUPABASE_ANON_KEY') supabaseKey = value;
    }
  }

  if (supabaseUrl == null || supabaseKey == null) {
    print('❌ Error: SUPABASE_URL atau SUPABASE_ANON_KEY tidak ditemukan di .env');
    return;
  }

  // 2. Download data dari GitHub idn-area-data
  // Kita coba branch 'main' karena 'master' sudah deprecated di banyak repo
  String villagesCsvUrl = 'https://raw.githubusercontent.com/fshangala/idn-area-data/main/data/villages.csv';
  // Fallback URL jika URL utama gagal
  const String fallbackUrl = 'https://raw.githubusercontent.com/fityannugroho/idn-area-data/main/data/villages.csv';
  
  final targetDistrictCode = '33.02.21'; // Kode Kecamatan Gumelar

  print('📡 Men-download data desa dari GitHub...');
  final client = HttpClient();
  
  try {
    var request = await client.getUrl(Uri.parse(villagesCsvUrl));
    var response = await request.close();
    
    if (response.statusCode == 404) {
      print('⚠️ URL utama 404, mencoba URL cadangan...');
      request = await client.getUrl(Uri.parse(fallbackUrl));
      response = await request.close();
    }

    if (response.statusCode != 200) {
      print('❌ Gagal download data. Status: ${response.statusCode}');
      return;
    }

    final contents = await response.transform(utf8.decoder).join();
    final lines = const LineSplitter().convert(contents);
    print('✅ Berhasil mendownload ${lines.length} baris data.');

    int count = 0;
    print('🚀 Memproses data untuk Kecamatan Gumelar ($targetDistrictCode)...');

    for (var line in lines) {
      final columns = line.split(',');
      if (columns.length < 3) continue;

      final districtCode = columns[1].trim();
      final name = columns[2].trim().replaceAll('"', '');

      if (districtCode == targetDistrictCode) {
        // Format Title Case
        final formattedName = name.split(' ').map((s) {
          if (s.isEmpty) return '';
          return s[0].toUpperCase() + s.substring(1).toLowerCase();
        }).join(' ');

        print('➕ Menambahkan: $formattedName...');

        final postRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/villages'));
        postRequest.headers.set('apikey', supabaseKey);
        postRequest.headers.set('Authorization', 'Bearer $supabaseKey');
        postRequest.headers.set('Content-Type', 'application/json');
        postRequest.headers.set('Prefer', 'resolution=merge-duplicates');
        
        postRequest.write(jsonEncode({'name': formattedName}));
        
        final postResponse = await postRequest.close();
        if (postResponse.statusCode <= 204) {
          count++;
        } else {
          final errorBody = await postResponse.transform(utf8.decoder).join();
          print('⚠️ Gagal insert $formattedName: $errorBody');
        }
      }
    }

    print('\n🏁 SELESAI!');
    print('✨ $count desa berhasil dimasukkan ke database.');
    print('Sikadercantik makin cantik dengan data resmi! 😎');

  } catch (e) {
    print('💥 Terjadi kesalahan: $e');
  } finally {
    client.close();
  }
}

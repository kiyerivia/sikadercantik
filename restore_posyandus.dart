import 'dart:convert';
import 'dart:io';

void main() async {
  print('📝 Membaca konfigurasi .env...');
  final envFile = File('.env');
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

  final client = HttpClient();

  try {
    print('🧹 Membersihkan Posyandu yang tidak ada laporannya...');
    
    // Kita pakai SQL via REST API: delete where id not in reports
    // Tapi karena Supabase REST terbatas untuk subquery, kita ambil ID yang ada laporannya dulu.
    final reportReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/reports?select=posyandu_id'));
    reportReq.headers.set('apikey', supabaseKey);
    reportReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final reportRes = await reportReq.close();
    final reportBody = await reportRes.transform(utf8.decoder).join();
    final List reports = jsonDecode(reportBody);
    final Set<String> posyanduWithReports = reports.map((r) => r['posyandu_id'].toString()).toSet();

    // Ambil semua posyandu
    final posyanduReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?select=id,name'));
    posyanduReq.headers.set('apikey', supabaseKey);
    posyanduReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final posyanduRes = await posyanduReq.close();
    final posyanduBody = await posyanduRes.transform(utf8.decoder).join();
    final List allPosyandus = jsonDecode(posyanduBody);

    int deletedCount = 0;
    for (var p in allPosyandus) {
      final id = p['id'].toString();
      if (!posyanduWithReports.contains(id)) {
        final delReq = await client.deleteUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?id=eq.$id'));
        delReq.headers.set('apikey', supabaseKey);
        delReq.headers.set('Authorization', 'Bearer $supabaseKey');
        await delReq.close();
        deletedCount++;
      }
    }
    print('✅ Berhasil menghapus $deletedCount posyandu kosong.');

    // Restore Data Asli
    print('🚀 Memasukkan kembali data Posyandu asli...');
    // ... (Data originalData sama seperti sebelumnya)
    final List<Map<String, String>> originalData = [
      {'desa': 'Cilangkap', 'rw': '1', 'posyandu': 'Posyandu Bina Sejahtera 1'},
      {'desa': 'Cilangkap', 'rw': '2', 'posyandu': 'Posyandu Bina Sejahtera 2'},
      {'desa': 'Cilangkap', 'rw': '3', 'posyandu': 'Posyandu Bina Sejahtera 3'},
      {'desa': 'Cilangkap', 'rw': '4', 'posyandu': 'Posyandu Bina Sejahtera 4'},
      {'desa': 'Cilangkap', 'rw': '5', 'posyandu': 'Posyandu Bina Sejahtera 5'},
      {'desa': 'Cilangkap', 'rw': '6', 'posyandu': 'Posyandu Bina Sejahtera 6'},
      {'desa': 'Cihonje', 'rw': '2', 'posyandu': 'Posyandu Dahlia 1'},
      {'desa': 'Cihonje', 'rw': '3', 'posyandu': 'Posyandu Melati'},
      {'desa': 'Cihonje', 'rw': '7', 'posyandu': 'Posyandu Puji Lestari'},
      {'desa': 'Cihonje', 'rw': '8', 'posyandu': 'Posyandu Dahlia 2'},
      {'desa': 'Cihonje', 'rw': '9', 'posyandu': 'Posyandu Cempaka'},
      {'desa': 'Cihonje', 'rw': '13', 'posyandu': 'Posyandu Boby Lestari'},
      {'desa': 'Cihonje', 'rw': '12', 'posyandu': 'Posyandu Budi Sasono 1'},
      {'desa': 'Cihonje', 'rw': '18', 'posyandu': 'Posyandu Regil Rahayu'},
      {'desa': 'Cihonje', 'rw': '16', 'posyandu': 'Posyandu Wijaya Kusuma'},
      {'desa': 'Cihonje', 'rw': '17', 'posyandu': 'Posyandu Budi Sasono 2'},
      {'desa': 'Cihonje', 'rw': '14', 'posyandu': 'Posyandu Laksono Utomo'},
      {'desa': 'Paningkaban', 'rw': '1', 'posyandu': 'Posyandu Jatiwaluyo'},
      {'desa': 'Paningkaban', 'rw': '2', 'posyandu': 'Posyandu Widodo'},
      {'desa': 'Paningkaban', 'rw': '3', 'posyandu': 'Posyandu Lestari'},
      {'desa': 'Paningkaban', 'rw': '4', 'posyandu': 'Posyandu Rahayu'},
      {'desa': 'Karangkemojing', 'rw': '1', 'posyandu': 'Posyandu Sari Asih'},
      {'desa': 'Karangkemojing', 'rw': '2', 'posyandu': 'Posyandu Mardi Siwi'},
      {'desa': 'Karangkemojing', 'rw': '2', 'posyandu': 'Posyandu Pamardi Siwi'},
      {'desa': 'Karangkemojing', 'rw': '3', 'posyandu': 'Posyandu Mekar Sari'},
      {'desa': 'Karangkemojing', 'rw': '3', 'posyandu': 'Posyandu Mugi Lestari'},
      {'desa': 'Karangkemojing', 'rw': '4', 'posyandu': 'Posyandu Karya Lestari'},
      {'desa': 'Karangkemojing', 'rw': '4', 'posyandu': 'Posyandu Basuki'},
      {'desa': 'Gancang', 'rw': '1', 'posyandu': 'Posyandu Tunas Bangsa 1'},
      {'desa': 'Gancang', 'rw': '4', 'posyandu': 'Posyandu Tunas Bangsa 2'},
      {'desa': 'Gancang', 'rw': '5', 'posyandu': 'Posyandu Tunas Bangsa 3'},
      {'desa': 'Gancang', 'rw': '2', 'posyandu': 'Posyandu Tunas Bangsa 4'},
      {'desa': 'Gancang', 'rw': '5', 'posyandu': 'Posyandu Tunas Bangsa 5'},
      {'desa': 'Gancang', 'rw': '3', 'posyandu': 'Posyandu Tunas Bangsa 6'},
      {'desa': 'Kedungurang', 'rw': '4', 'posyandu': 'Posyandu Taman Sari'},
      {'desa': 'Kedungurang', 'rw': '1', 'posyandu': 'Posyandu Mawar'},
      {'desa': 'Kedungurang', 'rw': '7', 'posyandu': 'Posyandu Melati'},
      {'desa': 'Kedungurang', 'rw': '6', 'posyandu': 'Posyandu Sanggar Sari'},
      {'desa': 'Kedungurang', 'rw': '2', 'posyandu': 'Posyandu Laju Sejahtera'},
      {'desa': 'Kedungurang', 'rw': '8', 'posyandu': 'Posyandu Mugi Rahayu'},
      {'desa': 'Kedungurang', 'rw': '3', 'posyandu': 'Posyandu Mugi Lestari'},
      {'desa': 'Gumelar', 'rw': '1', 'posyandu': 'Posyandu Bina Laju Sejahtera 1'},
      {'desa': 'Gumelar', 'rw': '2', 'posyandu': 'Posyandu Bina Laju Sejahtera 2'},
      {'desa': 'Gumelar', 'rw': '3', 'posyandu': 'Posyandu Bina Laju Sejahtera 3'},
      {'desa': 'Gumelar', 'rw': '4', 'posyandu': 'Posyandu Bina Laju Sejahtera 4'},
      {'desa': 'Gumelar', 'rw': '5', 'posyandu': 'Posyandu Bina Laju Sejahtera 5'},
      {'desa': 'Gumelar', 'rw': '6', 'posyandu': 'Posyandu Bina Laju Sejahtera 6'},
      {'desa': 'Gumelar', 'rw': '7', 'posyandu': 'Posyandu Bina Laju Sejahtera 7'},
      {'desa': 'Gumelar', 'rw': '8', 'posyandu': 'Posyandu Bina Laju Sejahtera 8'},
      {'desa': 'Gumelar', 'rw': '9', 'posyandu': 'Posyandu Bina Laju Sejahtera 9'},
      {'desa': 'Gumelar', 'rw': '10', 'posyandu': 'Posyandu Bina Laju Sejahtera 10'},
      {'desa': 'Gumelar', 'rw': '11', 'posyandu': 'Posyandu Bina Laju Sejahtera 11'},
      {'desa': 'Tlaga', 'rw': '1', 'posyandu': 'Posyandu Balita Rahayu 1'},
      {'desa': 'Tlaga', 'rw': '2', 'posyandu': 'Posyandu Balita Rahayu 2'},
      {'desa': 'Tlaga', 'rw': '3', 'posyandu': 'Posyandu Balita Rahayu 3'},
      {'desa': 'Tlaga', 'rw': '4', 'posyandu': 'Posyandu Balita Rahayu 4'},
      {'desa': 'Tlaga', 'rw': '5', 'posyandu': 'Posyandu Balita Rahayu 5'},
      {'desa': 'Tlaga', 'rw': '6', 'posyandu': 'Posyandu Balita Rahayu 6'},
      {'desa': 'Tlaga', 'rw': '7', 'posyandu': 'Posyandu Balita Rahayu 7'},
      {'desa': 'Tlaga', 'rw': '8', 'posyandu': 'Posyandu Balita Rahayu 8'},
      {'desa': 'Samudra', 'rw': '1', 'posyandu': 'Posyandu Harapan Bangsa 1'},
      {'desa': 'Samudra', 'rw': '2', 'posyandu': 'Posyandu Harapan Bangsa 2'},
      {'desa': 'Samudra', 'rw': '3', 'posyandu': 'Posyandu Harapan Bangsa 3'},
      {'desa': 'Samudra', 'rw': '4', 'posyandu': 'Posyandu Harapan Bangsa 4'},
      {'desa': 'Samudra', 'rw': '5', 'posyandu': 'Posyandu Harapan Bangsa 5'},
      {'desa': 'Samudra', 'rw': '6', 'posyandu': 'Posyandu Harapan Bangsa 6'},
      {'desa': 'Samudra', 'rw': '7', 'posyandu': 'Posyandu Harapan Bangsa 7'},
      {'desa': 'Samudra', 'rw': '8', 'posyandu': 'Posyandu Harapan Bangsa 8'},
      {'desa': 'Samudra Kulon', 'rw': '1', 'posyandu': 'Posyandu Mawar'},
      {'desa': 'Samudra Kulon', 'rw': '2', 'posyandu': 'Posyandu Budi Asih'},
      {'desa': 'Samudra Kulon', 'rw': '3', 'posyandu': 'Posyandu Kasih Ibu'},
      {'desa': 'Samudra Kulon', 'rw': '4', 'posyandu': 'Posyandu Anak Sehat'},
      {'desa': 'Samudra Kulon', 'rw': '5', 'posyandu': 'Posyandu Sayang Anak'},
    ];

    // Ambil data desa terbaru
    final vReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/villages?select=id,name'));
    vReq.headers.set('apikey', supabaseKey);
    vReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final vRes = await vReq.close();
    final List villages = jsonDecode(await vRes.transform(utf8.decoder).join());
    Map<String, String> villageMap = { for (var v in villages) v['name'].toString().toUpperCase() : v['id'] };

    for (var item in originalData) {
      final vName = item['desa']!.toUpperCase();
      final villageId = villageMap[vName];
      if (villageId == null) continue;

      // Cek/Insert RW
      final rwNum = item['rw']!;
      final getRw = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/rws?village_id=eq.$villageId&rw_number=eq.$rwNum&select=id'));
      getRw.headers.set('apikey', supabaseKey);
      getRw.headers.set('Authorization', 'Bearer $supabaseKey');
      final getRwRes = await getRw.close();
      final rwList = jsonDecode(await getRwRes.transform(utf8.decoder).join());
      String rwId;
      if (rwList.isEmpty) {
        final postRw = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/rws'));
        postRw.headers.set('apikey', supabaseKey);
        postRw.headers.set('Authorization', 'Bearer $supabaseKey');
        postRw.headers.set('Content-Type', 'application/json');
        postRw.headers.set('Prefer', 'return=representation');
        postRw.write(jsonEncode({'village_id': villageId, 'rw_number': rwNum}));
        final postRwRes = await postRw.close();
        rwId = jsonDecode(await postRwRes.transform(utf8.decoder).join())[0]['id'];
      } else {
        rwId = rwList[0]['id'];
      }

      // Insert Posyandu (Upsert based on name & rw_id)
      final pName = item['posyandu']!;
      final postP = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus'));
      postP.headers.set('apikey', supabaseKey);
      postP.headers.set('Authorization', 'Bearer $supabaseKey');
      postP.headers.set('Content-Type', 'application/json');
      postP.headers.set('Prefer', 'resolution=merge-duplicates');
      postP.write(jsonEncode({'rw_id': rwId, 'name': pName}));
      await postP.close();
      print('➕ Restore: $pName');
    }
    print('🏁 SELESAI! Data sudah kembali rapi.');
  } finally {
    client.close();
  }
}

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

  if (supabaseUrl == null || supabaseKey == null) {
    print('❌ Gagal membaca konfigurasi .env');
    return;
  }

  final client = HttpClient();

  try {
    print('🚀 Memulai sinkronisasi data Posyandu...');

    final List<Map<String, String>> newData = [
      // Cilangkap
      {'desa': 'Cilangkap', 'rw': '1', 'posyandu': 'Posyandu Bina Sejahtera 1', 'tahun': '2017', 'alamat': 'Cilangkap Rt 2 Rw 1', 'ketua': 'Tasirem', 'hp': '0813 2745 8225'},
      {'desa': 'Cilangkap', 'rw': '2', 'posyandu': 'Posyandu Bina Sejahtera 2', 'tahun': '1993', 'alamat': 'Cilangkap Rt 3 Rw 2', 'ketua': 'Solimah', 'hp': '0812 1546 4313'},
      {'desa': 'Cilangkap', 'rw': '3', 'posyandu': 'Posyandu Bina Sejahtera 3', 'tahun': '1985', 'alamat': 'Cilangkap Rt 3 Rw 3', 'ketua': 'Sukini', 'hp': '0812 2528 5581'},
      {'desa': 'Cilangkap', 'rw': '4', 'posyandu': 'Posyandu Bina Sejahtera 4', 'tahun': '1982', 'alamat': 'Cilangkap Rt 3 Rw 4', 'ketua': 'Hernowati', 'hp': '0822 4204 4349'},
      {'desa': 'Cilangkap', 'rw': '5', 'posyandu': 'Posyandu Bina Sejahtera 5', 'tahun': '2006', 'alamat': 'Cilangkap Rt 4 Rw 5', 'ketua': 'Kustini', 'hp': '0823 2490 7637'},
      {'desa': 'Cilangkap', 'rw': '6', 'posyandu': 'Posyandu Bina Sejahtera 6', 'tahun': '2012', 'alamat': 'Cilangkap Rt 1 Rw 6', 'ketua': 'Dwi Wiyanti', 'hp': '0812 2991 4302'},
      // Cihonje
      {'desa': 'Cihonje', 'rw': '2', 'posyandu': 'Posyandu Dahlia 1', 'tahun': '1996', 'alamat': 'Cihonje Rt 3 Rw 2', 'ketua': 'Rusinah', 'hp': '0852 9302 7093'},
      {'desa': 'Cihonje', 'rw': '3', 'posyandu': 'Posyandu Melati', 'tahun': '1995', 'alamat': 'Cihonje Rt 3 Rw 3', 'ketua': 'Winarsih', 'hp': '0857 1213 5929'},
      {'desa': 'Cihonje', 'rw': '7', 'posyandu': 'Posyandu Puji Lestari', 'tahun': '1986', 'alamat': 'Cihonje Rt 1 Rw 7', 'ketua': 'Diyah Astuti', 'hp': '0858 0080 4315'},
      {'desa': 'Cihonje', 'rw': '8', 'posyandu': 'Posyandu Dahlia 2', 'tahun': '1985', 'alamat': 'Cihonje Rt 1 Rw 8', 'ketua': 'Komsiyati', 'hp': ''},
      {'desa': 'Cihonje', 'rw': '9', 'posyandu': 'Posyandu Cempaka', 'tahun': '1985', 'alamat': 'Cihonje Rt 3 Rw 9', 'ketua': 'Ria Supriyatin', 'hp': '0888 8282 7062'},
      {'desa': 'Cihonje', 'rw': '13', 'posyandu': 'Posyandu Boby Lestari', 'tahun': '1998', 'alamat': 'Cihonje Rt 2 Rw 13', 'ketua': 'Maryanti', 'hp': '0853 2854 0810'},
      {'desa': 'Cihonje', 'rw': '12', 'posyandu': 'Posyandu Budi Sasono 1', 'tahun': '1990', 'alamat': 'Cihonje Rt 1 Rw 12', 'ketua': 'Rumiyati', 'hp': ''},
      {'desa': 'Cihonje', 'rw': '18', 'posyandu': 'Posyandu Regil Rahayu', 'tahun': '1992', 'alamat': 'Cihonje Rt 3 Rw 18', 'ketua': 'Kustini', 'hp': '0812 3127 1652'},
      {'desa': 'Cihonje', 'rw': '16', 'posyandu': 'Posyandu Wijaya Kusuma', 'tahun': '1986', 'alamat': 'Cihonje Rt 3 Rw 16', 'ketua': 'Turyati', 'hp': '0857 0184 1631'},
      {'desa': 'Cihonje', 'rw': '17', 'posyandu': 'Posyandu Budi Sasono 2', 'tahun': '1992', 'alamat': 'Cihonje Rt 2 Rw 17', 'ketua': 'Kuswati', 'hp': '0852 2742 4893'},
      {'desa': 'Cihonje', 'rw': '14', 'posyandu': 'Posyandu Laksono Utomo', 'tahun': '1976', 'alamat': 'Cihonje Rt 3 Rw 14', 'ketua': 'Suminah', 'hp': '0852 4022 0855'},
      // Paningkaban
      {'desa': 'Paningkaban', 'rw': '1', 'posyandu': 'Posyandu Jatiwaluyo', 'tahun': '1986', 'alamat': 'Paningkaban Rt 4 Rw 1', 'ketua': 'Sri Setiowati', 'hp': '0852 2677 5619'},
      {'desa': 'Paningkaban', 'rw': '2', 'posyandu': 'Posyandu Widodo', 'tahun': '1982', 'alamat': 'Paningkaban Rt 1 Rw 2', 'ketua': 'Kasini', 'hp': '0858 1987 0314'},
      {'desa': 'Paningkaban', 'rw': '3', 'posyandu': 'Posyandu Lestari', 'tahun': '1985', 'alamat': 'Paningkaban Rt 2 Rw 3', 'ketua': 'Kustiyah', 'hp': '0857 4782 0428'},
      {'desa': 'Paningkaban', 'rw': '4', 'posyandu': 'Posyandu Rahayu', 'tahun': '1982', 'alamat': 'Paningkaban Rt 3 Rw 4', 'ketua': 'Kamiyah', 'hp': '0857 2621 0114'},
      // Karangkemojing
      {'desa': 'Karangkemojing', 'rw': '1', 'posyandu': 'Posyandu Sari Asih', 'tahun': '', 'alamat': 'Karangkemojing Rt 1 Rw 1', 'ketua': '', 'hp': ''},
      {'desa': 'Karangkemojing', 'rw': '2', 'posyandu': 'Posyandu Mardi Siwi', 'tahun': '', 'alamat': 'Karangkemojing Rt 1 Rw 2', 'ketua': '', 'hp': ''},
      {'desa': 'Karangkemojing', 'rw': '2', 'posyandu': 'Posyandu Pamardi Siwi', 'tahun': '', 'alamat': 'Karangkemojing Rt 5 Rw 2', 'ketua': '', 'hp': ''},
      {'desa': 'Karangkemojing', 'rw': '3', 'posyandu': 'Posyandu Mekar Sari', 'tahun': '', 'alamat': 'Karangkemojing Rt 5 Rw 3', 'ketua': '', 'hp': ''},
      {'desa': 'Karangkemojing', 'rw': '3', 'posyandu': 'Posyandu Mugi Lestari', 'tahun': '', 'alamat': 'Karangkemojing Rt 7 Rw 3', 'ketua': '', 'hp': ''},
      {'desa': 'Karangkemojing', 'rw': '4', 'posyandu': 'Posyandu Karya Lestari', 'tahun': '', 'alamat': 'Karangkemojing Rt 2 Rw 4', 'ketua': '', 'hp': ''},
      {'desa': 'Karangkemojing', 'rw': '4', 'posyandu': 'Posyandu Basuki', 'tahun': '', 'alamat': 'Karangkemojing Rt 7 Rw 4', 'ketua': '', 'hp': ''},
      // Gancang
      {'desa': 'Gancang', 'rw': '1', 'posyandu': 'Posyandu Tunas Bangsa 1', 'tahun': '1985', 'alamat': 'Gancang Rt 2 Rw 1', 'ketua': 'Erni Wahyuningsih', 'hp': '0815 4714 4210'},
      {'desa': 'Gancang', 'rw': '4', 'posyandu': 'Posyandu Tunas Bangsa 2', 'tahun': '1985', 'alamat': 'Gancang Rt 2 Rw 4', 'ketua': 'Darsini', 'hp': '0857 4729 9144'},
      {'desa': 'Gancang', 'rw': '5', 'posyandu': 'Posyandu Tunas Bangsa 3', 'tahun': '1992', 'alamat': 'Gancang Rt 3 Rw 5', 'ketua': 'Wasinah', 'hp': '0813 5748 4395'},
      {'desa': 'Gancang', 'rw': '2', 'posyandu': 'Posyandu Tunas Bangsa 4', 'tahun': '1985', 'alamat': 'Gancang Rt 2 Rw 2', 'ketua': 'Muslimah', 'hp': '0813 2812 5893'},
      {'desa': 'Gancang', 'rw': '5', 'posyandu': 'Posyandu Tunas Bangsa 5', 'tahun': '1985', 'alamat': 'Gancang Rt 3 Rw 5', 'ketua': 'Sukapti', 'hp': '0858 6658 2651'},
      {'desa': 'Gancang', 'rw': '3', 'posyandu': 'Posyandu Tunas Bangsa 6', 'tahun': '1985', 'alamat': 'Gancang Rt 3 Rw 3', 'ketua': 'Wasmiati', 'hp': '0857 2632 5325'},
      // Kedungurang
      {'desa': 'Kedungurang', 'rw': '4', 'posyandu': 'Posyandu Taman Sari', 'tahun': '1990', 'alamat': 'Kedungurang Rt 1 Rw 4', 'ketua': 'Warsiyati', 'hp': '0852 2709 8055'},
      {'desa': 'Kedungurang', 'rw': '1', 'posyandu': 'Posyandu Mawar', 'tahun': '1990', 'alamat': 'Kedungurang Rt 3 Rw 1', 'ketua': 'Sumini', 'hp': '0858 7515 2107'},
      {'desa': 'Kedungurang', 'rw': '7', 'posyandu': 'Posyandu Melati', 'tahun': '2017', 'alamat': 'Kedungurang Rt 1 Rw 7', 'ketua': 'Marsita', 'hp': '0852 9292 3624'},
      {'desa': 'Kedungurang', 'rw': '6', 'posyandu': 'Posyandu Sanggar Sari', 'tahun': '2005', 'alamat': 'Kedungurang Rt 1 Rw 6', 'ketua': 'Dalilah', 'hp': '0852 2902 3383'},
      {'desa': 'Kedungurang', 'rw': '2', 'posyandu': 'Posyandu Laju Sejahtera', 'tahun': '1986', 'alamat': 'Kedungurang Rt 3 Rw 2', 'ketua': 'Komariyah', 'hp': '0852 9283 3627'},
      {'desa': 'Kedungurang', 'rw': '8', 'posyandu': 'Posyandu Mugi Rahayu', 'tahun': '1986', 'alamat': 'Kedungurang Rt 1 Rw 8', 'ketua': 'Nurussolihah', 'hp': '0853 2728 9220'},
      {'desa': 'Kedungurang', 'rw': '3', 'posyandu': 'Posyandu Mugi Lestari', 'tahun': '1999', 'alamat': 'Kedungurang Rt 1 Rw 3', 'ketua': 'Rokhani', 'hp': '0813 2863 6037'},
      // Gumelar
      {'desa': 'Gumelar', 'rw': '1', 'posyandu': 'Posyandu Bina Laju Sejahtera 1', 'tahun': '', 'alamat': 'Gumelar Rt 2 Rw 1', 'ketua': '', 'hp': ''},
      {'desa': 'Gumelar', 'rw': '2', 'posyandu': 'Posyandu Bina Laju Sejahtera 2', 'tahun': '', 'alamat': 'Gumelar Rt 1 Rw 2', 'ketua': '', 'hp': ''},
      {'desa': 'Gumelar', 'rw': '3', 'posyandu': 'Posyandu Bina Laju Sejahtera 3', 'tahun': '', 'alamat': 'Gumelar Rt 3 Rw 3', 'ketua': '', 'hp': ''},
      {'desa': 'Gumelar', 'rw': '4', 'posyandu': 'Posyandu Bina Laju Sejahtera 4', 'tahun': '', 'alamat': 'Gumelar Rt 4 Rw 4', 'ketua': '', 'hp': ''},
      {'desa': 'Gumelar', 'rw': '5', 'posyandu': 'Posyandu Bina Laju Sejahtera 5', 'tahun': '', 'alamat': 'Gumelar Rt 5 Rw 5', 'ketua': '', 'hp': ''},
      {'desa': 'Gumelar', 'rw': '6', 'posyandu': 'Posyandu Bina Laju Sejahtera 6', 'tahun': '', 'alamat': 'Gumelar Rt 4 Rw 6', 'ketua': '', 'hp': ''},
      {'desa': 'Gumelar', 'rw': '7', 'posyandu': 'Posyandu Bina Laju Sejahtera 7', 'tahun': '', 'alamat': 'Gumelar Rt 1 Rw 7', 'ketua': '', 'hp': ''},
      {'desa': 'Gumelar', 'rw': '8', 'posyandu': 'Posyandu Bina Laju Sejahtera 8', 'tahun': '', 'alamat': 'Gumelar Rt 1 Rw 8', 'ketua': '', 'hp': ''},
      {'desa': 'Gumelar', 'rw': '9', 'posyandu': 'Posyandu Bina Laju Sejahtera 9', 'tahun': '', 'alamat': 'Gumelar Rt 6 Rw 9', 'ketua': '', 'hp': ''},
      {'desa': 'Gumelar', 'rw': '10', 'posyandu': 'Posyandu Bina Laju Sejahtera 10', 'tahun': '', 'alamat': 'Gumelar Rt 2 Rw 10', 'ketua': '', 'hp': ''},
      {'desa': 'Gumelar', 'rw': '11', 'posyandu': 'Posyandu Bina Laju Sejahtera 11', 'tahun': '', 'alamat': 'Gumelar Rt 2 Rw 11', 'ketua': '', 'hp': ''},
      // Tlaga
      {'desa': 'Tlaga', 'rw': '1', 'posyandu': 'Posyandu Balita Rahayu 1', 'tahun': '1979', 'alamat': 'Tlaga Rt 3 Rw 1', 'ketua': 'Asmiyah', 'hp': '0812 1096 785'},
      {'desa': 'Tlaga', 'rw': '2', 'posyandu': 'Posyandu Balita Rahayu 2', 'tahun': '1991', 'alamat': 'Tlaga Rt 3 Rw 2', 'ketua': 'Maryam', 'hp': '0813 2981 1340'},
      {'desa': 'Tlaga', 'rw': '3', 'posyandu': 'Posyandu Balita Rahayu 3', 'tahun': '1979', 'alamat': 'Tlaga Rt 4 Rw 3', 'ketua': 'Sri Wahyuni', 'hp': '0823 2639 4311'},
      {'desa': 'Tlaga', 'rw': '4', 'posyandu': 'Posyandu Balita Rahayu 4', 'tahun': '1993', 'alamat': 'Tlaga Rt 1 Rw 4', 'ketua': 'Wurjiyanti', 'hp': '0823 2840 5560'},
      {'desa': 'Tlaga', 'rw': '5', 'posyandu': 'Posyandu Balita Rahayu 5', 'tahun': '1993', 'alamat': 'Tlaga Rt 1 Rw 5', 'ketua': 'Tasidah', 'hp': '0812 2689 4663'},
      {'desa': 'Tlaga', 'rw': '6', 'posyandu': 'Posyandu Balita Rahayu 6', 'tahun': '1986', 'alamat': 'Tlaga Rt 1 Rw 6', 'ketua': 'Muryani', 'hp': '0895 4294 9633'},
      {'desa': 'Tlaga', 'rw': '7', 'posyandu': 'Posyandu Balita Rahayu 7', 'tahun': '1989', 'alamat': 'Tlaga Rt 1 Rw 7', 'ketua': 'Praptiningsih', 'hp': '0836 1540 8183'},
      {'desa': 'Tlaga', 'rw': '8', 'posyandu': 'Posyandu Balita Rahayu 8', 'tahun': '1977', 'alamat': 'Tlaga Rt 3 Rw 8', 'ketua': 'Darsiah', 'hp': '0852 9108 0203'},
      // Samudra
      {'desa': 'Samudra', 'rw': '1', 'posyandu': 'Posyandu Harapan Bangsa 1', 'tahun': '', 'alamat': 'Samudra Rt 2 Rw 1', 'ketua': '', 'hp': ''},
      {'desa': 'Samudra', 'rw': '2', 'posyandu': 'Posyandu Harapan Bangsa 2', 'tahun': '', 'alamat': 'Samudra Rt 2 Rw 2', 'ketua': '', 'hp': ''},
      {'desa': 'Samudra', 'rw': '3', 'posyandu': 'Posyandu Harapan Bangsa 3', 'tahun': '', 'alamat': 'Samudra Rt 2 Rw 3', 'ketua': '', 'hp': ''},
      {'desa': 'Samudra', 'rw': '4', 'posyandu': 'Posyandu Harapan Bangsa 4', 'tahun': '', 'alamat': 'Samudra Rt 2 Rw 4', 'ketua': '', 'hp': ''},
      {'desa': 'Samudra', 'rw': '5', 'posyandu': 'Posyandu Harapan Bangsa 5', 'tahun': '', 'alamat': 'Samudra Rt 2 Rw 5', 'ketua': '', 'hp': ''},
      {'desa': 'Samudra', 'rw': '6', 'posyandu': 'Posyandu Harapan Bangsa 6', 'tahun': '', 'alamat': 'Samudra Rt 2 Rw 6', 'ketua': '', 'hp': ''},
      {'desa': 'Samudra', 'rw': '7', 'posyandu': 'Posyandu Harapan Bangsa 7', 'tahun': '', 'alamat': 'Samudra Rt 2 Rw 7', 'ketua': '', 'hp': ''},
      {'desa': 'Samudra', 'rw': '8', 'posyandu': 'Posyandu Harapan Bangsa 8', 'tahun': '', 'alamat': 'Samudra Rt 2 Rw 8', 'ketua': '', 'hp': ''},
      // Samudra Kulon
      {'desa': 'Samudra Kulon', 'rw': '1', 'posyandu': 'Posyandu Mawar', 'tahun': '2005', 'alamat': 'Samudra Kulon Rt 2 Rw 1', 'ketua': 'Paryati', 'hp': '0812 2820 0869'},
      {'desa': 'Samudra Kulon', 'rw': '2', 'posyandu': 'Posyandu Budi Asih', 'tahun': '2005', 'alamat': 'Samudra Kulon Rt 4 Rw 4', 'ketua': 'Titin Kurniasih', 'hp': '0823 1635 8226'},
      {'desa': 'Samudra Kulon', 'rw': '3', 'posyandu': 'Posyandu Kasih Ibu', 'tahun': '2005', 'alamat': 'Samudra Kulon Rt 5 Rw 3', 'ketua': 'Ratiyah', 'hp': '0813 3131 2326'},
      {'desa': 'Samudra Kulon', 'rw': '4', 'posyandu': 'Posyandu Anak Sehat', 'tahun': '2005', 'alamat': 'Samudra Kulon Rt 3 Rw 4', 'ketua': 'Watini', 'hp': '0812 2616 1635'},
      {'desa': 'Samudra Kulon', 'rw': '5', 'posyandu': 'Posyandu Sayang Anak', 'tahun': '2005', 'alamat': 'Samudra Kulon Rt 3 Rw 5', 'ketua': 'Tasini', 'hp': '0857 0193 4232'},
    ];

    // Ambil data desa terbaru
    final vReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/villages?select=id,name'));
    vReq.headers.set('apikey', supabaseKey);
    vReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final vRes = await vReq.close();
    final List villages = jsonDecode(await vRes.transform(utf8.decoder).join());
    Map<String, String> villageMap = { for (var v in villages) v['name'].toString().toUpperCase() : v['id'] };

    // Untuk melacak Posyandu yang ada di data baru (untuk pembersihan nanti jika perlu)
    Set<String> processedPosyanduNames = {};

    for (var item in newData) {
      final vName = item['desa']!.toUpperCase();
      var villageId = villageMap[vName];
      
      if (villageId == null) {
        print('➕ Menambahkan desa baru: ${item['desa']}');
        final postV = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/villages'));
        postV.headers.set('apikey', supabaseKey);
        postV.headers.set('Authorization', 'Bearer $supabaseKey');
        postV.headers.set('Content-Type', 'application/json');
        postV.headers.set('Prefer', 'return=representation');
        postV.write(jsonEncode({'name': item['desa']}));
        final postVRes = await postV.close();
        final postVBody = await postVRes.transform(utf8.decoder).join();
        villageId = jsonDecode(postVBody)[0]['id'];
        villageMap[vName] = villageId!;
      }

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

      // Upsert Posyandu
      final pName = item['posyandu']!;
      final postP = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus'));
      postP.headers.set('apikey', supabaseKey);
      postP.headers.set('Authorization', 'Bearer $supabaseKey');
      postP.headers.set('Content-Type', 'application/json');
      postP.headers.set('Prefer', 'resolution=merge-duplicates');
      
      // Menggunakan nama kolom bahasa Indonesia sesuai DB
      postP.write(jsonEncode({
        'rw_id': rwId,
        'name': pName,
        'tahun_pendirian': item['tahun'],
        'alamat': item['alamat'],
        'nama_ketua': item['ketua'],
        'nomor_hp': item['hp'],
      }));
      await postP.close();
      print('✅ Tersinkron: $pName (${item['desa']})');
      processedPosyanduNames.add(pName);
    }

    print('🧹 Membersihkan Posyandu lama yang tidak ada di daftar baru dan tidak punya laporan...');
    // Logika pembersihan (optional, tapi baik untuk menjaga data tetap sinkron)
    final reportReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/reports?select=posyandu_id'));
    reportReq.headers.set('apikey', supabaseKey);
    reportReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final reportRes = await reportReq.close();
    final List reports = jsonDecode(await reportRes.transform(utf8.decoder).join());
    final Set<String> posyanduWithReports = reports.map((r) => r['posyandu_id'].toString()).toSet();

    final allPosyanduReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?select=id,name'));
    allPosyanduReq.headers.set('apikey', supabaseKey);
    allPosyanduReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final List allPosyandus = jsonDecode(await (await allPosyanduReq.close()).transform(utf8.decoder).join());

    int deletedCount = 0;
    for (var p in allPosyandus) {
      final name = p['name'].toString();
      final id = p['id'].toString();
      if (!processedPosyanduNames.contains(name) && !posyanduWithReports.contains(id)) {
        final delReq = await client.deleteUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?id=eq.$id'));
        delReq.headers.set('apikey', supabaseKey);
        delReq.headers.set('Authorization', 'Bearer $supabaseKey');
        await delReq.close();
        deletedCount++;
      }
    }
    
    print('✅ Berhasil menghapus $deletedCount posyandu usang.');
    print('🏁 SELESAI! Data sudah terupdate sesuai gambar.');

  } catch (e) {
    print('❌ Terjadi kesalahan: $e');
  } finally {
    client.close();
  }
}

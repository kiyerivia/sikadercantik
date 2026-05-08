import 'dart:convert';
import 'dart:io';

void main() async {
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
    final vReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/villages?select=id&name=eq.Samudra%20Kulon'));
    vReq.headers.set('apikey', supabaseKey!);
    vReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final vRes = await vReq.close();
    final vBody = await vRes.transform(utf8.decoder).join();
    final List villages = jsonDecode(vBody);
    final skId = villages[0]['id'];

    final rReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/rws?select=*&village_id=eq.$skId'));
    rReq.headers.set('apikey', supabaseKey);
    rReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final rRes = await rReq.close();
    final rBody = await rRes.transform(utf8.decoder).join();
    final List rws = jsonDecode(rBody);
    
    print('DEBUG: RWs in DB for Samudra Kulon:');
    for (var r in rws) {
      print(' - ID: ${r['id']} | rw_number: ${r['rw_number']} | type: ${r['rw_number'].runtimeType}');
    }

    final newData = [
      {'rw': '1', 'name': 'Posyandu Mawar'},
      {'rw': '2', 'name': 'Posyandu Budi Asih'},
      {'rw': '3', 'name': 'Posyandu Kasih Ibu'},
      {'rw': '4', 'name': 'Posyandu Anak Sehat'},
      {'rw': '5', 'name': 'Posyandu Sayang Anak'},
    ];

    for (var item in newData) {
      final rwMatch = rws.firstWhere((r) {
        final dbRw = r['rw_number'].toString();
        return dbRw == item['rw'];
      }, orElse: () => null);
      
      if (rwMatch != null) {
        final rwId = rwMatch['id'];
        final iReq = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus'));
        iReq.headers.set('apikey', supabaseKey);
        iReq.headers.set('Authorization', 'Bearer $supabaseKey');
        iReq.headers.set('Content-Type', 'application/json');
        iReq.add(utf8.encode(jsonEncode({
          'rw_id': rwId,
          'name': item['name'],
          'tahun_pendirian': 2000,
        })));
        await iReq.close();
        print('✅ Inserted: ${item['name']}');
      } else {
        print('❌ No match for RW ${item['rw']}');
      }
    }
  } finally {
    client.close();
  }
}

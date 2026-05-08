import 'dart:io';
import 'dart:convert';

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
    print('❌ SUPABASE_URL atau SUPABASE_ANON_KEY tidak ditemukan di .env');
    return;
  }

  final client = HttpClient();

  try {
    print('--- Village & Posyandu Audit ---');
    
    // Get all villages
    final vReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/villages?select=id,name&order=name'));
    vReq.headers.set('apikey', supabaseKey);
    vReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final vRes = await vReq.close();
    final vBody = await vRes.transform(utf8.decoder).join();
    final List villages = jsonDecode(vBody);

    for (var v in villages) {
      final vId = v['id'];
      final vName = v['name'];

      // Get posyandus for this village
      // Note: we need to join through rws
      final pReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?select=id,name,rws!inner(village_id)&rws.village_id=eq.$vId'));
      pReq.headers.set('apikey', supabaseKey);
      pReq.headers.set('Authorization', 'Bearer $supabaseKey');
      final pRes = await pReq.close();
      final pBody = await pRes.transform(utf8.decoder).join();
      final List posyandus = jsonDecode(pBody);

      print('Village: $vName ($vId) | Posyandu Count: ${posyandus.length}');
      if (posyandus.isEmpty) {
        print('  !!! MISSING POSYANDUS !!!');
      } else {
        for (var p in posyandus) {
          print('  - ${p['name']}');
        }
      }
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

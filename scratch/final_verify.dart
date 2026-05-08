import 'dart:io';
import 'dart:convert';

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

  final targetVillages = ['Cilangkap', 'Cihonje', 'Paningkaban', 'Gancang', 'Kedungurang', 'Tlaga', 'Samudra Kulon'];

  try {
    print('Verifying Posyandu Data for: $targetVillages');
    
    for (var vName in targetVillages) {
      final url = '$supabaseUrl/rest/v1/villages?select=id,name&name=eq.$vName';
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('apikey', supabaseKey!);
      req.headers.set('Authorization', 'Bearer $supabaseKey');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final List villages = jsonDecode(body);

      if (villages.isEmpty) {
        print('❌ Village NOT FOUND: $vName');
        continue;
      }

      final vId = villages[0]['id'];
      
      final pUrl = '$supabaseUrl/rest/v1/posyandus?select=name,rws!inner(village_id)&rws.village_id=eq.$vId';
      final pReq = await client.getUrl(Uri.parse(pUrl));
      pReq.headers.set('apikey', supabaseKey);
      pReq.headers.set('Authorization', 'Bearer $supabaseKey');
      final pRes = await pReq.close();
      final pBody = await pRes.transform(utf8.decoder).join();
      final List posyandus = jsonDecode(pBody);

      if (posyandus.isEmpty) {
        print('❌ POSYANDUS MISSING for $vName ($vId)');
      } else {
        print('✅ $vName: Found ${posyandus.length} posyandus');
      }
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

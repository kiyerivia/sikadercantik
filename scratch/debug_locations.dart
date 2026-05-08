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
    print('--- VILLAGES ---');
    final vReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/villages?select=id,name&order=name'));
    vReq.headers.set('apikey', supabaseKey!);
    vReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final vRes = await vReq.close();
    final vBody = await vRes.transform(utf8.decoder).join();
    final List villages = jsonDecode(vBody);
    for (var v in villages) {
      print('Village: ${v['name']} (ID: ${v['id']})');
    }

    print('\n--- POSYANDUS FOR SAMUDRA KULON ---');
    final samudraKulon = villages.firstWhere((v) => v['name'].toString().toLowerCase() == 'samudra kulon', orElse: () => null);
    if (samudraKulon != null) {
      final pReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?select=*,rws!inner(*)&rws.village_id=eq.${samudraKulon['id']}'));
      pReq.headers.set('apikey', supabaseKey);
      pReq.headers.set('Authorization', 'Bearer $supabaseKey');
      final pRes = await pReq.close();
      final pBody = await pRes.transform(utf8.decoder).join();
      final List posyandus = jsonDecode(pBody);
      print('Found ${posyandus.length} posyandus for Samudra Kulon');
      for (var p in posyandus) {
        print(' - ${p['name']} (RW: ${p['rws']['rw_number']})');
      }
    } else {
      print('Samudra Kulon not found!');
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

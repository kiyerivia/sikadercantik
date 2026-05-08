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
  final tlagaId = 'a5164b22-51ad-491a-9256-a932e95d82ac';

  try {
    print('--- Investigating Tlaga ($tlagaId) ---');
    
    // 1. Check RWs
    final rUrl = '$supabaseUrl/rest/v1/rws?select=*&village_id=eq.$tlagaId';
    final rReq = await client.getUrl(Uri.parse(rUrl));
    rReq.headers.set('apikey', supabaseKey!);
    rReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final rRes = await rReq.close();
    final rBody = await rRes.transform(utf8.decoder).join();
    final List rws = jsonDecode(rBody);
    print('RWs found: ${rws.length}');

    // 2. Check Posyandus via these RWs
    for (var rw in rws) {
      final rwId = rw['id'];
      final pUrl = '$supabaseUrl/rest/v1/posyandus?select=*&rw_id=eq.$rwId';
      final pReq = await client.getUrl(Uri.parse(pUrl));
      pReq.headers.set('apikey', supabaseKey);
      pReq.headers.set('Authorization', 'Bearer $supabaseKey');
      final pRes = await pReq.close();
      final pBody = await pRes.transform(utf8.decoder).join();
      final List posyandus = jsonDecode(pBody);
      print('  RW ${rw['rw_number']} Posyandus: ${posyandus.length}');
      for (var p in posyandus) {
        print('    - ${p['name']} (ID: ${p['id']})');
      }
    }

    // 3. Check POSYANDUS in reports that claim to be Tlaga
    print('\nChecking Posyandus from Reports:');
    final repUrl = '$supabaseUrl/rest/v1/reports?select=posyandu_id,posyandus(name,rw_id,rws(village_id))&limit=5';
    final repReq = await client.getUrl(Uri.parse(repUrl));
    repReq.headers.set('apikey', supabaseKey);
    repReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final repRes = await repReq.close();
    final repBody = await repRes.transform(utf8.decoder).join();
    final List reports = jsonDecode(repBody);
    for (var rep in reports) {
      print('  Report Posyandu: ${rep['posyandus']['name']}');
      print('    Village ID from DB: ${rep['posyandus']['rws']['village_id']}');
      print('    Target Tlaga ID: $tlagaId');
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

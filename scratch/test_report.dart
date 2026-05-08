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
    print('🧪 Submitting test report for Samudra Kulon...');
    
    // 1. Find Samudra Kulon village
    final vReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/villages?name=eq.Samudra%20Kulon&select=id'));
    vReq.headers.set('apikey', supabaseKey!);
    vReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final vRes = await vReq.close();
    final List villages = jsonDecode(await vRes.transform(utf8.decoder).join());
    if (villages.isEmpty) {
      print('❌ Village not found');
      return;
    }
    final vId = villages[0]['id'];

    // 2. Find a Posyandu in Samudra Kulon
    final pReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?select=*,rws!inner(*)&rws.village_id=eq.$vId&limit=1'));
    pReq.headers.set('apikey', supabaseKey);
    pReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final pRes = await pReq.close();
    final List posyandus = jsonDecode(await pRes.transform(utf8.decoder).join());
    if (posyandus.isEmpty) {
      print('❌ Posyandu not found');
      return;
    }
    final pId = posyandus[0]['id'];
    print('Found Posyandu: ${posyandus[0]['name']} (ID: $pId)');

    // 3. Get any user ID to act as kader
    final uReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/profiles?select=id&limit=1'));
    uReq.headers.set('apikey', supabaseKey);
    uReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final List profiles = jsonDecode(await (await uReq.close()).transform(utf8.decoder).join());
    if (profiles.isEmpty) {
      print('❌ No profiles found');
      return;
    }
    final uId = profiles[0]['id'];

    // 4. Submit report
    final postR = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/reports'));
    postR.headers.set('apikey', supabaseKey);
    postR.headers.set('Authorization', 'Bearer $supabaseKey');
    postR.headers.set('Content-Type', 'application/json');
    postR.write(jsonEncode({
      'kader_id': uId,
      'posyandu_id': pId,
      'houses_inspected': 10,
      'houses_positive': 2,
      'notes': 'Test report from script',
      'status': 'submitted',
      'report_date': DateTime.now().toIso8601String(),
    }));
    final res = await postR.close();
    if (res.statusCode == 201) {
      print('✅ Test report submitted successfully!');
    } else {
      print('❌ Failed to submit report: ${res.statusCode}');
      print(await res.transform(utf8.decoder).join());
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

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
    final vReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/villages?select=id,name'));
    vReq.headers.set('apikey', supabaseKey!);
    vReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final vRes = await vReq.close();
    final List villages = jsonDecode(await vRes.transform(utf8.decoder).join());
    
    Map<String, List<String>> nameToIds = {};
    for (var v in villages) {
      final name = v['name'].toString().toUpperCase();
      nameToIds.putIfAbsent(name, () => []).add(v['id']);
    }

    print('--- DUPLICATE VILLAGES ---');
    nameToIds.forEach((name, ids) {
      if (ids.length > 1) {
        print('Village "$name" has ${ids.length} entries: $ids');
      }
    });

    print('\n--- ALL VILLAGES (Sorted) ---');
    villages.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
    for (var v in villages) {
      print('${v['name']}');
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

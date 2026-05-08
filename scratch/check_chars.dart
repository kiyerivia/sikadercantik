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

  try {
    print('Checking for hidden characters in Village names...');
    final url = '$supabaseUrl/rest/v1/villages?select=id,name';
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('apikey', supabaseKey!);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final List villages = jsonDecode(body);

    for (var v in villages) {
      final name = v['name'] as String;
      if (name.contains('Samudra')) {
        print('Village: "$name" | Length: ${name.length} | Bytes: ${utf8.encode(name)}');
      }
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

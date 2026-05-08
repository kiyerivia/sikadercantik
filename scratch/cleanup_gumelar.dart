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
    print('🧹 Cleaning up Gumelar data...');

    // 1. Get all Posyandus
    final pReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?select=id,name,rw_id'));
    pReq.headers.set('apikey', supabaseKey!);
    pReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final pRes = await pReq.close();
    final List posyandus = jsonDecode(await pRes.transform(utf8.decoder).join());

    // 2. Get all reports to know which posyandus to keep
    final rReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/reports?select=posyandu_id'));
    rReq.headers.set('apikey', supabaseKey);
    rReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final rRes = await rReq.close();
    final List reports = jsonDecode(await rRes.transform(utf8.decoder).join());
    final Set<String> posyanduWithReports = reports.map((r) => r['posyandu_id'].toString()).toSet();

    // 3. Find duplicates
    Map<String, List<String>> nameRwToIds = {};
    for (var p in posyandus) {
      final key = '${p['name']}_${p['rw_id']}';
      nameRwToIds.putIfAbsent(key, () => []).add(p['id']);
    }

    int deletedCount = 0;
    for (var entry in nameRwToIds.entries) {
      final ids = entry.value;
      if (ids.length > 1) {
        // Keep one that has reports if possible
        String? toKeep;
        for (var id in ids) {
          if (posyanduWithReports.contains(id)) {
            toKeep = id;
            break;
          }
        }
        toKeep ??= ids[0];

        for (var id in ids) {
          if (id != toKeep) {
            if (posyanduWithReports.contains(id)) {
              print('⚠️ Cannot delete $id because it has reports even though it is a duplicate.');
              continue;
            }
            final delReq = await client.deleteUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?id=eq.$id'));
            delReq.headers.set('apikey', supabaseKey);
            delReq.headers.set('Authorization', 'Bearer $supabaseKey');
            await delReq.close();
            deletedCount++;
          }
        }
      }
    }
    print('✅ Deleted $deletedCount duplicate posyandus.');

    // 4. Do the same for RWs
    final rwReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/rws?select=id,rw_number,village_id'));
    rwReq.headers.set('apikey', supabaseKey);
    rwReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final List rws = jsonDecode(await (await rwReq.close()).transform(utf8.decoder).join());

    Map<String, List<String>> numVillageToIds = {};
    for (var rw in rws) {
      final key = '${rw['rw_number']}_${rw['village_id']}';
      numVillageToIds.putIfAbsent(key, () => []).add(rw['id']);
    }

    int deletedRwCount = 0;
    for (var entry in numVillageToIds.entries) {
      final ids = entry.value;
      if (ids.length > 1) {
        // Cek if any posyandus are linked to these RWs
        String? toKeep;
        for (var id in ids) {
          final checkP = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?rw_id=eq.$id&select=id&limit=1'));
          checkP.headers.set('apikey', supabaseKey);
          checkP.headers.set('Authorization', 'Bearer $supabaseKey');
          final List pList = jsonDecode(await (await checkP.close()).transform(utf8.decoder).join());
          if (pList.isNotEmpty) {
            toKeep = id;
            break;
          }
        }
        toKeep ??= ids[0];

        for (var id in ids) {
          if (id != toKeep) {
            final delReq = await client.deleteUrl(Uri.parse('$supabaseUrl/rest/v1/rws?id=eq.$id'));
            delReq.headers.set('apikey', supabaseKey);
            delReq.headers.set('Authorization', 'Bearer $supabaseKey');
            final res = await delReq.close();
            if (res.statusCode < 400) deletedRwCount++;
          }
        }
      }
    }
    print('✅ Deleted $deletedRwCount duplicate RWs.');

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/domain/models.dart';

class LocationManagementScreen extends ConsumerWidget {
  const LocationManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villagesAsync = ref.watch(villagesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F618D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/images/psn_logo_new.jpg', fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Text('SI KADER PSN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          PopupMenuButton<void>(
            onSelected: (_) async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            offset: const Offset(0, 50),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF1F618D), size: 20),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: villagesAsync.when(
        data: (villages) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: villages.length,
          itemBuilder: (context, index) {
            final village = villages[index];
            return _VillageExpandable(village: village);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Gagal memuat data: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement Add Village
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VillageExpandable extends ConsumerWidget {
  final Village village;

  const _VillageExpandable({required this.village});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(village.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.home_work_outlined),
        children: [
          _RWList(villageId: village.id),
        ],
      ),
    );
  }
}

class _RWList extends ConsumerWidget {
  final String villageId;

  const _RWList({required this.villageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rwsAsync = ref.watch(rwsProvider(villageId));

    return rwsAsync.when(
      data: (rws) => Column(
        children: rws.map((rw) => _RWExpandable(rw: rw)).toList(),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
      error: (e, s) => Text('Error: $e'),
    );
  }
}

class _RWExpandable extends ConsumerWidget {
  final RW rw;

  const _RWExpandable({required this.rw});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExpansionTile(
      title: Text('RW ${rw.rwNumber}'),
      leading: const Icon(Icons.groups_outlined),
      children: [
        _PosyanduList(rwId: rw.id),
      ],
    );
  }
}

class _PosyanduList extends ConsumerWidget {
  final String rwId;

  const _PosyanduList({required this.rwId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posyandusAsync = ref.watch(posyandusProvider(rwId));

    return posyandusAsync.when(
      data: (posyandus) => Column(
        children: posyandus
            .map((p) => ListTile(
                  title: Text(p.name),
                  leading: const Icon(Icons.local_hospital_outlined, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                ))
            .toList(),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => Text('Error: $e'),
    );
  }
}

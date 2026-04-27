import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/widgets/location_selector.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/auth_providers.dart';

class ReportFormScreen extends HookConsumerWidget {
  const ReportFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final housesInspectedController = useTextEditingController(text: '0');
    final housesPositiveController = useTextEditingController(text: '0');
    final kkNameController = useTextEditingController();
    final rtController = useTextEditingController();
    final rwController = useTextEditingController();
    final positivePlacesCountController = useTextEditingController(text: '0');
    
    final selectedVillageId = useState<String?>(null);
    final selectedPosyanduId = useState<String?>(null);
    final selectedResult = useState<String?>(null);
    final selectedPlaceId = useState<String?>(null);
    final reportDate = useState(DateTime.now());
    final isLoading = useState(false);

    // Watch Master Data
    final villagesAsync = ref.watch(villagesProvider);
    final posyandusAsync = selectedVillageId.value != null 
        ? ref.watch(posyandusByVillageProvider(selectedVillageId.value!)) 
        : const AsyncValue.data(<Posyandu>[]);
    final breedingPlacesAsync = ref.watch(breedingPlacesProvider);

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;
      if (selectedPosyanduId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih Posyandu')),
        );
        return;
      }

      isLoading.value = true;
      try {
        await ref.read(reportRepositoryProvider).submitReport(
          posyanduId: selectedPosyanduId.value!,
          housesInspected: int.parse(housesInspectedController.text),
          housesPositive: int.parse(housesPositiveController.text),
          breedingPlaceIds: selectedPlaceId.value != null ? [selectedPlaceId.value!] : [],
          notes: 'Hasil: ${selectedResult.value ?? "-"}\nKK: ${kkNameController.text}, RT: ${rtController.text}, RW: ${rwController.text}',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan berhasil dikirim!')),
          );
          ref.invalidate(myReportsProvider);
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim laporan: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0077B6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bug_report, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'SI KADER PSN',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          PopupMenuButton<void>(
            onSelected: (_) => ref.read(authRepositoryProvider).signOut(),
            offset: const Offset(0, 50),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.person, color: Color(0xFF0077B6), size: 20),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumbs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white.withOpacity(0.5),
            child: Row(
              children: [
                InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Beranda',
                      style: GoogleFonts.outfit(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                Text('Entri Laporan PSN', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENTRI LAPORAN PSN',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF003049),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Nama Desa
                      _buildLabel(Icons.location_on, 'Nama Desa', Colors.blue),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: selectedVillageId.value,
                        hint: villagesAsync.maybeWhen(
                          loading: () => 'Memuat desa...',
                          error: (e, s) => 'Error: $e',
                          orElse: () => 'Pilih Desa',
                        ),
                        onChanged: villagesAsync.maybeWhen<void Function(String?)?>(
                          data: (villages) => villages.isEmpty ? null : (val) {
                            selectedVillageId.value = val;
                            selectedPosyanduId.value = null;
                          },
                          orElse: () => null,
                        ),
                        items: villagesAsync.maybeWhen(
                          data: (villages) => villages.map((v) => 
                            DropdownMenuItem<String>(value: v.id, child: Text(v.name))
                          ).toList(),
                          orElse: () => [],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nama Posyandu
                      _buildLabel(Icons.eco, 'Nama Posyandu', Colors.green),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: selectedPosyanduId.value,
                        hint: selectedVillageId.value == null 
                            ? 'Pilih Desa Terlebih Dahulu' 
                            : posyandusAsync.maybeWhen(
                                loading: () => 'Memuat posyandu...',
                                error: (e, s) => 'Error: $e',
                                orElse: () => 'Pilih Posyandu',
                              ),
                        onChanged: posyandusAsync.maybeWhen<void Function(String?)?>(
                          data: (posyandus) => posyandus.isEmpty ? null : (val) => selectedPosyanduId.value = val,
                          orElse: () => null,
                        ),
                        items: posyandusAsync.maybeWhen(
                          data: (posyandus) => posyandus.map((p) => 
                            DropdownMenuItem<String>(value: p.id, child: Text(p.name))
                          ).toList(),
                          orElse: () => [],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tanggal Laporan
                      _buildLabel(Icons.calendar_today, 'Tanggal Laporan', Colors.blue),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: reportDate.value,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) reportDate.value = date;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 12),
                              Text(DateFormat('dd MMMM yyyy').format(reportDate.value)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Numeric Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Jumlah Rumah Diperiksa', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF003049))),
                                const SizedBox(height: 8),
                                _buildNumericInput(housesInspectedController),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Jumlah Rumah Positif Jentik', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF003049))),
                                const SizedBox(height: 8),
                                _buildNumericInput(housesPositiveController),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Hasil PSN
                      _buildLabel(Icons.bug_report, 'Hasil PSN (Pemberantasan Sarang Nyamuk)', Colors.green),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: selectedResult.value,
                        hint: 'Pilih Hasil',
                        onChanged: (val) => selectedResult.value = val,
                        items: (['Ada Jentik', 'Nihil']..sort()).map<DropdownMenuItem<String>>((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Nama KK section
                      _buildLabel(Icons.assignment, 'Nama KK Positif Jentik', Colors.teal),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextInput(kkNameController, 'Nama'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextInput(rtController, 'RT'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextInput(rwController, 'RW'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                              child: const Icon(Icons.add, color: Colors.white, size: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('Tambah\nNama KK', style: GoogleFonts.outfit(fontSize: 10, color: Colors.black54), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tempat Positif
                      _buildLabel(Icons.water_drop, 'Tempat Positif Jentik', Colors.blue),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              value: selectedPlaceId.value,
                              hint: breedingPlacesAsync.maybeWhen(
                                loading: () => 'Memuat tempat...',
                                orElse: () => 'Pilih Tempat',
                              ),
                              onChanged: breedingPlacesAsync.maybeWhen<void Function(String?)?>(
                                data: (places) => (val) => selectedPlaceId.value = val,
                                orElse: () => null,
                              ),
                              items: breedingPlacesAsync.maybeWhen(
                                data: (places) => places.map((e) => 
                                  DropdownMenuItem<String>(value: e['id'] as String, child: Text(e['name'] as String))
                                ).toList(),
                                orElse: () => [],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                                child: const Icon(Icons.add, color: Colors.white, size: 16),
                              ),
                              const SizedBox(height: 4),
                              Text('Tambah\nTempat', style: GoogleFonts.outfit(fontSize: 10, color: Colors.black54), textAlign: TextAlign.center),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Jumlah Tempat
                      Row(
                        children: [
                          _buildLabel(Icons.settings, 'Jumlah Tempat Positif Jentik', Colors.teal),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: _buildNumericInput(positivePlacesCountController),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1D7423), Color(0xFF388E3C)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1D7423).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading.value ? null : handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading.value
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'KIRIM LAPORAN',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003049),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          isExpanded: true,
          menuMaxHeight: 350, // Higher menu for better scrolling
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          dropdownColor: Colors.white,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildNumericInput(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildTextInput(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }
}

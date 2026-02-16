import 'package:flutter/material.dart';
import '../theme/app_color.dart';
import '../widgets/kontrol_widgets.dart';
import 'pot_selection_page.dart';
import 'jadwal_management_page.dart';
import '../services/kontrol_storage.dart';
import '../services/firebase_database_service.dart';

class KontrolPage extends StatefulWidget {
  const KontrolPage({super.key});

  @override
  State<KontrolPage> createState() => _KontrolPageState();
}

class _KontrolPageState extends State<KontrolPage> {
  String _selectedMode = 'Manual';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Di halaman kontrol, biarkan navigasi normal (kembali 1 tahap)
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColor.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kontrol',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textDark,
                  ),
                ),
                const SizedBox(height: 20),

                // Mode Kontrol Selection
                Text(
                  'Mode Kontrol',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ModeButton(
                      mode: 'Manual',
                      isSelected: _selectedMode == 'Manual',
                      onPressed: () {
                        setState(() {
                          _selectedMode = 'Manual';
                        });
                      },
                    ),
                    ModeButton(
                      mode: 'Waktu',
                      isSelected: _selectedMode == 'Waktu',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const JadwalManagementPage(),
                          ),
                        );
                      },
                    ),
                    ModeButton(
                      mode: 'Sensor',
                      isSelected: _selectedMode == 'Sensor',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const PotSelectionPage(mode: 'Sensor'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Expanded(child: ManualControlPage()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Manual Control Page
class ManualControlPage extends StatefulWidget {
  const ManualControlPage({super.key});

  @override
  State<ManualControlPage> createState() => _ManualControlPageState();
}

class _ManualControlPageState extends State<ManualControlPage> {
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();

  bool _pompaAir = false;
  bool _pompaNutrisi = false;
  bool _pengaduk = false; // Motor pengaduk (mosvet_8)

  // POT switches (5 POTs now)
  List<bool> _potStatus = [false, false, false, false, false];
  bool _isLoading = true;
  bool _hasLocalChanges = false; // Track jika ada perubahan lokal

  @override
  void initState() {
    super.initState();
    _loadFirebaseState();
    // Tidak listen real-time changes agar tidak menimpa perubahan lokal user
  }

  /// Load initial state from Firebase
  Future<void> _loadFirebaseState() async {
    try {
      final aktuatorData = await _dbService.getAktuatorStream().first;
      if (mounted) {
        setState(() {
          _pompaAir = aktuatorData['mosvet_1'] ?? false;
          _pompaNutrisi = aktuatorData['mosvet_2'] ?? false;
          _pengaduk = aktuatorData['mosvet_8'] ?? false;
          _potStatus = [
            aktuatorData['mosvet_3'] ?? false,
            aktuatorData['mosvet_4'] ?? false,
            aktuatorData['mosvet_5'] ?? false,
            aktuatorData['mosvet_6'] ?? false,
            aktuatorData['mosvet_7'] ?? false,
          ];
          _isLoading = false;
          _hasLocalChanges = false;
        });
      }
    } catch (e) {
      print('Error loading Firebase state: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // Tampilkan snackbar tapi jangan crash
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _jalankan() async {
    try {
      // Update Firebase with current state
      await _dbService.setMultipleAktuator({
        'mosvet_1': _pompaAir,
        'mosvet_2': _pompaNutrisi,
        'mosvet_3': _potStatus[0],
        'mosvet_4': _potStatus[1],
        'mosvet_5': _potStatus[2],
        'mosvet_6': _potStatus[3],
        'mosvet_7': _potStatus[4],
        'mosvet_8': _pengaduk,
      });

      // Also save to local storage as backup
      await KontrolStorage.saveManualControl(
        pompaAir: _pompaAir,
        pompaNutrisi: _pompaNutrisi,
        pots: _potStatus,
      );

      // Reset flag perubahan lokal
      setState(() {
        _hasLocalChanges = false;
      });

      // Show which devices are running
      List<String> activeDevices = [];
      if (_pompaAir) activeDevices.add('Pompa Air');
      if (_pompaNutrisi) activeDevices.add('Pompa Nutrisi');
      if (_pengaduk) activeDevices.add('Pengaduk');
      for (int i = 0; i < _potStatus.length; i++) {
        if (_potStatus[i]) activeDevices.add('POT ${i + 1}');
      }

      if (activeDevices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak ada perangkat yang diaktifkan'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Berhasil dijalankan: ${activeDevices.join(', ')}'),
            backgroundColor: AppColor.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Pompa Controls
          ControlSwitchCard(
            title: 'Pompa Air',
            isActive: _pompaAir,
            onPressed: () {
              setState(() {
                _pompaAir = !_pompaAir;
                _hasLocalChanges = true;
              });
            },
          ),
          ControlSwitchCard(
            title: 'Pompa Nutrisi',
            isActive: _pompaNutrisi,
            onPressed: () {
              setState(() {
                _pompaNutrisi = !_pompaNutrisi;
                _hasLocalChanges = true;
              });
            },
          ),
          ControlSwitchCard(
            title: 'Pengaduk',
            isActive: _pengaduk,
            onPressed: () {
              setState(() {
                _pengaduk = !_pengaduk;
                _hasLocalChanges = true;
              });
            },
          ),

          const SizedBox(height: 16),

          // POT Controls Section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Kontrol POT (Kran)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.textDark,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // POT switches (5 POTs)
          ...List.generate(5, (index) {
            return ControlSwitchCard(
              title: 'POT ${index + 1}',
              isActive: _potStatus[index],
              onPressed: () {
                setState(() {
                  _potStatus[index] = !_potStatus[index];
                  _hasLocalChanges = true;
                });
              },
            );
          }),

          const SizedBox(height: 24),

          // Info text jika ada perubahan lokal
          if (_hasLocalChanges)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ada perubahan yang belum disimpan',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _jalankan,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _hasLocalChanges ? AppColor.primary : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_hasLocalChanges)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.send, size: 18),
                    ),
                  Text(
                    _hasLocalChanges ? 'Jalankan Sekarang' : 'Jalankan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

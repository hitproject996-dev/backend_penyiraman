import 'package:flutter/material.dart';
import '../theme/app_color.dart';
import '../widgets/kontrol_widgets.dart';
import '../services/kontrol_storage.dart';
import '../services/firebase_database_service.dart';
import '../services/kontrol_automation_service.dart';

class WaktuConfigPage extends StatefulWidget {
  final String potName;
  final String selectedMode;

  const WaktuConfigPage({
    super.key,
    required this.potName,
    this.selectedMode = 'Waktu',
  });

  @override
  State<WaktuConfigPage> createState() => _WaktuConfigPageState();
}

class _WaktuConfigPageState extends State<WaktuConfigPage> {
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  final KontrolAutomationService _automationService =
      KontrolAutomationService();

  bool _isSaved = false;
  bool _isLoading = true;
  bool _isWaktuModeActive = false;

  // 2 Jadwal penyiraman untuk pot ini
  List<Map<String, dynamic>> _jadwalPenyiraman = [
    {
      'jamMulai': '08:00',
      'durasi': '10',
      'durasiUnit': 'menit',
      'pompaAir': false,
      'pompaPupuk': false,
    },
    {
      'jamMulai': '16:00',
      'durasi': '10',
      'durasiUnit': 'menit',
      'pompaAir': false,
      'pompaPupuk': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
    _loadWaktuModeStatus();
  }

  Future<void> _loadSavedConfig() async {
    try {
      final loadedData = await KontrolStorage.loadWaktuConfig(widget.potName);

      // Convert old format to new format if needed
      for (var jadwal in loadedData) {
        if (jadwal['durasi'] is String) {
          final durasiStr = jadwal['durasi'] as String;
          // Check if it contains unit (e.g., "10 menit")
          if (durasiStr.contains(' ')) {
            final parts = durasiStr.split(' ');
            jadwal['durasi'] = parts[0]; // Extract number
            jadwal['durasiUnit'] =
                parts.length > 1 ? parts[1] : 'menit'; // Extract unit
          } else {
            // If no unit, ensure durasiUnit exists
            jadwal['durasiUnit'] = jadwal['durasiUnit'] ?? 'menit';
          }
        }
      }

      if (mounted) {
        setState(() {
          _jadwalPenyiraman = loadedData;
          _isLoading = false;
          // Check if data was previously saved
          _isSaved =
              loadedData[0]['jamMulai'] != '08:00' ||
              loadedData[0]['pompaAir'] ||
              loadedData[0]['pompaPupuk'];
        });
      }
    } catch (e) {
      debugPrint('Error loading waktu config: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWaktuModeStatus() async {
    try {
      final kontrolConfig = await _dbService.getKontrolConfig();
      setState(() {
        _isWaktuModeActive = kontrolConfig['waktu'] ?? false;
      });
    } catch (e) {
      debugPrint('Error loading waktu mode status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Biarkan navigasi normal (kembali ke pot selection)
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          title: const Text('Kontrol'),
          centerTitle: true,
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mode Kontrol Selection (persistent)
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
                              isSelected: widget.selectedMode == 'Manual',
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                            ),
                            ModeButton(
                              mode: 'Waktu',
                              isSelected: widget.selectedMode == 'Waktu',
                              onPressed: () {},
                            ),
                            ModeButton(
                              mode: 'Sensor',
                              isSelected: widget.selectedMode == 'Sensor',
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Will navigate to sensor mode from pot selection
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Konfigurasi ${widget.potName}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Toggle Mode Waktu
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                _isWaktuModeActive
                                    ? AppColor.primary.withOpacity(0.1)
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _isWaktuModeActive
                                      ? AppColor.primary
                                      : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isWaktuModeActive
                                    ? Icons.schedule
                                    : Icons.schedule_outlined,
                                color:
                                    _isWaktuModeActive
                                        ? AppColor.primary
                                        : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mode Waktu',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _isWaktuModeActive
                                                ? AppColor.primary
                                                : Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      _isWaktuModeActive
                                          ? 'Aktif - Penyiraman otomatis'
                                          : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isWaktuModeActive,
                                onChanged: (value) async {
                                  setState(() => _isWaktuModeActive = value);
                                  try {
                                    await _dbService.updateKontrolConfig({
                                      'waktu': value,
                                    });
                                    if (value) {
                                      _automationService.startWaktuMode();
                                    } else {
                                      _automationService.stopWaktuMode();
                                    }
                                  } catch (e) {
                                    setState(() => _isWaktuModeActive = !value);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                activeColor: AppColor.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Expanded(
                          child: ListView.builder(
                            itemCount: _jadwalPenyiraman.length,
                            itemBuilder: (context, index) {
                              return _buildJadwalCard(index);
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Button Salin ke Semua POT
                        OutlinedButton.icon(
                          onPressed: _copyToAllPots,
                          icon: const Icon(Icons.content_copy),
                          label: const Text('Salin ke Semua POT'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColor.primary,
                            side: BorderSide(color: AppColor.primary),
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleSaveOrUpdate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _isSaved ? 'Update' : 'Simpan',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildJadwalCard(int index) {
    final jadwal = _jadwalPenyiraman[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Penyiraman ${index + 1}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Jam Mulai
          _buildSettingRow(
            label: 'Jam Mulai',
            value: jadwal['jamMulai'],
            onTap: () => _selectTime(index, 'jamMulai'),
          ),

          // Durasi
          _buildSettingRow(
            label: 'Durasi',
            value: '${jadwal['durasi']} ${jadwal['durasiUnit'] ?? 'menit'}',
            onTap: () => _selectDuration(index),
          ),

          // Pompa Air Switch
          _buildSwitchRow(
            label: 'Pompa Air',
            value: jadwal['pompaAir'],
            onChanged: (value) {
              setState(() {
                _jadwalPenyiraman[index]['pompaAir'] = value;
              });
            },
          ),

          // Pompa Pupuk Switch
          _buildSwitchRow(
            label: 'Pompa Pupuk',
            value: jadwal['pompaPupuk'],
            onChanged: (value) {
              setState(() {
                _jadwalPenyiraman[index]['pompaPupuk'] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColor.textDark),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit, size: 18, color: AppColor.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: AppColor.textDark)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColor.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(int index, String field) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: AppColor.primary)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _jadwalPenyiraman[index][field] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectDuration(int index) async {
    final TextEditingController controller = TextEditingController(
      text: _jadwalPenyiraman[index]['durasi'].toString(),
    );
    String selectedUnit = _jadwalPenyiraman[index]['durasiUnit'] ?? 'menit';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Atur Durasi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan durasi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Detik'),
                          value: 'detik',
                          groupValue: selectedUnit,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedUnit = value!;
                            });
                          },
                          activeColor: AppColor.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Menit'),
                          value: 'menit',
                          groupValue: selectedUnit,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedUnit = value!;
                            });
                          },
                          activeColor: AppColor.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'durasi': controller.text,
                      'unit': selectedUnit,
                    });
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null &&
        result['durasi'] != null &&
        result['durasi'].isNotEmpty) {
      setState(() {
        _jadwalPenyiraman[index]['durasi'] = result['durasi'];
        _jadwalPenyiraman[index]['durasiUnit'] = result['unit'];
      });
    }
  }

  Future<void> _handleSaveOrUpdate() async {
    try {
      print('🔧 [DEBUG] Starting save configuration...');

      // Save to local storage
      await KontrolStorage.saveWaktuConfig(widget.potName, _jadwalPenyiraman);
      print('✅ [DEBUG] Local storage saved');

      // Convert durasi to seconds untuk Firebase
      final durasi1Detik = _convertToSeconds(
        _jadwalPenyiraman[0]['durasi'],
        _jadwalPenyiraman[0]['durasiUnit'],
      );
      final durasi2Detik = _convertToSeconds(
        _jadwalPenyiraman[1]['durasi'],
        _jadwalPenyiraman[1]['durasiUnit'],
      );

      final configData = {
        'waktu_1': _jadwalPenyiraman[0]['jamMulai'],
        'waktu_2': _jadwalPenyiraman[1]['jamMulai'],
        'durasi_1': durasi1Detik,
        'durasi_2': durasi2Detik,
        'waktu': _isWaktuModeActive,
      };

      print('📊 [DEBUG] Config to Firebase: $configData');

      // Update Firebase dengan konfigurasi waktu
      await _dbService.updateKontrolConfig(configData);

      print('✅ [DEBUG] Firebase config saved successfully');

      setState(() {
        _isSaved = true;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Konfigurasi ${widget.potName} berhasil ${_isSaved ? 'diupdate' : 'disimpan'}',
          ),
          backgroundColor: AppColor.primary,
        ),
      );

      // Start automation jika mode aktif
      if (_isWaktuModeActive) {
        print('🚀 [DEBUG] Starting Waktu Mode automation...');
        _automationService.startWaktuMode();
        print('✅ [DEBUG] Waktu Mode started');
      } else {
        print('⏹️ [DEBUG] Waktu Mode is disabled - not starting automation');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  int _convertToSeconds(String durasi, String unit) {
    final value = int.tryParse(durasi) ?? 10;
    switch (unit) {
      case 'detik':
        return value;
      case 'menit':
        return value * 60;
      case 'jam':
        return value * 3600;
      default:
        return value * 60;
    }
  }

  Future<void> _copyToAllPots() async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: Text(
              'Salin konfigurasi ${widget.potName} ke semua POT (1-5)?\\n\\nSemua POT akan memiliki konfigurasi yang sama.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salin'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Copy to all pots
    for (int i = 1; i <= 5; i++) {
      await KontrolStorage.saveWaktuConfig('POT $i', _jadwalPenyiraman);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Konfigurasi berhasil disalin ke semua POT'),
        backgroundColor: AppColor.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

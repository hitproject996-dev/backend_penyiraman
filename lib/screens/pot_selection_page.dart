import 'package:flutter/material.dart';
import '../theme/app_color.dart';
import '../widgets/kontrol_widgets.dart';
import '../services/kontrol_storage.dart';
import 'waktu_config_page.dart';
import 'sensor_config_page.dart';
import 'jadwal_management_page.dart';
import 'threshold_management_page.dart';

class PotSelectionPage extends StatefulWidget {
  final String mode;

  const PotSelectionPage({super.key, required this.mode});

  @override
  State<PotSelectionPage> createState() => _PotSelectionPageState();
}

class _PotSelectionPageState extends State<PotSelectionPage> {
  bool _isModeActive = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModeStatus();
  }

  Future<void> _loadModeStatus() async {
    try {
      final isActive =
          widget.mode == 'Waktu'
              ? await KontrolStorage.loadWaktuModeActive()
              : await KontrolStorage.loadSensorModeActive();

      if (mounted) {
        setState(() {
          _isModeActive = isActive;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mode status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleMode(bool value) async {
    // Jika mengaktifkan mode ini, nonaktifkan mode lainnya
    if (value) {
      if (widget.mode == 'Waktu') {
        await KontrolStorage.saveSensorModeActive(false);
      } else {
        await KontrolStorage.saveWaktuModeActive(false);
      }
    }

    // Simpan status mode ini
    if (widget.mode == 'Waktu') {
      await KontrolStorage.saveWaktuModeActive(value);
    } else {
      await KontrolStorage.saveSensorModeActive(value);
    }

    setState(() {
      _isModeActive = value;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Mode ${widget.mode} Diaktifkan'
              : 'Mode ${widget.mode} Dinonaktifkan',
        ),
        backgroundColor: value ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          title: const Text('Kontrol'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Biarkan navigasi normal (kembali ke kontrol page)
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
        body: SafeArea(
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
                      isSelected: widget.mode == 'Manual',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ModeButton(
                      mode: 'Waktu',
                      isSelected: widget.mode == 'Waktu',
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const JadwalManagementPage(),
                          ),
                        );
                      },
                    ),
                    ModeButton(
                      mode: 'Sensor',
                      isSelected: widget.mode == 'Sensor',
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder:
                                (context) => const ThresholdManagementPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Toggle Mode Active
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        _isModeActive
                            ? AppColor.primary.withOpacity(0.1)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _isModeActive ? AppColor.primary : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isModeActive
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _isModeActive ? AppColor.primary : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aktifkan Mode ${widget.mode}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isModeActive
                                  ? 'Mode ${widget.mode} sedang aktif'
                                  : 'Aktifkan untuk menggunakan mode ini',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isModeActive,
                        onChanged: _toggleMode,
                        activeColor: AppColor.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pengaturan POT ${widget.mode}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                    children: [
                      PotCard(
                        potName: 'POT 1',
                        onTap: () => _navigateToConfig(context, 'POT 1'),
                      ),
                      PotCard(
                        potName: 'POT 2',
                        onTap: () => _navigateToConfig(context, 'POT 2'),
                      ),
                      PotCard(
                        potName: 'POT 3',
                        onTap: () => _navigateToConfig(context, 'POT 3'),
                      ),
                      PotCard(
                        potName: 'POT 4',
                        onTap: () => _navigateToConfig(context, 'POT 4'),
                      ),
                      PotCard(
                        potName: 'POT 5',
                        onTap: () => _navigateToConfig(context, 'POT 5'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToConfig(BuildContext context, String potName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                widget.mode == 'Waktu'
                    ? WaktuConfigPage(
                      potName: potName,
                      selectedMode: widget.mode,
                    )
                    : SensorConfigPage(
                      potName: potName,
                      selectedMode: widget.mode,
                    ),
      ),
    );
  }
}

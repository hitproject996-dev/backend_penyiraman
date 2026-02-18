import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/threshold_model.dart';
import '../services/threshold_service.dart';
import '../theme/app_color.dart';

/// Form untuk tambah/edit threshold sensor
class ThresholdFormPage extends StatefulWidget {
  final ThresholdModel? threshold; // null = create new, not null = edit

  const ThresholdFormPage({super.key, this.threshold});

  @override
  State<ThresholdFormPage> createState() => _ThresholdFormPageState();
}

class _ThresholdFormPageState extends State<ThresholdFormPage> {
  final _formKey = GlobalKey<FormState>();

  late String _thresholdId;
  late double _batasBawah; // 0-100
  late double _batasAtas; // 0-100
  late int _durasi; // dalam detik
  late bool _smartMode;
  late List<bool> _potSelection; // [pot1, pot2, pot3, pot4, pot5]
  late bool _pompaAir;
  late bool _pompaPupuk;
  late bool _pompaPengaduk;
  late bool _aktif;

  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    _isEditMode = widget.threshold != null;

    if (_isEditMode) {
      final threshold = widget.threshold!;
      _thresholdId = threshold.id;
      _batasBawah = threshold.batasBawah.toDouble();
      _batasAtas = threshold.batasAtas.toDouble();
      _durasi = threshold.durasi;
      _smartMode = threshold.smartMode;

      // Initialize pot selection
      _potSelection = List.generate(5, (index) {
        return threshold.potAktif.contains(index + 1);
      });

      _pompaAir = threshold.pompaAir;
      _pompaPupuk = threshold.pompaPupuk;
      _pompaPengaduk = threshold.pompaPengaduk;
      _aktif = threshold.aktif;
    } else {
      // Default values for new threshold
      _thresholdId = ''; // Will be set when saving
      _batasBawah = 30.0;
      _batasAtas = 70.0;
      _durasi = 600; // 10 minutes
      _smartMode = true;
      _potSelection = [false, false, false, false, false];
      _pompaAir = true;
      _pompaPupuk = false;
      _pompaPengaduk = false;
      _aktif = true;
    }
  }

  int get _durasiMenit => (_durasi / 60).round();

  set _durasiMenit(int value) {
    _durasi = value * 60;
  }

  List<int> get _selectedPots {
    final List<int> selected = [];
    for (int i = 0; i < _potSelection.length; i++) {
      if (_potSelection[i]) {
        selected.add(i + 1);
      }
    }
    return selected;
  }

  bool _validate() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedPots.isEmpty) {
      _showError('Pilih minimal 1 pot');
      return false;
    }

    if (_batasBawah >= _batasAtas) {
      _showError('Batas bawah harus lebih kecil dari batas atas');
      return false;
    }

    if (!_smartMode && _durasi <= 0) {
      _showError('Durasi harus lebih dari 0');
      return false;
    }

    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get or create ID
      if (!_isEditMode) {
        _thresholdId = await ThresholdService.getNextThresholdId();
      }

      // Create threshold model
      final threshold = ThresholdModel(
        id: _thresholdId,
        aktif: _aktif,
        batasBawah: _batasBawah.toInt(),
        batasAtas: _batasAtas.toInt(),
        durasi: _durasi,
        smartMode: _smartMode,
        potAktif: _selectedPots,
        pompaAir: _pompaAir,
        pompaPupuk: _pompaPupuk,
        pompaPengaduk: _pompaPengaduk,
      );

      // Save to Firebase
      final success = await ThresholdService.saveThreshold(threshold);

      setState(() => _isLoading = false);

      if (success) {
        if (mounted) {
          _showSuccess(
            _isEditMode
                ? 'Threshold berhasil diupdate'
                : 'Threshold berhasil ditambahkan',
          );
          Navigator.pop(context, true);
        }
      } else {
        _showError('Gagal menyimpan threshold');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        title: Text(_isEditMode ? 'Edit Threshold' : 'Tambah Threshold'),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildRangeSection(),
                    const SizedBox(height: 24),
                    _buildModeSection(),
                    const SizedBox(height: 24),
                    _buildPotSelection(),
                    const SizedBox(height: 24),
                    _buildPumpSection(),
                    const SizedBox(height: 24),
                    _buildStatusSection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
    );
  }

  Widget _buildRangeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Range Kelembaban',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Batas Bawah
            Text(
              'Batas Bawah: ${_batasBawah.toInt()}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _batasBawah,
              min: 0,
              max: 100,
              divisions: 100,
              label: '${_batasBawah.toInt()}%',
              onChanged: (value) {
                setState(() {
                  _batasBawah = value;
                  if (_batasBawah >= _batasAtas) {
                    _batasAtas = (_batasBawah + 1).clamp(0, 100);
                  }
                });
              },
              activeColor: AppColor.primary,
            ),
            const SizedBox(height: 8),

            // Batas Atas
            Text(
              'Batas Atas: ${_batasAtas.toInt()}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _batasAtas,
              min: 0,
              max: 100,
              divisions: 100,
              label: '${_batasAtas.toInt()}%',
              onChanged: (value) {
                setState(() {
                  _batasAtas = value;
                  if (_batasAtas <= _batasBawah) {
                    _batasBawah = (_batasAtas - 1).clamp(0, 100);
                  }
                });
              },
              activeColor: AppColor.primary,
            ),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Siram jika kelembaban < ${_batasBawah.toInt()}%',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Mode Penyiraman',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Smart Mode Toggle
            SwitchListTile(
              value: _smartMode,
              onChanged: (value) {
                setState(() {
                  _smartMode = value;
                });
              },
              title: Text(
                _smartMode ? 'Smart Mode' : 'Fixed Duration',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _smartMode
                    ? 'Siram sampai kelembaban ${_batasAtas.toInt()}%'
                    : 'Siram dengan durasi tetap',
                style: const TextStyle(fontSize: 12),
              ),
              activeColor: AppColor.primary,
              contentPadding: EdgeInsets.zero,
            ),

            // Duration input (hanya jika Fixed Duration)
            if (!_smartMode) ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _durasiMenit.toString(),
                decoration: InputDecoration(
                  labelText: 'Durasi (menit)',
                  hintText: 'Masukkan durasi',
                  prefixIcon: const Icon(Icons.timer),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.primary, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Durasi tidak boleh kosong';
                  }
                  final durasi = int.tryParse(value);
                  if (durasi == null || durasi <= 0) {
                    return 'Durasi harus lebih dari 0';
                  }
                  return null;
                },
                onChanged: (value) {
                  final menit = int.tryParse(value);
                  if (menit != null) {
                    setState(() {
                      _durasiMenit = menit;
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPotSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_florist, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Pilih Pot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pot selection buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(5, (index) {
                final potNumber = index + 1;
                final isSelected = _potSelection[index];

                return FilterChip(
                  label: Text('Pot $potNumber'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _potSelection[index] = selected;
                    });
                  },
                  selectedColor: AppColor.primary.withOpacity(0.2),
                  checkmarkColor: AppColor.primary,
                  backgroundColor: Colors.grey[100],
                  side: BorderSide(
                    color: isSelected ? AppColor.primary : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // Quick actions
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _potSelection = [true, true, true, true, true];
                    });
                  },
                  icon: const Icon(Icons.select_all, size: 18),
                  label: const Text('Pilih Semua'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _potSelection = [false, false, false, false, false];
                    });
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Hapus Semua'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Pompa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              value: _pompaAir,
              onChanged: (value) {
                setState(() {
                  _pompaAir = value;
                });
              },
              title: const Text('Pompa Air'),
              subtitle: const Text('Aktifkan pompa air saat penyiraman'),
              activeColor: AppColor.primary,
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              value: _pompaPupuk,
              onChanged: (value) {
                setState(() {
                  _pompaPupuk = value;
                });
              },
              title: const Text('Pompa Larutan Nutrisi'),
              subtitle: const Text(
                'Aktifkan pompa larutan nutrisi saat penyiraman',
              ),
              activeColor: AppColor.primary,
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              value: _pompaPengaduk,
              onChanged: (value) {
                setState(() {
                  _pompaPengaduk = value;
                });
              },
              title: const Text('Pompa Pengaduk'),
              subtitle: const Text(
                'Aktifkan pompa pengaduk untuk mengaduk larutan',
              ),
              activeColor: AppColor.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        value: _aktif,
        onChanged: (value) {
          setState(() {
            _aktif = value;
          });
        },
        title: const Text(
          'Status Threshold',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_aktif ? 'Aktif' : 'Nonaktif'),
        activeColor: AppColor.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child:
          _isLoading
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Text(
                _isEditMode ? 'Update Threshold' : 'Simpan Threshold',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
    );
  }
}

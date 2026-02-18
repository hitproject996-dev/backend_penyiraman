import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/jadwal_model.dart';
import '../services/jadwal_service.dart';
import '../theme/app_color.dart';

/// Form untuk tambah/edit jadwal
class JadwalFormPage extends StatefulWidget {
  final JadwalModel? jadwal; // null = create new, not null = edit

  const JadwalFormPage({super.key, this.jadwal});

  @override
  State<JadwalFormPage> createState() => _JadwalFormPageState();
}

class _JadwalFormPageState extends State<JadwalFormPage> {
  final JadwalService _jadwalService = JadwalService();
  final _formKey = GlobalKey<FormState>();

  late String _jadwalId;
  late TimeOfDay _selectedTime;
  late int _durasi; // dalam detik
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
    _isEditMode = widget.jadwal != null;

    if (_isEditMode) {
      final jadwal = widget.jadwal!;
      _jadwalId = jadwal.id;

      // Parse waktu ke TimeOfDay
      final timeParts = jadwal.waktu.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );

      _durasi = jadwal.durasi;

      // Initialize pot selection
      _potSelection = List.generate(5, (index) {
        return jadwal.potAktif.contains(index + 1);
      });

      _pompaAir = jadwal.pompaAir;
      _pompaPupuk = jadwal.pompaPupuk;
      _pompaPengaduk = jadwal.pompaPengaduk;
      _aktif = jadwal.aktif;
    } else {
      // Default values for new jadwal
      _jadwalId = ''; // Will be set when saving
      _selectedTime = const TimeOfDay(hour: 8, minute: 0);
      _durasi = 60; // 60 seconds = 1 minute
      _potSelection = [false, false, false, false, false];
      _pompaAir = true;
      _pompaPupuk = false;
      _pompaPengaduk = false;
      _aktif = true;
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primaryGreen),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
      _showError('Pilih minimal 1 pot yang akan disiram');
      return false;
    }

    if (_durasi <= 0) {
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
        _jadwalId = await _jadwalService.getNextJadwalId();
      }

      // Create jadwal model
      final jadwal = JadwalModel(
        id: _jadwalId,
        aktif: _aktif,
        waktu: _formatTimeOfDay(_selectedTime),
        durasi: _durasi,
        potAktif: _selectedPots,
        pompaAir: _pompaAir,
        pompaPupuk: _pompaPupuk,
        pompaPengaduk: _pompaPengaduk,
      );

      // Check if time slot is taken (for new or time changed)
      if (!_isEditMode || widget.jadwal!.waktu != jadwal.waktu) {
        final isTaken = await _jadwalService.isTimeSlotTaken(
          jadwal.waktu,
          excludeJadwalId: _isEditMode ? _jadwalId : null,
        );

        if (isTaken) {
          setState(() => _isLoading = false);
          _showWarning(
            'Waktu ${jadwal.waktu} sudah digunakan jadwal lain.\n'
            'Yakin ingin melanjutkan?',
            () => _forceSave(jadwal),
          );
          return;
        }
      }

      // Save
      final success = await _jadwalService.saveJadwal(jadwal);

      setState(() => _isLoading = false);

      if (success) {
        _showSuccess(
          _isEditMode
              ? 'Jadwal berhasil diupdate'
              : 'Jadwal berhasil ditambahkan',
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        _showError('Gagal menyimpan jadwal');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  Future<void> _forceSave(JadwalModel jadwal) async {
    setState(() => _isLoading = true);
    final success = await _jadwalService.saveJadwal(jadwal);
    setState(() => _isLoading = false);

    if (success) {
      _showSuccess('Jadwal berhasil disimpan');
      Navigator.pop(context, true);
    } else {
      _showError('Gagal menyimpan jadwal');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showWarning(String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Peringatan'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isLoading = false);
                },
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: Text(_isEditMode ? 'Edit Jadwal' : 'Tambah Jadwal'),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Time Selection
                      _buildSection('Waktu Penyiraman', _buildTimeCard()),

                      const SizedBox(height: 20),

                      // Duration
                      _buildSection('Durasi Penyiraman', _buildDurationCard()),

                      const SizedBox(height: 20),

                      // Pot Selection
                      _buildSection('Pilih Pot', _buildPotSelectionCard()),

                      const SizedBox(height: 20),

                      // Pump Settings
                      _buildSection(
                        'Pengaturan Pompa',
                        _buildPumpSettingsCard(),
                      ),

                      const SizedBox(height: 20),

                      // Active Status
                      _buildSection('Status Jadwal', _buildActiveStatusCard()),

                      const SizedBox(height: 32),

                      // Save Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  _isEditMode
                                      ? 'SIMPAN PERUBAHAN'
                                      : 'TAMBAH JADWAL',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildTimeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: _selectTime,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.access_time,
                color: AppColors.primaryGreen,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTimeOfDay(_selectedTime),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Tap untuk ubah waktu',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: _durasiMenit.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Durasi (menit)',
                    suffixText: 'menit',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan durasi';
                    }
                    final val = int.tryParse(value);
                    if (val == null || val <= 0) {
                      return 'Durasi harus > 0';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final val = int.tryParse(value);
                    if (val != null) {
                      setState(() {
                        _durasiMenit = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Setara dengan ${_durasi} detik',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPotSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.grass, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text(
                'Pilih pot yang akan disiram',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(5, (index) {
              return _buildPotCheckbox(index + 1, _potSelection[index]);
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _potSelection = [true, true, true, true, true];
                  });
                },
                icon: const Icon(Icons.check_box, size: 18),
                label: const Text('Pilih Semua'),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _potSelection = [false, false, false, false, false];
                  });
                },
                icon: const Icon(Icons.check_box_outline_blank, size: 18),
                label: const Text('Bersihkan'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPotCheckbox(int potNumber, bool selected) {
    return InkWell(
      onTap: () {
        setState(() {
          _potSelection[potNumber - 1] = !_potSelection[potNumber - 1];
        });
      },
      child: Container(
        width: 65,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primaryGreen.withOpacity(0.1)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.primaryGreen : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Pot $potNumber',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primaryGreen : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _pompaAir,
            onChanged: (value) => setState(() => _pompaAir = value),
            title: const Text('Pompa Air'),
            subtitle: const Text('Mengalirkan air'),
            secondary: Icon(
              Icons.water_drop,
              color: _pompaAir ? Colors.blue : Colors.grey,
            ),
            activeColor: AppColors.primaryGreen,
          ),
          const Divider(),
          SwitchListTile(
            value: _pompaPupuk,
            onChanged: (value) => setState(() => _pompaPupuk = value),
            title: const Text('Pompa Larutan Nutrisi'),
            subtitle: const Text('Mengalirkan larutan nutrisi cair'),
            secondary: Icon(
              Icons.science,
              color: _pompaPupuk ? Colors.orange : Colors.grey,
            ),
            activeColor: AppColors.primaryGreen,
          ),
          const Divider(),
          SwitchListTile(
            value: _pompaPengaduk,
            onChanged: (value) => setState(() => _pompaPengaduk = value),
            title: const Text('Pompa Pengaduk'),
            subtitle: const Text('Mengaduk larutan nutrisi'),
            secondary: Icon(
              Icons.blender,
              color: _pompaPengaduk ? Colors.purple : Colors.grey,
            ),
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        value: _aktif,
        onChanged: (value) => setState(() => _aktif = value),
        title: const Text('Jadwal Aktif'),
        subtitle: Text(
          _aktif
              ? 'Jadwal akan berjalan otomatis'
              : 'Jadwal tidak akan berjalan',
        ),
        secondary: Icon(
          _aktif ? Icons.notifications_active : Icons.notifications_off,
          color: _aktif ? AppColors.primaryGreen : Colors.grey,
        ),
        activeColor: AppColors.primaryGreen,
      ),
    );
  }
}

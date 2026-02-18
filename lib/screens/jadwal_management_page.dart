import 'package:flutter/material.dart';
import '../models/jadwal_model.dart';
import '../services/jadwal_service.dart';
import '../theme/app_color.dart';
import 'jadwal_form_page.dart';

/// Screen untuk manage multiple jadwal penyiraman
class JadwalManagementPage extends StatefulWidget {
  const JadwalManagementPage({super.key});

  @override
  State<JadwalManagementPage> createState() => _JadwalManagementPageState();
}

class _JadwalManagementPageState extends State<JadwalManagementPage> {
  final JadwalService _jadwalService = JadwalService();
  List<JadwalModel> _jadwalList = [];
  bool _isLoading = true;
  bool _waktuModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadJadwal();
    _loadWaktuModeStatus();
  }

  Future<void> _loadJadwal() async {
    setState(() => _isLoading = true);
    try {
      final jadwalList = await _jadwalService.getAllJadwal();
      setState(() {
        _jadwalList = jadwalList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal memuat jadwal: $e');
    }
  }

  Future<void> _loadWaktuModeStatus() async {
    final status = await _jadwalService.getWaktuModeStatus();
    setState(() => _waktuModeEnabled = status);
  }

  Future<void> _toggleWaktuMode(bool value) async {
    final success = await _jadwalService.setWaktuModeStatus(value);
    if (success) {
      setState(() => _waktuModeEnabled = value);
      _showSuccess(
        value ? 'Mode Waktu Diaktifkan' : 'Mode Waktu Dinonaktifkan',
      );
    } else {
      _showError('Gagal mengubah mode waktu');
    }
  }

  Future<void> _toggleJadwalAktif(JadwalModel jadwal) async {
    final newStatus = !jadwal.aktif;
    final success = await _jadwalService.toggleJadwalAktif(
      jadwal.id,
      newStatus,
    );

    if (success) {
      _loadJadwal();
      _showSuccess(newStatus ? 'Jadwal diaktifkan' : 'Jadwal dinonaktifkan');
    } else {
      _showError('Gagal mengubah status jadwal');
    }
  }

  Future<void> _deleteJadwal(JadwalModel jadwal) async {
    final confirmed = await _showConfirmDialog(
      'Hapus Jadwal',
      'Yakin ingin menghapus ${jadwal.id}?',
    );

    if (confirmed == true) {
      final success = await _jadwalService.deleteJadwal(jadwal.id);
      if (success) {
        _loadJadwal();
        _showSuccess('Jadwal berhasil dihapus');
      } else {
        _showError('Gagal menghapus jadwal');
      }
    }
  }

  Future<void> _duplicateJadwal(JadwalModel jadwal) async {
    final newId = await _jadwalService.duplicateJadwal(jadwal);
    if (newId != null) {
      _loadJadwal();
      _showSuccess('Jadwal berhasil diduplikasi ke $newId');
    } else {
      _showError('Gagal menduplikasi jadwal');
    }
  }

  Future<void> _navigateToForm({JadwalModel? jadwal}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JadwalFormPage(jadwal: jadwal)),
    );

    if (result == true) {
      _loadJadwal();
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

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ya', style: TextStyle(color: Colors.red)),
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
        title: const Text('Kelola Jadwal Penyiraman'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildWaktuModeCard(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _jadwalList.isEmpty
                    ? _buildEmptyState()
                    : _buildJadwalList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWaktuModeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  _waktuModeEnabled
                      ? AppColors.primaryGreen.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.schedule,
              color: _waktuModeEnabled ? AppColors.primaryGreen : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode Waktu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _waktuModeEnabled
                      ? 'Penjadwalan otomatis aktif'
                      : 'Penjadwalan otomatis nonaktif',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _waktuModeEnabled,
            onChanged: _toggleWaktuMode,
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Jadwal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambah jadwal',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalList() {
    return RefreshIndicator(
      onRefresh: _loadJadwal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _jadwalList.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == _jadwalList.length) {
            // Add button at the bottom
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Jadwal Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            );
          }
          final jadwal = _jadwalList[index];
          return _buildJadwalCard(jadwal);
        },
      ),
    );
  }

  Widget _buildJadwalCard(JadwalModel jadwal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: jadwal.aktif ? AppColors.primaryGreen : Colors.grey[300]!,
          width: 2,
        ),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  jadwal.aktif
                      ? AppColors.primaryGreen.withOpacity(0.1)
                      : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                // Time Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: jadwal.aktif ? AppColors.primaryGreen : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Time & ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jadwal.waktu,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        jadwal.id.toUpperCase(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Active Switch
                Switch(
                  value: jadwal.aktif,
                  onChanged: (_) => _toggleJadwalAktif(jadwal),
                  activeColor: AppColors.primaryGreen,
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pot Selection
                _buildInfoRow(Icons.grass, 'Pot Aktif', jadwal.potAktifString),
                const SizedBox(height: 12),

                // Duration
                _buildInfoRow(
                  Icons.timer_outlined,
                  'Durasi',
                  '${jadwal.durasiMenit} menit (${jadwal.durasi} detik)',
                ),
                const SizedBox(height: 12),

                // Pumps - Display only if enabled
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (jadwal.pompaAir)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water,
                              size: 14,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Air',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (jadwal.pompaPupuk)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.eco, size: 14, color: Colors.green[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Larutan Nutrisi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (jadwal.pompaPengaduk)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.purple[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.blender,
                              size: 14,
                              color: Colors.purple[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pengaduk',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const Divider(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToForm(jadwal: jadwal),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _duplicateJadwal(jadwal),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Duplikat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteJadwal(jadwal),
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

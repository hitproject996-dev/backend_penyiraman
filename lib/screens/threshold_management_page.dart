import 'package:flutter/material.dart';
import '../models/threshold_model.dart';
import '../services/threshold_service.dart';
import '../theme/app_color.dart';
import 'threshold_form_page.dart';

/// Screen untuk manage multiple threshold sensor
class ThresholdManagementPage extends StatefulWidget {
  const ThresholdManagementPage({super.key});

  @override
  State<ThresholdManagementPage> createState() =>
      _ThresholdManagementPageState();
}

class _ThresholdManagementPageState extends State<ThresholdManagementPage> {
  List<ThresholdModel> _thresholdList = [];
  bool _isLoading = true;
  bool _sensorModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadThreshold();
  }

  Future<void> _loadThreshold() async {
    setState(() => _isLoading = true);
    try {
      final thresholdList = await ThresholdService.getAllThreshold();
      setState(() {
        _thresholdList = thresholdList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal memuat threshold: $e');
    }
  }

  Future<void> _toggleThresholdAktif(ThresholdModel threshold) async {
    final newStatus = !threshold.aktif;
    final success = await ThresholdService.toggleThresholdAktif(
      threshold.id,
      newStatus,
    );

    if (success) {
      _loadThreshold();
      _showSuccess(
        newStatus ? 'Threshold diaktifkan' : 'Threshold dinonaktifkan',
      );
    } else {
      _showError('Gagal mengubah status threshold');
    }
  }

  Future<void> _deleteThreshold(ThresholdModel threshold) async {
    final confirmed = await _showConfirmDialog(
      'Hapus Threshold',
      'Yakin ingin menghapus ${threshold.id}?',
    );

    if (confirmed == true) {
      final success = await ThresholdService.deleteThreshold(threshold.id);
      if (success) {
        _loadThreshold();
        _showSuccess('Threshold berhasil dihapus');
      } else {
        _showError('Gagal menghapus threshold');
      }
    }
  }

  Future<void> _duplicateThreshold(ThresholdModel threshold) async {
    final newId = await ThresholdService.duplicateThreshold(threshold);
    if (newId != null) {
      _loadThreshold();
      _showSuccess('Threshold berhasil diduplikasi ke $newId');
    } else {
      _showError('Gagal menduplikasi threshold');
    }
  }

  void _navigateToForm({ThresholdModel? threshold}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ThresholdFormPage(threshold: threshold),
      ),
    );

    if (result == true) {
      _loadThreshold();
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
        title: const Text('Kontrol Sensor'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadThreshold,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadThreshold,
              child: _thresholdList.isEmpty
                  ? _buildEmptyState()
                  : _buildThresholdList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: AppColor.primary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Threshold'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada threshold',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambah',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _thresholdList.length,
      itemBuilder: (context, index) {
        final threshold = _thresholdList[index];
        return _buildThresholdCard(threshold);
      },
    );
  }

  Widget _buildThresholdCard(ThresholdModel threshold) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToForm(threshold: threshold),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID + Toggle
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          threshold.aktif
                              ? AppColors.primaryGreen.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sensors,
                      color: threshold.aktif ? AppColors.primaryGreen : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ID + Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          threshold.id.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          threshold.aktif ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 12,
                            color: threshold.aktif ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Toggle Switch
                  Switch(
                    value: threshold.aktif,
                    onChanged: (_) => _toggleThresholdAktif(threshold),
                    activeColor: AppColor.primary,
                  ),
                ],
              ),

              const Divider(height: 24),

              // Range kelembaban
              Row(
                children: [
                  Icon(Icons.water_drop, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Range: ${threshold.rangeString}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Mode
              Row(
                children: [
                  Icon(
                    threshold.smartMode ? Icons.psychology : Icons.timer,
                    size: 18,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    threshold.modeString,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (!threshold.smartMode) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${threshold.durasiMenit} menit)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Pot aktif
              Row(
                children: [
                  Icon(Icons.local_florist, size: 18, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pot: ${threshold.potAktifString}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Pompa
              Row(
                children: [
                  if (threshold.pompaAir)
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
                          Icon(Icons.water, size: 14, color: Colors.blue[700]),
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
                  if (threshold.pompaAir && threshold.pompaPupuk)
                    const SizedBox(width: 8),
                  if (threshold.pompaPupuk)
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
                            'Pupuk',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _navigateToForm(threshold: threshold),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _duplicateThreshold(threshold),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Duplikat'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteThreshold(threshold),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Hapus'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_color.dart';
import '../services/auth_service.dart';
import '../services/firebase_database_service.dart';
import 'kontrol_page.dart';
import 'histori_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final _dbService = FirebaseDatabaseService();
  final _authService = AuthService();
  bool _isInitialized = false;
  StreamSubscription? _authSubscription;

  final List<Map<String, dynamic>> _pages = [
    {'title': 'Dashboard', 'icon': Icons.dashboard},
    {'title': 'Kontrol', 'icon': Icons.settings_remote},
    {'title': 'Histori', 'icon': Icons.history},
  ];

  @override
  void initState() {
    super.initState();

    // Verify user is logged in on init
    if (_authService.currentUser == null) {
      // If no user, redirect immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      return;
    }

    _isInitialized = true;

    // Monitor auth state untuk mencegah logout tidak terduga
    // Hanya trigger jika sudah initialized dan user jadi null
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (_isInitialized && user == null && mounted) {
        // User logged out, redirect to login
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Apakah Anda yakin ingin logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Jika di halaman dashboard (index 0), tampilkan konfirmasi logout
        if (_selectedIndex == 0) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Konfirmasi'),
                  content: const Text(
                    'Apakah Anda yakin ingin keluar dari aplikasi?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
          );
          return shouldExit ?? false;
        }
        // Untuk tab lain, set kembali ke dashboard
        setState(() {
          _selectedIndex = 0;
        });
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_pages[_selectedIndex]['title']),
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: Drawer(
          child: Column(
            children: [
              // Drawer Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(color: AppColor.primary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo_apsgo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.eco,
                              size: 35,
                              color: AppColor.primary,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ApsGo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AuthService().currentUser?.email ?? 'user@example.com',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      index: 0,
                    ),
                    _buildDrawerItem(
                      icon: Icons.settings_remote,
                      title: 'Kontrol',
                      index: 1,
                    ),
                    _buildDrawerItem(
                      icon: Icons.history,
                      title: 'Histori',
                      index: 2,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _handleLogout(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColor.primary : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColor.primary : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColor.primary.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const KontrolPage();
      case 2:
        return const HistoriPage();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _dbService.getSensorDataStream(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // No data state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No data available'),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final suhu = data['suhu'] ?? '0';
        final kelembapan = data['kelembapan'] ?? '0';
        final ldr = data['ldr'] ?? '0';
        final waterFlow = data['water_flow'] ?? 0;
        final soil1 = data['soil_1'] ?? '0';
        final soil2 = data['soil_2'] ?? '0';
        final soil3 = data['soil_3'] ?? '0';
        final soil4 = data['soil_4'] ?? '0';
        final soil5 = data['soil_5'] ?? '0';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status & Water Status Indicators
              Row(
                children: [
                  _buildConnectionStatus(),
                  const SizedBox(width: 12),
                  _buildWaterFlowStatus(waterFlow),
                ],
              ),
              const SizedBox(height: 8),

              // Sensor Cards - Temperature, Humidity, Light
              _buildSensorCard(
                title: "Temperature",
                value: suhu,
                unit: "°C",
                icon: Icons.thermostat_outlined,
                color: Colors.orange,
              ),
              _buildSensorCard(
                title: "Humidity",
                value: kelembapan,
                unit: "%",
                icon: Icons.water_drop_outlined,
                color: Colors.blue,
              ),
              _buildSensorCard(
                title: "Light",
                value: ldr,
                unit: "%",
                icon: Icons.wb_sunny_outlined,
                color: Colors.amber,
              ),

              const SizedBox(height: 12),

              // Pot Cards - Pot 1 to Pot 5
              _buildPotCard(potNumber: 1, soilMoisture: soil1),
              _buildPotCard(potNumber: 2, soilMoisture: soil2),
              _buildPotCard(potNumber: 3, soilMoisture: soil3),
              _buildPotCard(potNumber: 4, soilMoisture: soil4),
              _buildPotCard(potNumber: 5, soilMoisture: soil5),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatus() {
    return StreamBuilder<bool>(
      stream: _dbService.getConnectionStatus(),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                isConnected
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConnected ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  color: isConnected ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaterFlowStatus(dynamic waterFlow) {
    // Debug: Print raw value
    print(
      '🔍 DEBUG Water Flow - Raw value: $waterFlow, Type: ${waterFlow.runtimeType}',
    );

    // Parse waterFlow to int - handles all cases
    int flowValue = 0;

    if (waterFlow == null) {
      flowValue = 0;
      print('   → Water flow is NULL');
    } else if (waterFlow is int) {
      flowValue = waterFlow;
      print('   → Parsed as int: $flowValue');
    } else if (waterFlow is double) {
      flowValue = waterFlow.toInt();
      print('   → Parsed as double to int: $flowValue');
    } else if (waterFlow is String) {
      flowValue = int.tryParse(waterFlow) ?? 0;
      print('   → Parsed from string: $flowValue');
    } else {
      final stringValue = waterFlow.toString();
      flowValue = int.tryParse(stringValue) ?? 0;
      print('   → Parsed from toString(): $flowValue');
    }

    final hasWater = flowValue > 0;
    print('   → Final: flowValue=$flowValue, hasWater=$hasWater');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            hasWater
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasWater ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop,
            size: 14,
            color: hasWater ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            hasWater ? 'Air Tersedia' : 'Air Habis',
            style: TextStyle(
              color: hasWater ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String value,
    String unit = '',
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColor.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      unit,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPotCard({required int potNumber, required String soilMoisture}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColor.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.yard, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pot $potNumber',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Soil Moisture',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              soilMoisture,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ---- Model Data untuk Perangkat ----
class Device {
  final String name;
  final String deviceId;
  final DateTime installDate;
  final String location;
  final String ipAddress;

  Device({
    required this.name,
    required this.deviceId,
    required this.installDate,
    required this.location,
    required this.ipAddress,
  });
}

// 1. Fungsi utama untuk menjalankan aplikasi
void main() {
  runApp(const MyApp());
}

// 2. Widget utama aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supergindul IOT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF2c3e50)),
          bodyLarge: TextStyle(color: Color(0xFF2c3e50)),
          bodyMedium: TextStyle(color: Color(0xFF7f8c8d)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// 3. Widget untuk Halaman Utama (Home Screen)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Device> _devices = [];

  void _addDevice(Device newDevice) {
    setState(() {
      _devices.add(newDevice);
    });
  }

  void _deleteDevice(int index) {
    setState(() {
      _devices.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    void scrollToDashboard() {
      scrollController.animateTo(
        MediaQuery.of(context).size.height,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            HeroSection(onScrollDown: scrollToDashboard),
            DashboardSection(
              devices: _devices,
              onAddDevice: _addDevice,
              onDeleteDevice: _deleteDevice,
            ),
          ],
        ),
      ),
    );
  }
}

// 4. Widget untuk Hero Section
class HeroSection extends StatelessWidget {
  final VoidCallback onScrollDown;
  const HeroSection({super.key, required this.onScrollDown});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)])),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Spacer(flex: 2),
          const Text('Supergindul IOT System',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF007AFF))),
          const SizedBox(height: 10),
          Text('Sistem Monitoring Inkubator Ayam DOC', style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(flex: 2),
          IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 40, color: Color(0xFF007AFF)), onPressed: onScrollDown),
          const Spacer(flex: 1)
        ]));
  }
}

// 5. Widget untuk Dashboard Section
class DashboardSection extends StatelessWidget {
  final List<Device> devices;
  final Function(Device) onAddDevice;
  final Function(int) onDeleteDevice;

  const DashboardSection({
    super.key,
    required this.devices,
    required this.onAddDevice,
    required this.onDeleteDevice,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Peringatan Penting', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 15),
          const WarningCard(
              title: 'Suhu Terlalu Tinggi', subtitle: 'Inkubator #A1 melebihi batas aman. Segera periksa.', severity: CardSeverity.critical),
          const WarningCard(
              title: 'Kelembaban Turun', subtitle: 'Kelembaban Inkubator #B2 di bawah ambang batas.', severity: CardSeverity.moderate),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Perangkat Tersedia', style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF007AFF), size: 30),
                onPressed: () async {
                  final result = await Navigator.push<Device>(
                    context,
                    MaterialPageRoute(builder: (context) => const AddDeviceScreen()),
                  );
                  if (result != null) {
                    onAddDevice(result);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (devices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Belum ada perangkat. Tekan tombol + untuk menambahkan.'),
              ),
            )
          else
            for (int i = 0; i < devices.length; i++)
              DeviceCard(
                device: devices[i],
                onDelete: () => onDeleteDevice(i),
              ),
        ],
      ),
    );
  }
}

enum CardSeverity { critical, moderate }

// 6. Widget untuk Kartu Peringatan
class WarningCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final CardSeverity severity;

  const WarningCard({super.key, required this.title, required this.subtitle, required this.severity});

  @override
  Widget build(BuildContext context) {
    final Color borderColor = severity == CardSeverity.critical ? const Color(0xFFe74c3c) : const Color(0xFFf39c12);
    final IconData iconData = Icons.warning_amber_rounded;
    return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(side: BorderSide(color: borderColor, width: 2), borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(children: [
              Icon(iconData, color: borderColor, size: 30),
              const SizedBox(width: 15),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)]))
            ])));
  }
}

// 7. Widget untuk Kartu Perangkat
class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onDelete;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const bool isOnline = true; // Data dummy
    return Card(
        elevation: 4,
        shadowColor: const Color(0xFF2c3e50).withOpacity(0.1),
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Navigasi ke halaman detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceDetailScreen(device: device),
                ),
              );
            },
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(children: [
                  Row(children: [
                    Text(device.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Row(children: [
                      Icon(Icons.circle, color: isOnline ? const Color(0xFF2ecc71) : const Color(0xFFbdc3c7), size: 12),
                      const SizedBox(width: 8),
                      Text(isOnline ? 'Online' : 'Offline', style: TextStyle(color: isOnline ? const Color(0xFF2ecc71) : const Color(0xFFbdc3c7)))
                    ]),
                    IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.grey),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Hapus Perangkat'),
                                content: Text('Apakah Anda yakin ingin menghapus ${device.name}?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Batal'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      onDelete();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        })
                  ]),
                  const SizedBox(height: 20),
                  // Data dummy untuk metrik
                  const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    MetricWidget(label: 'Suhu', value: '-- °C'),
                    MetricWidget(label: 'Kelembaban', value: '-- %'),
                    MetricWidget(label: 'Usia Telur', value: '-- Hari')
                  ])
                ]))));
  }
}

// 8. Widget kecil untuk menampilkan metrik
class MetricWidget extends StatelessWidget {
  final String label;
  final String value;

  const MetricWidget({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2c3e50)))
    ]);
  }
}


// --- CLASS DARI Tambahdev.dart DIPINDAHKAN KE SINI ---
class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceNameController = TextEditingController();
  final _deviceIDController = TextEditingController();
  final _installDateController = TextEditingController();
  final _locationController = TextEditingController();
  final _ipAddressController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void dispose() {
    _deviceNameController.dispose();
    _deviceIDController.dispose();
    _installDateController.dispose();
    _locationController.dispose();
    _ipAddressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _installDateController.text = DateFormat('dd MMMM yyyy').format(picked);
      });
    }
  }

  void _saveDevice() {
    if (_formKey.currentState!.validate()) {
      final newDevice = Device(
        name: _deviceNameController.text,
        deviceId: _deviceIDController.text,
        installDate: _selectedDate!,
        location: _locationController.text,
        ipAddress: _ipAddressController.text,
      );
      Navigator.pop(context, newDevice);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Perangkat Baru'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2c3e50),
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _deviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Perangkat',
                    hintText: 'Contoh: Inkubator Teras',
                    prefixIcon: Icon(Icons.label_important_outline),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Nama perangkat tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ipAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat IP Perangkat',
                    hintText: 'Contoh: 192.168.1.10',
                    prefixIcon: Icon(Icons.router_outlined),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Alamat IP tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _deviceIDController,
                  decoration: const InputDecoration(
                    labelText: 'ID Unik Perangkat',
                    prefixIcon: Icon(Icons.qr_code_scanner),
                    helperText: 'Masukkan ID yang tertera pada stiker perangkat ESP.',
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'ID Perangkat tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _installDateController,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Pemasangan',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) => (value == null || value.isEmpty) ? 'Tanggal pemasangan tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi / Keterangan (Opsional)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _saveDevice,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16)
                  ),
                  child: const Text('Simpan Perangkat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- CLASS DARI device_detail_screen.dart DIPINDAHKAN KE SINI ---
class DeviceDetailScreen extends StatefulWidget {
  final Device device;
  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  bool _led1Status = false;
  bool _led2Status = false;
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) => _fetchStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    if (!mounted) return;
    try {
      final response = await http.get(
        Uri.parse('http://${widget.device.ipAddress}/status'),
      ).timeout(const Duration(seconds: 2));
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _led1Status = data['led1_status'];
          _led2Status = data['led2_status'];
          _isLoading = false;
          _errorMessage = '';
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Gagal mengambil status dari perangkat.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Tidak dapat terhubung ke perangkat. Pastikan IP benar dan terhubung ke WiFi yang sama.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendControl(int ledNumber, bool state) async {
    final String stateString = state ? 'on' : 'off';
    try {
      await http.get(
        Uri.parse('http://${widget.device.ipAddress}/kontrol?led=$ledNumber&state=$stateString'),
      ).timeout(const Duration(seconds: 2));
      await _fetchStatus();
    } catch (e) {
      if (mounted) {
        setState(() { _errorMessage = 'Gagal mengirim perintah.'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        backgroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kontrol LED',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('LED 1 (Pin 23)'),
                  value: _led1Status,
                  onChanged: (value) {
                    setState(() => _led1Status = value);
                    _sendControl(1, value);
                  },
                ),
                SwitchListTile(
                  title: const Text('LED 2 (Pin 2)'),
                  value: _led2Status,
                  onChanged: (value) {
                    setState(() => _led2Status = value);
                    _sendControl(2, value);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


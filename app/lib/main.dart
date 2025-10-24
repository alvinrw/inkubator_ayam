import 'package:flutter/material.dart';
import 'package:app/Tambahdev.dart'; // Pastikan nama proyek 'app' sudah benar

// ---- Model Data untuk Perangkat ----
// Kita buat class ini untuk menyimpan data setiap perangkat
class Device {
  final String name;
  final String deviceId;
  // Kita ubah tipe data tanggal agar lebih mudah dikelola
  final DateTime installDate;
  final String location;

  Device({
    required this.name,
    required this.deviceId,
    required this.installDate,
    required this.location,
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
          headlineSmall: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c3e50)),
          bodyLarge: TextStyle(color: Color(0xFF2c3e50)),
          bodyMedium: TextStyle(color: Color(0xFF7f8c8d)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// 3. Widget untuk Halaman Utama (Home Screen)
// --- DIUBAH MENJADI STATEFULWIDGET ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Di sini kita simpan daftar perangkat yang bisa berubah-ubah
  final List<Device> _devices = [];

  // Fungsi untuk menambah perangkat baru ke dalam daftar
  void _addDevice(Device newDevice) {
    setState(() {
      _devices.add(newDevice);
    });
  }

  // Fungsi untuk menghapus perangkat dari daftar
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
            // Kirim daftar perangkat dan fungsi-fungsinya ke DashboardSection
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          const Text('Supergindul IOT System',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007AFF))),
          const SizedBox(height: 10),
          Text('Sistem Monitoring Inkubator Ayam DOC',
              style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(flex: 2),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down,
                size: 40, color: Color(0xFF007AFF)),
            onPressed: onScrollDown,
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

// 5. Widget untuk Dashboard Section
class DashboardSection extends StatelessWidget {
  // Terima daftar perangkat dan fungsi dari HomeScreen
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
          Text('Peringatan Penting',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 15),
          const WarningCard(
              title: 'Suhu Terlalu Tinggi',
              subtitle: 'Inkubator #A1 melebihi batas aman. Segera periksa.',
              severity: CardSeverity.critical),
          const WarningCard(
              title: 'Kelembaban Turun',
              subtitle: 'Kelembaban Inkubator #B2 di bawah ambang batas.',
              severity: CardSeverity.moderate),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Perangkat Tersedia',
                  style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.add_circle,
                    color: Color(0xFF007AFF), size: 30),
                onPressed: () async {
                  // Pindah halaman dan tunggu hasilnya
                  final result = await Navigator.push<Device>(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddDeviceScreen()),
                  );
                  // Jika ada hasil (perangkat baru), panggil fungsi onAddDevice
                  if (result != null) {
                    onAddDevice(result);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 15),

          // --- PERANGKAT STATIS DIHAPUS & DIGANTI DENGAN YANG DINAMIS ---
          if (devices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                    'Belum ada perangkat. Tekan tombol + untuk menambahkan.'),
              ),
            )
          else
            // Tampilkan setiap perangkat dalam daftar menggunakan loop
            for (int i = 0; i < devices.length; i++)
              DeviceCard(
                device: devices[i],
                // Kirim fungsi untuk menghapus perangkat ini
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

  const WarningCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.severity});

  @override
  Widget build(BuildContext context) {
    final Color borderColor = severity == CardSeverity.critical
        ? const Color(0xFFe74c3c)
        : const Color(0xFFf39c12);
    final IconData iconData = Icons.warning_amber_rounded;
    return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(children: [
              Icon(iconData, color: borderColor, size: 30),
              const SizedBox(width: 15),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)
                  ]))
            ])));
  }
}

// 7. Widget untuk Kartu Perangkat
class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onDelete; // Fungsi untuk menghapus

  const DeviceCard({
    super.key,
    required this.device,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Data dummy untuk tampilan, akan diganti data asli dari backend nanti
    const bool isOnline = true;
    const String temperature = '37.5°C';
    const String humidity = '60%';
    const String eggAge = '12 Hari';

    return Card(
        elevation: 4,
        shadowColor: const Color(0xFF2c3e50).withOpacity(0.1),
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Buka detail untuk ${device.name}')));
            },
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(children: [
                  Row(children: [
                    Text(device.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Row(children: [
                      Icon(Icons.circle,
                          color: isOnline
                              ? const Color(0xFF2ecc71)
                              : const Color(0xFFbdc3c7),
                          size: 12),
                      const SizedBox(width: 8),
                      Text(isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                              color: isOnline
                                  ? const Color(0xFF2ecc71)
                                  : const Color(0xFFbdc3c7)))
                    ]),
                    // --- FUNGSI TOMBOL INFO DIUBAH DI SINI ---
                    IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.grey),
                        onPressed: () {
                          // Tampilkan dialog konfirmasi hapus
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Hapus Perangkat'),
                                content: Text(
                                    'Apakah Anda yakin ingin menghapus ${device.name}?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Batal'),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Tutup dialog
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Hapus',
                                        style: TextStyle(color: Colors.red)),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Tutup dialog
                                      onDelete(); // Panggil fungsi hapus
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        })
                  ]),
                  const SizedBox(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        MetricWidget(label: 'Suhu', value: temperature),
                        MetricWidget(label: 'Kelembaban', value: humidity),
                        MetricWidget(label: 'Usia Telur', value: eggAge)
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
      Text(value,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c3e50)))
    ]);
  }
}


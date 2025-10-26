import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mqtt_client/mqtt_client.dart';

// Import file-file pendukung
import 'mqtt_service.dart';
import 'Tambahdev.dart';
import 'device_detail_screen.dart';
import 'models/device.dart'; // ✅ IMPORT DEVICE DARI FILE TERPISAH

// =====================================================================
// FUNGSI UTAMA DAN WIDGET UTAMA
// =====================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await mqttService.connect();
  runApp(const MyApp());
}

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Daftar Perangkat Statis
  final List<Device> _devices = [
    Device(
      name: 'Inkubator DOC Utama',
      deviceId: 'DOC_KANDANG_A',
      installDate: DateTime.now().subtract(const Duration(days: 5)),
      location: 'Gudang Belakang',
    ),
  ];

  MqttConnectionState? _mqttStatus;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _mqttStatus = mqttService.client.connectionStatus?.state;

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _mqttStatus = mqttService.client.connectionStatus?.state;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
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
            HeroSection(onScrollDown: scrollToDashboard, mqttStatus: _mqttStatus),
            DashboardSection(devices: _devices),
          ],
        ),
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  final VoidCallback onScrollDown;
  final MqttConnectionState? mqttStatus;

  const HeroSection({super.key, required this.onScrollDown, this.mqttStatus});

  String get _statusText {
    if (mqttStatus == MqttConnectionState.connected) {
      return 'ONLINE (HiveMQ Connected)';
    }
    if (mqttStatus == MqttConnectionState.connecting) {
      return 'Menghubungkan...';
    }
    if (mqttStatus == MqttConnectionState.disconnecting) {
      return 'Memutuskan...';
    }
    return 'OFFLINE (Cek Koneksi)';
  }

  Color get _statusColor {
    if (mqttStatus == MqttConnectionState.connected) {
      return const Color(0xFF2ecc71);
    }
    return const Color(0xFFe74c3c);
  }

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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 12, color: _statusColor),
              const SizedBox(width: 8),
              Text(_statusText,
                  style: TextStyle(
                      color: _statusColor, fontWeight: FontWeight.bold)),
            ],
          ),
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

class DashboardSection extends StatelessWidget {
  final List<Device> devices;

  const DashboardSection({super.key, required this.devices});

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
          Text('Perangkat Tersedia',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 15),
          if (devices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Belum ada perangkat yang terdaftar.'),
              ),
            )
          else
            ...devices.map((device) => DeviceCard(device: device)),
        ],
      ),
    );
  }
}

enum CardSeverity { critical, moderate }

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
    const IconData iconData = Icons.warning_amber_rounded;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
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
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final Device device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    const bool isOnline = true;
    const String temperature = '-- °C';
    const String humidity = '-- %';

    return Card(
      elevation: 4,
      shadowColor: const Color(0xFF2c3e50).withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailScreen(device: device),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(device.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Row(
                    children: [
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
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.grey),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(device.name),
                            content: Text('ID: ${device.deviceId}\n'
                                'Lokasi: ${device.location}\n'
                                'Tanggal Instalasi: ${DateFormat('dd MMMM yyyy').format(device.installDate)}'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Tutup'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  MetricWidget(label: 'Suhu', value: temperature),
                  MetricWidget(label: 'Kelembaban', value: humidity),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MetricWidget extends StatelessWidget {
  final String label;
  final String value;

  const MetricWidget({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2c3e50)))
      ],
    );
  }
}
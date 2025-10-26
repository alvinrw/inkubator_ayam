import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/device.dart'; // ✅ IMPORT DEVICE DARI FILE TERPISAH
import 'mqtt_service.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  // Data sensor real-time
  double _temperature = 0.0;
  double _humidity = 0.0;
  bool _isOnline = false;
  
  // Timer untuk timeout
  Timer? _timeoutTimer;
  
  // ⚠️ PENTING: Topic ini HARUS sama persis dengan yang di ESP32
  String get _sensorTopic => 'doc/data';
  String get _controlTopic => 'supergindul/${widget.device.deviceId}/control';

  @override
  void initState() {
    super.initState();
    print('🚀 DeviceDetailScreen init untuk ${widget.device.deviceId}');
    
    // Tunggu sebentar agar MQTT siap
    Future.delayed(const Duration(milliseconds: 500), () {
      _setupMqttListener();
      _subscribeToTopics();
      _startTimeoutTimer();
    });
  }

  void _setupMqttListener() {
    print('🎧 Setup MQTT listener...');
    mqttService.onMessageReceived = (topic, message) {
      print('📬 Pesan diterima di listener!');
      print('   Topic: $topic');
      print('   Message: $message');
      
      if (topic == _sensorTopic) {
        _handleSensorData(message);
      } else {
        print('⚠️ Topic tidak cocok: $topic != $_sensorTopic');
      }
    };
  }

  void _subscribeToTopics() {
    print('📡 Subscribe ke topic: $_sensorTopic');
    mqttService.subscribe(_sensorTopic);
  }

  void _handleSensorData(String message) {
    print('🔄 Memproses data sensor...');
    
    try {
      final data = jsonDecode(message);
      print('✅ JSON berhasil di-parse: $data');
      
      if (mounted) {
        setState(() {
          // Coba beberapa kemungkinan key JSON
          _temperature = (data['suhu'] ?? data['temperature'] ?? data['temp'] ?? 0).toDouble();
          _humidity = (data['kelembaban'] ?? data['humidity'] ?? data['hum'] ?? 0).toDouble();
          _isOnline = true;
          
          print('🌡️ Suhu: $_temperature °C');
          print('💧 Kelembaban: $_humidity %');
        });
        
        _resetTimeoutTimer();
      }
    } catch (e) {
      print('❌ Error parsing sensor data: $e');
      print('   Raw message: $message');
    }
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _isOnline = false;
          print('⏰ Timeout - Device offline');
        });
      }
    });
  }

  void _resetTimeoutTimer() {
    _timeoutTimer?.cancel();
    _startTimeoutTimer();
  }

  void _sendCommand(String command, dynamic value) {
    final message = jsonEncode({
      'command': command,
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    mqttService.publish(_controlTopic, message);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Perintah "$command" dikirim ke ${widget.device.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    print('🛑 Dispose - Unsubscribe dari $_sensorTopic');
    mqttService.unsubscribe(_sensorTopic);
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: _isOnline 
                      ? const Color(0xFF2ecc71) 
                      : const Color(0xFFe74c3c),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: _isOnline 
                        ? const Color(0xFF2ecc71) 
                        : const Color(0xFFe74c3c),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Perangkat
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF007AFF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Perangkat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow('ID Perangkat', widget.device.deviceId),
                  _buildInfoRow('Lokasi', widget.device.location),
                  _buildInfoRow(
                    'Tanggal Instalasi',
                    DateFormat('dd MMMM yyyy').format(widget.device.installDate),
                  ),
                  _buildInfoRow('Topic MQTT', _sensorTopic),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Data Sensor Real-time
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data Sensor Real-time',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Kartu Suhu
                  _buildSensorCard(
                    icon: Icons.thermostat,
                    label: 'Suhu',
                    value: _temperature.toStringAsFixed(1),
                    unit: '°C',
                    color: const Color(0xFFe74c3c),
                  ),
                  
                  // Kartu Kelembaban
                  _buildSensorCard(
                    icon: Icons.water_drop,
                    label: 'Kelembaban',
                    value: _humidity.toStringAsFixed(1),
                    unit: '%',
                    color: const Color(0xFF3498db),
                  ),
                  
                  // Debug Info
                  Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🔧 Debug Info',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Status: ${_isOnline ? "Online" : "Offline"}'),
                          Text('Topic: $_sensorTopic'),
                          Text('Last Update: ${DateTime.now().toString().substring(11, 19)}'),
                        ],
                      ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7f8c8d),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2c3e50),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5.0),
                        child: Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7f8c8d),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
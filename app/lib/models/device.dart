// lib/models/device.dart
// Model untuk Device - PISAHKAN dari main.dart!

class Device {
  final String name;
  final String deviceId; // Kunci unik untuk topik MQTT
  final DateTime installDate;
  final String location;

  Device({
    required this.name,
    required this.deviceId,
    required this.installDate,
    required this.location,
  });

  // Helper untuk konversi JSON (optional, untuk fitur future)
  Map<String, dynamic> toJson() => {
        'name': name,
        'deviceId': deviceId,
        'installDate': installDate.toIso8601String(),
        'location': location,
      };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        name: json['name'] as String,
        deviceId: json['deviceId'] as String,
        installDate: DateTime.parse(json['installDate'] as String),
        location: json['location'] as String,
      );
}
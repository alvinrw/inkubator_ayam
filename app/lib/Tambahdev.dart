import 'package:flutter/material.dart';

// File placeholder untuk Tambahdev.dart
// Karena di main.dart devices sudah statis, file ini tidak digunakan
// Namun tetap diperlukan agar import di main.dart tidak error

class AddDeviceScreen extends StatelessWidget {
  const AddDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Perangkat'),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Fitur ini tidak digunakan karena devices sudah statis',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
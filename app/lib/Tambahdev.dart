import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/main.dart'; // Import main.dart untuk mengakses class Device

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _deviceNameController = TextEditingController();
  final _deviceIDController = TextEditingController();
  final _installDateController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate; // Untuk menyimpan tanggal yang dipilih

  @override
  void dispose() {
    _deviceNameController.dispose();
    _deviceIDController.dispose();
    _installDateController.dispose();
    _locationController.dispose();
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
        _installDateController.text =
            DateFormat('dd MMMM yyyy').format(picked);
      });
    }
  }

  void _saveDevice() {
    // Validasi sederhana, pastikan nama & ID tidak kosong
    if (_deviceNameController.text.isEmpty ||
        _deviceIDController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Harap isi semua kolom yang ditandai *')),
      );
      return; // Hentikan fungsi jika ada yang kosong
    }

    // Buat objek Device baru dari input
    final newDevice = Device(
      name: _deviceNameController.text,
      deviceId: _deviceIDController.text,
      installDate: _selectedDate!,
      location: _locationController.text,
    );

    // Kirim objek baru ini kembali ke halaman sebelumnya
    Navigator.pop(context, newDevice);
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Perangkat *',
                  hintText: 'Contoh: Inkubator Teras',
                  prefixIcon: Icon(Icons.label_important_outline),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _deviceIDController,
                decoration: const InputDecoration(
                  labelText: 'ID Unik Perangkat *',
                  prefixIcon: Icon(Icons.qr_code_scanner),
                  helperText:
                      'Masukkan ID yang tertera pada stiker perangkat ESP.',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _installDateController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Pemasangan *',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),
              TextField(
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
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Simpan Perangkat',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


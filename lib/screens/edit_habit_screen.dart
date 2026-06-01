import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/habit.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class EditHabitScreen extends StatefulWidget {
  final Habit habit;
  const EditHabitScreen({super.key, required this.habit});

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  late TextEditingController _nameController;
  late TextEditingController _minimalController;
  late TextEditingController _liteController;
  late TextEditingController _fullController;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    _minimalController = TextEditingController(text: widget.habit.minimalVersion);
    _liteController = TextEditingController(text: widget.habit.liteVersion);
    _fullController = TextEditingController(text: widget.habit.fullVersion);
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _minimalController.text.trim().isEmpty ||
        _liteController.text.trim().isEmpty ||
        _fullController.text.trim().isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final userId = await AuthService.getUserId();
    final response = await ApiClient.patch(
      '/users/$userId/habits/${widget.habit.id}',
      {
        'name': _nameController.text.trim(),
        'minimalVersion': _minimalController.text.trim(),
        'liteVersion': _liteController.text.trim(),
        'fullVersion': _fullController.text.trim(),
      },
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      if (mounted) Navigator.pop(context, true);
    } else {
      final error = jsonDecode(response.body);
      setState(() => _error = error['message'] ?? 'Failed to update habit.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Habit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Habit Name'),
            const SizedBox(height: 6),
            _buildTextField(_nameController, 'e.g. Morning Run'),
            const SizedBox(height: 24),

            _buildVersionCard(
              emoji: '😴',
              label: 'Minimal Version',
              subtitle: 'Low energy day (score 1–2)',
              color: const Color(0xFF2A3A2A),
              borderColor: const Color(0xFF3A5A3A),
              controller: _minimalController,
              hint: 'e.g. Walk for 10 mins',
            ),
            const SizedBox(height: 14),

            _buildVersionCard(
              emoji: '⚡',
              label: 'Lite Version',
              subtitle: 'Normal day (score 3)',
              color: const Color(0xFF2A2A1A),
              borderColor: const Color(0xFF5A5A2A),
              controller: _liteController,
              hint: 'e.g. Run for 20 mins',
            ),
            const SizedBox(height: 14),

            _buildVersionCard(
              emoji: '🔥',
              label: 'Full Version',
              subtitle: 'High energy day (score 4–5)',
              color: const Color(0xFF2A1A0A),
              borderColor: const Color(0xFF5A3A1A),
              controller: _fullController,
              hint: 'e.g. Run for 45 mins + stretching',
            ),
            const SizedBox(height: 24),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(_error!,
                    style: const TextStyle(
                        color: Color(0xFFFF6B6B), fontSize: 13)),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 13,
            fontWeight: FontWeight.w500));
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B35)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildVersionCard({
    required String emoji,
    required String label,
    required String subtitle,
    required Color color,
    required Color borderColor,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Color(0xFF555555), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0F0F0F).withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFF6B35)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minimalController.dispose();
    _liteController.dispose();
    _fullController.dispose();
    super.dispose();
  }
}
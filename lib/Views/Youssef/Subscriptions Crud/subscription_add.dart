import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projetflutteryoussef/Models/Youssef/subscription_template.dart';
import 'package:projetflutteryoussef/Models/Youssef/user_subscription.dart';
import 'package:projetflutteryoussef/Views/Youssef/Subscriptions%20Crud/subscriptions_list.dart';
import 'package:projetflutteryoussef/repositories/youssef/subscription_repository.dart';

class SubscriptionAdd extends StatefulWidget {
  const SubscriptionAdd({super.key});

  @override
  State<SubscriptionAdd> createState() => _SubscriptionAddState();
}

class _SubscriptionAddState extends State<SubscriptionAdd> {
  final _formKey = GlobalKey<FormState>();
  final _repository = SubscriptionRepository();

  final TextEditingController _costController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isCustom = false;

  // ✨ TEMPLATES
  List<SubscriptionTemplate> _templates = [];
  SubscriptionTemplate? _selectedTemplate;

  // ✨ CUSTOM
  File? _customImage;
  String? _customImageUrl;
  String? _customName;

  BillingCycle _selectedCycle = BillingCycle.monthly;
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      _templates = await _repository.getTemplates();
      print('✅ Loaded ${_templates.length} templates');
    } catch (e) {
      print('❌ Error: $e');
      _templates = [];
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _customImage = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isCustom && _selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a template'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isCustom && _customImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      bool success;

      if (_isCustom) {
        // ✨ UPLOAD IMAGE FIRST
        _customImageUrl = await _repository.uploadCustomImage(_customImage!.path);
        if (_customImageUrl == null) throw Exception('Upload failed');

        // ✨ ADD CUSTOM
        success = await _repository.addCustomSubscription(
          _nameController.text,
          _customImageUrl!,
          double.parse(_costController.text),
          _selectedCycle,
          _startDate,
          _notesController.text.isEmpty ? null : _notesController.text,
        );
      } else {
        // ✨ ADD FROM TEMPLATE
        success = await _repository.addSubscriptionFromTemplate(
          _selectedTemplate!,
          double.parse(_costController.text),
          _selectedCycle,
          _startDate,
          _notesController.text.isEmpty ? null : _notesController.text,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Subscription added!'),
              backgroundColor: Colors.green,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const SubscriptionsList()),
                  (route) => false,
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to add subscription'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Subscription'),
        actions: [
          IconButton(
            icon: _isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _saveSubscription,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ✨ TOGGLE
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Template'), icon: Icon(Icons.apps)),
                ButtonSegment(value: true, label: Text('Custom'), icon: Icon(Icons.add)),
              ],
              selected: {_isCustom},
              onSelectionChanged: (v) => setState(() => _isCustom = v.first),
            ),
            const SizedBox(height: 24),

            // ✨ TEMPLATE SELECTION
            if (!_isCustom) ...[
              const Text('Choose Template', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _templates.map((t) {
                    final isSelected = _selectedTemplate?.id == t.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTemplate = t),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Card(
                          elevation: isSelected ? 8 : 2,
                          child: Container(
                            width: 140,
                            decoration: BoxDecoration(
                              border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                      image: DecorationImage(
                                        image: NetworkImage(t.imageUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                      child: Icon(Icons.check_circle, color: Colors.blue, size: 40),
                                    )
                                        : null,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Text(t.name, textAlign: TextAlign.center),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              // ✨ CUSTOM SUBSCRIPTION
              const Text('Custom Subscription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: _customImage == null
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 50, color: Colors.grey),
                        Text('Tap to select image'),
                      ],
                    ),
                  )
                      : Image.file(_customImage!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Subscription Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.label),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Enter name' : null,
              ),
            ],

            const SizedBox(height: 16),

            // ✨ COST
            TextFormField(
              controller: _costController,
              decoration: InputDecoration(
                labelText: 'Cost',
                prefixText: '€ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.euro),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Enter cost';
                if (double.tryParse(v!) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ✨ BILLING CYCLE
            DropdownButtonFormField<BillingCycle>(
              value: _selectedCycle,
              decoration: InputDecoration(
                labelText: 'Billing Cycle',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.calendar_month),
              ),
              items: BillingCycle.values.map((c) {
                return DropdownMenuItem(value: c, child: Text(c.displayName));
              }).toList(),
              onChanged: (v) => setState(() => _selectedCycle = v!),
            ),
            const SizedBox(height: 16),

            // ✨ START DATE
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey)),
            ),
            const SizedBox(height: 16),

            // ✨ NOTES
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _costController.dispose();
    _notesController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

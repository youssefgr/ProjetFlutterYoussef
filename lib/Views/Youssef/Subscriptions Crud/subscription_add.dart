import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projetflutteryoussef/Models/Youssef/subscription_template.dart';
import 'package:projetflutteryoussef/Models/Youssef/user_subscription.dart';
import 'package:projetflutteryoussef/Views/Youssef/Subscriptions%20Crud/subscriptions_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projetflutteryoussef/repositories/subscription_repository.dart';

class SubscriptionAdd extends StatefulWidget {
  const SubscriptionAdd({super.key});

  @override
  State<SubscriptionAdd> createState() => _SubscriptionAddState();
}

class _SubscriptionAddState extends State<SubscriptionAdd> {
  final _formKey = GlobalKey<FormState>();
  final _repository = SubscriptionRepository();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isCustom = false;

  List<SubscriptionTemplate> _templates = [];
  SubscriptionTemplate? _selectedTemplate;

  BillingCycle _selectedCycle = BillingCycle.monthly;
  DateTime _startDate = DateTime.now();

  File? _customImage;
  String? _customImageUrl;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    _templates = await _repository.getTemplates();
    setState(() => _isLoading = false);
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
        elevation: 0,
        actions: [
          IconButton(
            icon: _isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
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
            // Toggle between template and custom
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Use Template'),
                  icon: Icon(Icons.apps),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Custom'),
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {_isCustom},
              onSelectionChanged: (Set<bool> selection) {
                setState(() {
                  _isCustom = selection.first;
                  if (!_isCustom) {
                    _customImage = null;
                    _customImageUrl = null;
                    _nameController.clear();
                  } else {
                    _selectedTemplate = null;
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // Template selection or custom input
            if (!_isCustom) ...[
              _buildTemplateSelection(),
            ] else ...[
              _buildCustomSubscription(),
            ],

            const SizedBox(height: 24),

            // Cost field
            TextFormField(
              controller: _costController,
              decoration: InputDecoration(
                labelText: 'Cost',
                prefixText: '€ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.euro),
                helperText: 'Enter the subscription cost',
              ),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a cost';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Billing cycle
            DropdownButtonFormField<BillingCycle>(
              value: _selectedCycle,
              decoration: InputDecoration(
                labelText: 'Billing Cycle',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.calendar_month),
              ),
              items: BillingCycle.values.map((cycle) {
                return DropdownMenuItem(
                  value: cycle,
                  child: Text(cycle.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCycle = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Start date
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.note),
                helperText: 'Add any additional information',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // ✨ AMÉLIORATION : Affichage élégant des templates
  // ✨ MÉTHODE MODIFIÉE : Images qui remplissent le conteneur
  Widget _buildTemplateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a subscription',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Row avec scroll horizontal et cartes améliorées
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                const SizedBox(width: 6),
                ...List.generate(_templates.length, (index) {
                  final template = _templates[index];
                  final isSelected = _selectedTemplate?.id == template.id;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTemplate = template;
                          _nameController.text = template.name;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        transform: Matrix4.identity()
                          ..scale(isSelected ? 1.05 : 1.0),
                        child: Card(
                          elevation: isSelected ? 8 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? Colors.blue : Colors.transparent,
                              width: isSelected ? 2 : 0,
                            ),
                          ),
                          child: Container(
                            width: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: isSelected
                                  ? LinearGradient(
                                colors: [
                                  Colors.blue.shade50,
                                  Colors.blue.shade100,
                                ],
                              )
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Column(
                                children: [
                                  // 🖼️ IMAGE REMPLISSANT LE CONTENEUR
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      width: double.infinity,
                                      color: Colors.grey.shade200,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            template.imageUrl,
                                            fit: BoxFit.cover,
                                            filterQuality: FilterQuality.high,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Center(
                                                child: Icon(
                                                  Icons.subscriptions,
                                                  size: 40,
                                                  color: Colors.grey.shade400,
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child:
                                                CircularProgressIndicator(
                                                  value: loadingProgress
                                                      .expectedTotalBytes !=
                                                      null
                                                      ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                          ),
                                          // Badge de sélection sur l'image
                                          if (isSelected)
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.3),
                                                      blurRadius: 4,
                                                      offset:
                                                      const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // 📝 NOM DU TEMPLATE
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.blue.shade50
                                            : Colors.white,
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          template.name,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.blue.shade700
                                                : Colors.black87,
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Message de sélection
        if (_selectedTemplate == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select a subscription',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You selected: ${_selectedTemplate!.name}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }


  Widget _buildCustomSubscription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Subscription',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Image picker avec meilleur design
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: _customImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _customImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_search,
                      size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to select image',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Boutons d'image avec design amélioré
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Name field
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Subscription Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.label),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        setState(() {
          _customImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isCustom && _selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subscription template'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isCustom && _customImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image for your custom subscription'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String imageUrl;
      String name;

      if (_isCustom) {
        final uploadedUrl = await _repository.uploadCustomImage(
          _customImage!.path,
          _nameController.text,
        );

        if (uploadedUrl == null) {
          throw Exception('Failed to upload image');
        }

        imageUrl = uploadedUrl;
        name = _nameController.text;
      } else {
        imageUrl = _selectedTemplate!.imageUrl;
        name = _selectedTemplate!.name;
      }

      final nextBillingDate =
      _selectedCycle.calculateNextBillingDate(_startDate);
      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

      final subscription = UserSubscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: name,
        imageUrl: imageUrl,
        cost: double.parse(_costController.text),
        billingCycle: _selectedCycle,
        startDate: _startDate,
        nextBillingDate: nextBillingDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isCustom: _isCustom,
      );

      final success = await _repository.addSubscription(subscription);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Subscription added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const SubscriptionsList(),
              ),
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

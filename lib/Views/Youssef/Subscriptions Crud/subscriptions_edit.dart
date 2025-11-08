import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/user_subscription.dart';
import 'package:projetflutteryoussef/repositories/youssef/subscription_repository.dart';

class SubscriptionEdit extends StatefulWidget {
  final UserSubscription subscription;

  const SubscriptionEdit({super.key, required this.subscription});

  @override
  State<SubscriptionEdit> createState() => _SubscriptionEditState();
}

class _SubscriptionEditState extends State<SubscriptionEdit> {
  final _formKey = GlobalKey<FormState>();
  final SubscriptionRepository _repository = SubscriptionRepository();

  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _notesController;

  late BillingCycle _selectedCycle;
  late DateTime _startDate;
  late DateTime _nextBillingDate;
  bool _isActive = true;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subscription.name);
    _costController = TextEditingController(
        text: widget.subscription.cost.toStringAsFixed(2));
    _notesController =
        TextEditingController(text: widget.subscription.notes ?? '');
    _selectedCycle = widget.subscription.billingCycle;
    _startDate = widget.subscription.startDate;
    _nextBillingDate = widget.subscription.nextBillingDate;
    _isActive = widget.subscription.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Subscription'),
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
            onPressed: _isSubmitting ? null : _updateSubscription,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nom
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Subscription Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) =>
              (value == null || value.isEmpty)
                  ? 'Please enter a subscription name'
                  : null,
            ),
            const SizedBox(height: 16),

            // Coût
            TextFormField(
              controller: _costController,
              decoration: InputDecoration(
                labelText: 'Cost',
                prefixText: '€ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.euro),
              ),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the cost';
                }
                if (double.tryParse(value) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Cycle de facturation
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

            // Date de début
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onTap: () => _selectStartDate(),
            ),
            const SizedBox(height: 16),

            // Date du prochain paiement
            ListTile(
              title: const Text('Next Billing Date'),
              subtitle: Text(
                '${_nextBillingDate.day}/${_nextBillingDate.month}/${_nextBillingDate.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onTap: () => _selectNextBillingDate(),
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
                hintText: 'Add any additional information',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Statut Active/Inactive
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton de sauvegarde
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _updateSubscription,
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
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectNextBillingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _nextBillingDate) {
      setState(() {
        _nextBillingDate = picked;
      });
    }
  }

  Future<void> _updateSubscription() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final updatedSubscription = widget.subscription.copyWith(
          name: _nameController.text,
          cost: double.parse(_costController.text),
          billingCycle: _selectedCycle,
          startDate: _startDate,
          nextBillingDate: _nextBillingDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          isActive: _isActive,
        );

        // Mettre à jour dans la base de données
        final success =
        await _repository.updateSubscription(updatedSubscription);

        if (mounted) {
          if (success) {
            Navigator.pop(context, updatedSubscription);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Subscription updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Failed to update subscription'),
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
  }
}

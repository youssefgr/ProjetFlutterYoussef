import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';

class SubscriptionsEdit extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionsEdit({super.key, required this.subscription});

  @override
  State<SubscriptionsEdit> createState() => _SubscriptionsEditState();
}

class _SubscriptionsEditState extends State<SubscriptionsEdit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _costController;

  late List<SubscriptionCycle> _selectedCycles;
  late DateTime _nextPaymentDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subscription.name);
    _costController = TextEditingController(text: widget.subscription.cost.toString());
    _selectedCycles = List.from(widget.subscription.cycles);
    _nextPaymentDate = widget.subscription.nextPaymentDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateSubscription,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Subscription Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter a subscription name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter the cost';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Select Cycles:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8.0,
                children: SubscriptionCycle.values.map((category) {
                  final isSelected = _selectedCycles.contains(category);
                  return FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCycles.add(category);
                        } else {
                          _selectedCycles.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              ListTile(
                title: const Text('Next Payment Date'),
                subtitle: Text(
                    '${_nextPaymentDate.day}/${_nextPaymentDate.month}/${_nextPaymentDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextPaymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _nextPaymentDate) {
      setState(() {
        _nextPaymentDate = picked;
      });
    }
  }

  void _updateSubscription() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCycles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one cycle'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final updatedSubscription = widget.subscription.copyWith(
        name: _nameController.text,
        cost: double.parse(_costController.text),
        cycles: _selectedCycles,
        nextPaymentDate: _nextPaymentDate,
      );

      Navigator.pop(context, updatedSubscription);
    }
  }
}

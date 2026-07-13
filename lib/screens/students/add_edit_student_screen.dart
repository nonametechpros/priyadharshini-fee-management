import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course_type.dart';
import '../../models/student.dart';
import '../../providers/auth_providers.dart';
import '../../providers/service_providers.dart';
import '../../utils/formatters.dart';

class AddEditStudentScreen extends ConsumerStatefulWidget {
  const AddEditStudentScreen({super.key, this.existing});

  final Student? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends ConsumerState<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _amountController;
  late DateTime _dateOfBirth;
  late DateTime _joiningDate;
  late Set<CourseType> _courseTypes;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _firstNameController = TextEditingController(text: existing?.firstName ?? '');
    _lastNameController = TextEditingController(text: existing?.lastName ?? '');
    _phoneController = TextEditingController(text: existing?.phoneNumber ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
    _amountController = TextEditingController(text: existing != null ? existing.totalAmount.toStringAsFixed(0) : '');
    _dateOfBirth = existing?.dateOfBirth ?? DateTime(DateTime.now().year - 18, 1, 1);
    _joiningDate = existing?.joiningDate ?? DateTime.now();
    _courseTypes = existing != null ? {...existing.courseTypes} : {CourseType.mcwg};
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// The most recent date of birth that still makes a student 18 today.
  DateTime get _maxDateOfBirth {
    final now = DateTime.now();
    return DateTime(now.year - 18, now.month, now.day);
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_courseTypes.isEmpty) {
      setState(() => _errorText = 'Select at least one course type.');
      return;
    }
    if (_dateOfBirth.isAfter(_maxDateOfBirth)) {
      setState(() => _errorText = 'Student must be at least 18 years old.');
      return;
    }
    final appUser = ref.read(currentAppUserProvider).valueOrNull;
    if (appUser == null) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final service = ref.read(studentServiceProvider);
      final existing = widget.existing;
      final student = Student(
        id: existing?.id ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _dateOfBirth,
        emailId: existing?.emailId ?? '',
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        joiningDate: _joiningDate,
        courseTypes: _courseTypes,
        totalAmount: double.parse(_amountController.text.trim()),
        amountPaid: existing?.amountPaid ?? 0,
        addedBy: existing?.addedBy ?? appUser.uid,
        addedByName: existing?.addedByName ?? appUser.name,
      );

      if (existing == null) {
        await service.addStudent(student, performedByUid: appUser.uid, performedByName: appUser.name);
      } else {
        await service.updateStudent(student, performedByUid: appUser.uid, performedByName: appUser.name);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorText = 'Could not save student. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Student' : 'Add Student')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last name (optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) return 'Enter a valid 10-digit phone number';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _addressController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 2,
                maxLines: null,
                decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _DateField(
                label: 'Date of birth',
                date: _dateOfBirth,
                onTap: () => _pickDate(
                  initial: _dateOfBirth.isAfter(_maxDateOfBirth) ? _maxDateOfBirth : _dateOfBirth,
                  lastDate: _maxDateOfBirth,
                  onPicked: (d) => setState(() => _dateOfBirth = d),
                ),
              ),
              const SizedBox(height: 14),
              _DateField(
                label: 'Joining date',
                date: _joiningDate,
                onTap: () => _pickDate(initial: _joiningDate, onPicked: (d) => setState(() => _joiningDate = d)),
              ),
              const SizedBox(height: 14),
              Text('Course type', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              ...selectableCourseTypes.map(
                (c) => CheckboxListTile(
                  value: _courseTypes.contains(c),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: Icon(c.icon),
                  title: Text(c.label),
                  onChanged: (checked) => setState(() {
                    if (checked ?? false) {
                      _courseTypes.add(c);
                    } else {
                      _courseTypes.remove(c);
                    }
                  }),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Total course amount', prefixText: '₹ '),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 14),
                Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.isEditing ? 'Save Changes' : 'Add Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined)),
        child: Text(formatDate(date)),
      ),
    );
  }
}

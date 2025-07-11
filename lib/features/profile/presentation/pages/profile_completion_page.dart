import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthday;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your birthday',
    );

    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  void _submitProfile() {
    if (_formKey.currentState!.validate() &&
        _selectedGender != null &&
        _selectedBirthday != null) {
      context.read<AuthBloc>().add(
        AuthUpdateProfileEvent(
          country: _countryController.text.trim(),
          gender: _selectedGender!,
          birthday: _selectedBirthday!,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is AuthAuthenticated) {
          // Profile completion successful, navigate to home
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Your Profile'),
          automaticallyImplyLeading: false, // Prevent going back
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.spacingM),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: UIConstants.spacingL),
                      const Icon(
                        Icons.person_add,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: UIConstants.spacingL),
                      const Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: UIConstants.spacingS),
                      const Text(
                        'Please provide some additional information to complete your registration.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: UIConstants.spacingXL),

                      // Country Field
                      TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          hintText: 'Enter your country',
                          prefixIcon: Icon(Icons.public),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Country is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: UIConstants.spacingM),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        items: _genderOptions.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Gender is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: UIConstants.spacingM),

                      // Birthday Field
                      InkWell(
                        onTap: _selectBirthday,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Birthday',
                            prefixIcon: Icon(Icons.cake),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _selectedBirthday != null
                                ? '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'
                                : 'Select your birthday',
                            style: TextStyle(
                              color: _selectedBirthday != null
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacingXL),

                      // Submit Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: state is AuthLoading
                              ? null
                              : _submitProfile,
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Complete Profile',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:country_picker/country_picker.dart';
import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  Country? _selectedCountry;
  String? _selectedGender;
  DateTime? _selectedBirthday;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  // Local theme tokens to align with app face/design
  static const Color _primaryPink = Color(0xFFFF6B9D);
  static const Color _primaryBlue = Color(0xFF9BC7FB);
  static const BorderRadius _cardRadius = BorderRadius.all(Radius.circular(16));

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
        _selectedCountry != null &&
        _selectedGender != null &&
        _selectedBirthday != null) {
      context.read<AuthBloc>().add(
        AuthUpdateProfileEvent(
          country: _selectedCountry!.name,
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.centerLeft,
              colors: [Color(0xFFD7CAFE), Color(0xFFFFFFFF)],
            ),
          ),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final inputBorder = OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              );

              final focusedBorder = const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: _primaryPink, width: 1.5),
              );

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingM,
                    vertical: UIConstants.spacingM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      // Themed header with gradient and icon
                      //Complete Profile
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Complete Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),

                      //Space and Divider
                      SizedBox(height: UIConstants.spacingM),
                      Divider(color: Colors.white.withValues(alpha: 0.5)),
                      SizedBox(height: UIConstants.spacingM),

                      // Contents
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryPink, _primaryBlue, _primaryPink],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: _cardRadius,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person_add,
                                size: 40,
                                color: _primaryPink,
                              ),
                            ),
                            SizedBox(height: UIConstants.spacingM),
                            Text(
                              'Complete Your Profile',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: UIConstants.spacingS),
                            Text(
                              'Provide a few details to finish setting up your account.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: UIConstants.spacingM),

                      // Card-like form container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: _cardRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(UIConstants.spacingM),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Country Picker
                              InkWell(
                                onTap: () {
                                  showCountryPicker(
                                    context: context,
                                    showPhoneCode: false,
                                    onSelect: (Country country) {
                                      setState(() {
                                        _selectedCountry = country;
                                      });
                                    },
                                    countryListTheme: CountryListThemeData(
                                      bottomSheetHeight: 500,
                                      backgroundColor: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                      inputDecoration: InputDecoration(
                                        labelText: 'Search',
                                        hintText: 'Start typing to search',
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: const Color(
                                              0xFF8C98A8,
                                            ).withValues(alpha: 0.2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Country',
                                    hintText: 'Select your country',
                                    prefixIcon: _selectedCountry != null
                                        ? Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                              _selectedCountry!.flagEmoji,
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.public),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    border: inputBorder,
                                    enabledBorder: inputBorder,
                                    focusedBorder: focusedBorder,
                                    suffixIcon: const Icon(
                                      Icons.arrow_drop_down,
                                    ),
                                  ),
                                  child: Text(
                                    _selectedCountry?.name ??
                                        'Select your country',
                                    style: TextStyle(
                                      color: _selectedCountry != null
                                          ? Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color
                                          : Theme.of(context).hintColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: UIConstants.spacingM),

                              // Gender Dropdown
                              DropdownButtonFormField<String>(
                                value: _selectedGender,
                                decoration: InputDecoration(
                                  labelText: 'Gender',
                                  prefixIcon: const Icon(Icons.person),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  border: inputBorder,
                                  enabledBorder: inputBorder,
                                  focusedBorder: focusedBorder,
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
                                  decoration: InputDecoration(
                                    labelText: 'Birthday',
                                    prefixIcon: const Icon(Icons.cake),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    border: inputBorder,
                                    enabledBorder: inputBorder,
                                    focusedBorder: focusedBorder,
                                  ),
                                  child: Text(
                                    _selectedBirthday != null
                                        ? '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'
                                        : 'Select your birthday',
                                    style: TextStyle(
                                      color: _selectedBirthday != null
                                          ? Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color
                                          : Theme.of(context).hintColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: UIConstants.spacingL),

                      // Submit Button (themed)
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: state is AuthLoading
                              ? null
                              : _submitProfile,
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Complete Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

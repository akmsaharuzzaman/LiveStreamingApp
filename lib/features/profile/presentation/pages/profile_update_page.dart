import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/models/user_model.dart';

class ProfileUpdatePage extends StatefulWidget {
  const ProfileUpdatePage({super.key});

  @override
  State<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _firstNameController = TextEditingController();
  String? _selectedGender; // New state variable for gender
  File? _selectedImage;
  File? _selectedCoverImage;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    // Get current user data from AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUser = authState.user;
      _nameController.text = _currentUser?.name ?? '';
      _firstNameController.text = _currentUser?.firstName ?? '';
      _selectedGender = _currentUser?.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedCoverImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking cover image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submitUpdate() {
    if (_formKey.currentState!.validate()) {
      final hasNameChanged =
          _nameController.text.trim() != (_currentUser?.name ?? '');
      final hasFirstNameChanged =
          _firstNameController.text.trim() != (_currentUser?.firstName ?? '');
      final hasImageChanged = _selectedImage != null;
      final hasCoverImageChanged = _selectedCoverImage != null;
      final hasGenderChanged = _selectedGender != (_currentUser?.gender ?? '');

      if (!hasNameChanged &&
          !hasFirstNameChanged &&
          !hasImageChanged &&
          !hasCoverImageChanged &&
          !hasGenderChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes detected'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      context.read<AuthBloc>().add(
        AuthUpdateUserProfileEvent(
          name: hasNameChanged ? _nameController.text.trim() : null,
          firstName: hasFirstNameChanged
              ? _firstNameController.text.trim()
              : null,
          avatarFile: _selectedImage,
          coverPictureFile: _selectedCoverImage,
          gender: hasGenderChanged
              ? _selectedGender
              : null, // Add gender to event
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Edit Profile', style: TextStyle(fontSize: 18)),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return TextButton(
                  onPressed: state is AuthLoading ? null : _submitUpdate,
                  child: state is AuthLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Cover Photo Section
                      _buildCoverPhotoSection(),

                      // Content section with padding for overlapping profile picture
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.only(
                          top: 60.h, // Space for overlapping profile picture
                          left: 24.w,
                          right: 24.w,
                          bottom: 16.h,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Space for profile picture overlap
                              SizedBox(height: 20.h),

                              // Nick Name Field
                              _buildLabeledField(
                                label: 'Full Name',
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your full name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Gender Field
                              _buildLabeledField(
                                label: 'Gender',
                                child: _buildGenderSelector(),
                              ),
                              const SizedBox(height: 4),

                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  '*The gender of Agency Talent cannot be modified',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Region Field
                              _buildLabeledField(
                                label: 'Region',
                                child: TextFormField(
                                  controller: TextEditingController(
                                    text: 'Bangladesh',
                                  ),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Introduction Field
                              _buildLabeledField(
                                label: 'Introduction',
                                child: TextFormField(
                                  controller: TextEditingController(
                                    text: 'I am a new user',
                                  ),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  maxLines: 3,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Talent Grade
                              _buildProgressSection(
                                title: 'Talent Grade',
                                level: 'MD',
                                showGradeIcon: true,
                              ),
                              const SizedBox(height: 24),

                              // Star
                              _buildProgressSection(
                                title: 'Star',
                                heartCount: '0',
                                level: '0',
                                showExpProgress: true,
                              ),
                              const SizedBox(height: 24),

                              // Wealth
                              _buildProgressSection(
                                title: 'Wealth',
                                level: '1',
                                showExpProgress: true,
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Overlapping Profile Picture
                  Positioned(
                    top: 150.h, // Position to overlap cover photo and content
                    left: 25.w, // Left position
                    child: _buildOverlappingProfilePicture(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCoverPhotoSection() {
    return Stack(
      children: [
        // Cover Photo
        (_currentUser?.coverPicture != null &&
                    _currentUser!.coverPicture!.isNotEmpty) ||
                _selectedCoverImage != null
            ? Container(
                width: double.infinity,
                height: 200.h,
                decoration: const BoxDecoration(color: Colors.white),
                child: _selectedCoverImage != null
                    ? Image.file(_selectedCoverImage!, fit: BoxFit.cover)
                    : Image.network(
                        _currentUser!.coverPicture!,
                        fit: BoxFit.cover,
                      ),
              )
            : Container(
                height: 200.h,
                width: double.infinity,
                color: const Color(0xFF888686),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40.w,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Upload Cover Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

        // Cover photo edit overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
            ),
            child: Center(
              child: GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 20.w, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Change Cover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlappingProfilePicture() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100.w,
        height: 100.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // Profile image
              Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: _getProfileImage(),
                ),
                child: _getProfileImage() == null
                    ? Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),

              // Edit overlay
              Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: const Center(
                  child: Icon(Icons.camera_alt, size: 32, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.pink[300],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Gender dropdown header with dropdown icon
          GestureDetector(
            onTap: () {
              // No need for this since options are always visible
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedGender ?? 'Select gender',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedGender != null
                          ? Colors.grey[800]
                          : Colors.grey[700],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                ],
              ),
            ),
          ),

          // Dropdown options
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Male option
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Male';
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedGender == 'Male'
                                  ? Colors.pink[300]!
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedGender == 'Male'
                                  ? Colors.pink[300]
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Male',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Female option
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Female';
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedGender == 'Female'
                                  ? Colors.pink[300]!
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedGender == 'Female'
                                  ? Colors.pink[300]
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Female',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection({
    required String title,
    required String level,
    bool showGradeIcon = false,
    String? heartCount,
    bool showExpProgress = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title
        SizedBox(
          width: 120,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),

        // Level indicator
        if (heartCount != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  heartCount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: showGradeIcon ? Colors.pink[400] : Colors.pink[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  'Lv $level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        if (showExpProgress) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ],

        if (showExpProgress) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: heartCount != null ? Colors.amber : Colors.pink[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              heartCount ?? 'Lv $level',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  DecorationImage? _getProfileImage() {
    if (_selectedImage != null) {
      return DecorationImage(
        image: FileImage(_selectedImage!),
        fit: BoxFit.cover,
      );
    } else if (_currentUser?.avatar != null ||
        _currentUser?.profilePictureUrl != null) {
      return DecorationImage(
        image: NetworkImage(
          _currentUser!.avatar ?? _currentUser!.profilePictureUrl!,
        ),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  // Additional methods can be added here if needed
}

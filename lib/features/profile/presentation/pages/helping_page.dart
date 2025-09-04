import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/models/user_model.dart';

class HelpingPage extends StatefulWidget {
  final UserModel user;

  const HelpingPage({super.key, required this.user});

  @override
  State<HelpingPage> createState() => _HelpingPageState();
}

class _HelpingPageState extends State<HelpingPage> {
  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _problemController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _submitHelp() {
    if (_problemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your problem')),
      );
      return;
    }

    if (_contactController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide your contact information'),
        ),
      );
      return;
    }

    // TODO: Implement actual submission logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help request submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear form
    _problemController.clear();
    _contactController.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20.sp),
        ),
        title: Text(
          'Helping',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Problem Description Section
            _buildSectionTitle('Problem Description'),
            SizedBox(height: 12.h),
            _buildProblemDescriptionField(),

            SizedBox(height: 30.h),

            // Screenshot Section
            _buildSectionTitle('Screenshot of the issue'),
            SizedBox(height: 12.h),
            _buildScreenshotSection(),

            SizedBox(height: 30.h),

            // Contact Information Section
            _buildSectionTitle('Your contact information'),
            SizedBox(height: 12.h),
            _buildContactField(),

            SizedBox(height: 40.h),

            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildProblemDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          TextField(
            controller: _problemController,
            maxLines: 6,
            maxLength: 500,
            onChanged: (value) =>
                setState(() {}), // Trigger rebuild for counter
            decoration: InputDecoration(
              fillColor: Color(0xFFF5F5F5),
              hintText: 'Please enter a description of your issue',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
              counterText: '',
            ),
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              '${_problemController.text.length}/500',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : Icon(
                    Icons.camera_alt_outlined,
                    size: 40.sp,
                    color: Colors.grey[400],
                  ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Image size should not exceed 5 MB',
          style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
        ),
      ],
    );
  }

  Widget _buildContactField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _contactController,
        decoration: InputDecoration(
          fillColor: Color(0xFFF1F1F1),
          hintText: 'To help us get in touch with you',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16.w),
        ),
        style: TextStyle(fontSize: 14.sp, color: Colors.black87),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: _submitHelp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF69B4), // Pink color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
          elevation: 0,
        ),
        child: Text(
          'Submit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../components/custom_widgets/custom_text_form_field.dart';
import '../../../auth/presentation/bloc/log_in_bloc/log_in_bloc.dart';
import '../bloc/profile_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUidAndDispatchEvent();
    });
    super.initState();
  }

  @override
  void dispose() {
    _nickNameController.dispose();
    _genderController.dispose();
    _bioController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _loadUidAndDispatchEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString('uid');

    if (uid != null && uid.isNotEmpty) {
      print("Userid: $uid");
      context.read<ProfileBloc>().add(ProfileEvent.userDataLoaded(uid: uid));
    } else {
      print("No UID found");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();

    // Try parsing the controller text if it's valid
    if (_birthdayController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(_birthdayController.text);
      } catch (_) {
        // fallback to current date
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      context.read<LogInBloc>().add(
        LogInEvent.birthDayChanged(birthDay: formatted),
      );
      _birthdayController.text = formatted;
    }
  }

  final Map<String, List<String>> tagCategories = {
    'Occupation': ['Doctor', 'Engineer', 'Teacher', 'Designer'],
    'Hobby': ['Reading', 'Gaming', 'Traveling', 'Photography'],
    'Exercise': ['Yoga', 'Running', 'Gym', 'Cycling'],
  };

  String formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return rawDate;
    }
  }

  final Set<String> selectedTags = {};

  final TextEditingController _nickNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) =>
            previous.userProfile != current.userProfile,
        listener: (context, state) async {
          final result = state.userProfile.result;

          if (result != null) {
            _nickNameController.text = result.name ?? '';
            _genderController.text = result.gender ?? '';
            _bioController.text = result.bio ?? 'Welcome to DLStar Live';
            _birthdayController.text = result.birthday ?? '';

            print('Result: $result');
            print('Result First Name: "${result.name}"');
            print('Result Last Gender: "${result.gender}"');
            print('Result Birthday: ${result.birthday}');
            print('Result Bio: "${result.bio}"');
            print('Result Bio: "${result.country}"');
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final formatted = formatDate(
              state.userProfile.result?.birthday ?? '',
            );

            WidgetsBinding.instance.addPostFrameCallback((_) {
              final result = state.userProfile.result;
              if (result != null) {
                _nickNameController.text = result.name ?? '';
                _genderController.text = result.gender ?? '';
                _bioController.text = result.bio ?? 'Welcome to DLStar Live';
                _birthdayController.text = formatted;
              }
            });
            return SingleChildScrollView(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 26.sp),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.pop();
                        },
                        child: Image.asset(
                          "assets/images/new_images/arrow_back.png",
                          height: 18.sp,
                          width: 18.sp,
                          color: Colors.black,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 38.sp),
                        child: Text(
                          "My Profile",
                          style: GoogleFonts.openSans(
                            color: Color(0xff202020),
                            fontWeight: FontWeight.w600,
                            fontSize: 20.sp,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          context.read<ProfileBloc>().add(
                            ProfileEvent.saveUserProfile(
                              context: context,
                              name: _nickNameController.text,
                              birthday: _birthdayController.text,
                              bio: _bioController.text,
                            ),
                          );
                          context.pop();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(
                            0,
                            32,
                          ), // Height: 32, Width will wrap content
                          side: const BorderSide(
                            color: Color(0xff2c3968),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.save,
                              size: 16,
                              color: Color(0xff2c3968),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "Save",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xff2c3968),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.sp),
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // context.pop();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      contentPadding: EdgeInsets.zero,
                                      titlePadding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: const BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: SizedBox(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24.sp,
                                                vertical: 20.sp,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    "Update Image",
                                                    style:
                                                        GoogleFonts.notoSansBengali(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 12.sp,
                                                          color: Colors.black,
                                                        ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      context.pop();
                                                    },
                                                    child: Icon(
                                                      Icons.close,
                                                      color: Colors.black,
                                                      size: 14.sp,
                                                      weight: 10.w,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Divider(
                                              height: 1,
                                              color: Color(0xffE0E0DD),
                                            ),
                                          ],
                                        ),
                                      ),
                                      content: Container(
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.sp,
                                        ),
                                        height: 88.h,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height: 40.h,
                                              child: GestureDetector(
                                                onTap: () {
                                                  context.pop();
                                                  context.read<LogInBloc>().add(
                                                    LogInEvent.imagePicked(
                                                      cameraImage: true,
                                                      context: context,
                                                    ),
                                                  );
                                                },
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    SizedBox(width: 12.w),
                                                    Text(
                                                      "From Camera",
                                                      style:
                                                          GoogleFonts.notoSansBengali(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize: 11.sp,
                                                            color: Colors.black,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Divider(
                                              height: 1.h,
                                              color: const Color(0xffE0E0DD),
                                            ),
                                            SizedBox(
                                              height: 40.h,
                                              child: GestureDetector(
                                                onTap: () {
                                                  context.pop();
                                                  context.read<LogInBloc>().add(
                                                    LogInEvent.imagePicked(
                                                      cameraImage: false,
                                                      context: context,
                                                    ),
                                                  );
                                                },
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    SizedBox(width: 12.w),
                                                    Text(
                                                      "From Gallery",
                                                      style:
                                                          GoogleFonts.notoSansBengali(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize: 11.sp,
                                                            color: Colors.black,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Stack(
                                fit: StackFit.loose,
                                children: [
                                  state.pickedImageFile != null
                                      ? CircleAvatar(
                                          radius: 40.r,
                                          // Size of the avatar
                                          backgroundImage: FileImage(
                                            File(
                                              state.pickedImageFile?.path ?? "",
                                            ),
                                          ),
                                          // Image URL
                                          backgroundColor: Colors
                                              .grey[200], // Fallback background color
                                        )
                                      : state.userProfile.result?.avatar != null
                                      ? CircleAvatar(
                                          radius: 40.r,
                                          // Size of the avatar
                                          backgroundImage: NetworkImage(
                                            state
                                                    .userProfile
                                                    .result
                                                    ?.avatar
                                                    ?.url ??
                                                '',
                                          ),
                                          // Image URL
                                          backgroundColor: Colors
                                              .grey[200], // Fallback background color
                                        )
                                      : CircleAvatar(
                                          radius: 40.r, // Size of the avatar
                                          backgroundImage: const AssetImage(
                                            'assets/images/new_images/profile.png',
                                          ),
                                        ),
                                  Positioned(
                                    bottom: 25.sp,
                                    right: 25.sp,
                                    child: Icon(
                                      Icons.upload_file_rounded,
                                      size: 23.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.sp),
                        Text(
                          "Change Photo",
                          style: GoogleFonts.openSans(
                            color: Color(0xff202020),
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22.sp),
                  Text(
                    "Nickname",
                    style: GoogleFonts.openSans(
                      color: Color(0xff202020),
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 8.sp),
                  CustomTextField(
                    controller: _nickNameController,
                    hintText: "Nickname",
                    validator: (value) {
                      if (state.userProfile.result?.name == null ||
                          state.userProfile.result!.name!.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _nickNameController.text = value;
                    },
                  ),
                  SizedBox(height: 18.sp),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Gender",
                            style: GoogleFonts.openSans(
                              color: Color(0xff202020),
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                            ),
                          ),
                          Text(
                            "  [Cannot be modified] ",
                            style: GoogleFonts.openSans(
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        state.userProfile.result?.gender ?? "",
                        style: GoogleFonts.openSans(
                          color: Color(0xff202020),
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.sp),
                  Text(
                    "Date Of Birth",
                    style: GoogleFonts.openSans(
                      color: Color(0xff202020),
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 8.sp),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: _birthdayController,
                        decoration: InputDecoration(
                          fillColor: Colors.grey.shade200,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.sp),
                            borderSide: BorderSide(
                              width: 1.w,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.sp),
                            borderSide: BorderSide(
                              width: 1.w,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.sp),
                            borderSide: BorderSide(
                              width: 1.w,
                              color: Colors.red,
                            ),
                          ),
                          hintText: 'YYYY-MM-DD',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your birthday';
                          }
                          try {
                            DateFormat('yyyy-MM-dd').parse(value);
                          } catch (e) {
                            return 'Please enter a valid date in YYYY-MM-DD format';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 18.sp),
                  Row(
                    children: [
                      Text(
                        state.userProfile.result?.country ?? "",
                        style: GoogleFonts.openSans(
                          color: Color(0xff202020),
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
                      Text(
                        "  [Cannot be modified] ",
                        style: GoogleFonts.openSans(
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.sp),
                  Text(
                    "Self Introduction",
                    style: GoogleFonts.openSans(
                      color: Color(0xff202020),
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 8.sp),
                  CustomTextField(
                    controller: _bioController,
                    hintText: "Bio",
                    validator: (value) {
                      if (state.userProfile.result?.bio == null ||
                          state.userProfile.result!.bio!.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _bioController.text = value;
                    },
                  ),
                  SizedBox(height: 18.sp),
                  Text(
                    "Interest tags",
                    style: GoogleFonts.openSans(
                      color: Color(0xff202020),
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 8.sp),
                  SizedBox(
                    height: 350.sp,
                    child: ListView(
                      padding: const EdgeInsets.all(0),
                      children: tagCategories.entries.map((entry) {
                        final category = entry.key;
                        final tags = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 15.sp),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tags.map((tag) {
                                final isSelected = selectedTags.contains(tag);
                                return ChoiceChip(
                                  label: Text(tag),
                                  selected: isSelected,
                                  selectedColor: const Color(0xff2c3968),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    side: BorderSide(
                                      color: isSelected
                                          ? const Color(0xff2c3968)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      if (isSelected) {
                                        selectedTags.remove(tag);
                                      } else {
                                        selectedTags.add(tag);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 20.sp),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

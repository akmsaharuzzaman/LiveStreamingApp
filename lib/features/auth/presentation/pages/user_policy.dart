import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class UserPolicyScreen extends StatefulWidget {
  const UserPolicyScreen({super.key});

  @override
  State<UserPolicyScreen> createState() => _UserPolicyScreenState();
}

class _UserPolicyScreenState extends State<UserPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Privacy Policy',
          style: TextStyle(
              fontSize: 18.sp,
              color: Colors.black,
              fontWeight: FontWeight.w500),
        ),
        leading: GestureDetector(
          onTap: () {
            context.pop();
          },
          child: Image.asset(
            'assets/images/new_images/arrow_back.png',
            cacheWidth: 15,
            cacheHeight: 15,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 16),
                  children: [
                    TextSpan(
                      text: ' DJLive Privacy Policy\n\n',
                      style: TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: 'Introduction\n\n',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          'This Privacy Policy explains how DJLive and its affiliated companies ("DJLive," "we," "us") process any personal data we collect from visitors and users of our app.\n\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: 'Information Collection\n\n',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          '- **Voluntary Information**: When you register for an account or use our services, you may be required to provide certain information such as your name, email address, and phone number.\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text:
                          '- **Automatic Data Collection**: Our app may automatically collect data such as device information, usage patterns, and location data (if enabled).\n\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: 'Use of Information\n\n',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '- Provide and improve our services.\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text:
                          '- Enhance user experience through personalized content.\n',
                    ),
                    TextSpan(
                      text:
                          '- Conduct research and analysis to improve our app.\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text:
                          '- Send notifications and updates about our services.\n\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: 'Sharing of Information\n\n',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          'We will not share your personal information with anyone except as described in this Privacy Policy. This includes sharing with third-party service providers necessary for the operation of our app, or as required by law.\n\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: 'Retention of Personal Data\n\n',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          'We will retain your personal data only for as long as is necessary for the purposes set out in this Privacy Policy. We will retain and use your personal data to the extent necessary to comply with our legal obligations, resolve disputes, and enforce our legal agreements and policies.\n\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: 'User Rights\n\n',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          '- **Update Your Information**: You can update your profile information within the app.\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text:
                          '- **Opt-Out**: You can opt-out of having your personal information used for certain purposes.\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text:
                          '- **Request Data Deletion**: You can request the deletion of your personal data by contacting us at [support@DJLive.com](mailto:support@DJLive.com).\n\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: 'Contact Us\n\n',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          'If you have any questions or concerns about this Privacy Policy, please contact us at [support@DJLive.com](mailto:support@DJLive.com).\n',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

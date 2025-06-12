import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final useridController = TextEditingController();
  final passwordController = TextEditingController();
  late InAppWebViewController _webViewController;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/new_images/login_bg.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 45.sp),
                  ClipOval(
                    child: Material(
                      color: Colors.white, // Button color
                      child: InkWell(
                        splashColor: Colors.white, // Splash color
                        onTap: () {
                          context.pop();
                        },
                        child: SizedBox(
                            width: 32.sp,
                            height: 32.sp,
                            child: Image.asset(
                              'assets/images/new_images/arrow_back.png',
                              cacheWidth: 15,
                              cacheHeight: 15,
                            )),
                      ),
                    ),
                  ),
                  SizedBox(height: 45.sp),
                  Container(
                    height: 495.sp,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        color: Colors.white),
                    child: Padding(
                      padding: EdgeInsets.all(14.sp),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/new_images/ic_logo_white.png",
                                height: 120.sp,
                                width: 120.sp,
                                //color: kPrimaryColor,
                              ),
                              SizedBox(height: 18.sp),
                              ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      Color(0xff2c3968),
                                      Color(0xff2c3968)
                                    ],
                                    tileMode: TileMode.clamp,
                                  ).createShader(bounds);
                                },
                                child: Text(
                                  '"Sign in & Dive into the Ultimate Streaming Experience!"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 35.sp),
                          TextFormField(
                            keyboardType: TextInputType.text,
                            controller: useridController,
                            obscureText: false,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 0),
                              // contentPadding: EdgeInsets.zero,

                              filled: true,
                              fillColor: Colors.white,
                              hintText: "Enter your User Id here",
                              hintStyle: TextStyle(
                                  color: const Color(0xff3E5057),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14.sp),
                              suffixIconColor: CupertinoColors.white,
                              prefixIcon: InkWell(
                                onTap: () {},
                                child: Image.asset(
                                    'assets/images/new_images/id.png',
                                    cacheWidth: 25,
                                    cacheHeight: 23),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.sp).r,
                                borderSide: BorderSide(
                                    width: 1.sp,
                                    //color: controller.isEmailValid.value? Colors.green : Colors.red
                                    color: const Color(0xff1D272B)),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.sp),
                                borderSide: BorderSide(
                                    width: 1.w, color: const Color(0xffD9D9D9)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.sp),
                                borderSide: BorderSide(
                                    width: 1.w, color: const Color(0xff1D272B)),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.sp),
                                borderSide:
                                    BorderSide(width: 1.w, color: Colors.red),
                              ),
                            ),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return 'User Id Can Not Be Empty';
                              }
                              return null;
                            },
                            style: TextStyle(
                              color: CupertinoColors.black,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: (String passwordValue) {},
                          ),
                          SizedBox(height: 24.sp),
                          TextFormField(
                            keyboardType: TextInputType.text,
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 0),
                              // contentPadding: EdgeInsets.zero,

                              filled: true,
                              fillColor: Colors.white,
                              hintText: "Enter your password here",
                              hintStyle: TextStyle(
                                  color: const Color(0xff3E5057),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14.sp),
                              suffixIconColor: CupertinoColors.white,
                              prefixIcon: InkWell(
                                onTap: () {},
                                child: Image.asset(
                                    'assets/images/new_images/user_password.png',
                                    cacheWidth: 20,
                                    cacheHeight: 20),
                              ),
                              suffixIcon: InkWell(
                                onTap: () {},
                                child: Icon(
                                    // state.isLogInPasswordObscure
                                    //     ? Icons.visibility_outlined
                                    //     :
                                    Icons.visibility_off_outlined,
                                    color: Colors.black,
                                    size: 20.sp),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.sp).r,
                                borderSide: BorderSide(
                                    width: 1.sp,
                                    //color: controller.isEmailValid.value? Colors.green : Colors.red
                                    color: const Color(0xff1D272B)),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.sp),
                                borderSide: BorderSide(
                                    width: 1.w, color: const Color(0xffD9D9D9)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.sp),
                                borderSide: BorderSide(
                                    width: 1.w, color: const Color(0xff1D272B)),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.sp),
                                borderSide:
                                    BorderSide(width: 1.w, color: Colors.red),
                              ),
                            ),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return 'Password Field Can Not Be Empty';
                              }
                              if (value.length < 8) {
                                return "Password Must Be At Least 8 Characters";
                              }
                              return null;
                            },
                            style: TextStyle(
                              color: CupertinoColors.black,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: (String passwordValue) {},
                          ),
                          SizedBox(height: 39.sp),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return Color(0xff2c3968);
                                  } else {
                                    return Color(0xff2c3968);
                                  }
                                }),
                              ),
                              onPressed: () async {},
                              child: Text(
                                "Login",
                                style: TextStyle(
                                    fontSize: 15.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 27.sp),
                  Row(children: <Widget>[
                    Expanded(child: Divider()),
                    Text(
                      " OR ",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: 14.sp),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  SizedBox(height: 35.sp),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.pressed)) {
                            return Colors.white54;
                          } else {
                            return Colors.white10;
                          }
                        }),
                      ),
                      onPressed: () {},
                      icon: SvgPicture.asset(
                        'assets/svg/ic_google_login.svg',
                        width: 20.sp,
                        height: 20.sp,
                      ),
                      label: Text(
                        "Login with Google",
                        style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

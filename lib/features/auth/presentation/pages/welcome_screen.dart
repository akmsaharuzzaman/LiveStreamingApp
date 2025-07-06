import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../data/repositories/log_in_repository.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> {
  late VideoPlayerController videoController;

  @override
  void initState() {
    _loadBgVideo();
    super.initState();
  }

  void _loadBgVideo() {
    videoController = VideoPlayerController.asset(
      "assets/video/background_video.mp4",
    )..setVolume(0.0);

    videoController.addListener(() {});
    videoController.setLooping(true);
    videoController.initialize().then((_) => setState(() {}));
    videoController.play();
  }

  @override
  void dispose() {
    videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          body: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: VideoPlayer(videoController),
              ),
              Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xff2c3968).withOpacity(0.5.sp),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                child: Container(
                  height: 350.sp,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.sp),
                      topRight: Radius.circular(12.sp),
                    ),
                    color: const Color(0xff2c3968).withOpacity(0.2.sp),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.sp),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 35.r,
                              backgroundColor: Colors.white.withOpacity(0.2.sp),
                              child: Image.asset(
                                "assets/icon/icon.png",
                                height: 90.sp,
                                width: 90.sp,
                                //color: kPrimaryColor,
                              ),
                            ),
                            SizedBox(width: 2),
                            ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.purple.shade200,
                                  ],
                                  tileMode: TileMode.clamp,
                                ).createShader(bounds);
                              },
                              child: const Text(
                                'Stream Anywhere Anytime.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 25.sp),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith((states) {
                                    if (states.contains(
                                      MaterialState.pressed,
                                    )) {
                                      return Colors.white54;
                                    } else {
                                      return Colors.white10;
                                    }
                                  }),
                            ),
                            onPressed: () {
                              LogInRepository().googleLogin(context);
                              // context.read<LogInBloc>().add(
                              //     LogInEvent.googleLogIn(context: context));
                            },
                            icon: SvgPicture.asset(
                              'assets/svg/ic_google_login.svg',
                              width: 20.sp,
                              height: 20.sp,
                            ),
                            label: Text(
                              "Signup with Google",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 18.sp),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith((states) {
                                    if (states.contains(
                                      MaterialState.pressed,
                                    )) {
                                      return Colors.white54;
                                    } else {
                                      return Colors.white10;
                                    }
                                  }),
                            ),
                            onPressed: () {
                              context.push('/login');
                            },
                            icon: Image.asset(
                              'assets/images/new_images/userid.png',
                              width: 22.sp,
                              height: 22.sp,
                            ),
                            label: Text(
                              "Signup with UserId",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 35.sp),
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: 'By continuing, you agree to our ',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.white,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    shadows: const [
                                      Shadow(
                                        color: Colors.white,
                                        offset: Offset(0, -1),
                                      ),
                                    ],
                                    height: 1.5,
                                    fontSize: 11.sp,
                                    color: Colors.transparent,
                                    decoration: TextDecoration.underline,
                                    decorationThickness: 1,
                                    decorationColor: Colors.white,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      context.push('/policy');
                                    },
                                ),
                                TextSpan(
                                  text: ' & ',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.white,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        shadows: const [
                                          Shadow(
                                            color: Colors.white,
                                            offset: Offset(0, -2),
                                          ),
                                        ],
                                        fontSize: 11.sp,
                                        color: Colors.transparent,
                                        decoration: TextDecoration.underline,
                                        decorationThickness: 1,
                                        decorationColor: Colors.white,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          context.push('/policy');
                                        },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/auth/auth_bloc.dart';
import '../widgets/google_signin_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset(
      'assets/images/onboarding/intro_video.mp4',
    );

    _videoController.initialize().then((_) {
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController.setLooping(true);
      _videoController.setVolume(0.0); // Mute the video
      _videoController.play();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginEvent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            children: [
              // Background video
              if (_isVideoInitialized)
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  ),
                ),

              // Dark overlay for better text readability
              Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xff2c3968).withValues(alpha: 0.5.sp),
              ),

              // Login form content
              BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    // Navigate to home on successful login
                    context.go('/');
                  } else if (state is AuthProfileIncomplete) {
                    // Navigate to profile completion page
                    context.go('/profile-completion');
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                },
                child: Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Container(
                    height: 450.sp,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.sp),
                        topRight: Radius.circular(12.sp),
                      ),
                      color: const Color(0xff2c3968).withValues(alpha: 0.2.sp),
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99.r),
                                child: Image.asset(
                                  "assets/icons/icon.png",
                                  height: 90.sp,
                                  width: 90.sp,
                                  //color: kPrimaryColor,
                                ),
                              ),
                              SizedBox(height: 16.sp),
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
                          SizedBox(),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              return CustomButton(
                                text: 'Continue with Google',
                                svgPath: 'assets/icons/google_logo.svg',
                                isLoading: isLoading,
                                onPressed: () {
                                  context.read<AuthBloc>().add(
                                    const AuthGoogleSignInEvent(),
                                  );
                                },
                              );
                            },
                          ),
                          SizedBox(height: 20.sp),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              return CustomButton(
                                text: 'Sign In with UserID',
                                isLoading: isLoading,
                              );
                            },
                          ),
                          SizedBox(height: 35.sp),
                          Center(
                            child: Text.rich(
                              TextSpan(
                                text: 'By continuing, you agree to our ',
                                style: TextStyle(
                                  fontSize: 12.sp,
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
                                      fontSize: 12.sp,
                                      color: Colors.transparent,
                                      decoration: TextDecoration.underline,
                                      decorationThickness: 1,
                                      decorationColor: Colors.white,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        // context.push('/policy');
                                      },
                                  ),
                                  TextSpan(
                                    text: ' & ',
                                    style: TextStyle(
                                      fontSize: 12.sp,
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
                                          fontSize: 12.sp,
                                          color: Colors.transparent,
                                          decoration: TextDecoration.underline,
                                          decorationThickness: 1,
                                          decorationColor: Colors.white,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            // context.push('/policy');
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

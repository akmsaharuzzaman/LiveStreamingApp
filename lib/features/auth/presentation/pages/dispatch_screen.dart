import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:streaming_djlive/features/auth/presentation/pages/profile_signup_complete.dart';

import '../bloc/log_in_bloc/log_in_bloc.dart';

// ignore_for_file: must_be_immutable
class DispatchScreen extends StatefulWidget {
  static String route = "/check";

  const DispatchScreen({super.key});

  @override
  _DispatchScreenState createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LogInBloc>().add(LogInEvent.isProfileComplete());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LogInBloc, LogInState>(
      builder: (context, state) {
        if (!state.isProfileComplete) {
          return ProfileSignupComplete();
        } else {
          context.goNamed('home');
          return SizedBox();
        }
      },
    );
  }
}

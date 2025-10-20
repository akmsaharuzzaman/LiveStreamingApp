import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/audio_room_repository.dart';
import '../service/socket_service_audio.dart';
import 'bloc/audio_room_bloc.dart';

class AudioRoomBlocProvider extends StatelessWidget {
  final Widget child;
  final AudioRoomRepository? repository;

  const AudioRoomBlocProvider({
    super.key,
    required this.child,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AudioRoomBloc>(
      create: (context) {
        final socketService = context.read<AudioSocketService>();
        return AudioRoomBloc(repository ?? AudioRoomRepository(socketService));
      },
      child: child,
    );
  }
}

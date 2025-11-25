import 'package:dlstarlive/features/live_audio/presentation/bloc/audio_room_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svga_easyplayer/flutter_svga_easyplayer.dart';
import 'package:dlstarlive/features/live_audio/presentation/bloc/audio_room_bloc.dart';

const List<String> emojis = [
  'assets/icons/audio_room/emojis/Emoji 1.svga',
  'assets/icons/audio_room/emojis/Emoji 2.svga',
  'assets/icons/audio_room/emojis/Emoji 3.svga',
  'assets/icons/audio_room/emojis/Emoji 4.svga',
  'assets/icons/audio_room/emojis/Emoji 5.svga',
  'assets/icons/audio_room/emojis/Emoji 6.svga',
  'assets/icons/audio_room/emojis/Emoji 7.svga',
  'assets/icons/audio_room/emojis/Emoji 8.svga',
  'assets/icons/audio_room/emojis/Emoji 9.svga',
  'assets/icons/audio_room/emojis/Emoji 10.svga',
  'assets/icons/audio_room/emojis/Emoji 11.svga',
  'assets/icons/audio_room/emojis/Emoji 12.svga',
  'assets/icons/audio_room/emojis/Emoji 13.svga',
];

void showEmojiBottomSheet(BuildContext context, String roomId, String seatKey) {
  showModalBottomSheet(
    context: context,
    isDismissible: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
    backgroundColor: Color(0xFF1A1A2E),
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select an emoji',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 1),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      context.read<AudioRoomBloc>().add(
                        SendAudioEmojiEvent(roomId: roomId, seatKey: seatKey, emoji: "$index"),
                      );
                      Navigator.pop(context);
                    },
                    child: Center(
                      child: SizedBox(width: 50, height: 50, child: SVGAEasyPlayer(assetsName: emojis[index])),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

import 'package:dlstarlive/features/live_audio/presentation/bloc/audio_room_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../live_audio/presentation/bloc/audio_room_state.dart';

void showSendMessageBottomSheet(
  BuildContext context, {
  Function(String)? onSendMessage,
}) {
    // Check if we have a valid room before showing the bottom sheet
  final currentState = context.read<AudioRoomBloc>().state;
  if (currentState is! AudioRoomLoaded || currentState.currentRoomId == null || currentState.currentRoomId!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cannot send message - not connected to a room'), backgroundColor: Colors.red)
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _BottomSheetBackdrop(
      child: ShowMessageBottomsheet(
        onSendMessage:
            onSendMessage ??
            (m) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Message sent!',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              );
            },
      ),
    ),
  );
}

/// Semi–transparent blurred backdrop wrapper (tap to dismiss)
class _BottomSheetBackdrop extends StatelessWidget {
  final Widget child;
  const _BottomSheetBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Stack(
        children: [
          // Dark scrim
          Container(color: Colors.black.withValues(alpha: 0.35)),
          // Bottom sheet content (prevent sheet tap closing)
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(onTap: () {}, child: child),
          ),
        ],
      ),
    );
  }
}

class ShowMessageBottomsheet extends StatefulWidget {
  const ShowMessageBottomsheet({super.key, required this.onSendMessage});
  final Function(String)? onSendMessage;

  @override
  State<ShowMessageBottomsheet> createState() => _ShowMessageBottomsheetState();
}

class _ShowMessageBottomsheetState extends State<ShowMessageBottomsheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Delay focus to after build to ensure animations settle
    Future.microtask(() => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          16.w,
          12.h,
          16.w,
          12.h + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: Offset(0, -4.h),
              blurRadius: 12.r,
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46.w,
                  height: 5.h,
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text input
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 120.h),
                      child: Scrollbar(
                        thumbVisibility: false,
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLines: null,
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.06),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.r),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1.w,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.r),
                              borderSide: BorderSide(
                                color: const Color(0xFF9BC7FB),
                                width: 1.2.w,
                              ),
                            ),
                          ),
                          onSubmitted: (value) => _submit(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  _SendButton(onTap: _submit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendMessage?.call(text);
    Navigator.of(context).maybePop();
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF82A3), Color(0xFF9BC7FB), Color(0xFFFF82A3)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: Offset(0, 3.h),
              blurRadius: 6.r,
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(24.r),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.send_rounded, size: 18.sp, color: Colors.white),
                  SizedBox(width: 6.w),
                  Text(
                    'Send',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:lottie/lottie.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../../components/custom_widgets/quick_help.dart';
import '../../../../components/utilities/chat_theme.dart';

class ChatRoom extends StatefulWidget {
  ChatRoom({super.key, required this.userId});

  @override
  _ChatRoomState createState() => _ChatRoomState();
  final String userId;
}

class _ChatRoomState extends State<ChatRoom> {
  String toggleVoiceKeyboardButton = "assets/svg/ic_voice_message.svg";
  String? sendButtonIcon = "assets/svg/ic_menu_gifters.svg";
  Color sendButtonBackground = MyTheme.kPrimaryColor;
  TextEditingController messageController = TextEditingController();
  bool isTyping = false;
  bool emojiShowing = false;

  void onTyping() {
    setState(() {
      isTyping = true;
    });

    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        isTyping = false;
      });
    });
  }

  _choosePhoto() async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.image,
        filterOptions: FilterOptionGroup(
          containsLivePhotos: false,
        ),
      ),
    );

    if (result != null && result.length > 0) {
      final File? image = await result.first.file;
      cropPhoto(image!.path);
    } else {
      print("Photos null");
    }
  }

  void cropPhoto(String path) async {
    CroppedFile? croppedFile =
        await ImageCropper().cropImage(sourcePath: path, uiSettings: [
      AndroidUiSettings(
          toolbarTitle: "Crop Image",
          toolbarColor: const Color(0xff2c3968),
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false),
      IOSUiSettings(
        minimumAspectRatio: 1.0,
      )
    ]);

    if (croppedFile != null) {
      compressImage(croppedFile.path, setState);
    }
  }

  void compressImage(String path, StateSetter setState) {
    QuickHelp.showLoadingAnimation();

    Future.delayed(Duration(seconds: 1), () async {
      var result = await QuickHelp.compressImage(path);

      if (result != null) {
        uploadFile(result, setState);
      } else {
        QuickHelp.hideLoadingDialog(context);
      }
    });
  }

  uploadFile(XFile imageFile, StateSetter setState) async {
    if (imageFile.path.isNotEmpty) {
    } else {}

    QuickHelp.showLoadingDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60.sp,
        backgroundColor: Colors.white,
        centerTitle: false,
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 22.r,
              backgroundImage: AssetImage(
                '',
                //widget.user.avatar,
              ),
            ),
            SizedBox(
              width: 12.sp,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 135.sp,
                  child: Text(
                    // widget.user.name,
                    "Wahid",
                    style: MyTheme.chatSenderName,
                  ),
                ),
                Text(
                  'online',
                  style: MyTheme.bodyText1.copyWith(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Icon(
            Iconsax.video,
            size: 22.sp,
            color: Color(0xff2c3968),
          ),
          SizedBox(width: 18.sp),
          Icon(
            Iconsax.call,
            size: 22.sp,
            color: Color(0xff2c3968),
          ),
          SizedBox(width: 18.sp),
          Icon(
            Icons.more_vert,
            size: 22.sp,
            color: Color(0xff2c3968),
          ),
          SizedBox(width: 8.sp),
        ],
        elevation: 0,
      ),
      backgroundColor: const Color(0xfff5f5f5),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                color: const Color(0xfff5f5f5),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  // child: Conversation(user: widget.user),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                  top: 20.sp, bottom: 20.sp, left: 20.sp, right: 20.sp),

              // color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 30,
                        width: 30,
                        child: Lottie.asset(
                          "assets/lottie/ic_gift.json",
                          repeat: false,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _choosePhoto(),
                        child: Container(
                          margin: EdgeInsets.only(left: 5.sp),
                          height: 30.sp,
                          width: 30.sp,
                          child: const Icon(
                            Icons.image,
                            color: Color(0xFF656BF9),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: SvgPicture.asset(
                          toggleVoiceKeyboardButton,
                          color: Colors.black.withOpacity(0.7),
                          height: 25,
                          width: 25,
                        ),
                        onPressed: () {
                          setState(
                            () {
                              if (toggleVoiceKeyboardButton ==
                                  "assets/svg/ic_voice_message.svg") {
                                toggleVoiceKeyboardButton =
                                    "assets/svg/ic_keyboard.svg";
                              } else {
                                toggleVoiceKeyboardButton =
                                    "assets/svg/ic_voice_message.svg";
                              }
                            },
                          );
                        },
                      ),
                      Visibility(
                        visible: toggleVoiceKeyboardButton !=
                            "assets/svg/ic_voice_message.svg",
                        child: Expanded(
                          child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B93B1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              height: 35,
                              child: Center(
                                child: Text(
                                  "Press to talk",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: toggleVoiceKeyboardButton ==
                            "assets/svg/ic_voice_message.svg",
                        child: Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B93B1).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            height: 38,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, right: 10, bottom: 7),
                              child: TextFormField(
                                autocorrect: false,
                                keyboardType: TextInputType.multiline,
                                onChanged: (text) {
                                  setState(() {
                                    changeButtonIcon(text);
                                    if (text.isNotEmpty) {
                                      onTyping();
                                    }
                                  });
                                },
                                maxLines: 1,
                                controller: messageController,
                                decoration: InputDecoration(
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        emojiShowing = !emojiShowing;
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          top: 5.sp, left: 20.sp),
                                      height: 30,
                                      width: 30,
                                      child: SvgPicture.asset(
                                          "assets/svg/ic_emoji.svg"),
                                    ),
                                  ),
                                  hintText: "Say something !",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF8B93B1)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.sp),
                      GestureDetector(
                        onTap: () {
                          if (messageController.text.isNotEmpty) {
                            setState(() {
                              messageController.text = "";
                            });
                          }
                        },
                        child: Container(
                          height: 27.sp,
                          width: 65.sp,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.r),
                            color: MyTheme.kPrimaryColor,
                          ),
                          child: Center(
                            child: Text(
                              "Send",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Offstage(
                    offstage: !emojiShowing,
                    child: SizedBox(
                        height: 250,
                        child: EmojiPicker(
                          textEditingController: messageController,
                          config: Config(
                            height: 256,
                            checkPlatformCompatibility: true,
                            emojiViewConfig: EmojiViewConfig(
                              emojiSizeMax: 28 *
                                  (foundation.defaultTargetPlatform ==
                                          TargetPlatform.iOS
                                      ? 1.20
                                      : 1.0),
                            ),
                            skinToneConfig: const SkinToneConfig(),
                            categoryViewConfig: const CategoryViewConfig(),
                            bottomActionBarConfig:
                                const BottomActionBarConfig(),
                            searchViewConfig: const SearchViewConfig(),
                          ),
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void changeButtonIcon(String text) {
    setState(() {
      if (text.isNotEmpty) {
        sendButtonIcon = "assets/svg/ic_send_message.svg";
        sendButtonBackground = MyTheme.kPrimaryColor;
      } else {
        sendButtonIcon = "assets/svg/ic_menu_gifters.svg";
        sendButtonBackground = MyTheme.kPrimaryColor;
      }
    });
  }
}

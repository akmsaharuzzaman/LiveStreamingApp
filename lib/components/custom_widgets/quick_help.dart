import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dlstarlive/components/utilities/chat_theme.dart';
import 'package:universal_platform/universal_platform.dart';

class QuickHelp {
  static const int level1MaxPoint = 11795;
  static const int level2MaxPoint = 31905;
  static const int level3MaxPoint = 69085;
  static const int level4MaxPoint = 129345;
  static const int level5MaxPoint = 209035;
  static const int level6MaxPoint = 309030;
  static const int level7MaxPoint = 400915;
  static const int level8MaxPoint = 500915;
  static const int level9MaxPoint = 610925;
  static const int level10MaxPoint = 709251;
  static const int level11MaxPoint = 839295;
  static const int level12MaxPoint = 909125;
  static const int level13MaxPoint = 1091523;
  static const int level14MaxPoint = 1192053;
  static const int level15MaxPoint = 1293054;
  static const int level16MaxPoint = 1934052;
  static const int level17MaxPoint = 1490059;
  static const int level18MaxPoint = 1598588;
  static const int level19MaxPoint = 1693533;
  static const int level20MaxPoint = 1971523;
  static const int level21MaxPoint = 1890500;
  static const int level22MaxPoint = 1992523;
  static const int level23MaxPoint = 2093545;
  static const int level24MaxPoint = 2193500;
  static const int level25MaxPoint = 2298593;
  static const int level26MaxPoint = 2395930;
  static const int level27MaxPoint = 3395930;
  static const int level28MaxPoint = 4396040;
  static const int level29MaxPoint = 5396550;
  static const int level30MaxPoint = 6397060;
  static const int level31MaxPoint = 7397570;
  static const int level32MaxPoint = 8398080;
  static const int level33MaxPoint = 93958590;
  static const int level34MaxPoint = 1039590100;
  static const int level35MaxPoint = 1139595110;
  static const int level36MaxPoint = 12395100120;

  static bool isWebPlatform() {
    return UniversalPlatform.isWeb;
  }

  static goToNavigatorScreen(
    BuildContext context,
    Widget widget, {
    bool? finish = false,
    bool? back = true,
  }) {
    if (finish == false) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => widget));
    } else {
      Navigator.pushAndRemoveUntil<dynamic>(
        context,
        MaterialPageRoute<dynamic>(builder: (BuildContext context) => widget),
        (route) => back!, //if you want to disable back feature set to false
      );
    }
  }

  static Widget showLoadingAnimation({double size = 35}) {
    return Center(
      child: LoadingAnimationWidget.progressiveDots(
        size: size,
        color: MyTheme.kPrimaryColor,
      ),
    );
  }

  static copyText({required String textToCopy}) {
    Clipboard.setData(ClipboardData(text: textToCopy));
  }

  static Future<XFile?> compressImage(String path, {int quality = 40}) async {
    final dir = await getTemporaryDirectory();
    final targetPath = dir.absolute.path + '/file.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      path,
      targetPath,
      quality: quality,
      rotate: 0,
    );

    return result;
  }

  static void showLoadingDialog(BuildContext context, {bool? isDismissible}) {
    showDialog(
      context: context,
      barrierDismissible: isDismissible != null ? isDismissible : false,
      builder: (BuildContext context) {
        return showLoadingAnimation(); //LoadingDialog();
      },
    );
  }

  static void hideLoadingDialog(BuildContext context, {dynamic result}) {
    Navigator.pop(context, result);
  }

  static bool isAndroidPlatform() {
    return UniversalPlatform.isAndroid;
  }

  static int generateUId() {
    Random rnd = new Random();
    return 1000000000 + rnd.nextInt(999999999);
  }

  static String levelVipBanner({required double currentCredit}) {
    if (currentCredit > 0 && currentCredit <= 9999) {
      return "assets/images/vip_level/ic_vip_1.png";
    } else if (currentCredit >= 10000 && currentCredit <= 49999) {
      return "assets/images/vip_level/ic_vip_2.png";
    } else if (currentCredit >= 50000 && currentCredit <= 99999) {
      return "assets/images/vip_level/ic_vip_3.png";
    } else if (currentCredit >= 100000 && currentCredit <= 199999) {
      return "assets/images/vip_level/ic_vip_4.png";
    } else if (currentCredit >= 200000 && currentCredit <= 499999) {
      return "assets/images/vip_level/ic_vip_5.png";
    } else if (currentCredit >= 500000 && currentCredit <= 999999) {
      return "assets/images/vip_level/ic_vip_6.png";
    } else if (currentCredit >= 1000000 && currentCredit <= 1999999) {
      return "assets/images/vip_level/ic_vip_7.png";
    } else if (currentCredit >= 2000000 && currentCredit <= 4999999) {
      return "assets/images/vip_level/ic_vip_8.png";
    } else if (currentCredit >= 5000000 && currentCredit <= 9999999) {
      return "assets/images/vip_level/ic_vip_9.png";
    } else if (currentCredit >= 10000000) {
      return "assets/images/vip_level/ic_vip_10.png";
    } else {
      return "";
    }
  }

  static String levelImage({required int pointsInApp}) {
    if (pointsInApp <= level1MaxPoint) {
      return "assets/images/level/lv_1.png";
    } else if (pointsInApp <= level2MaxPoint) {
      return "assets/images/level/lv_2.png";
    } else if (pointsInApp <= level3MaxPoint) {
      return "assets/images/level/lv_3.png";
    } else if (pointsInApp <= level4MaxPoint) {
      return "assets/images/level/lv_4.png";
    } else if (pointsInApp <= level5MaxPoint) {
      return "assets/images/level/lv_5.png";
    } else if (pointsInApp <= level6MaxPoint) {
      return "assets/images/level/lv_6.png";
    } else if (pointsInApp <= level7MaxPoint) {
      return "assets/images/level/lv_7.png";
    } else if (pointsInApp <= level8MaxPoint) {
      return "assets/images/level/lv_8.png";
    } else if (pointsInApp <= level9MaxPoint) {
      return "assets/images/level/lv_9.png";
    } else if (pointsInApp <= level10MaxPoint) {
      return "assets/images/level/lv_10.png";
    } else if (pointsInApp <= level11MaxPoint) {
      return "assets/images/level/lv_11.png";
    } else if (pointsInApp <= level12MaxPoint) {
      return "assets/images/level/lv_12.png";
    } else if (pointsInApp <= level13MaxPoint) {
      return "assets/images/level/lv_13.png";
    } else if (pointsInApp <= level14MaxPoint) {
      return "assets/images/level/lv_14.png";
    } else if (pointsInApp <= level15MaxPoint) {
      return "assets/images/level/lv_15.png";
    } else if (pointsInApp <= level16MaxPoint) {
      return "assets/images/level/lv_16.png";
    } else if (pointsInApp <= level17MaxPoint) {
      return "assets/images/level/lv_17.png";
    } else if (pointsInApp <= level18MaxPoint) {
      return "assets/images/level/lv_18.png";
    } else if (pointsInApp <= level19MaxPoint) {
      return "assets/images/level/lv_19.png";
    } else if (pointsInApp <= level20MaxPoint) {
      return "assets/images/level/lv_20.png";
    } else if (pointsInApp <= level21MaxPoint) {
      return "assets/images/level/lv_21.png";
    } else if (pointsInApp <= level22MaxPoint) {
      return "assets/images/level/lv_22.png";
    } else if (pointsInApp <= level23MaxPoint) {
      return "assets/images/level/lv_23.png";
    } else if (pointsInApp <= level24MaxPoint) {
      return "assets/images/level/lv_24.png";
    } else if (pointsInApp <= level25MaxPoint) {
      return "assets/images/level/lv_25.png";
    } else if (pointsInApp <= level26MaxPoint) {
      return "assets/images/level/lv_26.png";
    } else if (pointsInApp <= level27MaxPoint) {
      return "assets/images/level/lv_27.png";
    } else if (pointsInApp <= level28MaxPoint) {
      return "assets/images/level/lv_28.png";
    } else if (pointsInApp <= level29MaxPoint) {
      return "assets/images/level/lv_29.png";
    } else if (pointsInApp <= level30MaxPoint) {
      return "assets/images/level/lv_30.png";
    } else if (pointsInApp <= level31MaxPoint) {
      return "assets/images/level/lv_31.png";
    } else if (pointsInApp <= level32MaxPoint) {
      return "assets/images/level/lv_32.png";
    } else if (pointsInApp <= level33MaxPoint) {
      return "assets/images/level/lv_33.png";
    } else if (pointsInApp <= level34MaxPoint) {
      return "assets/images/level/lv_34.png";
    } else if (pointsInApp <= level35MaxPoint) {
      return "assets/images/level/lv_35.png";
    } else if (pointsInApp <= level36MaxPoint) {
      return "assets/images/level/lv_36.png";
    } else {
      return "assets/images/level/lv_1.png";
    }
  }
}

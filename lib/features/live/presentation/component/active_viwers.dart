import 'package:flutter/material.dart';

import '../../../../core/network/models/joined_user_model.dart';
import '../../../profile/presentation/widgets/user_profile_bottom_sheet.dart';

class ActiveViewers extends StatelessWidget {
  const ActiveViewers({super.key, required this.activeUserList});
  final List<JoinedUserModel> activeUserList;

  @override
  Widget build(BuildContext context) {
    bool isLarge = MediaQuery.of(context).size.width > 400;
    int maxVisible = isLarge ? 3 : 2;
    int hiddenCount = (activeUserList.length - maxVisible) > 0
        ? activeUserList.length - maxVisible
        : 0;
    List visibleUsers = activeUserList.take(maxVisible).toList();
    return Row(
      // spacing: 8,
      children: [
        for (var user in visibleUsers)
          Row(
            children: [
              SizedBox(width: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        UserProfileBottomSheet(userId: user.id),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        child: Image.network(user.avatar, fit: BoxFit.cover),
                      ),
                      // to show the follower count
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha((255 * 0.58).toInt()),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: Text(
                              "2K",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        // to show the remaining user numbers
        if (hiddenCount == 0)
          SizedBox.shrink()
        else
          Transform.translate(
            offset: Offset(-12, 0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
              decoration: BoxDecoration(
                color: Color(0xff888686),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hiddenCount.toString(),
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

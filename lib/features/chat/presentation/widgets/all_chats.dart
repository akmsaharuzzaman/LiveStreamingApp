import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/utilities/chat_theme.dart';
import '../../data/models/message_model.dart';

class AllChats extends StatelessWidget {
  const AllChats({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: Row(
            children: [
              Text(
                'All Chats',
                style: MyTheme.heading2,
              ),
            ],
          ),
        ),
        ListView.builder(
            shrinkWrap: true,
            physics: const ScrollPhysics(),
            itemCount: allChats.length,
            itemBuilder: (context, int index) {
              final allChat = allChats[index];
              return Container(
                  margin: EdgeInsets.only(top: 20.sp),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25.r,
                        backgroundImage: AssetImage(allChat.avatar.toString()),
                      ),
                      SizedBox(
                        width: 20.sp,
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigator.push(context,
                          //     CupertinoPageRoute(builder: (context) {
                          //   return ChatRoom(user: allChat.sender!);
                          // }));
                          context.push('/chat-details/${allChat.sender!.id}');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              allChat.sender?.name ?? "",
                              style: MyTheme.heading1.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              allChat.text ?? "",
                              style: MyTheme.bodyText1,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          allChat.unreadCount == 0
                              ? Icon(
                                  Icons.done_all,
                                  color: MyTheme.bodyTextTime.color,
                                )
                              : CircleAvatar(
                                  radius: 8,
                                  backgroundColor: MyTheme.kUnreadChatBG,
                                  child: Text(
                                    allChat.unreadCount.toString(),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                          SizedBox(
                            height: 10.sp,
                          ),
                          Text(
                            allChat.time ?? "",
                            style: MyTheme.bodyTextTime,
                          )
                        ],
                      ),
                    ],
                  ));
            })
      ],
    );
  }
}

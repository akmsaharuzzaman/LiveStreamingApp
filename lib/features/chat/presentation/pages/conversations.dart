import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/chat_models.dart';

class Conversation extends StatelessWidget {
  const Conversation({Key? key, required this.user}) : super(key: key);

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, int index) {
          final message = messages[index];
          bool isMe = message.sender?.id == currentUser.id;
          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: isMe
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe)
                      Container(
                        margin: EdgeInsets.only(right: 8.w),
                        child: CircleAvatar(
                          radius: 16.r,
                          backgroundImage: NetworkImage(user.avatar),
                        ),
                      ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                          bottomLeft: Radius.circular(isMe ? 20.r : 4.r),
                          bottomRight: Radius.circular(isMe ? 4.r : 20.r),
                        ),
                      ),
                      child: Text(
                        messages[index].text,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: isMe ? Colors.black87 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Row(
                    mainAxisAlignment: isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isMe) SizedBox(width: 40.w),
                      if (isMe)
                        Icon(
                          Icons.done_all,
                          size: 16.sp,
                          color: message.isRead ? Colors.blue : Colors.grey,
                        ),
                      SizedBox(width: 4.w),
                      Text(
                        message.time,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

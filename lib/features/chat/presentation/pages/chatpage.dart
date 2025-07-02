import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../components/utilities/chat_theme.dart';
import '../../data/models/user_model.dart';
import '../widgets/tab_bar.dart';
import 'chatlist.dart';

class ChatPageScreen extends StatefulWidget {
  const ChatPageScreen({super.key});

  @override
  State<ChatPageScreen> createState() => _ChatPageScreenState();
}

class _ChatPageScreenState extends State<ChatPageScreen>
    with TickerProviderStateMixin {
  late TabController tabController;
  int currentTabIndex = 0;

  void _openChatList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatListPage()),
    );
  }

  void _openStatusList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StatusListPage()),
    );
  }

  void _openCallList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CallListPage()),
    );
  }

  void onTabChange() {
    setState(() {
      currentTabIndex = tabController.index;
      print(currentTabIndex);
    });
  }

  @override
  void initState() {
    tabController = TabController(length: 3, vsync: this);

    tabController.addListener(() {
      onTabChange();
    });
    super.initState();
  }

  @override
  void dispose() {
    tabController.addListener(() {
      onTabChange();
    });

    tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(128.sp),
        child: Container(
          color: const Color(0xfffafafa),
          child: Column(
            children: [
              AppBar(
                backgroundColor: const Color(0xfffafafa),
                centerTitle: false,
                title: Text('Messages', style: MyTheme.kAppTitle),
                actions: [
                  IconButton(
                    icon: const Icon(Iconsax.camera, color: Color(0xff2c3968)),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(
                      Iconsax.search_favorite,
                      color: Color(0xff2c3968),
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.more, color: Color(0xff2c3968)),
                    onPressed: () {},
                  ),
                ],
                elevation: 0,
              ),
              MyTabBar(tabController: tabController),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xfffafafa),
      body: Column(
        children: [
          SizedBox(height: 10.sp),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              decoration: BoxDecoration(
                color: const Color(0xfffafafa),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
              ),
              child: TabBarView(
                controller: tabController,
                children: const [
                  ChatPage(),
                  Center(child: Text('Status')),
                  Center(child: Text('Call')),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          switch (currentTabIndex) {
            case 0:
              _openChatList();
              break;
            case 1:
              _openStatusList();
              break;
            case 2:
              _openCallList();
              break;
          }
        },
        backgroundColor: const Color(0xff2c3968).withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Icon(
          currentTabIndex == 0
              ? Iconsax.message
              : currentTabIndex == 1
              ? Iconsax.status
              : Iconsax.call,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ChatListPage extends StatelessWidget {
  List<User> users = [
    User(id: 0, name: 'You', avatar: 'assets/images/new_images/person.png'),
    User(
      id: 1,
      name: 'Addison',
      avatar: 'assets/images/new_images/profile.png',
    ),
    User(id: 2, name: 'Angel', avatar: 'assets/images/new_images/person.png'),
    User(id: 3, name: 'Deanna', avatar: 'assets/images/new_images/profile.png'),
    User(id: 4, name: 'Json', avatar: 'assets/images/new_images/profile.png'),
    User(id: 5, name: 'Judd', avatar: 'assets/images/new_images/person.png'),
    User(id: 6, name: 'Leslie', avatar: 'assets/images/new_images/person.png'),
    User(id: 7, name: 'Nathan', avatar: 'assets/images/new_images/profile.png'),
    User(
      id: 8,
      name: 'Stanley',
      avatar: 'assets/images/new_images/profile.png',
    ),
    User(
      id: 9,
      name: 'Shahadat Vai Astha',
      avatar: 'assets/images/new_images/person.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat List')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(users[index].avatar),
            ),
            title: Text(users[index].name),
            subtitle: const Text('Last message...'),
            trailing: const Icon(Iconsax.message),
          );
        },
      ),
    );
  }
}

class StatusListPage extends StatelessWidget {
  final List<User> users = [
    addison,
    angel,
    deanna,
    jason,
    judd,
    leslie,
    nathan,
    stanley,
    virgil,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status List')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(users[index].avatar),
            ),
            title: Text(users[index].name),
            subtitle: const Text('Today, 12:00 PM'),
          );
        },
      ),
    );
  }
}

class CallListPage extends StatelessWidget {
  final List<User> users = [
    addison,
    angel,
    deanna,
    jason,
    judd,
    leslie,
    nathan,
    stanley,
    virgil,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call List')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(users[index].avatar),
            ),
            title: Text(users[index].name),
            subtitle: const Text('Missed call'),
            trailing: const Icon(Iconsax.call),
          );
        },
      ),
    );
  }
}

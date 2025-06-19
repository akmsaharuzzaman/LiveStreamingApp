import 'package:flutter/material.dart';

enum LiveScreenLeaveOptions { disconnect, muteCall, viewProfile }

class Livescreen extends StatefulWidget {
  const Livescreen({super.key});

  @override
  State<Livescreen> createState() => _LivescreenState();
}

class _LivescreenState extends State<Livescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // replace the container with actual live screen
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(color: Colors.deepPurple),
          ),

          // * This contaimer holds the livestream options,
          SafeArea(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                spacing: 15,
                children: [
                  // this is the top row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // *shows user informations
                      HostInfo(
                        imageUrl: "https://thispersondoesnotexist.com/",
                        name: "Md. Hasibur",
                        id: "154154",
                      ),

                      // *show the viwers
                      ActiveViewers(activeUserList: activeViewers),

                      // * to show the leave button
                      LiveScreenMenuButton(),
                    ],
                  ),

                  //  this is the second row
                  DiamondStarStatus(diamonCount: "100.0k", starCount: "2"),

                  Spacer(),

                  // the bottom buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CustomLiveButton(icon: Icons.chat_bubble_outline, onTap: () {}),
                      CustomLiveButton(icon: Icons.call, onTap: () {}),
                      CustomLiveButton(icon: Icons.mic_off, onTap: () {}),
                      CustomLiveButton(icon: Icons.redeem, onTap: () {}),
                      CustomLiveButton(icon: Icons.music_note, onTap: () {}),
                      CustomLiveButton(icon: Icons.more_vert, onTap: () {}),
                    
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiamondStarStatus extends StatelessWidget {
  const DiamondStarStatus({
    super.key,
    required this.diamonCount,
    required this.starCount,
  });

  final String starCount;
  final String diamonCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Color(0xff888686),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              Image.asset('assets/image.png'),
              Text(
                diamonCount,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Color(0xff888686),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 18),
              Text(
                starCount,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LiveScreenMenuButton extends StatelessWidget {
  const LiveScreenMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xff888686),
        borderRadius: BorderRadius.circular(100),
      ),
      padding: EdgeInsets.all(8),

      child: Center(
        child: PopupMenuButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),

          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: LiveScreenLeaveOptions.disconnect,
                  child: Row(
                    children: [
                      Icon(Icons.call_end, color: Color(0xff888686)),
                      SizedBox(width: 6),
                      Text(
                        "Disconnect",
                        style: TextStyle(color: Color(0xff888686)),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: LiveScreenLeaveOptions.muteCall,
                  child: Row(
                    children: [
                      Icon(Icons.mic_off),
                      SizedBox(width: 6),
                      Text("Mute Call"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: LiveScreenLeaveOptions.viewProfile,
                  child: Row(
                    children: [
                      Icon(Icons.person_outline),
                      SizedBox(width: 6),
                      Text("View Profile"),
                    ],
                  ),
                ),
              ],
          onSelected: (value) {
            if (value == LiveScreenLeaveOptions.disconnect) {
              // disconnect the call
            } else if (value == LiveScreenLeaveOptions.muteCall) {
              // mute the call;
            } else if (value == LiveScreenLeaveOptions.viewProfile) {
              // view the profile
            }
          },
          child: Icon(Icons.logout, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class CustomLiveButton extends StatelessWidget {
  const CustomLiveButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: Color(0xff888686),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class ActiveViewers extends StatelessWidget {
  const ActiveViewers({super.key, required this.activeUserList});
  final List activeUserList;

  @override
  Widget build(BuildContext context) {
    bool isLarge = MediaQuery.of(context).size.width > 400;
    int maxVisible = isLarge ? 4 : 3;
    int hiddenCount = activeUserList.length - maxVisible;
    List visibleUsers = activeUserList.take(maxVisible).toList();
    return Row(
      // spacing: 8,
      children: [
        // to render the user bubbles
        for (var user in visibleUsers)
          Row(
            children: [
              SizedBox(width: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      child: Image.network(
                        "https://thispersondoesnotexist.com/",
                      ),
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
                            user["follower"],
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

        // to show the remaining user numbers
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

class HostInfo extends StatelessWidget {
  const HostInfo({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.id,
  });
  final String imageUrl;
  final String name;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Color(0xFF888686),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        spacing: 5,
        children: [
          // holds the image of the user
          CircleAvatar(
            radius: 18,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.network(imageUrl),
            ),
          ),
          Column(
            spacing: 2,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 16, color: Colors.white)),
              Text(
                "ID: $id",
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const activeViewers = [
  {'dp': 'https://thispersondoesnotexist.com/', 'follower': '1.1M'},
  {'dp': 'https://thispersondoesnotexist.com/', 'follower': '100K'},
  {'dp': 'https://thispersondoesnotexist.com/', 'follower': '5k'},
  {'dp': 'https://thispersondoesnotexist.com/', 'follower': '550'},
  {'dp': 'https://thispersondoesnotexist.com/', 'follower': '1.1M'},
  {'dp': 'https://thispersondoesnotexist.com/', 'follower': '1.1M'},
  {'dp': 'https://thispersondoesnotexist.com/', 'follower': '1.1M'},
];

import 'package:equatable/equatable.dart';

/// Chat user model for chat conversations
class ChatUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final bool isOnline;

  const ChatUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    this.isOnline = false,
  });

  @override
  List<Object?> get props => [id, name, email, avatar, isOnline];

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? json['profilePicture'] ?? '',
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'isOnline': isOnline,
    };
  }
}

/// Chat message model for individual messages
class ChatMessage extends Equatable {
  final String id;
  final String text;
  final ChatUser? sender;
  final ChatUser? receiver;
  final DateTime timestamp;
  final String time;
  final bool seen;
  final String? roomId;
  final String? fileUrl;
  final MessageType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatMessage({
    required this.id,
    required this.text,
    this.sender,
    this.receiver,
    required this.timestamp,
    required this.time,
    this.seen = false,
    this.roomId,
    this.fileUrl,
    this.type = MessageType.text,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    text,
    sender,
    receiver,
    timestamp,
    time,
    seen,
    roomId,
    fileUrl,
    type,
    createdAt,
    updatedAt,
  ];

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      text: json['text'] ?? '',
      sender: json['senderId'] != null
          ? ChatUser.fromJson(
              json['senderId'] is Map<String, dynamic>
                  ? json['senderId']
                  : {'_id': json['senderId'], 'name': '', 'email': ''},
            )
          : null,
      receiver: json['recieverId'] != null || json['receiverId'] != null
          ? ChatUser.fromJson(
              (json['recieverId'] ?? json['receiverId']) is Map<String, dynamic>
                  ? (json['recieverId'] ?? json['receiverId'])
                  : {
                      '_id': (json['recieverId'] ?? json['receiverId']),
                      'name': '',
                      'email': '',
                    },
            )
          : null,
      timestamp: DateTime.parse(
        json['createdAt'] ??
            json['timestamp'] ??
            DateTime.now().toIso8601String(),
      ),
      time:
          json['time'] ??
          _formatTime(
            DateTime.parse(
              json['createdAt'] ??
                  json['timestamp'] ??
                  DateTime.now().toIso8601String(),
            ),
          ),
      seen: json['seen'] ?? json['isRead'] ?? false,
      roomId: json['roomId'],
      fileUrl: json['fileUrl'] ?? json['file'],
      type: json['fileUrl'] != null || json['file'] != null
          ? MessageType.file
          : MessageType.text,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'text': text,
      'senderId': sender?.id,
      'recieverId': receiver?.id,
      'timestamp': timestamp.toIso8601String(),
      'time': time,
      'seen': seen,
      'roomId': roomId,
      'fileUrl': fileUrl,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}

/// Chat conversation model for chat list
class ChatConversation extends Equatable {
  final String id;
  final String? roomId; // Room ID for fetching messages
  final ChatUser? sender;
  final String? text;
  final String? time;
  final int unreadCount;
  final String avatar;
  final DateTime lastMessageTime;
  final bool isActive;
  final bool isSentByMe; // Whether the last message was sent by current user
  final bool isSeen; // Whether the last message was seen

  const ChatConversation({
    required this.id,
    this.roomId,
    required this.sender,
    required this.text,
    required this.time,
    required this.unreadCount,
    required this.avatar,
    required this.lastMessageTime,
    this.isActive = true,
    this.isSentByMe = false,
    this.isSeen = false,
  });

  @override
  List<Object?> get props => [
    id,
    roomId,
    sender,
    text,
    time,
    unreadCount,
    avatar,
    lastMessageTime,
    isActive,
    isSentByMe,
    isSeen,
  ];

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] ?? '',
      roomId: json['roomId'],
      sender: json['sender'] != null ? ChatUser.fromJson(json['sender']) : null,
      text: json['text'],
      time: json['time'],
      unreadCount: json['unreadCount'] ?? 0,
      avatar: json['avatar'] ?? '',
      lastMessageTime: DateTime.parse(
        json['lastMessageTime'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['isActive'] ?? true,
      isSentByMe: json['isSentByMe'] ?? false,
      isSeen: json['isSeen'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'sender': sender?.toJson(),
      'text': text,
      'time': time,
      'unreadCount': unreadCount,
      'avatar': avatar,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'isActive': isActive,
      'isSentByMe': isSentByMe,
      'isSeen': isSeen,
    };
  }
}

/// Message type enum
enum MessageType { text, image, video, audio, file, location, sticker, gif }

/// Conversation model for conversation list from API
class Conversation extends Equatable {
  final String id;
  final String roomId;
  final ChatUser? sender;
  final ChatUser? receiver;
  final String lastMessage;
  final bool seenStatus;
  final List<String> deletedFor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatMessage? lstMsg; // The actual last message object

  const Conversation({
    required this.id,
    required this.roomId,
    this.sender,
    this.receiver,
    required this.lastMessage,
    required this.seenStatus,
    required this.deletedFor,
    required this.createdAt,
    required this.updatedAt,
    this.lstMsg,
  });

  @override
  List<Object?> get props => [
    id,
    roomId,
    sender,
    receiver,
    lastMessage,
    seenStatus,
    deletedFor,
    createdAt,
    updatedAt,
    lstMsg,
  ];

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      sender: json['senderId'] != null
          ? ChatUser.fromJson(json['senderId'])
          : null,
      receiver: json['receiverId'] != null
          ? ChatUser.fromJson(json['receiverId'])
          : null,
      lastMessage: json['lastMessage'] ?? '',
      seenStatus: json['seenStatus'] ?? false,
      deletedFor:
          (json['deletedFor'] as List<dynamic>?)
              ?.map(
                (item) => (item is String) ? item : item['userId'] as String,
              )
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      lstMsg: json['lstMsg'] != null
          ? ChatMessage.fromJson(json['lstMsg'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'senderId': sender?.toJson(),
      'receiverId': receiver?.toJson(),
      'lastMessage': lastMessage,
      'seenStatus': seenStatus,
      'deletedFor': deletedFor,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lstMsg': lstMsg?.toJson(),
    };
  }
}

/// Dummy data for testing - replace with real data from your backend
final ChatUser currentUser = ChatUser(
  id: '1',
  name: 'Me',
  email: 'me@example.com',
  avatar: 'https://i.pravatar.cc/150?img=1',
  isOnline: true,
);

final List<ChatMessage> messages = [
  ChatMessage(
    id: '1',
    text: 'Hello! How are you?',
    sender: ChatUser(
      id: '2',
      name: 'John Doe',
      email: 'john@example.com',
      avatar: 'https://i.pravatar.cc/150?img=2',
      isOnline: true,
    ),
    timestamp: DateTime.now().subtract(Duration(minutes: 10)),
    time: '10:30 AM',
    seen: true,
    createdAt: DateTime.now().subtract(Duration(minutes: 10)),
    updatedAt: DateTime.now().subtract(Duration(minutes: 10)),
  ),
  ChatMessage(
    id: '2',
    text: 'I am doing great, thanks for asking!',
    sender: currentUser,
    timestamp: DateTime.now().subtract(Duration(minutes: 8)),
    time: '10:32 AM',
    seen: true,
    createdAt: DateTime.now().subtract(Duration(minutes: 8)),
    updatedAt: DateTime.now().subtract(Duration(minutes: 8)),
  ),
  ChatMessage(
    id: '3',
    text: 'Are you coming to the party tonight?',
    sender: ChatUser(
      id: '2',
      name: 'John Doe',
      email: 'john@example.com',
      avatar: 'https://i.pravatar.cc/150?img=2',
      isOnline: true,
    ),
    timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    time: '10:35 AM',
    seen: false,
    createdAt: DateTime.now().subtract(Duration(minutes: 5)),
    updatedAt: DateTime.now().subtract(Duration(minutes: 5)),
  ),
];

final List<ChatConversation> allChats = [
  ChatConversation(
    id: '1',
    sender: ChatUser(
      id: '2',
      name: 'John Doe',
      email: 'john@example.com',
      avatar: 'https://i.pravatar.cc/150?img=2',
      isOnline: true,
    ),
    text: 'Are you coming to the party tonight?',
    time: '10:35 AM',
    unreadCount: 2,
    avatar: 'https://i.pravatar.cc/150?img=2',
    lastMessageTime: DateTime.now().subtract(Duration(minutes: 5)),
  ),
  ChatConversation(
    id: '2',
    sender: ChatUser(
      id: '3',
      name: 'Sarah Wilson',
      email: 'sarah@example.com',
      avatar: 'https://i.pravatar.cc/150?img=3',
      isOnline: false,
    ),
    text: 'Thanks for the help!',
    time: '9:20 AM',
    unreadCount: 0,
    avatar: 'https://i.pravatar.cc/150?img=3',
    lastMessageTime: DateTime.now().subtract(Duration(hours: 1)),
  ),
  ChatConversation(
    id: '3',
    sender: ChatUser(
      id: '4',
      name: 'Mike Johnson',
      email: 'mike@example.com',
      avatar: 'https://i.pravatar.cc/150?img=4',
      isOnline: true,
    ),
    text: 'See you tomorrow!',
    time: 'Yesterday',
    unreadCount: 1,
    avatar: 'https://i.pravatar.cc/150?img=4',
    lastMessageTime: DateTime.now().subtract(Duration(days: 1)),
  ),
  ChatConversation(
    id: '4',
    sender: ChatUser(
      id: '5',
      name: 'Emily Davis',
      email: 'emily@example.com',
      avatar: 'https://i.pravatar.cc/150?img=5',
      isOnline: true,
    ),
    text: 'Good morning! How was your weekend?',
    time: '8:15 AM',
    unreadCount: 0,
    avatar: 'https://i.pravatar.cc/150?img=5',
    lastMessageTime: DateTime.now().subtract(Duration(hours: 2)),
  ),
  ChatConversation(
    id: '5',
    sender: ChatUser(
      id: '6',
      name: 'Alex Brown',
      email: 'alex@example.com',
      avatar: 'https://i.pravatar.cc/150?img=6',
      isOnline: false,
    ),
    text: 'Let me know when you are free',
    time: '7:45 AM',
    unreadCount: 1,
    avatar: 'https://i.pravatar.cc/150?img=6',
    lastMessageTime: DateTime.now().subtract(Duration(hours: 3)),
  ),
];

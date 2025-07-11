import 'package:equatable/equatable.dart';

/// Chat user model for chat conversations
class ChatUser extends Equatable {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;

  const ChatUser({
    required this.id,
    required this.name,
    required this.avatar,
    this.isOnline = false,
  });

  @override
  List<Object?> get props => [id, name, avatar, isOnline];

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'avatar': avatar, 'isOnline': isOnline};
  }
}

/// Chat message model for individual messages
class ChatMessage extends Equatable {
  final String id;
  final String text;
  final ChatUser? sender;
  final DateTime timestamp;
  final String time;
  final bool isRead;
  final MessageType type;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    required this.time,
    this.isRead = false,
    this.type = MessageType.text,
  });

  @override
  List<Object?> get props => [id, text, sender, timestamp, time, isRead, type];

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      sender: json['sender'] != null ? ChatUser.fromJson(json['sender']) : null,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      time: json['time'] ?? '',
      isRead: json['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender?.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'time': time,
      'isRead': isRead,
      'type': type.name,
    };
  }
}

/// Chat conversation model for chat list
class ChatConversation extends Equatable {
  final String id;
  final ChatUser? sender;
  final String? text;
  final String? time;
  final int unreadCount;
  final String avatar;
  final DateTime lastMessageTime;
  final bool isActive;

  const ChatConversation({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    required this.unreadCount,
    required this.avatar,
    required this.lastMessageTime,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
    id,
    sender,
    text,
    time,
    unreadCount,
    avatar,
    lastMessageTime,
    isActive,
  ];

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] ?? '',
      sender: json['sender'] != null ? ChatUser.fromJson(json['sender']) : null,
      text: json['text'],
      time: json['time'],
      unreadCount: json['unreadCount'] ?? 0,
      avatar: json['avatar'] ?? '',
      lastMessageTime: DateTime.parse(
        json['lastMessageTime'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender?.toJson(),
      'text': text,
      'time': time,
      'unreadCount': unreadCount,
      'avatar': avatar,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'isActive': isActive,
    };
  }
}

/// Message type enum
enum MessageType { text, image, video, audio, file, location, sticker, gif }

/// Dummy data for testing - replace with real data from your backend
final ChatUser currentUser = ChatUser(
  id: '1',
  name: 'Me',
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
      avatar: 'https://i.pravatar.cc/150?img=2',
      isOnline: true,
    ),
    timestamp: DateTime.now().subtract(Duration(minutes: 10)),
    time: '10:30 AM',
    isRead: true,
  ),
  ChatMessage(
    id: '2',
    text: 'I am doing great, thanks for asking!',
    sender: currentUser,
    timestamp: DateTime.now().subtract(Duration(minutes: 8)),
    time: '10:32 AM',
    isRead: true,
  ),
  ChatMessage(
    id: '3',
    text: 'Are you coming to the party tonight?',
    sender: ChatUser(
      id: '2',
      name: 'John Doe',
      avatar: 'https://i.pravatar.cc/150?img=2',
      isOnline: true,
    ),
    timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    time: '10:35 AM',
    isRead: false,
  ),
];

final List<ChatConversation> allChats = [
  ChatConversation(
    id: '1',
    sender: ChatUser(
      id: '2',
      name: 'John Doe',
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

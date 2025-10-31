# Audio Room Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         AUDIO ROOM SYSTEM ARCHITECTURE                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐  │
│  │                          PRESENTATION LAYER                                  │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐ │  │
│  │  │  Pages: audio_golive_screen.dart                                       │ │  │
│  │  │  Widgets:                                                              │ │  │
│  │  │    - seat_widget.dart (Seat UI)                                        │ │  │
│  │  │    - chat_widget.dart (Chat UI)                                        │ │  │
│  │  │    - joined_member_page.dart (Members List)                            │ │  │
│  │  │    - listeners_list_page.dart (Listeners)                              │ │  │
│  │  │    - gift_bottom_sheet.dart (Gifts)                                    │ │  │
│  │  │    - show_host_menu_bottomsheet.dart (Host Controls)                   │ │  │
│  │  │    - show_audiance_menu_bottom_sheet.dart (Audience Controls)          │ │  │
│  │  └────────────────────────────────────────────────────────────────────────┘ │  │
│  │                              ▲                                               │  │
│  │                              │ listens to                                    │  │
│  │                              │                                               │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐ │  │
│  │  │  BLoC: AudioRoomBloc                                                   │ │  │
│  │  │  State: AudioRoomState                                                 │ │  │
│  │  │    - AudioRoomInitial                                                  │ │  │
│  │  │    - AudioRoomLoading                                                  │ │  │
│  │  │    - AudioRoomLoaded                                                   │ │  │
│  │  │    - AudioRoomError                                                    │ │  │
│  │  │                                                                        │ │  │
│  │  │  Events: audio_room_event.dart                                         │ │  │
│  │  │    - Connection: ConnectToSocket, DisconnectFromSocket                 │ │  │
│  │  │    - Room: CreateRoomEvent, JoinRoomEvent, LeaveRoomEvent              │ │  │
│  │  │    - Seat: JoinSeatEvent, LeaveSeatEvent, RemoveFromSeatEvent          │ │  │
│  │  │    - Chat: SendMessageEvent                                            │ │  │
│  │  │    - User: BanUserEvent, MuteUnmuteUserEvent                           │ │  │
│  │  │    - Stream: UpdateHostBonusEvent, UserJoinedEvent, etc.               │ │  │
│  │  └────────────────────────────────────────────────────────────────────────┘ │  │
│  │                              ▲                                               │  │
│  │                              │ processes events                              │  │
│  │                              │                                               │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐ │  │
│  │  │  Repository: AudioRoomRepository                                       │ │  │
│  │  │  Exposes streams:                                                      │ │  │
│  │  │    - connectionStatusStream                                            │ │  │
│  │  │    - audioRoomDetailsStream                                            │ │  │
│  │  │    - joinRoomStream, leaveRoomStream                                   │ │  │
│  │  │    - joinSeatStream, leaveSeatStream                                   │ │  │
│  │  │    - sendMessageStream                                                │ │  │
│  │  │    - muteUnmuteUserStream, banUserStream                               │ │  │
│  │  │    - updateHostBonusStream                                             │ │  │
│  │  │    - errorMessageStream                                                │ │  │
│  │  └────────────────────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐  │
│  │                          SERVICE LAYER                                       │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐ │  │
│  │  │  AudioSocketService (Main Service)                                     │ │  │
│  │  │  Composition Pattern:                                                  │ │  │
│  │  │                                                                        │ │  │
│  │  │  ├─ AudioSocketConnectionManager                                       │ │  │
│  │  │  │   └─ Handles: connect(), disconnect(), reconnect()                  │ │  │
│  │  │  │                                                                     │ │  │
│  │  │  ├─ AudioSocketEventListeners                                          │ │  │
│  │  │  │   └─ Handles: socket event parsing & stream controllers             │ │  │
│  │  │  │                                                                     │ │  │
│  │  │  ├─ AudioSocketRoomOperations                                          │ │  │
│  │  │  │   └─ Handles: createRoom(), joinRoom(), leaveRoom(), deleteRoom()   │ │  │
│  │  │  │                                                                     │ │  │
│  │  │  ├─ AudioSocketSeatOperations                                          │ │  │
│  │  │  │   └─ Handles: joinSeat(), leaveSeat(), removeFromSeat()             │ │  │
│  │  │  │                                                                     │ │  │
│  │  │  └─ AudioSocketUserOperations                                          │ │  │
│  │  │      └─ Handles: banUser(), muteUnmuteUser(), unbanUser()              │ │  │
│  │  │                                                                        │ │  │
│  │  └────────────────────────────────────────────────────────────────────────┘ │  │
│  │                              ▲                                               │  │
│  │                              │ uses                                          │  │
│  │                              │                                               │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐ │  │
│  │  │  Socket Constants: socket_constants.dart                               │ │  │
│  │  │  Event Names:                                                          │ │  │
│  │  │    - Room: create-audio-room, join-audio-room, leave-audio-room        │ │  │
│  │  │    - Seat: join-seat, leave-seat, remove-from-seat                     │ │  │
│  │  │    - Chat: send-message                                                │ │  │
│  │  │    - User: mute-user, ban-user, unban-user                             │ │  │
│  │  │    - Updates: update-audio-host-coins, user-joined, user-left          │ │  │
│  │  └────────────────────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐  │
│  │                          DATA LAYER                                          │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐ │  │
│  │  │  Models:                                                               │ │  │
│  │  │    - AudioRoomDetails: Complete room data                              │ │  │
│  │  │    - AudioMember: User info (name, avatar, hostBonus, isMuted)         │ │  │
│  │  │    - SeatModel: Seat configuration                                     │ │  │
│  │  │    - JoinedSeat: Seat occupancy                                        │ │  │
│  │  │    - AudioChatModel: Chat messages                                     │ │  │
│  │  └────────────────────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐  │
│  │                          SOCKET LAYER                                        │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐ │  │
│  │  │  Socket.IO Connection                                                 │ │  │
│  │  │  Real-time bidirectional communication with server                     │ │  │
│  │  └────────────────────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Room Operations Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ROOM OPERATIONS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  CREATE ROOM                                                                │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ UI: CreateRoomEvent(roomId, title, numberOfSeats)                   │  │
│  │  ↓                                                                   │  │
│  │ BLoC: _onCreateRoom()                                               │  │
│  │  ↓                                                                   │  │
│  │ Repository: createRoom()                                            │  │
│  │  ↓                                                                   │  │
│  │ Service: AudioSocketRoomOperations.createRoom()                     │  │
│  │  ↓                                                                   │  │
│  │ Socket: emit('create-audio-room', {...})                            │  │
│  │  ↓                                                                   │  │
│  │ Server processes & responds                                         │  │
│  │  ↓                                                                   │  │
│  │ Socket: on('create-audio-room', data) → Stream                      │  │
│  │  ↓                                                                   │  │
│  │ BLoC: Subscription listens → add(CreateRoomEvent)                   │  │
│  │  ↓                                                                   │  │
│  │ State: AudioRoomLoaded(roomData: AudioRoomDetails)                  │  │
│  │  ↓                                                                   │  │
│  │ UI: BlocBuilder rebuilds with room data                             │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  JOIN ROOM                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ UI: JoinRoomEvent(roomId)                                            │  │
│  │  ↓                                                                   │  │
│  │ BLoC: _onJoinRoom()                                                 │  │
│  │  ↓                                                                   │  │
│  │ Repository: joinRoom(roomId)                                        │  │
│  │  ↓                                                                   │  │
│  │ Service: AudioSocketRoomOperations.joinRoom()                       │  │
│  │  ↓                                                                   │  │
│  │ Socket: emit('join-audio-room', {roomId})                           │  │
│  │  ↓                                                                   │  │
│  │ Server adds user to room & broadcasts                               │  │
│  │  ↓                                                                   │  │
│  │ Socket: on('join-audio-room', memberData) → Stream                  │  │
│  │  ↓                                                                   │  │
│  │ BLoC: Subscription → add(UserJoinedEvent)                           │  │
│  │  ↓                                                                   │  │
│  │ State: Update members list in AudioRoomDetails                      │  │
│  │  ↓                                                                   │  │
│  │ UI: Members list updates                                            │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  LEAVE ROOM                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ UI: LeaveRoomEvent(roomId)                                           │  │
│  │  ↓                                                                   │  │
│  │ BLoC: _onLeaveRoom()                                                │  │
│  │  ↓                                                                   │  │
│  │ Repository: leaveRoom(roomId)                                       │  │
│  │  ↓                                                                   │  │
│  │ Service: AudioSocketRoomOperations.leaveRoom()                      │  │
│  │  ↓                                                                   │  │
│  │ Socket: emit('leave-audio-room', {roomId})                          │  │
│  │  ↓                                                                   │  │
│  │ Server removes user & broadcasts                                    │  │
│  │  ↓                                                                   │  │
│  │ Socket: on('leave-audio-room', data) → Stream                       │  │
│  │  ↓                                                                   │  │
│  │ BLoC: Subscription → add(UserLeftEvent)                             │  │
│  │  ↓                                                                   │  │
│  │ State: Update members list, clear room if host left                 │  │
│  │  ↓                                                                   │  │
│  │ UI: Navigate away or show empty room                                │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Seat Management Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SEAT OPERATIONS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  JOIN SEAT                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ UI: JoinSeatEvent(roomId, seatKey, targetId)                        │  │
│  │  ↓                                                                   │  │
│  │ BLoC: _onJoinSeat()                                                 │  │
│  │  ↓                                                                   │  │
│  │ Repository: joinSeat(roomId, seatKey, targetId)                     │  │
│  │  ↓                                                                   │  │
│  │ Service: AudioSocketSeatOperations.joinSeat()                       │  │
│  │  ↓                                                                   │  │
│  │ Socket: emit('join-seat', {roomId, seatKey, targetId})              │  │
│  │  ↓                                                                   │  │
│  │ Server validates & assigns seat                                     │  │
│  │  ↓                                                                   │  │
│  │ Socket: on('join-seat', seatData) → Stream                          │  │
│  │  ↓                                                                   │  │
│  │ BLoC: Subscription → Update seatsData in AudioRoomDetails           │  │
│  │  ↓                                                                   │  │
│  │ State: AudioRoomLoaded with updated seats                           │  │
│  │  ↓                                                                   │  │
│  │ UI: Seat widget shows occupied seat                                 │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  LEAVE SEAT                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ UI: LeaveSeatEvent(roomId, seatKey, targetId)                       │  │
│  │  ↓                                                                   │  │
│  │ BLoC: _onLeaveSeat()                                                │  │
│  │  ↓                                                                   │  │
│  │ Repository: leaveSeat(roomId, seatKey, targetId)                    │  │
│  │  ↓                                                                   │  │
│  │ Service: AudioSocketSeatOperations.leaveSeat()                      │  │
│  │  ↓                                                                   │  │
│  │ Socket: emit('leave-seat', {roomId, seatKey, targetId})             │  │
│  │  ↓                                                                   │  │
│  │ Server releases seat                                                │  │
│  │  ↓                                                                   │  │
│  │ Socket: on('leave-seat', seatData) → Stream                         │  │
│  │  ↓                                                                   │  │
│  │ BLoC: Subscription → Update seatsData                               │  │
│  │  ↓                                                                   │  │
│  │ UI: Seat widget shows empty seat                                    │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  REMOVE FROM SEAT (Host only)                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ UI: RemoveFromSeatEvent(roomId, seatKey, targetId)                  │  │
│  │  ↓                                                                   │  │
│  │ BLoC: _onRemoveFromSeat()                                           │  │
│  │  ↓                                                                   │  │
│  │ Repository: removeFromSeat(roomId, seatKey, targetId)               │  │
│  │  ↓                                                                   │  │
│  │ Service: AudioSocketSeatOperations.removeFromSeat()                 │  │
│  │  ↓                                                                   │  │
│  │ Socket: emit('remove-from-seat', {roomId, seatKey, targetId})       │  │
│  │  ↓                                                                   │  │
│  │ Server removes user from seat                                       │  │
│  │  ↓                                                                   │  │
│  │ Socket: on('remove-from-seat', seatData) → Stream                   │  │
│  │  ↓                                                                   │  │
│  │ BLoC: Subscription → Update seatsData                               │  │
│  │  ↓                                                                   │  │
│  │ UI: Seat widget shows empty seat, removed user notified             │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Chat & Messaging Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CHAT OPERATIONS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  SEND MESSAGE                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ UI: SendMessageEvent(roomId, message)                               │  │
│  │  ↓                                                                   │  │
│  │ BLoC: _onSendMessage()                                              │  │
│  │  ↓                                                                   │  │
│  │ Repository: sendMessage(roomId, message)                            │  │
│  │  ↓                                                                   │  │
│  │ Service: AudioSocketRoomOperations.sendMessage()                    │  │
│  │  ↓                                                                   │  │
│  │ Socket: emit('send-message', {roomId, message, userId, timestamp})  │  │
│  │  ↓                                                                   │  │
│  │ Server broadcasts to all room members                               │  │
│  │  ↓                                                                   │  │
│  │ Socket: on('send-message', chatData) → Stream                       │  │
│  │  ↓                                                                   │  │
│  │ BLoC: Subscription → add(NewMessageReceivedEvent)                   │  │
│  │  ↓                                                                   │  │
│  │ State: Append AudioChatModel to messages list                       │  │
│  │  ↓                                                                   │  │
│  │ UI: Chat widget displays new message                                │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## User Management Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          USER MANAGEMENT                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  MUTE/UNMUTE USER (Host only)                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ UI: MuteUnmuteUserEvent(userId)                                     │  │
│  │  ↓                                                                   │  │
│  │ BLoC: _onMuteUnmuteUser()                                           │  │
│  │  ↓                                                                   │  │
│  │ Repository: muteUnmuteUser(userId)                                  │  │
│  │  ↓                                                                   │  │
│  │ Service: AudioSocketUserOperations.muteUnmuteUser()                 │  │
│  │  ↓                                                                   │  │
│  │ Socket: emit('mute-user', {userId})                                 │  │
│  │  ↓                                                                   │  │
│  │ Server toggles mute status                                          │  │
│  │  ↓                                                                   │  │
│  │ Socket: on('mute-user', userData) → Stream                          │  │
│  │  ↓                                                                   │  │
│  │ BLoC: Subscription → add(UserMutedEvent)                            │  │
│  │  ↓                                                                   │  │
│  │ State: Update AudioMember.isMuted in members list                   │  │
│  │  ↓                                                                   │  │
│  │ UI: Member widget shows muted indicator                             │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  BAN USER (Host only)                                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ UI: BanUserEvent(userId)                                            │  │
│  │  ↓                                                                   │  │
│  │ BLoC: _onBanUser()                                                  │  │
│  │  ↓                                                                   │  │
│  │ Repository: banUser(userId)                                         │  │
│  │  ↓                                                                   │  │
│  │ Service: AudioSocketUserOperations.banUser()                        │  │
│  │  ↓                                                                   │  │
│  │ Socket: emit('ban-user', {userId})                                  │  │
│  │  ↓                                                                   │  │
│  │ Server bans user from room                                          │  │
│  │  ↓                                                                   │  │
│  │ Socket: on('ban-user', userData) → Stream                           │  │
│  │  ↓                                                                   │  │
│  │ BLoC: Subscription → add(UserBannedEvent)                           │  │
│  │  ↓                                                                   │  │
│  │ State: Remove user from members list                                │  │
│  │  ↓                                                                   │  │
│  │ UI: Member removed from UI, user kicked from room                   │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  UNBAN USER (Host only)                                                     │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ UI: UnbanUserEvent(userId)                                          │  │
│  │  ↓                                                                   │  │
│  │ BLoC: _onUnbanUser()                                                │  │
│  │  ↓                                                                   │  │
│  │ Repository: unbanUser(userId)                                       │  │
│  │  ↓                                                                   │  │
│  │ Service: AudioSocketUserOperations.unbanUser()                      │  │
│  │  ↓                                                                   │  │
│  │ Socket: emit('unban-user', {userId})                                │  │
│  │  ↓                                                                   │  │
│  │ Server removes ban                                                  │  │
│  │  ↓                                                                   │  │
│  │ Socket: on('unban-user', userData) → Stream                         │  │
│  │  ↓                                                                   │  │
│  │ BLoC: Subscription → Update state                                   │  │
│  │  ↓                                                                   │  │
│  │ UI: User can rejoin room                                            │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## State Management & Data Models

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AUDIO ROOM STATE                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  AudioRoomLoaded                                                            │
│  ├─ roomData: AudioRoomDetails                                              │
│  │   ├─ roomId: String                                                     │
│  │   ├─ title: String                                                      │
│  │   ├─ hostDetails: AudioMember                                           │
│  │   │   ├─ userId: String                                                │
│  │   │   ├─ name: String                                                  │
│  │   │   ├─ avatar: String                                                │
│  │   │   ├─ hostBonus: int                                                │
│  │   │   ├─ isMuted: bool                                                 │
│  │   │   └─ copyWith(): Create updated instance                           │
│  │   │                                                                     │
│  │   ├─ seatsData: SeatsData                                               │
│  │   │   ├─ seats: List<SeatModel>                                        │
│  │   │   │   ├─ seatKey: String (e.g., "seat_1")                         │
│  │   │   │   ├─ seatPosition: int                                         │
│  │   │   │   └─ joinedSeat: JoinedSeat?                                   │
│  │   │   │       ├─ userId: String                                        │
│  │   │   │       ├─ userName: String                                      │
│  │   │   │       └─ userAvatar: String                                    │
│  │   │   └─ totalSeats: int                                               │
│  │   │                                                                     │
│  │   ├─ members: List<AudioMember>                                         │
│  │   │   └─ All room members (hosts + guests on seats)                    │
│  │   │                                                                     │
│  │   └─ messages: List<AudioChatModel>                                     │
│  │       ├─ messageId: String                                             │
│  │       ├─ userId: String                                                │
│  │       ├─ userName: String                                              │
│  │       ├─ message: String                                               │
│  │       └─ timestamp: DateTime                                           │
│  │                                                                         │
│  ├─ listeners: List<AudioMember>                                           │
│  │   └─ Users listening but not on seats                                  │
│  │                                                                         │
│  ├─ currentRoomId: String                                                  │
│  ├─ isHost: bool                                                           │
│  └─ playAnimation: bool                                                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Connection Lifecycle

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CONNECTION LIFECYCLE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. INITIALIZATION                                                          │
│     ├─ AudioRoomBloc created                                               │
│     ├─ Repository injected                                                 │
│     └─ State: AudioRoomInitial                                             │
│                                                                              │
│  2. CONNECT                                                                 │
│     ├─ UI: ConnectToSocket(userId)                                         │
│     ├─ BLoC: _onConnectToSocket()                                          │
│     ├─ Repository: connect(userId)                                         │
│     ├─ Service: AudioSocketConnectionManager.connect()                     │
│     ├─ Socket: Connect to server                                           │
│     ├─ State: AudioRoomLoading                                             │
│     └─ Setup subscriptions:                                                │
│        ├─ _connectionSubscription                                          │
│        ├─ _roomDetailsSubscription                                         │
│        ├─ _joinRoomSubscription                                            │
│        ├─ _leaveRoomSubscription                                           │
│        ├─ _joinSeatSubscription                                            │
│        ├─ _sendMessageSubscription                                         │
│        ├─ _banUserSubscription                                             │
│        ├─ _muteUserSubscription                                            │
│        └─ _updateHostBonusSubscription                                     │
│                                                                              │
│  3. CONNECTED                                                               │
│     ├─ Socket: 'connect' event                                             │
│     ├─ State: AudioRoomLoaded (if room data available)                     │
│     └─ Ready for operations                                                │
│                                                                              │
│  4. OPERATIONS                                                              │
│     ├─ Create/Join/Leave rooms                                             │
│     ├─ Join/Leave seats                                                    │
│     ├─ Send messages                                                       │
│     ├─ Manage users (mute, ban)                                            │
│     └─ Receive real-time updates                                           │
│                                                                              │
│  5. DISCONNECT                                                              │
│     ├─ UI: DisconnectFromSocket()                                          │
│     ├─ BLoC: _onDisconnectFromSocket()                                     │
│     ├─ Cancel all subscriptions                                            │
│     ├─ Repository: disconnect()                                            │
│     ├─ Service: AudioSocketConnectionManager.disconnect()                  │
│     ├─ Socket: Disconnect from server                                      │
│     └─ State: AudioRoomInitial                                             │
│                                                                              │
│  6. CLEANUP                                                                 │
│     ├─ BLoC: close()                                                       │
│     ├─ Cancel remaining subscriptions                                      │
│     ├─ Repository: dispose()                                               │
│     ├─ Service: dispose()                                                  │
│     └─ All resources released                                              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```


Example of a room operation flow:

---

# Architecture Diagram: Host Bonus Update Flow

## Complete Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SERVER EVENT                                      │
│                   update-audio-host-coins                                   │
│              {"hostBonus": 300, "success": true}                            │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│              SOCKET EVENT LISTENER (socket_event_listeners.dart)            │
│                                                                              │
│  void _handleUpdateHostBonus(dynamic data) {                               │
│    if (data is Map<String, dynamic>) {                                     │
│      _updateHostBonusController.add(data['data']['hostBonus']);            │
│    }                                                                        │
│  }                                                                          │
│                                                                              │
│  Stream<int> get updateHostBonusStream =>                                  │
│    _updateHostBonusController.stream;                                      │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│           REPOSITORY (audio_room_repository.dart)                           │
│                                                                              │
│  Stream<int> get updateHostBonusStream =>                                  │
│    _socketService.updateHostBonusStream;                                   │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│         BLOC SUBSCRIPTION (audio_room_bloc.dart)                            │
│                                                                              │
│  _updateHostBonusSubscription =                                            │
│    _repository.updateHostBonusStream.listen((hostBonus) {                  │
│      add(UpdateHostBonusEvent(hostBonus: hostBonus));                      │
│    });                                                                      │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│              EVENT (audio_room_event.dart)                                  │
│                                                                              │
│  class UpdateHostBonusEvent extends AudioRoomEvent {                       │
│    final int hostBonus;                                                    │
│    const UpdateHostBonusEvent({required this.hostBonus});                  │
│  }                                                                          │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│         EVENT HANDLER (audio_room_bloc.dart)                                │
│                                                                              │
│  void _onUpdateHostBonus(UpdateHostBonusEvent event,                       │
│                          Emitter<AudioRoomState> emit) {                   │
│    if (state is AudioRoomLoaded) {                                         │
│      final currentState = state as AudioRoomLoaded;                        │
│      if (currentState.roomData != null) {                                  │
│        // Create updated hostDetails with new hostBonus                    │
│        final updatedHostDetails =                                          │
│          currentState.roomData!.hostDetails.copyWith(                      │
│            hostBonus: event.hostBonus,                                     │
│          );                                                                │
│        // Create updated roomData with new hostDetails                     │
│        final updatedRoomData =                                             │
│          currentState.roomData!.copyWith(                                  │
│            hostDetails: updatedHostDetails,                                │
│          );                                                                │
│        // Emit new state                                                   │
│        emit(currentState.copyWith(roomData: updatedRoomData));             │
│      }                                                                      │
│    }                                                                        │
│  }                                                                          │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    STATE UPDATE                                             │
│                                                                              │
│  AudioRoomLoaded(                                                          │
│    roomData: AudioRoomDetails(                                             │
│      hostDetails: AudioMember(                                             │
│        hostBonus: 300  ◄── UPDATED                                         │
│      )                                                                      │
│    )                                                                        │
│  )                                                                          │
└────────────────────────────┬────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    UI REBUILD (audio_golive_screen.dart)                    │
│                                                                              │
│  BlocBuilder<AudioRoomBloc, AudioRoomState>(                               │
│    builder: (context, roomState) {                                         │
│      return DiamondStarStatus(                                             │
│        diamonCount: AppUtils.formatNumber(                                 │
│          roomState.roomData?.hostDetails.hostBonus ?? 0,  ◄── DISPLAYS 300│
│        ),                                                                  │
│      );                                                                    │
│    }                                                                        │
│  )                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

## State Immutability Pattern

```
BEFORE:
┌─────────────────────────────────────┐
│ AudioRoomLoaded                     │
│  └─ roomData: AudioRoomDetails      │
│      └─ hostDetails: AudioMember    │
│          └─ hostBonus: 100          │
└─────────────────────────────────────┘

EVENT: UpdateHostBonusEvent(hostBonus: 300)

AFTER:
┌─────────────────────────────────────┐
│ AudioRoomLoaded (NEW)               │
│  └─ roomData: AudioRoomDetails (NEW)│
│      └─ hostDetails: AudioMember (NEW)
│          └─ hostBonus: 300 (UPDATED)│
└─────────────────────────────────────┘
```

## Subscription Lifecycle

```
┌──────────────────────────────────────────────────────────────┐
│                   BLoC Lifecycle                             │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  1. Socket Connected                                         │
│     └─ _onConnectToSocket()                                 │
│        └─ _setupSocketSubscriptions()                       │
│           └─ _updateHostBonusSubscription = listen(...)     │
│                                                               │
│  2. Event Received                                           │
│     └─ Socket: update-audio-host-coins                      │
│        └─ _handleUpdateHostBonus()                          │
│           └─ Stream: add(300)                               │
│              └─ Subscription: listen() triggered            │
│                 └─ add(UpdateHostBonusEvent(300))           │
│                    └─ _onUpdateHostBonus()                  │
│                       └─ emit(newState)                     │
│                          └─ UI rebuilds                     │
│                                                               │
│  3. Socket Disconnected                                      │
│     └─ _onDisconnectFromSocket()                            │
│        └─ _cancelSubscriptions()                            │
│           └─ _updateHostBonusSubscription?.cancel()         │
│                                                               │
│  4. BLoC Closed                                              │
│     └─ close()                                              │
│        └─ _cancelSubscriptions()                            │
│        └─ _repository.dispose()                             │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Model Hierarchy

```
AudioRoomLoaded (State)
  │
  ├─ roomData: AudioRoomDetails
  │   │
  │   ├─ hostDetails: AudioMember ◄── CONTAINS hostBonus
  │   │   ├─ name: String
  │   │   ├─ avatar: String
  │   │   ├─ hostBonus: int ◄── UPDATED HERE
  │   │   ├─ isMuted: bool
  │   │   └─ copyWith() ◄── NEW METHOD
  │   │
  │   ├─ seatsData: SeatsData
  │   ├─ members: List<AudioMember>
  │   └─ messages: List<AudioChatModel>
  │
  ├─ listeners: List<AudioMember>
  ├─ currentRoomId: String
  └─ isHost: bool
```

## Key Components

| Component | File | Purpose |
|-----------|------|---------|
| Socket Listener | `socket_event_listeners.dart` | Receives socket events |
| Stream Controller | `socket_event_listeners.dart` | Manages data stream |
| Repository | `audio_room_repository.dart` | Exposes streams |
| Event | `audio_room_event.dart` | Carries event data |
| Subscription | `audio_room_bloc.dart` | Listens to stream |
| Handler | `audio_room_bloc.dart` | Processes event |
| State | `audio_room_state.dart` | Holds app state |
| UI Widget | `audio_golive_screen.dart` | Displays data |


## ################################# END #################################

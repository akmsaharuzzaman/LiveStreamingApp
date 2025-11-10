import 'package:equatable/equatable.dart';

import '../../../../core/network/models/admin_details_model.dart';
import '../../../../core/network/models/ban_user_model.dart';
import '../../../../core/network/models/mute_user_model.dart';

abstract class ModerationEvent extends Equatable {
  const ModerationEvent();

  @override
  List<Object?> get props => [];
}

class ModerationStarted extends ModerationEvent {
  const ModerationStarted();
}

class ModerationBanUser extends ModerationEvent {
  final String roomId;
  final String userId;

  const ModerationBanUser({
    required this.roomId,
    required this.userId,
  });

  @override
  List<Object?> get props => [roomId, userId];
}

class ModerationMuteUser extends ModerationEvent {
  final String roomId;
  final String userId;

  const ModerationMuteUser({
    required this.roomId,
    required this.userId,
  });

  @override
  List<Object?> get props => [roomId, userId];
}

class ModerationToggleAdmin extends ModerationEvent {
  final String roomId;
  final String userId;

  const ModerationToggleAdmin({
    required this.roomId,
    required this.userId,
  });

  @override
  List<Object?> get props => [roomId, userId];
}

class ModerationBannedListUpdated extends ModerationEvent {
  final List<String> userIds;

  const ModerationBannedListUpdated(this.userIds);

  @override
  List<Object?> get props => [userIds];
}

class ModerationBannedUserReceived extends ModerationEvent {
  final BanUserModel banEvent;

  const ModerationBannedUserReceived(this.banEvent);

  @override
  List<Object?> get props => [banEvent];
}

class ModerationMuteStateUpdated extends ModerationEvent {
  final MuteUserModel muteState;

  const ModerationMuteStateUpdated(this.muteState);

  @override
  List<Object?> get props => [muteState];
}

class ModerationAdminUpdated extends ModerationEvent {
  final AdminDetailsModel admin;

  const ModerationAdminUpdated(this.admin);

  @override
  List<Object?> get props => [admin];
}

class ModerationClearNotification extends ModerationEvent {
  const ModerationClearNotification();
}

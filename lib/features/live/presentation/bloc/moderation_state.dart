import 'package:equatable/equatable.dart';

import '../../../../core/network/models/admin_details_model.dart';
import '../../../../core/network/models/ban_user_model.dart';
import '../../../../core/network/models/mute_user_model.dart';

enum ModerationAction {
  none,
  banRequested,
  muteRequested,
  adminToggled,
  bannedListUpdated,
  bannedUserEvent,
  muteStateUpdated,
  adminUpdated,
}

class ModerationState extends Equatable {
  final List<String> bannedUserIds;
  final List<BanUserModel> bannedUsers;
  final List<AdminDetailsModel> adminList;
  final MuteUserModel? muteState;
  final bool isProcessing;
  final String? errorMessage;
  final String? successMessage;
  final ModerationAction lastAction;
  final String? actionUserId;

  const ModerationState({
    this.bannedUserIds = const [],
    this.bannedUsers = const [],
    this.adminList = const [],
    this.muteState,
    this.isProcessing = false,
    this.errorMessage,
    this.successMessage,
    this.lastAction = ModerationAction.none,
    this.actionUserId,
  });

  ModerationState copyWith({
    List<String>? bannedUserIds,
    List<BanUserModel>? bannedUsers,
    List<AdminDetailsModel>? adminList,
    MuteUserModel? muteState,
    bool? isProcessing,
    String? errorMessage,
    String? successMessage,
    ModerationAction? lastAction,
    String? actionUserId,
    bool resetError = false,
    bool resetSuccess = false,
  }) {
    return ModerationState(
      bannedUserIds: bannedUserIds ?? this.bannedUserIds,
      bannedUsers: bannedUsers ?? this.bannedUsers,
      adminList: adminList ?? this.adminList,
      muteState: muteState ?? this.muteState,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          resetSuccess ? null : successMessage ?? this.successMessage,
      lastAction: lastAction ?? this.lastAction,
      actionUserId: actionUserId ?? this.actionUserId,
    );
  }

  @override
  List<Object?> get props => [
        bannedUserIds,
        bannedUsers,
        adminList,
        muteState,
        isProcessing,
        errorMessage,
        successMessage,
        lastAction,
        actionUserId,
      ];
}

class ModerationInitial extends ModerationState {
  const ModerationInitial();
}

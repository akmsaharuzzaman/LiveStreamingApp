import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/models/admin_details_model.dart';
import '../../../../core/network/models/ban_user_model.dart';
import '../../../../core/network/models/mute_user_model.dart';
import '../../data/repositories/moderation_repository.dart';
import 'moderation_event.dart';
import 'moderation_state.dart';

@injectable
class ModerationBloc extends Bloc<ModerationEvent, ModerationState> {
  final ModerationRepository _repository;

  StreamSubscription<List<String>>? _bannedIdsSubscription;
  StreamSubscription<BanUserModel>? _bannedUserSubscription;
  StreamSubscription<MuteUserModel>? _muteStateSubscription;
  StreamSubscription<AdminDetailsModel>? _adminSubscription;

  ModerationBloc(this._repository) : super(const ModerationInitial()) {
    on<ModerationStarted>(_onStarted);
    on<ModerationBanUser>(_onBanUser);
    on<ModerationMuteUser>(_onMuteUser);
    on<ModerationToggleAdmin>(_onToggleAdmin);
    on<ModerationBannedListUpdated>(_onBannedListUpdated);
    on<ModerationBannedUserReceived>(_onBannedUserReceived);
    on<ModerationMuteStateUpdated>(_onMuteStateUpdated);
    on<ModerationAdminUpdated>(_onAdminUpdated);
    on<ModerationClearNotification>(_onClearNotification);

    add(const ModerationStarted());
  }

  void _onStarted(
    ModerationStarted event,
    Emitter<ModerationState> emit,
  ) {
    _bannedIdsSubscription ??=
        _repository.bannedUserIdsStream.listen((ids) {
      add(ModerationBannedListUpdated(ids));
    });

    _bannedUserSubscription ??=
        _repository.bannedUserStream.listen((banEvent) {
      add(ModerationBannedUserReceived(banEvent));
    });

    _muteStateSubscription ??=
        _repository.muteUserStream.listen((muteState) {
      add(ModerationMuteStateUpdated(muteState));
    });

    _adminSubscription ??=
        _repository.adminDetailsStream.listen((admin) {
      add(ModerationAdminUpdated(admin));
    });
  }

  Future<void> _onBanUser(
    ModerationBanUser event,
    Emitter<ModerationState> emit,
  ) async {
    emit(state.copyWith(
      isProcessing: true,
      errorMessage: null,
      successMessage: null,
      lastAction: ModerationAction.banRequested,
      actionUserId: event.userId,
    ));

    final result = await _repository.banUser(
      roomId: event.roomId,
      userId: event.userId,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          isProcessing: false,
          errorMessage: failure.message,
          lastAction: ModerationAction.banRequested,
          actionUserId: event.userId,
        ));
      },
      (_) {
        emit(state.copyWith(
          isProcessing: false,
          successMessage: 'User removed from room',
          lastAction: ModerationAction.banRequested,
          actionUserId: event.userId,
        ));
      },
    );
  }

  Future<void> _onMuteUser(
    ModerationMuteUser event,
    Emitter<ModerationState> emit,
  ) async {
    emit(state.copyWith(
      isProcessing: true,
      errorMessage: null,
      successMessage: null,
      lastAction: ModerationAction.muteRequested,
      actionUserId: event.userId,
    ));

    final result = await _repository.muteUser(
      roomId: event.roomId,
      userId: event.userId,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          isProcessing: false,
          errorMessage: failure.message,
          lastAction: ModerationAction.muteRequested,
          actionUserId: event.userId,
        ));
      },
      (_) {
        emit(state.copyWith(
          isProcessing: false,
          successMessage: 'Mute request sent',
          lastAction: ModerationAction.muteRequested,
          actionUserId: event.userId,
        ));
      },
    );
  }

  Future<void> _onToggleAdmin(
    ModerationToggleAdmin event,
    Emitter<ModerationState> emit,
  ) async {
    emit(state.copyWith(
      isProcessing: true,
      errorMessage: null,
      successMessage: null,
      lastAction: ModerationAction.adminToggled,
      actionUserId: event.userId,
    ));

    final result = await _repository.toggleAdmin(
      roomId: event.roomId,
      userId: event.userId,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          isProcessing: false,
          errorMessage: failure.message,
          lastAction: ModerationAction.adminToggled,
          actionUserId: event.userId,
        ));
      },
      (_) {
        emit(state.copyWith(
          isProcessing: false,
          successMessage: 'Admin status updated',
          lastAction: ModerationAction.adminToggled,
          actionUserId: event.userId,
        ));
      },
    );
  }

  void _onBannedListUpdated(
    ModerationBannedListUpdated event,
    Emitter<ModerationState> emit,
  ) {
    emit(state.copyWith(
      bannedUserIds: event.userIds,
      lastAction: ModerationAction.bannedListUpdated,
      actionUserId: null,
    ));
  }

  void _onBannedUserReceived(
    ModerationBannedUserReceived event,
    Emitter<ModerationState> emit,
  ) {
    final updatedDetails = List<BanUserModel>.from(state.bannedUsers)
      ..add(event.banEvent);

    emit(state.copyWith(
      bannedUsers: updatedDetails,
      lastAction: ModerationAction.bannedUserEvent,
      actionUserId: event.banEvent.targetId,
      successMessage: event.banEvent.message,
    ));
  }

  void _onMuteStateUpdated(
    ModerationMuteStateUpdated event,
    Emitter<ModerationState> emit,
  ) {
    emit(state.copyWith(
      muteState: event.muteState,
      lastAction: ModerationAction.muteStateUpdated,
      actionUserId: null,
    ));
  }

  void _onAdminUpdated(
    ModerationAdminUpdated event,
    Emitter<ModerationState> emit,
  ) {
    final updatedAdmins = List<AdminDetailsModel>.from(state.adminList)
      ..removeWhere((admin) => admin.id == event.admin.id)
      ..add(event.admin);

    emit(state.copyWith(
      adminList: updatedAdmins,
      lastAction: ModerationAction.adminUpdated,
      actionUserId: event.admin.id,
    ));
  }

  void _onClearNotification(
    ModerationClearNotification event,
    Emitter<ModerationState> emit,
  ) {
    emit(state.copyWith(
      errorMessage: null,
      successMessage: null,
      lastAction: ModerationAction.none,
      actionUserId: null,
      resetError: true,
      resetSuccess: true,
    ));
  }

  @override
  Future<void> close() {
    _bannedIdsSubscription?.cancel();
    _bannedUserSubscription?.cancel();
    _muteStateSubscription?.cancel();
    _adminSubscription?.cancel();
    return super.close();
  }
}

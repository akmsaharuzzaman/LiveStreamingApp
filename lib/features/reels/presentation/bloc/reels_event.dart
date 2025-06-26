import 'package:equatable/equatable.dart';

abstract class ReelsEvent extends Equatable {
  const ReelsEvent();

  @override
  List<Object> get props => [];
}

class LoadReels extends ReelsEvent {}

class LoadMoreReels extends ReelsEvent {}

class RefreshReels extends ReelsEvent {}

class LikeReel extends ReelsEvent {
  final String reelId;

  const LikeReel(this.reelId);

  @override
  List<Object> get props => [reelId];
}

class ShareReel extends ReelsEvent {
  final String reelId;

  const ShareReel(this.reelId);

  @override
  List<Object> get props => [reelId];
}

class AddComment extends ReelsEvent {
  final String reelId;
  final String comment;

  const AddComment(this.reelId, this.comment);

  @override
  List<Object> get props => [reelId, comment];
}

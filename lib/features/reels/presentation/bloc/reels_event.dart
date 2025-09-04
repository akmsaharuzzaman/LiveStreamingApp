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

class ReactToReel extends ReelsEvent {
  final String reelId;
  final String reactionType;

  const ReactToReel(this.reelId, this.reactionType);

  @override
  List<Object> get props => [reelId, reactionType];
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

class EditComment extends ReelsEvent {
  final String commentId;
  final String newComment;

  const EditComment(this.commentId, this.newComment);

  @override
  List<Object> get props => [commentId, newComment];
}

class DeleteComment extends ReelsEvent {
  final String reelId;
  final String commentId;

  const DeleteComment(this.reelId, this.commentId);

  @override
  List<Object> get props => [reelId, commentId];
}

class ReactToComment extends ReelsEvent {
  final String commentId;
  final String reactionType;

  const ReactToComment(this.commentId, this.reactionType);

  @override
  List<Object> get props => [commentId, reactionType];
}

class ReplyToComment extends ReelsEvent {
  final String commentId;
  final String reelId;
  final String commentText;

  const ReplyToComment(this.commentId, this.reelId, this.commentText);

  @override
  List<Object> get props => [commentId, reelId, commentText];
}

class GetReelComments extends ReelsEvent {
  final String reelId;
  final int page;
  final int limit;

  const GetReelComments(this.reelId, {this.page = 1, this.limit = 10});

  @override
  List<Object> get props => [reelId, page, limit];
}

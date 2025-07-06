import 'package:equatable/equatable.dart';
import '../../domain/entities/reel_entity.dart';

abstract class ReelsState extends Equatable {
  const ReelsState();

  @override
  List<Object> get props => [];
}

class ReelsInitial extends ReelsState {}

class ReelsLoading extends ReelsState {}

class ReelsLoaded extends ReelsState {
  final List<ReelEntity> reels;
  final bool hasReachedMax;
  final int currentPage;

  const ReelsLoaded({
    required this.reels,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  ReelsLoaded copyWith({
    List<ReelEntity>? reels,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return ReelsLoaded(
      reels: reels ?? this.reels,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object> get props => [reels, hasReachedMax, currentPage];
}

class ReelsError extends ReelsState {
  final String message;

  const ReelsError(this.message);

  @override
  List<Object> get props => [message];
}

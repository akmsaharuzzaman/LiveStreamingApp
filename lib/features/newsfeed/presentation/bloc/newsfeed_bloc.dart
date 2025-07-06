import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/post_response_model.dart';
import '../../domain/usecases/get_all_posts_usecase.dart';

// Events
abstract class NewsfeedEvent extends Equatable {
  const NewsfeedEvent();

  @override
  List<Object?> get props => [];
}

class LoadPostsEvent extends NewsfeedEvent {
  final int page;
  final int limit;
  final bool isRefresh;

  const LoadPostsEvent({
    this.page = 1,
    this.limit = 10,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [page, limit, isRefresh];
}

class RefreshPostsEvent extends NewsfeedEvent {}

class LoadMorePostsEvent extends NewsfeedEvent {}

// States
abstract class NewsfeedState extends Equatable {
  const NewsfeedState();

  @override
  List<Object?> get props => [];
}

class NewsfeedInitial extends NewsfeedState {}

class NewsfeedLoading extends NewsfeedState {}

class NewsfeedLoadingMore extends NewsfeedState {
  final List<PostModel> currentPosts;

  const NewsfeedLoadingMore(this.currentPosts);

  @override
  List<Object?> get props => [currentPosts];
}

class NewsfeedLoaded extends NewsfeedState {
  final List<PostModel> posts;
  final PostPagination? pagination;
  final bool hasReachedMax;

  const NewsfeedLoaded({
    required this.posts,
    this.pagination,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [posts, pagination, hasReachedMax];

  NewsfeedLoaded copyWith({
    List<PostModel>? posts,
    PostPagination? pagination,
    bool? hasReachedMax,
  }) {
    return NewsfeedLoaded(
      posts: posts ?? this.posts,
      pagination: pagination ?? this.pagination,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class NewsfeedError extends NewsfeedState {
  final String message;

  const NewsfeedError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class NewsfeedBloc extends Bloc<NewsfeedEvent, NewsfeedState> {
  final GetAllPostsUseCase _getAllPostsUseCase;
  int _currentPage = 1;
  List<PostModel> _allPosts = [];

  NewsfeedBloc(this._getAllPostsUseCase) : super(NewsfeedInitial()) {
    on<LoadPostsEvent>(_onLoadPosts);
    on<RefreshPostsEvent>(_onRefreshPosts);
    on<LoadMorePostsEvent>(_onLoadMorePosts);
  }

  Future<void> _onLoadPosts(
    LoadPostsEvent event,
    Emitter<NewsfeedState> emit,
  ) async {
    if (event.isRefresh) {
      _currentPage = 1;
      _allPosts.clear();
    }

    if (state is! NewsfeedLoadingMore) {
      emit(NewsfeedLoading());
    }

    final result = await _getAllPostsUseCase(
      page: event.page,
      limit: event.limit,
    );

    result.when(
      success: (postResponse) {
        if (event.isRefresh) {
          _allPosts = postResponse.result.data;
        } else {
          _allPosts.addAll(postResponse.result.data);
        }

        final hasReachedMax = postResponse.result.pagination != null
            ? _currentPage >= postResponse.result.pagination!.totalPage
            : postResponse.result.data.isEmpty;

        emit(NewsfeedLoaded(
          posts: List.from(_allPosts),
          pagination: postResponse.result.pagination,
          hasReachedMax: hasReachedMax,
        ));
      },
      failure: (error) {
        emit(NewsfeedError(error.toString()));
      },
    );
  }

  Future<void> _onRefreshPosts(
    RefreshPostsEvent event,
    Emitter<NewsfeedState> emit,
  ) async {
    add(const LoadPostsEvent(page: 1, isRefresh: true));
  }

  Future<void> _onLoadMorePosts(
    LoadMorePostsEvent event,
    Emitter<NewsfeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is NewsfeedLoaded && !currentState.hasReachedMax) {
      emit(NewsfeedLoadingMore(currentState.posts));
      _currentPage++;
      add(LoadPostsEvent(page: _currentPage));
    }
  }
}

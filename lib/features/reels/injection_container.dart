import 'package:dlstarlive/core/network/api_service.dart';

import 'data/repositories/reels_repository_impl.dart';
import 'data/services/reels_api_service.dart';
import 'domain/repositories/reels_repository.dart';
import 'domain/usecases/reels_usecases.dart';
import 'presentation/bloc/reels_bloc.dart';

class ReelsDependencyContainer {
  static ReelsRepository createRepository() {
    // Create API service instance
    final apiService = ApiService.instance;

    // Create reels API service
    final reelsApiService = ReelsApiService(apiService);

    // Create and return repository
    return ReelsRepositoryImpl(reelsApiService);
  }

  static ReelsBloc createReelsBloc() {
    // Create repository
    final repository = createRepository();

    // Create use cases
    final getReelsUseCase = GetReelsUseCase(repository);
    final likeReelUseCase = LikeReelUseCase(repository);
    final shareReelUseCase = ShareReelUseCase(repository);
    final addCommentUseCase = AddCommentUseCase(repository);
    final getReelCommentsUseCase = GetReelCommentsUseCase(repository);
    final editCommentUseCase = EditCommentUseCase(repository);
    final deleteCommentUseCase = DeleteCommentUseCase(repository);
    final reactToCommentUseCase = ReactToCommentUseCase(repository);
    final replyToCommentUseCase = ReplyToCommentUseCase(repository);

    // Create and return BLoC
    return ReelsBloc(
      getReelsUseCase: getReelsUseCase,
      likeReelUseCase: likeReelUseCase,
      shareReelUseCase: shareReelUseCase,
      addCommentUseCase: addCommentUseCase,
      getReelCommentsUseCase: getReelCommentsUseCase,
      editCommentUseCase: editCommentUseCase,
      deleteCommentUseCase: deleteCommentUseCase,
      reactToCommentUseCase: reactToCommentUseCase,
      replyToCommentUseCase: replyToCommentUseCase,
    );
  }
}

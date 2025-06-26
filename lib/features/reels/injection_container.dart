import 'package:dlstarlive/core/network/api_service.dart';
import 'data/repositories/reels_repository_impl.dart';
import 'data/services/reels_api_service.dart';
import 'domain/usecases/reels_usecases.dart';
import 'presentation/bloc/reels_bloc.dart';

class ReelsDependencyContainer {
  static ReelsBloc createReelsBloc() {
    // Create API service instance
    final apiService = ApiService.instance;

    // Create reels API service
    final reelsApiService = ReelsApiService(apiService);

    // Create repository
    final repository = ReelsRepositoryImpl(reelsApiService);

    // Create use cases
    final getReelsUseCase = GetReelsUseCase(repository);
    final likeReelUseCase = LikeReelUseCase(repository);
    final shareReelUseCase = ShareReelUseCase(repository);
    final addCommentUseCase = AddCommentUseCase(repository);

    // Create and return BLoC
    return ReelsBloc(
      getReelsUseCase: getReelsUseCase,
      likeReelUseCase: likeReelUseCase,
      shareReelUseCase: shareReelUseCase,
      addCommentUseCase: addCommentUseCase,
    );
  }
}

import '../../core/network_temp/api_service.dart';
import 'data/datasources/newsfeed_remote_datasource.dart';
import 'data/repositories/newsfeed_repository_impl.dart';
import 'domain/usecases/get_all_posts_usecase.dart';
import 'presentation/bloc/newsfeed_bloc.dart';

class NewsfeedDependencyContainer {
  static NewsfeedBloc createNewsfeedBloc() {
    // Create API service instance
    final apiService = ApiService.instance;
    
    // Create data source
    final remoteDataSource = NewsfeedRemoteDataSourceImpl(apiService);
    
    // Create repository
    final repository = NewsfeedRepositoryImpl(remoteDataSource);
    
    // Create use case
    final getAllPostsUseCase = GetAllPostsUseCase(repository);
    
    // Create and return BLoC
    return NewsfeedBloc(getAllPostsUseCase);
  }
}

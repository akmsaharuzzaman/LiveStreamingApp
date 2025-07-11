import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../core/network/api_clients.dart';

// Events
abstract class ApiExampleEvent extends Equatable {
  const ApiExampleEvent();

  @override
  List<Object?> get props => [];
}

class GetUserProfileEvent extends ApiExampleEvent {
  const GetUserProfileEvent();
}

class UpdateUserProfileEvent extends ApiExampleEvent {
  final Map<String, dynamic> userData;

  const UpdateUserProfileEvent(this.userData);

  @override
  List<Object?> get props => [userData];
}

class UploadFileEvent extends ApiExampleEvent {
  final File file;
  final String fieldName;

  const UploadFileEvent(this.file, {this.fieldName = 'file'});

  @override
  List<Object?> get props => [file, fieldName];
}

class UploadMultipleFilesEvent extends ApiExampleEvent {
  final List<File> files;

  const UploadMultipleFilesEvent(this.files);

  @override
  List<Object?> get props => [files];
}

class SendFormDataEvent extends ApiExampleEvent {
  final Map<String, dynamic> formData;

  const SendFormDataEvent(this.formData);

  @override
  List<Object?> get props => [formData];
}

class DownloadFileEvent extends ApiExampleEvent {
  final String fileId;
  final String savePath;

  const DownloadFileEvent(this.fileId, this.savePath);

  @override
  List<Object?> get props => [fileId, savePath];
}

class LoginEvent extends ApiExampleEvent {
  final String email;
  final String password;

  const LoginEvent(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

// States
abstract class ApiExampleState extends Equatable {
  const ApiExampleState();

  @override
  List<Object?> get props => [];
}

class ApiExampleInitial extends ApiExampleState {
  const ApiExampleInitial();
}

class ApiExampleLoading extends ApiExampleState {
  const ApiExampleLoading();
}

class ApiExampleSuccess extends ApiExampleState {
  final dynamic data;
  final String message;

  const ApiExampleSuccess(this.data, {this.message = 'Success'});

  @override
  List<Object?> get props => [data, message];
}

class ApiExampleError extends ApiExampleState {
  final String message;

  const ApiExampleError(this.message);

  @override
  List<Object?> get props => [message];
}

class FileUploadProgress extends ApiExampleState {
  final double progress;

  const FileUploadProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}

// BLoC
@injectable
class ApiExampleBloc extends Bloc<ApiExampleEvent, ApiExampleState> {
  final AuthApiClient _authApiClient;
  final UserApiClient _userApiClient;
  final FileUploadApiClient _fileUploadApiClient;
  final GenericApiClient _genericApiClient;

  ApiExampleBloc(
    this._authApiClient,
    this._userApiClient,
    this._fileUploadApiClient,
    this._genericApiClient,
  ) : super(const ApiExampleInitial()) {
    on<GetUserProfileEvent>(_onGetUserProfile);
    on<UpdateUserProfileEvent>(_onUpdateUserProfile);
    on<UploadFileEvent>(_onUploadFile);
    on<UploadMultipleFilesEvent>(_onUploadMultipleFiles);
    on<SendFormDataEvent>(_onSendFormData);
    on<DownloadFileEvent>(_onDownloadFile);
    on<LoginEvent>(_onLogin);
  }

  Future<void> _onGetUserProfile(
    GetUserProfileEvent event,
    Emitter<ApiExampleState> emit,
  ) async {
    emit(const ApiExampleLoading());

    try {
      final response = await _userApiClient.getUserProfile();

      if (response.isSuccess) {
        emit(
          ApiExampleSuccess(
            response.data,
            message: 'User profile loaded successfully',
          ),
        );
      } else {
        emit(
          ApiExampleError(response.message ?? 'Failed to load user profile'),
        );
      }
    } catch (e) {
      emit(ApiExampleError(e.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfileEvent event,
    Emitter<ApiExampleState> emit,
  ) async {
    emit(const ApiExampleLoading());

    try {
      final response = await _userApiClient.updateUserProfile(event.userData);

      if (response.isSuccess) {
        emit(
          ApiExampleSuccess(
            response.data,
            message: 'User profile updated successfully',
          ),
        );
      } else {
        emit(
          ApiExampleError(response.message ?? 'Failed to update user profile'),
        );
      }
    } catch (e) {
      emit(ApiExampleError(e.toString()));
    }
  }

  Future<void> _onUploadFile(
    UploadFileEvent event,
    Emitter<ApiExampleState> emit,
  ) async {
    emit(const ApiExampleLoading());

    try {
      final response = await _fileUploadApiClient.uploadFile(
        file: event.file,
        fieldName: event.fieldName,
        onProgress: (sent, total) {
          final progress = sent / total;
          emit(FileUploadProgress(progress));
        },
      );

      if (response.isSuccess) {
        emit(
          ApiExampleSuccess(
            response.data,
            message: 'File uploaded successfully',
          ),
        );
      } else {
        emit(ApiExampleError(response.message ?? 'Failed to upload file'));
      }
    } catch (e) {
      emit(ApiExampleError(e.toString()));
    }
  }

  Future<void> _onUploadMultipleFiles(
    UploadMultipleFilesEvent event,
    Emitter<ApiExampleState> emit,
  ) async {
    emit(const ApiExampleLoading());

    try {
      final response = await _fileUploadApiClient.uploadFiles(
        files: event.files,
        onProgress: (sent, total) {
          final progress = sent / total;
          emit(FileUploadProgress(progress));
        },
      );

      if (response.isSuccess) {
        emit(
          ApiExampleSuccess(
            response.data,
            message: 'Files uploaded successfully',
          ),
        );
      } else {
        emit(ApiExampleError(response.message ?? 'Failed to upload files'));
      }
    } catch (e) {
      emit(ApiExampleError(e.toString()));
    }
  }

  Future<void> _onSendFormData(
    SendFormDataEvent event,
    Emitter<ApiExampleState> emit,
  ) async {
    emit(const ApiExampleLoading());

    try {
      final response = await _genericApiClient
          .sendFormData<Map<String, dynamic>>(
            '/contact',
            data: event.formData,
            requiresAuth: true,
            parser: (data) => data as Map<String, dynamic>,
          );

      if (response.isSuccess) {
        emit(
          ApiExampleSuccess(
            response.data,
            message: 'Form data sent successfully',
          ),
        );
      } else {
        emit(ApiExampleError(response.message ?? 'Failed to send form data'));
      }
    } catch (e) {
      emit(ApiExampleError(e.toString()));
    }
  }

  Future<void> _onDownloadFile(
    DownloadFileEvent event,
    Emitter<ApiExampleState> emit,
  ) async {
    emit(const ApiExampleLoading());

    try {
      final response = await _genericApiClient.downloadFile(
        '/files/${event.fileId}',
        event.savePath,
        requiresAuth: true,
        onProgress: (received, total) {
          final progress = received / total;
          emit(FileUploadProgress(progress));
        },
      );

      if (response.isSuccess) {
        emit(
          ApiExampleSuccess(
            response.data,
            message: 'File downloaded successfully',
          ),
        );
      } else {
        emit(ApiExampleError(response.message ?? 'Failed to download file'));
      }
    } catch (e) {
      emit(ApiExampleError(e.toString()));
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<ApiExampleState> emit) async {
    emit(const ApiExampleLoading());

    try {
      final response = await _authApiClient.login(event.email, event.password);

      if (response.isSuccess) {
        emit(ApiExampleSuccess(response.data, message: 'Login successful'));
      } else {
        emit(ApiExampleError(response.message ?? 'Login failed'));
      }
    } catch (e) {
      emit(ApiExampleError(e.toString()));
    }
  }
}

// Example usage in a widget
/*
class ApiExampleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ApiExampleBloc>(),
      child: BlocBuilder<ApiExampleBloc, ApiExampleState>(
        builder: (context, state) {
          if (state is ApiExampleLoading) {
            return const CircularProgressIndicator();
          } else if (state is FileUploadProgress) {
            return Column(
              children: [
                LinearProgressIndicator(value: state.progress),
                Text('Upload Progress: ${(state.progress * 100).toStringAsFixed(1)}%'),
              ],
            );
          } else if (state is ApiExampleSuccess) {
            return Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                Text(state.message),
                if (state.data != null) Text('Data: ${state.data}'),
              ],
            );
          } else if (state is ApiExampleError) {
            return Column(
              children: [
                Icon(Icons.error, color: Colors.red),
                Text(state.message),
              ],
            );
          }
          
          return Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  context.read<ApiExampleBloc>().add(const GetUserProfileEvent());
                },
                child: const Text('Get User Profile'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<ApiExampleBloc>().add(
                    const UpdateUserProfileEvent({'name': 'John Doe', 'email': 'john@example.com'}),
                  );
                },
                child: const Text('Update User Profile'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<ApiExampleBloc>().add(
                    const SendFormDataEvent({'message': 'Hello, World!', 'subject': 'Test'}),
                  );
                },
                child: const Text('Send Form Data'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<ApiExampleBloc>().add(
                    const LoginEvent('user@example.com', 'password123'),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          );
        },
      ),
    );
  }
}
*/

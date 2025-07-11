import 'dart:io';
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';
import '../network/api_service.dart';

/// Example repository interface showing how to use the API service
abstract class ExampleRepository {
  Future<Either<Failure, Map<String, dynamic>>> getUser(String userId);
  Future<Either<Failure, Map<String, dynamic>>> createUser(
    Map<String, dynamic> userData,
  );
  Future<Either<Failure, Map<String, dynamic>>> updateUser(
    String userId,
    Map<String, dynamic> userData,
  );
  Future<Either<Failure, bool>> deleteUser(String userId);
  Future<Either<Failure, Map<String, dynamic>>> uploadProfilePicture(
    String userId,
    File imageFile,
  );
  Future<Either<Failure, Map<String, dynamic>>> uploadMultipleFiles(
    List<File> files,
  );
  Future<Either<Failure, String>> downloadFile(String fileId, String savePath);
  Future<Either<Failure, Map<String, dynamic>>> sendFormData(
    Map<String, dynamic> formData,
  );
}

/// Example implementation showing how to use the API service
class ExampleRepositoryImpl implements ExampleRepository {
  final ApiService _apiService;

  ExampleRepositoryImpl(this._apiService);

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUser(String userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/users/$userId',
        requiresAuth: true,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message ?? 'Failed to get user'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createUser(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/users',
        data: userData,
        requiresAuth: true,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message ?? 'Failed to create user'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/users/$userId',
        data: userData,
        requiresAuth: true,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message ?? 'Failed to update user'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUser(String userId) async {
    try {
      final response = await _apiService.delete<bool>(
        '/users/$userId',
        requiresAuth: true,
        parser: (data) => true,
      );

      if (response.isSuccess) {
        return const Right(true);
      } else {
        return Left(ServerFailure(response.message ?? 'Failed to delete user'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadProfilePicture(
    String userId,
    File imageFile,
  ) async {
    try {
      final request = FileUploadRequest(
        endpoint: '/users/$userId/profile-picture',
        file: imageFile,
        fieldName: 'profile_picture',
        requiresAuth: true,
        additionalFields: {'user_id': userId},
      );

      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        request,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(
          ServerFailure(response.message ?? 'Failed to upload profile picture'),
        );
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadMultipleFiles(
    List<File> files,
  ) async {
    try {
      final request = MultiFileUploadRequest(
        endpoint: '/upload/multiple',
        files: files,
        fieldName: 'files',
        requiresAuth: true,
        additionalFields: {'upload_type': 'multiple'},
      );

      final response = await _apiService.uploadFiles<Map<String, dynamic>>(
        request,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(
          ServerFailure(response.message ?? 'Failed to upload files'),
        );
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> downloadFile(
    String fileId,
    String savePath,
  ) async {
    try {
      final response = await _apiService.downloadFile(
        '/files/$fileId/download',
        savePath,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(
          ServerFailure(response.message ?? 'Failed to download file'),
        );
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> sendFormData(
    Map<String, dynamic> formData,
  ) async {
    try {
      final response = await _apiService.sendFormData<Map<String, dynamic>>(
        '/form-submit',
        data: formData,
        requiresAuth: true,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(
          ServerFailure(response.message ?? 'Failed to send form data'),
        );
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

/// Example usage in a BLoC or Use Case
class ExampleUseCases {
  final ExampleRepository _repository;

  ExampleUseCases(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> getUserProfile(
    String userId,
  ) async {
    return await _repository.getUser(userId);
  }

  Future<Either<Failure, Map<String, dynamic>>> updateUserProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    return await _repository.updateUser(userId, userData);
  }

  Future<Either<Failure, Map<String, dynamic>>> uploadProfileImage(
    String userId,
    File imageFile,
  ) async {
    return await _repository.uploadProfilePicture(userId, imageFile);
  }

  Future<Either<Failure, Map<String, dynamic>>> uploadDocuments(
    List<File> documents,
  ) async {
    return await _repository.uploadMultipleFiles(documents);
  }

  Future<Either<Failure, String>> downloadDocument(
    String fileId,
    String savePath,
  ) async {
    return await _repository.downloadFile(fileId, savePath);
  }

  Future<Either<Failure, Map<String, dynamic>>> submitContactForm(
    Map<String, dynamic> formData,
  ) async {
    return await _repository.sendFormData(formData);
  }
}

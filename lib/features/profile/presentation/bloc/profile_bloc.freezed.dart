// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ProfileEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String uid) userDataLoaded,
    required TResult Function(BuildContext context, bool cameraImage)
        imagePicked,
    required TResult Function(
            BuildContext context, String name, String birthday, String bio)
        saveUserProfile,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String uid)? userDataLoaded,
    TResult? Function(BuildContext context, bool cameraImage)? imagePicked,
    TResult? Function(
            BuildContext context, String name, String birthday, String bio)?
        saveUserProfile,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String uid)? userDataLoaded,
    TResult Function(BuildContext context, bool cameraImage)? imagePicked,
    TResult Function(
            BuildContext context, String name, String birthday, String bio)?
        saveUserProfile,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UserDataLoaded value) userDataLoaded,
    required TResult Function(_ImagePicked value) imagePicked,
    required TResult Function(_SaveUserProfile value) saveUserProfile,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UserDataLoaded value)? userDataLoaded,
    TResult? Function(_ImagePicked value)? imagePicked,
    TResult? Function(_SaveUserProfile value)? saveUserProfile,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UserDataLoaded value)? userDataLoaded,
    TResult Function(_ImagePicked value)? imagePicked,
    TResult Function(_SaveUserProfile value)? saveUserProfile,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileEventCopyWith<$Res> {
  factory $ProfileEventCopyWith(
          ProfileEvent value, $Res Function(ProfileEvent) then) =
      _$ProfileEventCopyWithImpl<$Res, ProfileEvent>;
}

/// @nodoc
class _$ProfileEventCopyWithImpl<$Res, $Val extends ProfileEvent>
    implements $ProfileEventCopyWith<$Res> {
  _$ProfileEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$UserDataLoadedImplCopyWith<$Res> {
  factory _$$UserDataLoadedImplCopyWith(_$UserDataLoadedImpl value,
          $Res Function(_$UserDataLoadedImpl) then) =
      __$$UserDataLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String uid});
}

/// @nodoc
class __$$UserDataLoadedImplCopyWithImpl<$Res>
    extends _$ProfileEventCopyWithImpl<$Res, _$UserDataLoadedImpl>
    implements _$$UserDataLoadedImplCopyWith<$Res> {
  __$$UserDataLoadedImplCopyWithImpl(
      _$UserDataLoadedImpl _value, $Res Function(_$UserDataLoadedImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfileEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
  }) {
    return _then(_$UserDataLoadedImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$UserDataLoadedImpl implements _UserDataLoaded {
  const _$UserDataLoadedImpl({required this.uid});

  @override
  final String uid;

  @override
  String toString() {
    return 'ProfileEvent.userDataLoaded(uid: $uid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserDataLoadedImpl &&
            (identical(other.uid, uid) || other.uid == uid));
  }

  @override
  int get hashCode => Object.hash(runtimeType, uid);

  /// Create a copy of ProfileEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserDataLoadedImplCopyWith<_$UserDataLoadedImpl> get copyWith =>
      __$$UserDataLoadedImplCopyWithImpl<_$UserDataLoadedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String uid) userDataLoaded,
    required TResult Function(BuildContext context, bool cameraImage)
        imagePicked,
    required TResult Function(
            BuildContext context, String name, String birthday, String bio)
        saveUserProfile,
  }) {
    return userDataLoaded(uid);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String uid)? userDataLoaded,
    TResult? Function(BuildContext context, bool cameraImage)? imagePicked,
    TResult? Function(
            BuildContext context, String name, String birthday, String bio)?
        saveUserProfile,
  }) {
    return userDataLoaded?.call(uid);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String uid)? userDataLoaded,
    TResult Function(BuildContext context, bool cameraImage)? imagePicked,
    TResult Function(
            BuildContext context, String name, String birthday, String bio)?
        saveUserProfile,
    required TResult orElse(),
  }) {
    if (userDataLoaded != null) {
      return userDataLoaded(uid);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UserDataLoaded value) userDataLoaded,
    required TResult Function(_ImagePicked value) imagePicked,
    required TResult Function(_SaveUserProfile value) saveUserProfile,
  }) {
    return userDataLoaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UserDataLoaded value)? userDataLoaded,
    TResult? Function(_ImagePicked value)? imagePicked,
    TResult? Function(_SaveUserProfile value)? saveUserProfile,
  }) {
    return userDataLoaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UserDataLoaded value)? userDataLoaded,
    TResult Function(_ImagePicked value)? imagePicked,
    TResult Function(_SaveUserProfile value)? saveUserProfile,
    required TResult orElse(),
  }) {
    if (userDataLoaded != null) {
      return userDataLoaded(this);
    }
    return orElse();
  }
}

abstract class _UserDataLoaded implements ProfileEvent {
  const factory _UserDataLoaded({required final String uid}) =
      _$UserDataLoadedImpl;

  String get uid;

  /// Create a copy of ProfileEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserDataLoadedImplCopyWith<_$UserDataLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ImagePickedImplCopyWith<$Res> {
  factory _$$ImagePickedImplCopyWith(
          _$ImagePickedImpl value, $Res Function(_$ImagePickedImpl) then) =
      __$$ImagePickedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({BuildContext context, bool cameraImage});
}

/// @nodoc
class __$$ImagePickedImplCopyWithImpl<$Res>
    extends _$ProfileEventCopyWithImpl<$Res, _$ImagePickedImpl>
    implements _$$ImagePickedImplCopyWith<$Res> {
  __$$ImagePickedImplCopyWithImpl(
      _$ImagePickedImpl _value, $Res Function(_$ImagePickedImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfileEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? context = null,
    Object? cameraImage = null,
  }) {
    return _then(_$ImagePickedImpl(
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as BuildContext,
      cameraImage: null == cameraImage
          ? _value.cameraImage
          : cameraImage // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ImagePickedImpl implements _ImagePicked {
  const _$ImagePickedImpl({required this.context, required this.cameraImage});

  @override
  final BuildContext context;
  @override
  final bool cameraImage;

  @override
  String toString() {
    return 'ProfileEvent.imagePicked(context: $context, cameraImage: $cameraImage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImagePickedImpl &&
            (identical(other.context, context) || other.context == context) &&
            (identical(other.cameraImage, cameraImage) ||
                other.cameraImage == cameraImage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, context, cameraImage);

  /// Create a copy of ProfileEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImagePickedImplCopyWith<_$ImagePickedImpl> get copyWith =>
      __$$ImagePickedImplCopyWithImpl<_$ImagePickedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String uid) userDataLoaded,
    required TResult Function(BuildContext context, bool cameraImage)
        imagePicked,
    required TResult Function(
            BuildContext context, String name, String birthday, String bio)
        saveUserProfile,
  }) {
    return imagePicked(context, cameraImage);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String uid)? userDataLoaded,
    TResult? Function(BuildContext context, bool cameraImage)? imagePicked,
    TResult? Function(
            BuildContext context, String name, String birthday, String bio)?
        saveUserProfile,
  }) {
    return imagePicked?.call(context, cameraImage);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String uid)? userDataLoaded,
    TResult Function(BuildContext context, bool cameraImage)? imagePicked,
    TResult Function(
            BuildContext context, String name, String birthday, String bio)?
        saveUserProfile,
    required TResult orElse(),
  }) {
    if (imagePicked != null) {
      return imagePicked(context, cameraImage);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UserDataLoaded value) userDataLoaded,
    required TResult Function(_ImagePicked value) imagePicked,
    required TResult Function(_SaveUserProfile value) saveUserProfile,
  }) {
    return imagePicked(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UserDataLoaded value)? userDataLoaded,
    TResult? Function(_ImagePicked value)? imagePicked,
    TResult? Function(_SaveUserProfile value)? saveUserProfile,
  }) {
    return imagePicked?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UserDataLoaded value)? userDataLoaded,
    TResult Function(_ImagePicked value)? imagePicked,
    TResult Function(_SaveUserProfile value)? saveUserProfile,
    required TResult orElse(),
  }) {
    if (imagePicked != null) {
      return imagePicked(this);
    }
    return orElse();
  }
}

abstract class _ImagePicked implements ProfileEvent {
  const factory _ImagePicked(
      {required final BuildContext context,
      required final bool cameraImage}) = _$ImagePickedImpl;

  BuildContext get context;
  bool get cameraImage;

  /// Create a copy of ProfileEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImagePickedImplCopyWith<_$ImagePickedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SaveUserProfileImplCopyWith<$Res> {
  factory _$$SaveUserProfileImplCopyWith(_$SaveUserProfileImpl value,
          $Res Function(_$SaveUserProfileImpl) then) =
      __$$SaveUserProfileImplCopyWithImpl<$Res>;
  @useResult
  $Res call({BuildContext context, String name, String birthday, String bio});
}

/// @nodoc
class __$$SaveUserProfileImplCopyWithImpl<$Res>
    extends _$ProfileEventCopyWithImpl<$Res, _$SaveUserProfileImpl>
    implements _$$SaveUserProfileImplCopyWith<$Res> {
  __$$SaveUserProfileImplCopyWithImpl(
      _$SaveUserProfileImpl _value, $Res Function(_$SaveUserProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfileEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? context = null,
    Object? name = null,
    Object? birthday = null,
    Object? bio = null,
  }) {
    return _then(_$SaveUserProfileImpl(
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as BuildContext,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      birthday: null == birthday
          ? _value.birthday
          : birthday // ignore: cast_nullable_to_non_nullable
              as String,
      bio: null == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SaveUserProfileImpl implements _SaveUserProfile {
  const _$SaveUserProfileImpl(
      {required this.context,
      required this.name,
      required this.birthday,
      required this.bio});

  @override
  final BuildContext context;
  @override
  final String name;
  @override
  final String birthday;
  @override
  final String bio;

  @override
  String toString() {
    return 'ProfileEvent.saveUserProfile(context: $context, name: $name, birthday: $birthday, bio: $bio)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaveUserProfileImpl &&
            (identical(other.context, context) || other.context == context) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.birthday, birthday) ||
                other.birthday == birthday) &&
            (identical(other.bio, bio) || other.bio == bio));
  }

  @override
  int get hashCode => Object.hash(runtimeType, context, name, birthday, bio);

  /// Create a copy of ProfileEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaveUserProfileImplCopyWith<_$SaveUserProfileImpl> get copyWith =>
      __$$SaveUserProfileImplCopyWithImpl<_$SaveUserProfileImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String uid) userDataLoaded,
    required TResult Function(BuildContext context, bool cameraImage)
        imagePicked,
    required TResult Function(
            BuildContext context, String name, String birthday, String bio)
        saveUserProfile,
  }) {
    return saveUserProfile(context, name, birthday, bio);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String uid)? userDataLoaded,
    TResult? Function(BuildContext context, bool cameraImage)? imagePicked,
    TResult? Function(
            BuildContext context, String name, String birthday, String bio)?
        saveUserProfile,
  }) {
    return saveUserProfile?.call(context, name, birthday, bio);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String uid)? userDataLoaded,
    TResult Function(BuildContext context, bool cameraImage)? imagePicked,
    TResult Function(
            BuildContext context, String name, String birthday, String bio)?
        saveUserProfile,
    required TResult orElse(),
  }) {
    if (saveUserProfile != null) {
      return saveUserProfile(context, name, birthday, bio);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UserDataLoaded value) userDataLoaded,
    required TResult Function(_ImagePicked value) imagePicked,
    required TResult Function(_SaveUserProfile value) saveUserProfile,
  }) {
    return saveUserProfile(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UserDataLoaded value)? userDataLoaded,
    TResult? Function(_ImagePicked value)? imagePicked,
    TResult? Function(_SaveUserProfile value)? saveUserProfile,
  }) {
    return saveUserProfile?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UserDataLoaded value)? userDataLoaded,
    TResult Function(_ImagePicked value)? imagePicked,
    TResult Function(_SaveUserProfile value)? saveUserProfile,
    required TResult orElse(),
  }) {
    if (saveUserProfile != null) {
      return saveUserProfile(this);
    }
    return orElse();
  }
}

abstract class _SaveUserProfile implements ProfileEvent {
  const factory _SaveUserProfile(
      {required final BuildContext context,
      required final String name,
      required final String birthday,
      required final String bio}) = _$SaveUserProfileImpl;

  BuildContext get context;
  String get name;
  String get birthday;
  String get bio;

  /// Create a copy of ProfileEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaveUserProfileImplCopyWith<_$SaveUserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ProfileState {
  ProfileStatus get logInStatus => throw _privateConstructorUsedError;
  XFile? get pickedImageFile => throw _privateConstructorUsedError;
  Uint8List? get imageBytes => throw _privateConstructorUsedError;
  UserProfileDataResponse get userProfile => throw _privateConstructorUsedError;

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileStateCopyWith<ProfileState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileStateCopyWith<$Res> {
  factory $ProfileStateCopyWith(
          ProfileState value, $Res Function(ProfileState) then) =
      _$ProfileStateCopyWithImpl<$Res, ProfileState>;
  @useResult
  $Res call(
      {ProfileStatus logInStatus,
      XFile? pickedImageFile,
      Uint8List? imageBytes,
      UserProfileDataResponse userProfile});
}

/// @nodoc
class _$ProfileStateCopyWithImpl<$Res, $Val extends ProfileState>
    implements $ProfileStateCopyWith<$Res> {
  _$ProfileStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? logInStatus = null,
    Object? pickedImageFile = freezed,
    Object? imageBytes = freezed,
    Object? userProfile = null,
  }) {
    return _then(_value.copyWith(
      logInStatus: null == logInStatus
          ? _value.logInStatus
          : logInStatus // ignore: cast_nullable_to_non_nullable
              as ProfileStatus,
      pickedImageFile: freezed == pickedImageFile
          ? _value.pickedImageFile
          : pickedImageFile // ignore: cast_nullable_to_non_nullable
              as XFile?,
      imageBytes: freezed == imageBytes
          ? _value.imageBytes
          : imageBytes // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
      userProfile: null == userProfile
          ? _value.userProfile
          : userProfile // ignore: cast_nullable_to_non_nullable
              as UserProfileDataResponse,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileStateImplCopyWith<$Res>
    implements $ProfileStateCopyWith<$Res> {
  factory _$$ProfileStateImplCopyWith(
          _$ProfileStateImpl value, $Res Function(_$ProfileStateImpl) then) =
      __$$ProfileStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ProfileStatus logInStatus,
      XFile? pickedImageFile,
      Uint8List? imageBytes,
      UserProfileDataResponse userProfile});
}

/// @nodoc
class __$$ProfileStateImplCopyWithImpl<$Res>
    extends _$ProfileStateCopyWithImpl<$Res, _$ProfileStateImpl>
    implements _$$ProfileStateImplCopyWith<$Res> {
  __$$ProfileStateImplCopyWithImpl(
      _$ProfileStateImpl _value, $Res Function(_$ProfileStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? logInStatus = null,
    Object? pickedImageFile = freezed,
    Object? imageBytes = freezed,
    Object? userProfile = null,
  }) {
    return _then(_$ProfileStateImpl(
      logInStatus: null == logInStatus
          ? _value.logInStatus
          : logInStatus // ignore: cast_nullable_to_non_nullable
              as ProfileStatus,
      pickedImageFile: freezed == pickedImageFile
          ? _value.pickedImageFile
          : pickedImageFile // ignore: cast_nullable_to_non_nullable
              as XFile?,
      imageBytes: freezed == imageBytes
          ? _value.imageBytes
          : imageBytes // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
      userProfile: null == userProfile
          ? _value.userProfile
          : userProfile // ignore: cast_nullable_to_non_nullable
              as UserProfileDataResponse,
    ));
  }
}

/// @nodoc

class _$ProfileStateImpl implements _ProfileState {
  const _$ProfileStateImpl(
      {this.logInStatus = ProfileStatus.initial,
      this.pickedImageFile = null,
      this.imageBytes,
      this.userProfile = const UserProfileDataResponse()});

  @override
  @JsonKey()
  final ProfileStatus logInStatus;
  @override
  @JsonKey()
  final XFile? pickedImageFile;
  @override
  final Uint8List? imageBytes;
  @override
  @JsonKey()
  final UserProfileDataResponse userProfile;

  @override
  String toString() {
    return 'ProfileState(logInStatus: $logInStatus, pickedImageFile: $pickedImageFile, imageBytes: $imageBytes, userProfile: $userProfile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileStateImpl &&
            (identical(other.logInStatus, logInStatus) ||
                other.logInStatus == logInStatus) &&
            (identical(other.pickedImageFile, pickedImageFile) ||
                other.pickedImageFile == pickedImageFile) &&
            const DeepCollectionEquality()
                .equals(other.imageBytes, imageBytes) &&
            (identical(other.userProfile, userProfile) ||
                other.userProfile == userProfile));
  }

  @override
  int get hashCode => Object.hash(runtimeType, logInStatus, pickedImageFile,
      const DeepCollectionEquality().hash(imageBytes), userProfile);

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileStateImplCopyWith<_$ProfileStateImpl> get copyWith =>
      __$$ProfileStateImplCopyWithImpl<_$ProfileStateImpl>(this, _$identity);
}

abstract class _ProfileState implements ProfileState {
  const factory _ProfileState(
      {final ProfileStatus logInStatus,
      final XFile? pickedImageFile,
      final Uint8List? imageBytes,
      final UserProfileDataResponse userProfile}) = _$ProfileStateImpl;

  @override
  ProfileStatus get logInStatus;
  @override
  XFile? get pickedImageFile;
  @override
  Uint8List? get imageBytes;
  @override
  UserProfileDataResponse get userProfile;

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileStateImplCopyWith<_$ProfileStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

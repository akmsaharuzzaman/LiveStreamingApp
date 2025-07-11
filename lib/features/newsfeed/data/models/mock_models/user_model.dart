class User {
  final int id;
  final String name;
  final String avatar;

  User({
    required this.id,
    required this.name,
    required this.avatar,
  });

  factory User.empty() {
    return User(
      id: 0,
      name: 'No Name',
      avatar: '',
    );
  }
}

final User currentUser =
    User(id: 0, name: 'You', avatar: 'assets/images/new_images/person.png');

final User addison = User(
    id: 1, name: 'Addison', avatar: 'assets/images/new_images/profile.png');

final User angel =
    User(id: 2, name: 'Angel', avatar: 'assets/images/new_images/person.png');

final User deanna =
    User(id: 3, name: 'Deanna', avatar: 'assets/images/new_images/profile.png');

final User jason =
    User(id: 4, name: 'Json', avatar: 'assets/images/new_images/profile.png');

final User judd =
    User(id: 5, name: 'Judd', avatar: 'assets/images/new_images/person.png');

final User leslie =
    User(id: 6, name: 'Leslie', avatar: 'assets/images/new_images/person.png');

final User nathan =
    User(id: 7, name: 'Nathan', avatar: 'assets/images/new_images/profile.png');

final User stanley = User(
    id: 8, name: 'Stanley', avatar: 'assets/images/new_images/profile.png');

final User virgil = User(
    id: 9,
    name: 'Shahadat Vai Astha',
    avatar: 'assets/images/new_images/person.png');

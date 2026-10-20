class DummyUser {
  const DummyUser({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

class DummyUserDatabase {
  DummyUserDatabase._()
    : _users = [
        const DummyUser(
          name: 'Lidya',
          email: 'lidya@gmail.com',
          password: '12345678',
        ),
      ];

  static final DummyUserDatabase instance = DummyUserDatabase._();

  final List<DummyUser> _users;

  bool emailExists(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    return _users.any((user) => user.email.toLowerCase() == normalizedEmail);
  }

  bool register(DummyUser user) {
    if (emailExists(user.email)) return false;
    _users.add(user);
    return true;
  }

  DummyUser? login(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final user in _users) {
      if (user.email.toLowerCase() == normalizedEmail &&
          user.password == password) {
        return user;
      }
    }
    return null;
  }
}

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
          name: 'User Testing',
          email: 'user_test01@gmail.com',
          password: 'Glucosafe123!',
        ),
      ];

  static final DummyUserDatabase instance = DummyUserDatabase._();

  final List<DummyUser> _users;

  DummyUser? _currentUser;

  /// User yang sedang login, atau null jika belum ada sesi aktif.
  DummyUser? get currentUser => _currentUser;

  void logout() {
    _currentUser = null;
  }

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
        _currentUser = user;
        return user;
      }
    }
    return null;
  }

  /// Perbarui data akun yang sedang login (dipakai halaman edit profil).
  bool updateCurrentUser({required String name, required String email}) {
    final current = _currentUser;
    if (current == null) return false;

    final index = _users.indexWhere((user) => user.email == current.email);
    if (index == -1) return false;

    final updated = DummyUser(name: name, email: email, password: current.password);
    _users[index] = updated;
    _currentUser = updated;
    return true;
  }
}

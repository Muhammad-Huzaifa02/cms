/// Tracks failed login attempts to prevent brute-force password guessing.
/// Enforces a cooldown lockout after 5 consecutive failed attempts.
class LoginRateLimiter {
  LoginRateLimiter._();
  static final LoginRateLimiter instance = LoginRateLimiter._();

  static const int maxAllowedAttempts = 5;
  static const int lockoutSeconds = 30;

  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;

  int get failedAttempts => _failedAttempts;

  bool get isLockedOut {
    if (_lockoutEndTime == null) return false;
    if (DateTime.now().isAfter(_lockoutEndTime!)) {
      _lockoutEndTime = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  int get remainingLockoutSeconds {
    if (_lockoutEndTime == null) return 0;
    final remaining = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Call this when a login attempt fails due to bad credentials.
  /// Returns remaining seconds if lockout was triggered or is active.
  int recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= maxAllowedAttempts) {
      _lockoutEndTime = DateTime.now().add(const Duration(seconds: lockoutSeconds));
      return lockoutSeconds;
    }
    return 0;
  }

  /// Call this on successful login to reset counters.
  void recordSuccessfulLogin() {
    _failedAttempts = 0;
    _lockoutEndTime = null;
  }
}

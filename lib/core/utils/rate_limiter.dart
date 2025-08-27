class RateLimiter {
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, int> _requestCount = {};

  static const Duration _defaultCooldown =
      Duration(minutes: 1); // Reduced from 2 to 1
  static const int _defaultMaxRequests = 5; // Increased from 3 to 5
  static const Duration _resetPeriod = Duration(hours: 24);

  /// Check if a request is allowed for the given key
  bool canMakeRequest(
    String key, {
    Duration cooldown = _defaultCooldown,
    int maxRequests = _defaultMaxRequests,
  }) {
    final now = DateTime.now();
    final lastRequest = _lastRequestTime[key];
    final requestCount = _requestCount[key] ?? 0;

    // Reset counter if 24 hours have passed
    if (lastRequest != null && now.difference(lastRequest) > _resetPeriod) {
      _requestCount[key] = 0;
      return true;
    }

    // Check if we're within cooldown period
    if (lastRequest != null && now.difference(lastRequest) < cooldown) {
      return false;
    }

    // Check if we've exceeded max requests
    if (requestCount >= maxRequests) {
      return false;
    }

    return true;
  }

  /// Record a request for the given key
  void recordRequest(String key) {
    final now = DateTime.now();
    _lastRequestTime[key] = now;
    _requestCount[key] = (_requestCount[key] ?? 0) + 1;
  }

  /// Get remaining time until next request is allowed
  Duration? getRemainingCooldown(String key, Duration cooldown) {
    final lastRequest = _lastRequestTime[key];
    if (lastRequest == null) return null;

    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(lastRequest);

    if (timeSinceLastRequest >= cooldown) {
      return Duration.zero;
    }

    return cooldown - timeSinceLastRequest;
  }

  /// Get remaining requests allowed
  int getRemainingRequests(String key, int maxRequests) {
    final requestCount = _requestCount[key] ?? 0;
    return maxRequests - requestCount;
  }

  /// Reset the rate limiter for a specific key
  void reset(String key) {
    _lastRequestTime.remove(key);
    _requestCount.remove(key);
  }

  /// Reset all rate limiters
  void resetAll() {
    _lastRequestTime.clear();
    _requestCount.clear();
  }
}

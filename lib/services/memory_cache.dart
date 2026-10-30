class MemoryCache {
  static final Map<String, _CacheEntry> _entries = {};

  static T? read<T>(String key, Duration ttl) {
    final entry = _entries[key];
    if (entry == null || DateTime.now().difference(entry.createdAt) > ttl) {
      _entries.remove(key);
      return null;
    }
    return entry.value is T ? entry.value as T : null;
  }

  static void write(String key, Object value) {
    _entries[key] = _CacheEntry(value, DateTime.now());
  }

  static void clear() => _entries.clear();

  static void remove(String key) => _entries.remove(key);
}

class _CacheEntry {
  const _CacheEntry(this.value, this.createdAt);

  final Object value;
  final DateTime createdAt;
}

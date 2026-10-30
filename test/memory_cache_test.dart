import 'package:flutter_test/flutter_test.dart';
import 'package:itlabcare/services/memory_cache.dart';

void main() {
  tearDown(MemoryCache.clear);

  test('returns fresh values and expires stale values', () async {
    MemoryCache.write('dashboard', 42);

    expect(MemoryCache.read<int>('dashboard', const Duration(seconds: 1)), 42);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(MemoryCache.read<int>('dashboard', Duration.zero), isNull);
  });
}

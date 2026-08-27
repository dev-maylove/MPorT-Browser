import 'package:flutter_test/flutter_test.dart';
import 'package:mport_browser/security/tracker_blocker.dart';

void main() {
  final blocker = TrackerBlocker();

  test('blocks known tracker hosts', () {
    expect(blocker.shouldBlock(Uri.parse('https://www.google-analytics.com/collect')), isTrue);
    expect(blocker.shouldBlock(Uri.parse('https://sub.doubleclick.net/script.js')), isTrue);
  });

  test('blocks Facebook tracking path but not normal Facebook pages', () {
    expect(blocker.shouldBlock(Uri.parse('https://www.facebook.com/tr')), isTrue);
    expect(blocker.shouldBlock(Uri.parse('https://www.facebook.com/')), isFalse);
  });

  test('allows normal sites', () {
    expect(blocker.shouldBlock(Uri.parse('https://example.com/')), isFalse);
    expect(blocker.shouldBlock(Uri.parse('https://example.com/assets/app.js')), isFalse);
  });
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Throttle noisy notifyListeners / setState storms (especially on web).
class NotifyThrottle {
  NotifyThrottle({this.minInterval = const Duration(milliseconds: 32)});

  final Duration minInterval;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _pending;
  VoidCallback? _action;

  void call(VoidCallback action) {
    _action = action;
    final now = DateTime.now();
    final elapsed = now.difference(_last);
    if (elapsed >= minInterval) {
      _last = now;
      _pending?.cancel();
      action();
      return;
    }
    _pending?.cancel();
    _pending = Timer(minInterval - elapsed, () {
      _last = DateTime.now();
      _action?.call();
    });
  }

  void dispose() {
    _pending?.cancel();
  }
}

/// Schedule work after the current frame (keeps first paint fast).
void afterFirstFrame(VoidCallback fn) {
  WidgetsBinding.instance.addPostFrameCallback((_) => fn());
}

void perfLog(String message) {
  if (kDebugMode) {
    debugPrint('[perf] $message');
  }
}

/// Coalesce multiple rebuild requests into one per frame.
class FrameCoalescer {
  bool _scheduled = false;
  VoidCallback? _fn;

  void schedule(VoidCallback fn) {
    _fn = fn;
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _scheduled = false;
      final action = _fn;
      _fn = null;
      action?.call();
    });
  }
}

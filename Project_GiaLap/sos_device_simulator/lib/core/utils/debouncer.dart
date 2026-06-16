import 'dart:async';

/// Helper that delays invocation of an action until [delay] has passed
/// without any new calls.
///
/// Used by the battery slider to avoid spamming the backend with API
/// requests while the user is dragging the slider.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  /// Cancels any pending invocation and schedules [action] after [delay].
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancels the pending invocation without running it.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Disposes the debouncer and cancels any pending timer.
  void dispose() {
    cancel();
  }
}

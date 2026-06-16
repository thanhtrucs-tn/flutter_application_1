/// Helper that ensures an action is executed at most once within a
/// given [duration].
///
/// Used to prevent the heart-rate auto alert from spamming the server
/// while the heart rate stays above the alert threshold.
class ThrottleHelper {
  final Duration duration;
  DateTime? _lastExecution;

  ThrottleHelper({required this.duration});

  /// Runs [action] only if enough time has passed since the last run.
  /// Returns `true` if the action was executed, `false` if throttled.
  bool run(void Function() action) {
    final now = DateTime.now();
    if (_lastExecution != null &&
        now.difference(_lastExecution!) < duration) {
      return false;
    }
    _lastExecution = now;
    action();
    return true;
  }

  /// Resets the throttle state so the next call executes immediately.
  void reset() {
    _lastExecution = null;
  }
}

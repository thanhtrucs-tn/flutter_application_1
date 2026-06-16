import '../../../../core/errors/failure.dart';

/// Result of the most recent backend operation exposed to the UI for
/// Snackbar feedback.
///
/// Lives in the domain layer so that the [DeviceStatus] entity can
/// carry it without depending on the presentation layer.
sealed class OperationResult {
  const OperationResult();
}

class OperationSuccess extends OperationResult {
  final String message;
  const OperationSuccess(this.message);
}

class OperationFailure extends OperationResult {
  final Failure failure;
  const OperationFailure(this.failure);
}

import 'package:equatable/equatable.dart';

/// Outcome of a "Test Connection" request, shown on the Add/Edit API flow.
class AdapterTestResult extends Equatable {
  const AdapterTestResult.success({
    required this.latency,
    this.message = 'Connection verified.',
  }) : success = true;

  const AdapterTestResult.failure({required this.message, this.latency})
      : success = false;

  final bool success;
  final String message;
  final Duration? latency;

  String get latencyLabel {
    final l = latency;
    if (l == null) return '';
    if (l.inMilliseconds < 1000) return '${l.inMilliseconds} ms';
    return '${(l.inMilliseconds / 1000).toStringAsFixed(1)} s';
  }

  @override
  List<Object?> get props => [success, message, latency];
}

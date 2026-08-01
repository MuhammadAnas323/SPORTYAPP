/// Lifecycle of a user-added API connection.
///
/// The status pill on API cards and the state driving the Add/Edit flow both
/// hang off this enum.
enum ConnectionStatus {
  /// Created but never tested.
  notTested,

  /// A test request is currently in flight.
  testing,

  /// Last test passed and the channel is enabled.
  connected,

  /// The connection exists but the user paused it (still verified).
  disabled,

  /// Last test failed; `lastError` carries the readable message.
  failed;

  bool get isVerified => this == ConnectionStatus.connected;
}

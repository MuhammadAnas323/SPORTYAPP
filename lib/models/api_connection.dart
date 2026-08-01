import 'package:equatable/equatable.dart';

import '../core/utils/id_generator.dart';
import 'auth_style.dart';
import 'connection_status.dart';
import 'sport_type.dart';

/// A persisted, user-supplied API connection.
///
/// This is the only "source of truth" SportSync owns about data: the label,
/// host and credentials the user configured. **The API key is stored via
/// secure storage and is never logged or rendered in full.**
class ApiConnection extends Equatable {
  const ApiConnection({
    required this.id,
    required this.label,
    required this.sportType,
    required this.baseUrl,
    required this.apiKey,
    required this.authStyle,
    this.headerName,
    this.extraHeaders = const {},
    this.status = ConnectionStatus.notTested,
    this.lastTestedAt,
    this.lastError,
    this.createdByUid,
    this.enabled = true,
  });

  final String id;

  /// User-facing name, e.g. "My cricket API".
  final String label;

  final SportType sportType;

  /// Normalized base URL (no trailing slash).
  final String baseUrl;

  /// Secret key — lives only in secure storage.
  final String apiKey;

  /// How the key is attached to requests.
  final AuthStyle authStyle;

  /// Header/query param name when [authStyle] is `customHeader`/`queryParam`.
  final String? headerName;

  /// Optional extra headers, e.g. `{'Accept': 'application/json'}`.
  final Map<String, String> extraHeaders;

  final ConnectionStatus status;
  final DateTime? lastTestedAt;
  final String? lastError;
  final String? createdByUid;

  /// Master on/off switch without deleting.
  final bool enabled;

  /// A connection only feeds Home/Live when verified **and** enabled.
  bool get feedsFeed => enabled && status.isVerified;

  bool get isLiveCapable => sportType == SportType.cricket || sportType == SportType.football;

  ApiConnection copyWith({
    String? id,
    String? label,
    SportType? sportType,
    String? baseUrl,
    String? apiKey,
    AuthStyle? authStyle,
    String? headerName,
    Map<String, String>? extraHeaders,
    ConnectionStatus? status,
    DateTime? lastTestedAt,
    bool clearLastTestedAt = false,
    String? lastError,
    bool clearLastError = false,
    String? createdByUid,
    bool clearCreatedByUid = false,
    bool? enabled,
  }) {
    return ApiConnection(
      id: id ?? this.id,
      label: label ?? this.label,
      sportType: sportType ?? this.sportType,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      authStyle: authStyle ?? this.authStyle,
      headerName: headerName ?? this.headerName,
      extraHeaders: extraHeaders ?? this.extraHeaders,
      status: status ?? this.status,
      lastTestedAt: clearLastTestedAt ? null : lastTestedAt ?? this.lastTestedAt,
      lastError: clearLastError ? null : lastError ?? this.lastError,
      createdByUid: clearCreatedByUid ? null : createdByUid ?? this.createdByUid,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Fresh connection before any test.
  factory ApiConnection.draft({
    String? id,
    required String label,
    required SportType sportType,
    required String baseUrl,
    required String apiKey,
    required AuthStyle authStyle,
    String? headerName,
    Map<String, String> extraHeaders = const {},
  }) {
    return ApiConnection(
      id: id ?? IdGenerator.newId(),
      label: label,
      sportType: sportType,
      baseUrl: baseUrl,
      apiKey: apiKey,
      authStyle: authStyle,
      headerName: headerName,
      extraHeaders: extraHeaders,
    );
  }

  // ---- Persistence ----------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'sportType': sportType.key,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'authStyle': authStyle.name,
        'headerName': headerName,
        'extraHeaders': extraHeaders,
        'status': status.name,
        'lastTestedAt': lastTestedAt?.toIso8601String(),
        'lastError': lastError,
        'createdByUid': createdByUid,
        'enabled': enabled,
      };

  factory ApiConnection.fromJson(Map<String, dynamic> json) {
    return ApiConnection(
      id: json['id'] as String? ?? IdGenerator.newId(),
      label: json['label'] as String? ?? 'Unnamed channel',
      sportType: SportType.fromKey(json['sportType'] as String?),
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      authStyle: AuthStyle.fromKey(json['authStyle'] as String?),
      headerName: json['headerName'] as String?,
      extraHeaders: (json['extraHeaders'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          const {},
      status: ConnectionStatus.values.asNameMap()[json['status']] ??
          ConnectionStatus.notTested,
      lastTestedAt: DateTime.tryParse(json['lastTestedAt'] as String? ?? ''),
      lastError: json['lastError'] as String?,
      createdByUid: json['createdByUid'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        sportType,
        baseUrl,
        apiKey,
        authStyle,
        headerName,
        extraHeaders,
        status,
        lastTestedAt,
        lastError,
        createdByUid,
        enabled,
      ];
}

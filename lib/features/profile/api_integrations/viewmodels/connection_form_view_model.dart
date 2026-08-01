import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../models/api_connection.dart';
import '../../../../models/auth_style.dart';
import '../../../../models/connection_status.dart';
import '../../../../models/sport_type.dart';
import '../../../../repositories/providers.dart';
import '../../../../services/adapters/adapter_test_result.dart';

/// Form state for the Add/Edit connection screen.
class ConnectionFormState {
  const ConnectionFormState({
    this.editingId,
    this.label = '',
    this.sportType = SportType.cricket,
    this.baseUrl = '',
    this.apiKey = '',
    this.authStyle = AuthStyle.bearer,
    this.headerName = '',
    this.extraHeadersText = '',
    this.isTesting = false,
    this.testResult,
    this.saved = false,
  });

  final String? editingId;
  final String label;
  final SportType sportType;
  final String baseUrl;
  final String apiKey;
  final AuthStyle authStyle;
  final String headerName;
  final String extraHeadersText;
  final bool isTesting;
  final AdapterTestResult? testResult;
  final bool saved;

  /// Only a fresh, passing test unlocks Save.
  bool get canSave => !isTesting && testResult?.success == true;

  bool get isEditing => editingId != null;

  /// Auth style needs a header/param name.
  bool get needsHeaderName =>
      authStyle == AuthStyle.customHeader || authStyle == AuthStyle.queryParam;

  ConnectionFormState copyWith({
    String? editingId,
    String? label,
    SportType? sportType,
    String? baseUrl,
    String? apiKey,
    AuthStyle? authStyle,
    String? headerName,
    String? extraHeadersText,
    bool? isTesting,
    AdapterTestResult? testResult,
    bool clearTestResult = false,
    bool? saved,
  }) {
    return ConnectionFormState(
      editingId: editingId ?? this.editingId,
      label: label ?? this.label,
      sportType: sportType ?? this.sportType,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      authStyle: authStyle ?? this.authStyle,
      headerName: headerName ?? this.headerName,
      extraHeadersText: extraHeadersText ?? this.extraHeadersText,
      isTesting: isTesting ?? this.isTesting,
      testResult: clearTestResult ? null : testResult ?? this.testResult,
      saved: saved ?? this.saved,
    );
  }

  ApiConnection toDraft() => ApiConnection.draft(
        label: label.trim(),
        sportType: sportType,
        baseUrl: baseUrl.normalizedUrl(),
        apiKey: apiKey.trim(),
        authStyle: authStyle,
        headerName: needsHeaderName && headerName.trim().isNotEmpty
            ? headerName.trim()
            : null,
        extraHeaders: extraHeadersText.parseHeaderLines(),
      );

  /// Final persisted connection after a passing test.
  ApiConnection toSaved() {
    final draft = toDraft();
    return ApiConnection(
      id: editingId ?? draft.id,
      label: draft.label,
      sportType: draft.sportType,
      baseUrl: draft.baseUrl,
      apiKey: draft.apiKey,
      authStyle: draft.authStyle,
      headerName: draft.headerName,
      extraHeaders: draft.extraHeaders,
      status: ConnectionStatus.connected,
      lastTestedAt: DateTime.now(),
      enabled: true,
    );
  }
}

/// ViewModel for the Add/Edit connection form (MVVM).
final connectionFormViewModelProvider = NotifierProvider<
    ConnectionFormViewModel, ConnectionFormState>(ConnectionFormViewModel.new);

class ConnectionFormViewModel extends Notifier<ConnectionFormState> {
  @override
  ConnectionFormState build() => const ConnectionFormState();

  /// Fresh form for adding a new API, optionally pre-selecting the sport.
  void resetForAdd(SportType? initialSportType) {
    state = ConnectionFormState(
      sportType: initialSportType ?? SportType.cricket,
    );
  }

  /// Loads an existing connection into edit mode.
  void loadForEdit(ApiConnection connection) {
    state = ConnectionFormState(
      editingId: connection.id,
      label: connection.label,
      sportType: connection.sportType,
      baseUrl: connection.baseUrl,
      apiKey: connection.apiKey,
      authStyle: connection.authStyle,
      headerName: connection.headerName ?? '',
      extraHeadersText: connection.extraHeaders.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n'),
    );
  }

  /// Any field change invalidates a stale test result (save stays locked
  /// until the user tests the *current* values again).
  void invalidate() {
    if (state.testResult != null) {
      state = state.copyWith(clearTestResult: true);
    }
  }

  void setLabel(String v) {
    state = state.copyWith(label: v);
    invalidate();
  }

  void setSportType(SportType v) {
    state = state.copyWith(sportType: v);
    invalidate();
  }

  void setBaseUrl(String v) {
    state = state.copyWith(baseUrl: v);
    invalidate();
  }

  void setApiKey(String v) {
    state = state.copyWith(apiKey: v);
    invalidate();
  }

  void setAuthStyle(AuthStyle v) {
    state = state.copyWith(authStyle: v);
    invalidate();
  }

  void setHeaderName(String v) {
    state = state.copyWith(headerName: v);
    invalidate();
  }

  void setExtraHeaders(String v) {
    state = state.copyWith(extraHeadersText: v);
    invalidate();
  }

  /// Validation shared by the Test button. Returns null when valid.
  String? validate() {
    if (state.label.trim().isEmpty) return 'Give this channel a name';
    if (state.baseUrl.trim().isEmpty) return 'Enter the API host';
    if (!RegExp(r'^https?://').hasMatch(state.baseUrl.trim())) {
      return 'The base URL must start with http:// or https://';
    }
    if (state.apiKey.trim().isEmpty) return 'Paste your API key';
    if (state.needsHeaderName && state.headerName.trim().isEmpty) {
      return 'A header/param name is required for this auth style';
    }
    return null;
  }

  /// Runs a real request against the configured host/key through the correct
  /// sport adapter. Sets [ConnectionFormState.isTesting] while in flight and
  /// [ConnectionFormState.testResult] on completion.
  Future<String?> testConnection() async {
    final validation = validate();
    if (validation != null) return validation;

    final draft = state.toDraft();
    final adapter =
        ref.read(feedAggregatorProvider).adapterFor(draft.sportType);
    if (adapter == null) {
      return 'No adapter is available for ${draft.sportType.label} yet.';
    }

    state = state.copyWith(isTesting: true, clearTestResult: true);
    try {
      final result = await adapter.testConnection(draft);
      state = state.copyWith(isTesting: false, testResult: result);
      return result.success ? null : result.message;
    } catch (error) {
      final readable = normalizeError(error).message;
      state = state.copyWith(
        isTesting: false,
        testResult: AdapterTestResult.failure(message: readable),
      );
      return readable;
    }
  }

  /// Persists the connection. Guarded by [ConnectionFormState.canSave].
  Future<bool> save() async {
    if (!state.canSave) return false;
    final connection = state.toSaved();
    await ref.read(connectionsProvider.notifier).save(connection);
    state = state.copyWith(saved: true);
    return true;
  }
}

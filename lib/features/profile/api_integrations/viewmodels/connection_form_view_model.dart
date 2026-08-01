import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/id_generator.dart';
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
    this.draftId,
    this.label = '',
    this.sportType = SportType.cricket,
    this.baseUrl = '',
    this.apiKey = '',
    this.authStyle = AuthStyle.bearer,
    this.headerName = '',
    this.extraHeadersText = '',
    this.isTesting = false,
    this.testResult,
    this.retryBlockedUntil,
    this.retryRemaining,
    this.saved = false,
  });

  final String? editingId;
  final String? draftId;
  final String label;
  final SportType sportType;
  final String baseUrl;
  final String apiKey;
  final AuthStyle authStyle;
  final String headerName;
  final String extraHeadersText;
  final bool isTesting;
  final AdapterTestResult? testResult;
  final DateTime? retryBlockedUntil;
  final Duration? retryRemaining;
  final bool saved;

  /// Only a fresh, passing test unlocks Save.
  bool get canSave => !isTesting && testResult?.success == true;

  bool get isEditing => editingId != null;

  bool get isRetryLocked => retryRemaining != null && retryRemaining!.inMilliseconds > 0;

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
    String? draftId,
    bool? isTesting,
    AdapterTestResult? testResult,
    DateTime? retryBlockedUntil,
    Duration? retryRemaining,
    bool clearTestResult = false,
    bool? saved,
  }) {
    return ConnectionFormState(
      editingId: editingId ?? this.editingId,
      draftId: draftId ?? this.draftId,
      label: label ?? this.label,
      sportType: sportType ?? this.sportType,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      authStyle: authStyle ?? this.authStyle,
      headerName: headerName ?? this.headerName,
      extraHeadersText: extraHeadersText ?? this.extraHeadersText,
      isTesting: isTesting ?? this.isTesting,
      testResult: clearTestResult ? null : testResult ?? this.testResult,
      retryBlockedUntil: retryBlockedUntil ?? this.retryBlockedUntil,
      retryRemaining: retryRemaining ?? this.retryRemaining,
      saved: saved ?? this.saved,
    );
  }

  ApiConnection toDraft() => ApiConnection.draft(
        id: editingId ?? draftId,
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
  bool _testInProgress = false;
  int _currentTestId = 0;
  Timer? _blockCountdownTimer;
  bool _alive = true;
  bool _disposeRegistered = false;

  static const _blockedUntilKeyPrefix = 'api_test_retry_until:';

  @override
  ConnectionFormState build() {
    if (!_disposeRegistered) {
      ref.onDispose(() {
        _blockCountdownTimer?.cancel();
        _alive = false;
      });
      _disposeRegistered = true;
    }
    return const ConnectionFormState();
  }

  /// Fresh form for adding a new API, optionally pre-selecting the sport.
  void resetForAdd(SportType? initialSportType) {
    final draftId = IdGenerator.newId();
    state = ConnectionFormState(
      sportType: initialSportType ?? SportType.cricket,
      draftId: draftId,
    );
    _restoreRetryState(draftId);
  }

  /// Loads an existing connection into edit mode.
  void loadForEdit(ApiConnection connection) {
    state = ConnectionFormState(
      editingId: connection.id,
      draftId: connection.id,
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
    _restoreRetryState(connection.id);
  }

  /// Any field change invalidates a stale test result (save stays locked
  /// until the user tests the *current* values again).
  void invalidate() {
    if (state.testResult != null) {
      state = state.copyWith(clearTestResult: true);
    }
  }

  String _retryStateKey(String connectionId) {
    return '$_blockedUntilKeyPrefix$connectionId';
  }

  Future<void> _restoreRetryState(String connectionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_retryStateKey(connectionId));
    if (raw == null) return;

    final until = DateTime.tryParse(raw);
    if (until == null) return;

    final remaining = until.difference(DateTime.now());
    if (remaining.inMilliseconds <= 0) {
      await prefs.remove(_retryStateKey(connectionId));
      return;
    }

    if (_alive) {
      state = state.copyWith(
        retryBlockedUntil: until,
        retryRemaining: remaining,
      );
      _startRetryCountdown();
    }
  }

  Future<void> _cacheRetryBlockedUntil(String connectionId, DateTime until) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_retryStateKey(connectionId), until.toIso8601String());
  }

  Future<void> _clearCachedRetryState(String connectionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_retryStateKey(connectionId));
  }

  void _startRetryCountdown() {
    _blockCountdownTimer?.cancel();
    _blockCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final until = state.retryBlockedUntil;
      if (until == null) {
        _stopRetryCountdown();
        return;
      }
      final remaining = until.difference(DateTime.now());
      if (remaining.inMilliseconds <= 0) {
        _stopRetryCountdown();
        state = state.copyWith(
          retryBlockedUntil: null,
          retryRemaining: null,
        );
        if (state.draftId != null) {
          _clearCachedRetryState(state.draftId!);
        }
      } else {
        state = state.copyWith(retryRemaining: remaining);
      }
    });
  }

  void _stopRetryCountdown() {
    _blockCountdownTimer?.cancel();
    _blockCountdownTimer = null;
  }

  void _applyRetryBlock(Duration retryAfter) {
    final blockedUntil = DateTime.now().add(retryAfter);
    state = state.copyWith(
      retryBlockedUntil: blockedUntil,
      retryRemaining: retryAfter,
    );
    if (state.draftId != null) {
      _cacheRetryBlockedUntil(state.draftId!, blockedUntil);
    }
    _startRetryCountdown();
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
    final baseUrl = state.baseUrl.trim();
    if (baseUrl.isEmpty) return 'Enter the API host';
    if (!RegExp(r'^https?://').hasMatch(baseUrl)) {
      return 'The base URL must start with http:// or https://';
    }
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.host.isEmpty) {
      return AppStrings.invalidBaseUrl;
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
    if (_testInProgress || state.isRetryLocked) {
      return null;
    }

    final validation = validate();
    if (validation != null) return validation;

    final draft = state.toDraft();
    final adapter =
        ref.read(feedAggregatorProvider).adapterFor(draft.sportType);
    if (adapter == null) {
      return 'No adapter is available for ${draft.sportType.label} yet.';
    }

    _testInProgress = true;
    final testId = ++_currentTestId;
    state = state.copyWith(isTesting: true, clearTestResult: true);
    try {
      final result = await adapter.testConnection(draft);
      if (testId != _currentTestId) return null;
      if (result.retryAfter != null) {
        _applyRetryBlock(result.retryAfter!);
      }
      state = state.copyWith(testResult: result);
      return result.success ? null : result.message;
    } on TimeoutException {
      final failure = AdapterTestResult.failure(
        message: AppStrings.connectionTimedOut,
      );
      if (testId == _currentTestId) {
        state = state.copyWith(testResult: failure);
      }
      return failure.message;
    } catch (error) {
      final readable = normalizeError(error).message;
      final failure = AdapterTestResult.failure(message: readable);
      if (testId == _currentTestId) {
        state = state.copyWith(testResult: failure);
      }
      return readable;
    } finally {
      if (testId == _currentTestId) {
        _testInProgress = false;
        state = state.copyWith(isTesting: false);
      }
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

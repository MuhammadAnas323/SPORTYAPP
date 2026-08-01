import 'package:flutter/material.dart';

/// How a connected API expects its key to be attached.
enum AuthStyle {
  /// `Authorization: Bearer <key>`
  bearer,

  /// A user-named header, e.g. `X-Api-Key: <key>`
  customHeader,

  /// A query parameter, e.g. `?api_key=<key>`
  queryParam;

  String get label => switch (this) {
        AuthStyle.bearer => 'Bearer token',
        AuthStyle.customHeader => 'Custom header',
        AuthStyle.queryParam => 'Query param',
      };

  /// Small leading glyph for the picker.
  IconData get icon => switch (this) {
        AuthStyle.bearer => Icons.key_rounded,
        AuthStyle.customHeader => Icons.north_east_rounded,
        AuthStyle.queryParam => Icons.link_rounded,
      };

  static AuthStyle fromKey(String? value) => switch (value) {
        'customHeader' => AuthStyle.customHeader,
        'queryParam' => AuthStyle.queryParam,
        _ => AuthStyle.bearer,
      };
}

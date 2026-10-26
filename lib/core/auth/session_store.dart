import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'session.dart';

/// Session token plus the last known session, kept so the app reopens signed in.
class StoredSession {
  const StoredSession({required this.token, required this.session});

  final String token;
  final Session session;
}

abstract interface class SessionStore {
  Future<StoredSession?> read();
  Future<void> write(StoredSession stored);
  Future<void> clear();
}

/// Keeps the session in the app's private support directory, which other apps cannot read.
class FileSessionStore implements SessionStore {
  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/session.json');

  @override
  Future<StoredSession?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString()) as Map<String, Object?>;
      return StoredSession(
        token: json['token'] as String,
        session: Session.fromJson(json['session'] as Map<String, Object?>),
      );
    } catch (error) {
      debugPrint('Ignoring unreadable stored session: $error');
      return null;
    }
  }

  @override
  Future<void> write(StoredSession stored) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'token': stored.token, 'session': stored.session.toJson()}), flush: true);
  }

  @override
  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }
}

/// In-memory store for tests.
class MemorySessionStore implements SessionStore {
  MemorySessionStore([this.stored]);

  StoredSession? stored;

  @override
  Future<StoredSession?> read() async => stored;

  @override
  Future<void> write(StoredSession value) async => stored = value;

  @override
  Future<void> clear() async => stored = null;
}

import 'dart:async';
import 'dart:convert';

import '../service/db_service.dart';
import 'notification_item.dart';

class NotificationRepository {
  NotificationRepository._();
  // emit initial state when repository is first accessed
  void _initOnce() {
    Future.microtask(() async {
      try {
        await _ensureTable();
        // Migrate any existing string `data` columns to JSON strings
        // so future reads are reliable.
        try {
          await _migrateDataToJson();
        } catch (_) {}
        await _emitUpdates();
      } catch (_) {}
    });
  }

  static final NotificationRepository instance = (() {
    final r = NotificationRepository._();
    r._initOnce();
    return r;
  })();

  final _itemsController = StreamController<List<NotificationItem>>.broadcast();
  final _unreadController = StreamController<int>.broadcast();

  Stream<List<NotificationItem>> get notificationsStream =>
      _itemsController.stream;
  Stream<int> get unreadCountStream => _unreadController.stream;

  Future<void> _ensureTable() async {
    try {
      await DBService.instance.executeSqlInsUpDel('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          body TEXT,
          data TEXT,
          created_at INTEGER NOT NULL,
          read INTEGER DEFAULT 0
        );
      ''');
    } catch (_) {}
  }

  Future<void> insertFromRemote(dynamic msg) async {
    try {
      await _ensureTable();
      String? title;
      String? body;
      Map<String, dynamic> data = {};

      // Robustly extract fields from several possible shapes. Background
      // isolates / platform channels may pass a Map, while firebase_messaging
      // provides a RemoteMessage with a nested `notification` and `data`.
      try {
        // Prefer RemoteMessage.notification when available
        try {
          title = msg.notification?.title?.toString();
        } catch (_) {}
        try {
          body = msg.notification?.body?.toString();
        } catch (_) {}
        // Extract `data` for RemoteMessage
        try {
          if (msg.data != null) {
            if (msg.data is Map) {
              data = Map<String, dynamic>.from(msg.data as Map);
            } else if (msg.data is String) {
              data = jsonDecode(msg.data);
            }
          }
        } catch (_) {}

        // If title/body are still empty, try Map-shaped payloads
        if ((title == null || title.isEmpty) &&
            (body == null || body.isEmpty)) {
          try {
            if (msg is Map) {
              final notif = msg['notification'];
              if (notif is Map) {
                title ??= notif['title']?.toString();
                body ??= notif['body']?.toString();
              }
              title ??= msg['title']?.toString();
              body ??= msg['body']?.toString();

              final d = msg['data'] ?? msg['payload'] ?? msg['message'] ?? {};
              if (d is Map) {
                data = Map<String, dynamic>.from(d);
              } else if (d is String) {
                try {
                  data = jsonDecode(d);
                } catch (_) {}
              }
            }
          } catch (_) {}
        }
      } catch (_) {}

      // Last-resort: decode when the entire msg is a JSON string
      if ((data.isEmpty) && msg is String) {
        try {
          final decoded = jsonDecode(msg);
          if (decoded is Map<String, dynamic>) data = decoded;
        } catch (_) {}
      }

      // If the message contained no `data` payload, synthesize a helpful
      // fallback map from available fields so UI can show something useful
      // when the app handled a notification-only payload in the background.
      if (data.isEmpty) {
        final fallback = <String, dynamic>{};
        try {
          if (title != null && title.isNotEmpty) fallback['title'] = title;
        } catch (_) {}
        try {
          if (body != null && body.isNotEmpty) fallback['body'] = body;
        } catch (_) {}

        // Try to include other useful metadata when available.
        try {
          if (msg is Map) {
            if (msg.containsKey('messageId')) {
              fallback['messageId'] = msg['messageId'];
            }
            if (msg.containsKey('from')) fallback['from'] = msg['from'];
            if (msg.containsKey('collapseKey')) {
              fallback['collapseKey'] = msg['collapseKey'];
            }
          } else {
            // RemoteMessage properties (access defensively)
            try {
              final mid = msg.messageId;
              if (mid != null) fallback['messageId'] = mid;
            } catch (_) {}
            try {
              final from = msg.from;
              if (from != null) fallback['from'] = from;
            } catch (_) {}
            try {
              final ck = msg.collapseKey;
              if (ck != null) fallback['collapseKey'] = ck;
            } catch (_) {}
            try {
              final sent = msg.sentTime;
              if (sent != null) fallback['sentTime'] = sent.toString();
            } catch (_) {}
          }
        } catch (_) {}

        // Try to include nested notification fields (image, tag, etc.)
        try {
          final notif = msg is Map ? msg['notification'] : null;
          if (notif is Map) {
            notif.forEach((k, v) {
              if (!fallback.containsKey(k) && v != null) fallback[k] = v;
            });
          } else {
            try {
              final n = msg.notification;
              if (n != null) {
                try {
                  final nTitle = n.title;
                  if (nTitle != null) fallback['notification_title'] = nTitle;
                } catch (_) {}
                try {
                  final nBody = n.body;
                  if (nBody != null) fallback['notification_body'] = nBody;
                } catch (_) {}
                // android/apple-specific fields (image etc.)
                try {
                  final android = n.android;
                  if (android != null) {
                    final img = android.imageUrl;
                    if (img != null) fallback['notification_image'] = img;
                  }
                } catch (_) {}
                try {
                  final apple = n.apple;
                  if (apple != null) {
                    final img = apple.imageUrl;
                    if (img != null) fallback['notification_image'] = img;
                  }
                } catch (_) {}
              }
            } catch (_) {}
          }
        } catch (_) {}

        if (fallback.isNotEmpty) data = fallback;
      }

      // If title/body are still empty, prefer values present in `data`.
      try {
        if ((title == null || title.isEmpty) && data.containsKey('title')) {
          title = data['title']?.toString();
        }
      } catch (_) {}
      try {
        if ((body == null || body.isEmpty) && data.containsKey('body')) {
          body = data['body']?.toString();
        }
      } catch (_) {}

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // Deduplicate: if messageId exists in payload and DB already has
      // an entry containing that id, skip inserting to avoid duplicates
      // when background delivery + tap both run handlers.
      String? messageId;
      try {
        messageId = msg is Map ? msg['messageId']?.toString() : null;
      } catch (_) {}
      try {
        messageId ??= msg.messageId?.toString();
      } catch (_) {}
      try {
        messageId ??= data['messageId']?.toString();
      } catch (_) {}
      if (messageId != null && messageId.isNotEmpty) {
        try {
          final rows = await DBService.instance.selectFrom(
            'notifications',
            columns: ['COUNT(*) as c'],
            where: 'data LIKE ?',
            whereArgs: ['%$messageId%'],
          );
          if (rows.isNotEmpty) {
            final c = rows.first['c'];
            final count = c is int ? c : int.tryParse(c?.toString() ?? '') ?? 0;
            if (count > 0) return;
          }
        } catch (_) {}
      }

      // Also dedupe by identical title+body within a short window (30s).
      if (title != null &&
          title.isNotEmpty &&
          body != null &&
          body.isNotEmpty) {
        try {
          final windowStart = nowMs - 30000;
          final rows = await DBService.instance.selectFrom(
            'notifications',
            columns: ['id'],
            where: 'title = ? AND body = ? AND created_at >= ?',
            whereArgs: [title, body, windowStart],
          );
          if (rows.isNotEmpty) return;
        } catch (_) {}
      }

      final item = NotificationItem(
        title: title,
        body: body,
        data: data,
        createdAt: nowMs,
        read: 0,
      );
      await insert(item);
    } catch (_) {}
  }

  Future<int> insert(NotificationItem item) async {
    await _ensureTable();
    final id = await DBService.instance.insert('notifications', item.toMap());
    await _emitUpdates();
    return id;
  }

  Future<List<NotificationItem>> all() async {
    await _ensureTable();
    final rows = await DBService.instance.selectFrom(
      'notifications',
      orderBy: 'created_at DESC',
    );
    final items = rows.map((r) => NotificationItem.fromMap(r)).toList();
    // Ensure callers that explicitly request `all()` also receive an
    // immediate emission so late subscribers (e.g. widgets built after the
    // singleton initialized) can get data without relying on the initial
    // microtask-based emit which may have occurred earlier.
    try {
      _itemsController.add(items);
      final count = await unreadCount();
      _unreadController.add(count);
    } catch (_) {}
    return items;
  }

  Future<int> unreadCount() async {
    await _ensureTable();
    final rows = await DBService.instance.selectFrom(
      'notifications',
      columns: ['COUNT(*) as c'],
      where: 'read = 0',
    );
    if (rows.isNotEmpty) {
      final v = rows.first['c'];
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  Future<void> markAsRead(int id) async {
    await _ensureTable();
    await DBService.instance.update(
      'notifications',
      {'read': 1},
      'id = ?',
      [id],
    );
    await _emitUpdates();
  }

  Future<void> markAllRead() async {
    await _ensureTable();
    await DBService.instance.executeSqlInsUpDel(
      'UPDATE notifications SET read = 1 WHERE read = 0',
    );
    await _emitUpdates();
  }

  Future<void> _emitUpdates() async {
    try {
      final items = await all();
      _itemsController.add(items);
      final count = await unreadCount();
      _unreadController.add(count);
    } catch (_) {}
  }

  Future<void> _migrateDataToJson() async {
    try {
      final rows = await DBService.instance.selectFrom(
        'notifications',
        columns: ['id', 'data'],
      );
      for (final r in rows) {
        final id = r['id'] is int
            ? r['id'] as int
            : int.tryParse(r['id']?.toString() ?? '');
        if (id == null) continue;
        final raw = r['data'];
        if (raw == null) continue;
        if (raw is Map) {
          // already structured
          continue;
        }
        final s = raw.toString();
        if (s.trim().isEmpty) continue;
        // If it's already valid JSON object, normalize encoding
        try {
          final decoded = jsonDecode(s);
          if (decoded is Map<String, dynamic>) {
            final encoded = jsonEncode(decoded);
            await DBService.instance.update(
              'notifications',
              {'data': encoded},
              'id = ?',
              [id],
              autoHandlePayload: false,
            );
            continue;
          }
        } catch (_) {}

        // Try simple key:value fallback parsing
        try {
          final cleaned = s.replaceAll(RegExp(r'[{}]'), '');
          final parts = cleaned.split(',');
          final out = <String, dynamic>{};
          for (final p in parts) {
            final idx = p.indexOf(':');
            if (idx <= 0) continue;
            final k = p.substring(0, idx).trim();
            final v = p.substring(idx + 1).trim();
            if (k.isNotEmpty) out[k] = v;
          }
          final encoded = jsonEncode(out);
          await DBService.instance.update(
            'notifications',
            {'data': encoded},
            'id = ?',
            [id],
            autoHandlePayload: false,
          );
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Find a notification by checking whether the serialized `data` contains
  /// the given `messageId`. Returns the most recent match or `null`.
  Future<NotificationItem?> findByMessageId(String messageId) async {
    try {
      final rows = await DBService.instance.selectFrom(
        'notifications',
        where: 'data LIKE ?',
        whereArgs: ['%$messageId%'],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return NotificationItem.fromMap(rows.first);
    } catch (_) {
      return null;
    }
  }

  /// Find the most recent notification with matching `title` and `body`
  /// created within [withinMs] milliseconds from now. Returns null when
  /// no recent match exists.
  Future<NotificationItem?> findRecentByTitleBody(
    String title,
    String body,
    int withinMs,
  ) async {
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final windowStart = nowMs - withinMs;
      final rows = await DBService.instance.selectFrom(
        'notifications',
        where: 'title = ? AND body = ? AND created_at >= ?',
        whereArgs: [title, body, windowStart],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return NotificationItem.fromMap(rows.first);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _itemsController.close();
    _unreadController.close();
  }
}

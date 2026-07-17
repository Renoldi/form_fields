import 'dart:convert';

class NotificationItem {
  final int? id;
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;
  final int createdAt;
  final int read; // 0 = unread, 1 = read

  NotificationItem({
    this.id,
    this.title,
    this.body,
    this.data,
    required this.createdAt,
    this.read = 0,
  });

  NotificationItem copyWith({int? id, int? read}) => NotificationItem(
    id: id ?? this.id,
    title: title,
    body: body,
    data: data,
    createdAt: createdAt,
    read: read ?? this.read,
  );

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title ?? '',
      'body': body ?? '',
      // Store `data` as a JSON string for reliable round-trip decoding.
      'data': data != null ? jsonEncode(data) : '{}',
      'created_at': createdAt,
      'read': read,
    };
  }

  static NotificationItem fromMap(Map<String, dynamic> m) {
    return NotificationItem(
      id: m['id'] is int
          ? m['id'] as int
          : int.tryParse(m['id']?.toString() ?? ''),
      title: m['title']?.toString(),
      body: m['body']?.toString(),
      data: () {
        try {
          final raw = m['data'];
          if (raw == null) return <String, dynamic>{};
          if (raw is Map<String, dynamic>) return raw;
          final s = raw.toString();
          if (s.trim().isEmpty) return <String, dynamic>{};
          // Try JSON decode first
          try {
            final decoded = jsonDecode(s);
            if (decoded is Map<String, dynamic>) return decoded;
            return <String, dynamic>{};
          } catch (_) {}
          // Fallback: attempt to parse key:value pairs like k1:v1,k2:v2
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
            return out;
          } catch (_) {
            return <String, dynamic>{};
          }
        } catch (_) {
          return <String, dynamic>{};
        }
      }(),
      createdAt: m['created_at'] is int
          ? m['created_at'] as int
          : int.tryParse(m['created_at']?.toString() ?? '') ??
                DateTime.now().millisecondsSinceEpoch,
      read: m['read'] is int
          ? m['read'] as int
          : int.tryParse(m['read']?.toString() ?? '') ?? 0,
    );
  }
}

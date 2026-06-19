import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/data/models/post.dart';

// ViewModel backing the worker demo form. Holds simple input state and
// provides helpers to submit either a Map payload or a `Post` draft.
class ViewModel extends ChangeNotifier {
  bool isLoading = false;
  Post post = Post();
  List<Map<String, dynamic>> pending = [];

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> submit() async {
    // await Post.add(post: post);
  }

  Future<void> ensureTableExists() async {
    await DBService.instance.executeSqlInsUpDel('''
      CREATE TABLE IF NOT EXISTS pending_submissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payload TEXT NOT NULL,
        title TEXT,
        body TEXT,
        user_id INTEGER,
        tags TEXT,
        created_at INTEGER DEFAULT (strftime('%s','now'))
      );
    ''');
  }

  Future<void> loadPending() async {
    await ensureTableExists();
    pending = await DBService.instance
        .selectFrom('pending_submissions', orderBy: 'created_at DESC');
    commit();
  }

  Future<void> removePending(int id) async {
    await DBService.instance.delete('pending_submissions', 'id = ?', [id]);
    await loadPending();
  }

  Future<void> addPending() async {
    // Ensure minimal required fields for the example API. Some test
    // endpoints require a `userId` field — set a default if missing so
    // server returns a meaningful response instead of HTTP 400.
    post.userId ??= 1;
    await DBService.instance.insertOrUpdate('pending_submissions', {
      'payload': post.toJson(),
      'status': 'pending',
    });
    await loadPending();
    post = Post();
    commit();
  }

  void commit() {
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    commit();
  }
}

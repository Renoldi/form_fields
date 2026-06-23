import 'package:json_annotation/json_annotation.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/config/environment.dart';
import 'dart:convert';

part 'post.g.dart';

@JsonSerializable(explicitToJson: true)
class Post {
  int? id;
  String? title;
  String? body;
  int? userId;
  List<String>? tags;
  int? reactions;

  Post({
    this.id,
    this.title,
    this.body,
    this.userId,
    this.tags,
    this.reactions,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);

  // -----------------------
  // Convenience HTTP helpers using DioUtil
  // -----------------------
  static Future<List<Post>> list({int limit = 30, int skip = 0}) async {
    final base = EnvironmentConfig.currentBaseUrl;
    final url = base.endsWith('/')
        ? '${base}posts?limit=$limit&skip=$skip'
        : '$base/posts?limit=$limit&skip=$skip';
    final resp = await DioUtil.get<Map<String, dynamic>>(url);
    if (resp.statusCode == 200 && resp.data != null) {
      final list = (resp.data!['posts'] as List?) ?? [];
      return list
          .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<Post?> getById(int id) async {
    final base = EnvironmentConfig.currentBaseUrl;
    final url = base.endsWith('/') ? '${base}posts/$id' : '$base/posts/$id';
    final resp = await DioUtil.get<Map<String, dynamic>>(url);
    if (resp.statusCode == 200 && resp.data != null) {
      return Post.fromJson(Map<String, dynamic>.from(resp.data!));
    }
    return null;
  }

  static Future<Post?> add({Post? post}) async {
    final base = EnvironmentConfig.currentBaseUrl;
    final url = base.endsWith('/') ? '${base}posts/add' : '$base/posts/add';

    return DioUtil.post<Map<String, dynamic>>(url, data: post?.toJson())
        .then((resp) {
      final code = resp.statusCode ?? 0;
      try {
        final body = resp.data != null ? json.encode(resp.data) : '-';
        ForegroundTaskService.instance.lastLogListenable.value =
            'Post.add -> status=$code url=$url body=$body';
      } catch (_) {}
      if (code >= 200 && code < 300 && resp.data != null) {
        return Post.fromJson(Map<String, dynamic>.from(resp.data!));
      }
      return null;
    }).catchError((e) {
      try {
        ForegroundTaskService.instance.lastLogListenable.value =
            'Post.add threw: $e';
      } catch (_) {}
      throw e;
    });
  }

  static Future<List<Post>> search(String q,
      {int limit = 30, int skip = 0}) async {
    final base = EnvironmentConfig.currentBaseUrl;
    final query = 'q=${Uri.encodeQueryComponent(q)}&limit=$limit&skip=$skip';
    final url = base.endsWith('/')
        ? '${base}posts/search?$query'
        : '$base/posts/search?$query';
    final resp = await DioUtil.get<Map<String, dynamic>>(url);
    if (resp.statusCode == 200 && resp.data != null) {
      final list = (resp.data!['posts'] as List?) ?? [];
      return list
          .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}

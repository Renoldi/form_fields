import 'package:json_annotation/json_annotation.dart';

part 'direct_upload_payload.g.dart';

@JsonSerializable()
class DirectUploadPayload {
  final String url;
  final String filePath;
  final String fileName;
  final String? base64;
  final Map<String, String> headers;
  final Map<String, String> fields;
  final String fileFieldName;
  final bool includeReqType;
  final String? uploadCorrelationId;

  DirectUploadPayload({
    required this.url,
    required this.filePath,
    required this.fileName,
    this.base64,
    Map<String, String>? headers,
    Map<String, String>? fields,
    this.fileFieldName = 'file',
    this.includeReqType = false,
    this.uploadCorrelationId,
  })  : headers = headers ?? {},
        fields = fields ?? {};

  factory DirectUploadPayload.fromJson(Map<String, dynamic> json) =>
      _$DirectUploadPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$DirectUploadPayloadToJson(this);

  Map<String, dynamic> toMap() => toJson();

  @override
  String toString() =>
      'DirectUploadPayload(url: $url, filePath: $filePath, fileName: $fileName)';
}

/// Merges payloads that were already buffered with payloads built later for
/// the same captures, without queueing a capture twice.
///
/// The local file identifies a capture, so payloads are deduped by
/// [DirectUploadPayload.filePath]. A buffered entry wins over a rebuilt one,
/// because the buffered entry keeps the correlation id it was queued with.
List<DirectUploadPayload> mergeQueuedPayloads(
  Iterable<DirectUploadPayload> buffered,
  Iterable<DirectUploadPayload> rebuilt,
) {
  String keyOf(DirectUploadPayload p) => p.filePath.trim().isNotEmpty
      ? 'path:${p.filePath}'
      : 'id:${p.uploadCorrelationId}';

  final byKey = <String, DirectUploadPayload>{};
  for (final p in buffered) {
    byKey[keyOf(p)] = p;
  }
  for (final p in rebuilt) {
    byKey.putIfAbsent(keyOf(p), () => p);
  }
  return byKey.values.toList(growable: false);
}

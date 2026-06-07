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

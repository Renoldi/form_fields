// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'direct_upload_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DirectUploadPayload _$DirectUploadPayloadFromJson(Map<String, dynamic> json) =>
    DirectUploadPayload(
      url: json['url'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      base64: json['base64'] as String?,
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      fields: (json['fields'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      fileFieldName: json['fileFieldName'] as String? ?? 'file',
      includeReqType: json['includeReqType'] as bool? ?? false,
      uploadCorrelationId: json['uploadCorrelationId'] as String?,
    );

Map<String, dynamic> _$DirectUploadPayloadToJson(
        DirectUploadPayload instance) =>
    <String, dynamic>{
      'url': instance.url,
      'filePath': instance.filePath,
      'fileName': instance.fileName,
      'base64': instance.base64,
      'headers': instance.headers,
      'fields': instance.fields,
      'fileFieldName': instance.fileFieldName,
      'includeReqType': instance.includeReqType,
      'uploadCorrelationId': instance.uploadCorrelationId,
    };

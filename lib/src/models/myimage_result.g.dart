// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'myimage_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyImageResult _$MyImageResultFromJson(Map<String, dynamic> json) =>
    MyImageResult(
      link: json['link'] as String? ?? "",
      base64: json['base64'] as String? ?? "",
      path: json['path'] as String? ?? "",
      imageId: json['imageId'] as String? ?? "",
      description: json['description'] as String? ?? "",
      payload: json['payload'] as Map<String, dynamic>?,
      status: json['status'] == null
          ? MyImageStatus.idle
          : _statusFromJson(json['status'] as String?),
    );

Map<String, dynamic> _$MyImageResultToJson(MyImageResult instance) =>
    <String, dynamic>{
      'link': instance.link,
      'base64': instance.base64,
      'path': instance.path,
      'imageId': instance.imageId,
      'description': instance.description,
      'payload': instance.payload,
      'status': _statusToJson(instance.status),
    };

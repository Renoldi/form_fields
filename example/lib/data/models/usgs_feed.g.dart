// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usgs_feed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EarthquakeFeed _$EarthquakeFeedFromJson(Map<String, dynamic> json) =>
    EarthquakeFeed(
      type: json['type'] as String?,
      metadata: json['metadata'] == null
          ? null
          : Metadata.fromJson(json['metadata'] as Map<String, dynamic>),
      features: (json['features'] as List<dynamic>?)
          ?.map((e) =>
              e == null ? null : Feature.fromJson(e as Map<String, dynamic>))
          .whereType<Feature>()
          .toList(),
      bbox: json['bbox'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$EarthquakeFeedToJson(EarthquakeFeed instance) =>
    <String, dynamic>{
      'type': instance.type,
      'metadata': instance.metadata?.toJson(),
      'features': instance.features?.map((e) => e.toJson()).toList(),
      'bbox': instance.bbox,
    };

Metadata _$MetadataFromJson(Map<String, dynamic> json) => Metadata(
      generated: json['generated'] as int?,
      url: json['url'] as String?,
      title: json['title'] as String?,
      status: json['status'] as int?,
      api: json['api'] as String?,
      count: json['count'] as int?,
    );

Map<String, dynamic> _$MetadataToJson(Metadata instance) => <String, dynamic>{
      'generated': instance.generated,
      'url': instance.url,
      'title': instance.title,
      'status': instance.status,
      'api': instance.api,
      'count': instance.count,
    };

Feature _$FeatureFromJson(Map<String, dynamic> json) => Feature(
      type: json['type'] as String?,
      properties: json['properties'] == null
          ? null
          : Properties.fromJson(json['properties'] as Map<String, dynamic>),
      geometry: json['geometry'] == null
          ? null
          : Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
      id: json['id'] as String?,
    );

Map<String, dynamic> _$FeatureToJson(Feature instance) => <String, dynamic>{
      'type': instance.type,
      'properties': instance.properties?.toJson(),
      'geometry': instance.geometry?.toJson(),
      'id': instance.id,
    };

Properties _$PropertiesFromJson(Map<String, dynamic> json) => Properties(
      mag: (json['mag'] as num?)?.toDouble(),
      place: json['place'] as String?,
      time: json['time'] as int?,
      updated: json['updated'] as int?,
      tz: json['tz'] as int?,
      url: json['url'] as String?,
      detail: json['detail'] as String?,
      felt: json['felt'] as int?,
      cdi: (json['cdi'] as num?)?.toDouble(),
      mmi: (json['mmi'] as num?)?.toDouble(),
      alert: json['alert'] as String?,
      status: json['status'] as String?,
      tsunami: json['tsunami'] as int?,
      sig: json['sig'] as int?,
      net: json['net'] as String?,
      code: json['code'] as String?,
      ids: json['ids'] as String?,
      sources: json['sources'] as String?,
      types: json['types'] as String?,
      nst: json['nst'] as int?,
      dmin: (json['dmin'] as num?)?.toDouble(),
      rms: (json['rms'] as num?)?.toDouble(),
      gap: (json['gap'] as num?)?.toDouble(),
      magType: json['magType'] as String?,
      type: json['type'] as String?,
    );

Map<String, dynamic> _$PropertiesToJson(Properties instance) =>
    <String, dynamic>{
      'mag': instance.mag,
      'place': instance.place,
      'time': instance.time,
      'updated': instance.updated,
      'tz': instance.tz,
      'url': instance.url,
      'detail': instance.detail,
      'felt': instance.felt,
      'cdi': instance.cdi,
      'mmi': instance.mmi,
      'alert': instance.alert,
      'status': instance.status,
      'tsunami': instance.tsunami,
      'sig': instance.sig,
      'net': instance.net,
      'code': instance.code,
      'ids': instance.ids,
      'sources': instance.sources,
      'types': instance.types,
      'nst': instance.nst,
      'dmin': instance.dmin,
      'rms': instance.rms,
      'gap': instance.gap,
      'magType': instance.magType,
      'type': instance.type,
    };

Geometry _$GeometryFromJson(Map<String, dynamic> json) => Geometry(
      type: json['type'] as String?,
      coordinates: (json['coordinates'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$GeometryToJson(Geometry instance) => <String, dynamic>{
      'type': instance.type,
      'coordinates': instance.coordinates,
    };

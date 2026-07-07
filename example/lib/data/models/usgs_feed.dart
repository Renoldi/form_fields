import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:form_fields/form_fields.dart';

part 'usgs_feed.g.dart';

@JsonSerializable()
class EarthquakeFeed {
  final String? type;
  final Metadata? metadata;
  final List<Feature>? features;
  final Map<String, dynamic>? bbox;

  EarthquakeFeed({this.type, this.metadata, this.features, this.bbox});

  factory EarthquakeFeed.fromJson(Map<String, dynamic> json) =>
      _$EarthquakeFeedFromJson(json);
  Map<String, dynamic> toJson() => _$EarthquakeFeedToJson(this);

  /// Fetch the given [url] (expected USGS GeoJSON or a list-like JSON)
  /// and convert to a serializable list of marker-like maps ready for
  /// `generateMarkers`. Each map contains at least `lat` and `lon`.
  static Future<List<Map<String, dynamic>>> fetchRawMarkers(String url) async {
    final out = <Map<String, dynamic>>[];
    final resp = await DioUtil.get(url);
    final dynamic parsed =
        resp.data is String ? json.decode(resp.data as String) : resp.data;

    double? toDoubleLocal(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      return null;
    }

    String formatDepth(double d) {
      final abs = d.abs();
      if (abs < 1) {
        final meters = (d * 1000).round();
        return '$meters m';
      }
      final rounded = (d * 10).round() / 10.0;
      if (rounded == rounded.toInt()) return '${rounded.toInt()} km';
      return '$rounded km';
    }

    String? formatTime(dynamic t) {
      try {
        if (t == null) return null;
        int ms;
        if (t is int) {
          ms = t;
        } else if (t is String) {
          ms = int.tryParse(t) ?? 0;
        } else if (t is double) {
          ms = t.toInt();
        } else {
          return null;
        }
        if (ms <= 0) return null;
        final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
        String two(int v) => v.toString().padLeft(2, '0');
        return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
      } catch (_) {
        return null;
      }
    }

    String formatMag(dynamic m) {
      final v = toDoubleLocal(m);
      if (v == null) return '';
      final rounded = (v * 10).round() / 10.0;
      if (rounded == rounded.toInt()) return 'M ${rounded.toInt()}';
      return 'M $rounded';
    }

    // Try typed GeoJSON -> EarthquakeFeed
    if (parsed is Map) {
      try {
        final feed = EarthquakeFeed.fromJson(parsed as Map<String, dynamic>);
        if (feed.features != null) {
          for (final f in feed.features!) {
            try {
              final geom = f.geometry;
              if (geom?.coordinates != null && geom!.coordinates!.length >= 2) {
                final lon = toDoubleLocal(geom.coordinates![0]);
                final lat = toDoubleLocal(geom.coordinates![1]);
                if (lat != null && lon != null) {
                  final mag = f.properties?.mag;
                  double? depth;
                  if (geom.coordinates != null &&
                      geom.coordinates!.length >= 3) {
                    depth = toDoubleLocal(geom.coordinates![2]);
                  }

                  final titlePlace = f.properties?.place;
                  final magLabel = formatMag(f.properties?.mag);
                  final title = titlePlace ??
                      (magLabel.isNotEmpty
                          ? (f.id != null ? '$magLabel (${f.id})' : magLabel)
                          : f.id);

                  final timeStr = formatTime(f.properties?.time);
                  final parts = <String>[];
                  if (mag != null) parts.add('Magnitude $mag');
                  if (depth != null) parts.add(formatDepth(depth));
                  if (timeStr != null) parts.add(timeStr);
                  String? subtitle =
                      parts.isNotEmpty ? parts.join(' • ') : f.properties?.type;

                  out.add({
                    'lat': lat,
                    'lon': lon,
                    'title': title,
                    'subtitle': subtitle,
                    'id': f.id,
                    'shapeType': ShapeTypes.marker,
                  });
                }
              }
            } catch (_) {}
          }
          return out;
        }
      } catch (_) {
        // fall through to generic heuristics
      }
    }

    // Generic fallbacks: features list, data list, or top-level list
    List<dynamic>? list;
    if (parsed is List) {
      list = parsed;
    } else if (parsed is Map && parsed['features'] is List) {
      list = parsed['features'] as List<dynamic>;
    } else if (parsed is Map && parsed['data'] is List) {
      list = parsed['data'] as List<dynamic>;
    }

    if (list != null) {
      for (final itm in list) {
        try {
          double? lat;
          double? lon;
          double? depth;
          String? derivedTitle;
          String? derivedSubtitle;
          if (itm is Map) {
            lat ??= toDoubleLocal(itm['lat']);
            lon ??= toDoubleLocal(itm['lon']);
            lat ??= toDoubleLocal(itm['latitude']);
            lon ??= toDoubleLocal(itm['longitude']);
            lat ??= toDoubleLocal(itm['Lat']);
            lon ??= toDoubleLocal(itm['Lon']);
            lat ??= toDoubleLocal(itm['LAT']);
            lon ??= toDoubleLocal(itm['LON']);

            // try common depth fields
            depth ??= toDoubleLocal(itm['depth']);
            depth ??= toDoubleLocal(itm['depth_km']);
            depth ??= toDoubleLocal(itm['depthKm']);
            depth ??= toDoubleLocal(itm['elevation']);

            if ((lat == null || lon == null) && itm['geometry'] is Map) {
              final geom = itm['geometry'] as Map;
              if (geom['coordinates'] is List) {
                final coords = (geom['coordinates'] as List).cast<dynamic>();
                if (coords.length >= 2) {
                  lon ??= toDoubleLocal(coords[0]);
                  lat ??= toDoubleLocal(coords[1]);
                }
                if (coords.length >= 3) {
                  depth ??= toDoubleLocal(coords[2]);
                }
              }
            }

            if ((lat == null || lon == null) && itm['location'] is Map) {
              final loc = itm['location'] as Map;
              lat ??= toDoubleLocal(loc['lat'] ?? loc['latitude']);
              lon ??= toDoubleLocal(loc['lon'] ?? loc['longitude']);
            }
          } else if (itm is List && itm.length >= 2) {
            lon = toDoubleLocal(itm[0]);
            lat = toDoubleLocal(itm[1]);
          }

          if (lat != null && lon != null) {
            if (itm is Map) {
              derivedTitle = itm['title']?.toString() ??
                  itm['place']?.toString() ??
                  itm['name']?.toString() ??
                  itm['locationName']?.toString();
              // Fallback to mag or id if no readable place/title
              derivedTitle ??= () {
                final magLabel = formatMag(itm['mag'] ?? itm['magnitude']);
                if (magLabel.isNotEmpty) {
                  return itm['id'] != null
                      ? '$magLabel (${itm['id']})'
                      : magLabel;
                }
                return itm['id']?.toString();
              }();

              final magVal = itm['mag'] ?? itm['magnitude'];
              final timeVal = itm['time'] ?? itm['timestamp'] ?? itm['time_ms'];
              final timeStr = formatTime(timeVal);
              final parts = <String>[];
              if (magVal != null) parts.add('Magnitude $magVal');
              if (depth != null) parts.add(formatDepth(depth));
              if (timeStr != null) parts.add(timeStr);
              derivedSubtitle = parts.isNotEmpty
                  ? parts.join(' • ')
                  : itm['subtitle']?.toString() ?? itm['type']?.toString();
            } else {
              derivedTitle = null;
              derivedSubtitle = null;
            }

            // If derivedTitle is a magnitude-only label and there's an id, append id
            if (derivedTitle != null &&
                derivedTitle.startsWith('Magnitude') &&
                itm is Map &&
                itm['id'] != null) {
              derivedTitle = '$derivedTitle (${itm['id']})';
            }

            out.add({
              'lat': lat,
              'lon': lon,
              'title': derivedTitle,
              'subtitle': derivedSubtitle,
              'id': itm is Map ? itm['id']?.toString() : null,
              'shapeType': itm is Map
                  ? (itm['shapeType'] ?? ShapeTypes.marker)
                  : ShapeTypes.marker,
            });
          }
        } catch (_) {}
      }
    }

    return out;
  }
}

@JsonSerializable()
class Metadata {
  final int? generated;
  final String? url;
  final String? title;
  final int? status;
  final String? api;
  final int? count;

  Metadata(
      {this.generated,
      this.url,
      this.title,
      this.status,
      this.api,
      this.count});

  factory Metadata.fromJson(Map<String, dynamic> json) =>
      _$MetadataFromJson(json);
  Map<String, dynamic> toJson() => _$MetadataToJson(this);
}

@JsonSerializable()
class Feature {
  final String? type;
  final Properties? properties;
  final Geometry? geometry;
  final String? id;

  Feature({this.type, this.properties, this.geometry, this.id});

  factory Feature.fromJson(Map<String, dynamic> json) =>
      _$FeatureFromJson(json);
  Map<String, dynamic> toJson() => _$FeatureToJson(this);
}

@JsonSerializable()
class Properties {
  final double? mag;
  final String? place;
  final int? time;
  final int? updated;
  final int? tz;
  final String? url;
  final String? detail;
  final int? felt;
  final double? cdi;
  final double? mmi;
  final String? alert;
  final String? status;
  final int? tsunami;
  final int? sig;
  final String? net;
  final String? code;
  final String? ids;
  final String? sources;
  final String? types;
  final int? nst;
  final double? dmin;
  final double? rms;
  final double? gap;
  final String? magType;
  final String? type;

  Properties({
    this.mag,
    this.place,
    this.time,
    this.updated,
    this.tz,
    this.url,
    this.detail,
    this.felt,
    this.cdi,
    this.mmi,
    this.alert,
    this.status,
    this.tsunami,
    this.sig,
    this.net,
    this.code,
    this.ids,
    this.sources,
    this.types,
    this.nst,
    this.dmin,
    this.rms,
    this.gap,
    this.magType,
    this.type,
  });

  factory Properties.fromJson(Map<String, dynamic> json) =>
      _$PropertiesFromJson(json);
  Map<String, dynamic> toJson() => _$PropertiesToJson(this);
}

@JsonSerializable()
class Geometry {
  final String? type;
  final List<double>? coordinates; // [lon, lat, depth]

  Geometry({this.type, this.coordinates});

  factory Geometry.fromJson(Map<String, dynamic> json) =>
      _$GeometryFromJson(json);
  Map<String, dynamic> toJson() => _$GeometryToJson(this);
}

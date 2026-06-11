import '../../../core/network/api_client.dart';

class Footprint {
  final int groupId;
  final String groupName;
  final double latitude;
  final double longitude;
  final DateTime metAt;
  final int attendeeCount;
  final List<String> interests;

  Footprint({
    required this.groupId,
    required this.groupName,
    required this.latitude,
    required this.longitude,
    required this.metAt,
    required this.attendeeCount,
    required this.interests,
  });

  factory Footprint.fromJson(Map<String, dynamic> json) => Footprint(
    groupId: json['group_id'] as int,
    groupName: json['group_name'] as String? ?? '모임',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    metAt: DateTime.parse(json['met_at'] as String),
    attendeeCount: json['attendee_count'] as int? ?? 0,
    interests: (json['interests'] as List?)
        ?.map((e) => e as String)
        .toList() ??
        [],
  );
}

class FootprintRepository {
  Future<List<Footprint>> getFootprints() async {
    final res = await ApiClient.dio.get('/api/footprints');
    return (res.data as List)
        .map((e) => Footprint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createFootprint({
    required int groupId,
    required double latitude,
    required double longitude,
  }) async {
    await ApiClient.dio.post('/api/footprints', data: {
      'group_id': groupId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}
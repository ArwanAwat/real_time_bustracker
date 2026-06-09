class BusLog {
  final int? id;
  final int busId;
  final double latitude;
  final double longitude;
  final int speed;
  final String status;
  final int passengerCount;
  final DateTime recordedAt;

  BusLog({
    this.id,
    required this.busId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.status,
    required this.passengerCount,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'busId': busId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'status': status,
        'passengerCount': passengerCount,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory BusLog.fromMap(Map<String, dynamic> map) => BusLog(
        id: map['id'],
        busId: map['busId'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        speed: map['speed'],
        status: map['status'],
        passengerCount: map['passengerCount'] ?? 0,
        recordedAt: DateTime.parse(map['recordedAt']),
      );
}
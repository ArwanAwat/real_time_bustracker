class Bus {
  final int? id;
  final String busNumber;
  final String routeName;
  final String driverName;
  final double latitude;
  final double longitude;
  final String status; // 'on_route' | 'delayed' | 'stopped' | 'maintenance'
  final int speed;
  final int passengerCount;
  final int capacity;
  final DateTime lastUpdated;
  final DateTime createdAt;

  Bus({
    this.id,
    required this.busNumber,
    required this.routeName,
    required this.driverName,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.speed,
    required this.passengerCount,
    required this.capacity,
    required this.lastUpdated,
    required this.createdAt,
  });

  double get occupancyRate =>
      capacity > 0 ? (passengerCount / capacity).clamp(0.0, 1.0) : 0.0;

  bool get isLive => DateTime.now().difference(lastUpdated).inSeconds < 30;

  Map<String, dynamic> toMap() => {
        'id': id,
        'busNumber': busNumber,
        'routeName': routeName,
        'driverName': driverName,
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
        'speed': speed,
        'passengerCount': passengerCount,
        'capacity': capacity,
        'lastUpdated': lastUpdated.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bus.fromMap(Map<String, dynamic> map) => Bus(
        id: map['id'],
        busNumber: map['busNumber'],
        routeName: map['routeName'],
        driverName: map['driverName'] ?? 'Unknown',
        latitude: map['latitude'],
        longitude: map['longitude'],
        status: map['status'],
        speed: map['speed'],
        passengerCount: map['passengerCount'] ?? 0,
        capacity: map['capacity'] ?? 50,
        lastUpdated: DateTime.parse(map['lastUpdated']),
        createdAt: DateTime.parse(
            map['createdAt'] ?? map['lastUpdated']),
      );

  Bus copyWith({
    int? id,
    String? busNumber,
    String? routeName,
    String? driverName,
    double? latitude,
    double? longitude,
    String? status,
    int? speed,
    int? passengerCount,
    int? capacity,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) =>
      Bus(
        id: id ?? this.id,
        busNumber: busNumber ?? this.busNumber,
        routeName: routeName ?? this.routeName,
        driverName: driverName ?? this.driverName,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        status: status ?? this.status,
        speed: speed ?? this.speed,
        passengerCount: passengerCount ?? this.passengerCount,
        capacity: capacity ?? this.capacity,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        createdAt: createdAt ?? this.createdAt,
      );
}
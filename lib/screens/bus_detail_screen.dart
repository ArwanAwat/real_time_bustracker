import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/bus.dart';
import '../providers/bus_provider.dart';
import '../widgets/live_badge.dart';
import '../widgets/bus_card.dart';
import 'trip_log_screen.dart';
import 'add_edit_bus_screen.dart';

class BusDetailScreen extends StatefulWidget {
  final int busId;
  const BusDetailScreen({super.key, required this.busId});

  @override
  State<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends State<BusDetailScreen> {
  Bus? _bus;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadBus();
  }

  Future<void> _loadBus() async {
    final buses = context.read<BusProvider>().buses;
    final found = buses.where((b) => b.id == widget.busId);
    if (found.isNotEmpty) setState(() => _bus = found.first);
  }

  Future<void> _doRefresh() async {
    setState(() => _refreshing = true);
    final result =
        await context.read<BusProvider>().refreshBus(widget.busId);
    setState(() {
      _bus = result.updated;
      _refreshing = false;
    });
    if (result.statusChange != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Status changed to: ${result.statusChange!.replaceAll('_', ' ')}'),
        backgroundColor: Colors.orange,
      ));
    }
  }

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color.fromARGB(255, 255, 68, 68).withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.grey[700])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bus == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bus = _bus!;
    final color = BusCard.statusColor(bus.status);
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Bus ${bus.busNumber}'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddEditBusScreen(bus: bus)));
              _loadBus();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Trip Log',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TripLogScreen(bus: bus))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_bus, color: color, size: 42),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bus.busNumber,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          LiveBadge(isLive: bus.isLive),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(bus.routeName,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center),
                  Text('Driver: ${bus.driverName}',
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(height: 14),
                  // Occupancy bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              'Occupancy: ${(bus.occupancyRate * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600])),
                          Text(
                              '${bus.passengerCount} / ${bus.capacity}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400])),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: bus.occupancyRate,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            bus.occupancyRate > 0.9
                                ? Colors.red
                                : bus.occupancyRate > 0.7
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Info card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    _row(Icons.info_outline, 'Status',
                        BusCard.statusLabel(bus.status),
                        valueColor: color),
                    const Divider(height: 1),
                    _row(Icons.speed, 'Speed', '${bus.speed} km/h'),
                    const Divider(height: 1),
                    _row(Icons.location_on_outlined, 'Latitude',
                        bus.latitude.toStringAsFixed(6)),
                    const Divider(height: 1),
                    _row(Icons.location_searching, 'Longitude',
                        bus.longitude.toStringAsFixed(6)),
                    const Divider(height: 1),
                    _row(Icons.event_seat_outlined, 'Capacity',
                        '${bus.capacity} seats'),
                    const Divider(height: 1),
                    _row(Icons.update, 'Last Updated',
                        fmt.format(bus.lastUpdated)),
                    const Divider(height: 1),
                    _row(Icons.calendar_today_outlined, 'Added',
                        fmt.format(bus.createdAt)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _refreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.my_location),
                    label: const Text('Simulate GPS Update'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 68, 68),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _refreshing ? null : _doRefresh,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Logs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade50,
                    foregroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TripLogScreen(bus: bus))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
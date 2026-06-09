import 'package:flutter/material.dart';
import '../models/bus.dart';
import 'live_badge.dart';

class BusCard extends StatelessWidget {
  final Bus bus;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const BusCard({
    super.key,
    required this.bus,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  static Color statusColor(String s) {
    switch (s) {
      case 'on_route':   return Colors.green;
      case 'delayed':    return Colors.orange;
      case 'stopped':    return Colors.red;
      case 'maintenance': return Colors.blueGrey;
      default:           return Colors.grey;
    }
  }

  static String statusLabel(String s) {
    switch (s) {
      case 'on_route':    return 'On Route';
      case 'delayed':     return 'Delayed';
      case 'stopped':     return 'Stopped';
      case 'maintenance': return 'Maintenance';
      default:            return 'Unknown';
    }
  }

  static IconData statusIcon(String s) {
    switch (s) {
      case 'on_route':    return Icons.directions_bus;
      case 'delayed':     return Icons.warning_amber_rounded;
      case 'stopped':     return Icons.stop_circle_outlined;
      case 'maintenance': return Icons.build_outlined;
      default:            return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(bus.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon(bus.status),
                        color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(bus.busNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(width: 8),
                            LiveBadge(isLive: bus.isLive),
                          ],
                        ),
                        Text(bus.routeName,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                        Text('Driver: ${bus.driverName}',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11)),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel(bus.status),
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Occupancy bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Occupancy',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                      Text(
                          '${bus.passengerCount}/${bus.capacity} passengers',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: bus.occupancyRate,
                      minHeight: 5,
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.speed, size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Text('${bus.speed} km/h',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 12),
                  Icon(Icons.location_on_outlined,
                      size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Text(
                      '${bus.latitude.toStringAsFixed(4)}, ${bus.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined,
                          size: 18, color: const Color.fromARGB(255, 255, 68, 68)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline,
                          size: 18, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bus_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/bus_card.dart';
import 'bus_detail_screen.dart';
import 'add_edit_bus_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BusProvider>(builder: (context, provider, _) {
      final stats = provider.fleetStats;
      final avgs = provider.fleetAverages;
      final topBuses =
          provider.buses.where((b) => b.status == 'on_route').take(3).toList();

      return RefreshIndicator(
        onRefresh: () => provider.loadAll(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Fleet Overview header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fleet Overview',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: provider.autoRefresh
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        provider.autoRefresh
                            ? Icons.sync
                            : Icons.sync_disabled,
                        size: 14,
                        color: provider.autoRefresh
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.autoRefresh ? 'Live' : 'Paused',
                        style: TextStyle(
                            fontSize: 12,
                            color: provider.autoRefresh
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                StatCard(
                  label: 'Total Buses',
                  value: '${stats['total'] ?? 0}',
                  icon: Icons.directions_bus,
                  color: const Color.fromARGB(255, 255, 68, 68),
                ),
                StatCard(
                  label: 'On Route',
                  value: '${stats['on_route'] ?? 0}',
                  icon: Icons.play_arrow_rounded,
                  color: Colors.green,
                ),
                StatCard(
                  label: 'Delayed',
                  value: '${stats['delayed'] ?? 0}',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
                StatCard(
                  label: 'Avg Speed',
                  value: '${avgs['avgSpeed']?.toStringAsFixed(0) ?? 0}',
                  icon: Icons.speed,
                  color: Colors.purple,
                  subtitle: 'km/h across active fleet',
                ),
                StatCard(
                  label: 'Stopped',
                  value: '${stats['stopped'] ?? 0}',
                  icon: Icons.stop_circle_outlined,
                  color: Colors.red,
                ),
                StatCard(
                  label: 'Avg Occupancy',
                  value:
                      '${((avgs['avgOccupancy'] ?? 0) * 100).toStringAsFixed(0)}%',
                  icon: Icons.people_outline,
                  color: Colors.teal,
                  subtitle: 'fleet-wide load',
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Active Buses',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (topBuses.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('No buses currently on route',
                      style: TextStyle(color: Colors.grey[400])),
                ),
              )
            else
              ...topBuses.map((b) => BusCard(
                    bus: b,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => BusDetailScreen(busId: b.id!))),
                    onDelete: () {},
                    onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AddEditBusScreen(bus: b))),
                  )),
          ],
        ),
      );
    });
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bus.dart';
import '../models/bus_log.dart';
import '../providers/bus_provider.dart';
import '../widgets/bus_card.dart';

class TripLogScreen extends StatefulWidget {
  final Bus bus;
  const TripLogScreen({super.key, required this.bus});

  @override
  State<TripLogScreen> createState() => _TripLogScreenState();
}

class _TripLogScreenState extends State<TripLogScreen> {
  List<BusLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    final logs =
        await context.read<BusProvider>().getLogsForBus(widget.bus.id!);
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm:ss');
    final dateFmt = DateFormat('MMM dd');

    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Log — ${widget.bus.busNumber}'),
        backgroundColor: const Color.fromARGB(255, 255, 68, 68),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('No log entries yet'))
              : Column(
                  children: [
                    // Summary bar
                    Container(
                      padding: const EdgeInsets.all(14),
                      color: const Color.fromARGB(255, 255, 68, 68).withOpacity(0.05),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _summaryItem(
                              '${_logs.length}', 'Log entries', Icons.history),
                          _summaryItem(
                            '${_logs.map((l) => l.speed).reduce((a, b) => a > b ? a : b)} km/h',
                            'Peak speed',
                            Icons.speed,
                          ),
                          _summaryItem(
                            '${_logs.map((l) => l.passengerCount).reduce((a, b) => a > b ? a : b)}',
                            'Peak passengers',
                            Icons.people,
                          ),
                        ],
                      ),
                    ),
                    // Log list
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _logs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (_, i) {
                          final log = _logs[i];
                          final color = BusCard.statusColor(log.status);
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: color.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                // Time column
                                SizedBox(
                                  width: 60,
                                  child: Column(
                                    children: [
                                      Text(fmt.format(log.recordedAt),
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 13)),
                                      Text(
                                          dateFmt.format(log.recordedAt),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[400])),
                                    ],
                                  ),
                                ),
                                // Timeline dot
                                Column(
                                  children: [
                                    Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 14),
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: color)),
                                    if (i < _logs.length - 1)
                                      Container(
                                          width: 2,
                                          height: 20,
                                          color: color.withOpacity(0.2)),
                                  ],
                                ),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  color.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      6),
                                            ),
                                            child: Text(
                                                BusCard.statusLabel(
                                                    log.status),
                                                style: TextStyle(
                                                    color: color,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('${log.speed} km/h',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Colors.grey[600])),
                                          const SizedBox(width: 8),
                                          Icon(Icons.people_outline,
                                              size: 12,
                                              color: Colors.grey[400]),
                                          Text(' ${log.passengerCount}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Colors.grey[600])),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${log.latitude.toStringAsFixed(5)}, ${log.longitude.toStringAsFixed(5)}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[400],
                                            fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _summaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color.fromARGB(255, 255, 68, 68)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}
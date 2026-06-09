import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bus_provider.dart';
import '../widgets/bus_card.dart';
import 'add_edit_bus_screen.dart';
import 'bus_detail_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ADD SingleTickerProviderStateMixin here — this is the vsync source
class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize here in initState, not lazily inside build
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Bus'),
        content: const Text('Remove this bus from the fleet?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<BusProvider>().deleteBus(id);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus removed from fleet')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusProvider>(builder: (context, provider, _) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 255, 68, 68),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Row(
            children: [
              Icon(Icons.directions_bus, size: 22),
              SizedBox(width: 8),
              Text('BusTrack Pro',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                provider.autoRefresh
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
              tooltip: provider.autoRefresh
                  ? 'Pause live updates'
                  : 'Resume live updates',
              onPressed: provider.toggleAutoRefresh,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => provider.loadAll(),
            ),
          ],
          bottom: TabBar(
            controller: _tabController, // use the field directly
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
              Tab(icon: Icon(Icons.list_alt), text: 'Fleet'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController, // use TabBarView instead of IndexedStack
          children: [
            const DashboardScreen(),
            _buildFleetTab(context, provider),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditBusScreen()));
            provider.loadAll();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Bus'),
          backgroundColor: const Color.fromARGB(255, 255, 68, 68),
          foregroundColor: Colors.white,
        ),
      );
    });
  }

  Widget _buildFleetTab(BuildContext context, BusProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: provider.setSearch,
            decoration: InputDecoration(
              hintText: 'Search by bus, route, or driver...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        provider.setSearch('');
                      })
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final f in [
                ('all', 'All'),
                ('on_route', 'On Route'),
                ('delayed', 'Delayed'),
                ('stopped', 'Stopped'),
                ('maintenance', 'Maintenance'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(f.$1 == 'all'
                        ? 'All'
                        : f.$2),
                    selected: provider.filter == f.$1,
                    onSelected: (_) => provider.setFilter(f.$1),
                    selectedColor: const Color.fromARGB(255, 255, 68, 68).withOpacity(0.15),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${provider.buses.length} bus${provider.buses.length == 1 ? '' : 'es'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              if (provider.autoRefresh)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('• Auto-refreshing every 5s',
                      style: TextStyle(
                          fontSize: 12, color: Colors.green[400])),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : provider.buses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No buses found',
                              style:
                                  TextStyle(color: Colors.grey[400])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.loadAll(),
                      child: ListView.builder(
                        itemCount: provider.buses.length,
                        itemBuilder: (_, i) {
                          final bus = provider.buses[i];
                          return BusCard(
                            bus: bus,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => BusDetailScreen(
                                        busId: bus.id!))),
                            onDelete: () =>
                                _showDeleteDialog(context, bus.id!),
                            onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        AddEditBusScreen(bus: bus))),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
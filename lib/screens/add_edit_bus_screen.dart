import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bus.dart';
import '../providers/bus_provider.dart';

class AddEditBusScreen extends StatefulWidget {
  final Bus? bus;
  const AddEditBusScreen({super.key, this.bus});

  @override
  State<AddEditBusScreen> createState() => _AddEditBusScreenState();
}

class _AddEditBusScreenState extends State<AddEditBusScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _busNumberCtrl;
  late final TextEditingController _routeCtrl;
  late final TextEditingController _driverCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _capacityCtrl;
  String _status = 'on_route';
  bool _saving = false;

  bool get isEdit => widget.bus != null;

  @override
  void initState() {
    super.initState();
    final b = widget.bus;
    _busNumberCtrl = TextEditingController(text: b?.busNumber ?? '');
    _routeCtrl = TextEditingController(text: b?.routeName ?? '');
    _driverCtrl = TextEditingController(text: b?.driverName ?? '');
    _latCtrl = TextEditingController(
        text: b?.latitude.toString() ?? '36.1901');
    _lngCtrl = TextEditingController(
        text: b?.longitude.toString() ?? '44.0091');
    _capacityCtrl =
        TextEditingController(text: b?.capacity.toString() ?? '50');
    _status = b?.status ?? 'on_route';
  }

  @override
  void dispose() {
    for (final c in [
      _busNumberCtrl,
      _routeCtrl,
      _driverCtrl,
      _latCtrl,
      _lngCtrl,
      _capacityCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final bus = Bus(
      id: widget.bus?.id,
      busNumber: _busNumberCtrl.text.trim(),
      routeName: _routeCtrl.text.trim(),
      driverName: _driverCtrl.text.trim(),
      latitude: double.parse(_latCtrl.text.trim()),
      longitude: double.parse(_lngCtrl.text.trim()),
      status: _status,
      speed: widget.bus?.speed ?? 0,
      passengerCount: widget.bus?.passengerCount ?? 0,
      capacity: int.parse(_capacityCtrl.text.trim()),
      lastUpdated: now,
      createdAt: widget.bus?.createdAt ?? now,
    );

    final provider = context.read<BusProvider>();
    if (isEdit) {
      await provider.updateBus(bus);
    } else {
      await provider.addBus(bus);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(isEdit ? 'Bus updated successfully' : 'Bus added to fleet'),
        backgroundColor: Colors.green,
      ));
    }
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: validator ??
            (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Bus' : 'Add New Bus'),
        backgroundColor: const Color.fromARGB(255, 255, 68, 68),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bus Details',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              _field(_busNumberCtrl, 'Bus Number',
                  Icons.confirmation_number_outlined),
              _field(_routeCtrl, 'Route Name', Icons.route),
              _field(_driverCtrl, 'Driver Name', Icons.person_outline),
              _field(
                _capacityCtrl,
                'Passenger Capacity',
                Icons.event_seat_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Enter a valid number';
                  return null;
                },
              ),
              const Text('Location',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                          filled: true),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                          filled: true),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in [
                    ('on_route', 'On Route', Colors.green),
                    ('delayed', 'Delayed', Colors.orange),
                    ('stopped', 'Stopped', const Color.fromARGB(255, 255, 17, 0)),
                    ('maintenance', 'Maintenance', Colors.blueGrey),
                  ])
                    ChoiceChip(
                      label: Text(s.$2),
                      selected: _status == s.$1,
                      selectedColor: s.$3.withOpacity(0.2),
                      onSelected: (_) => setState(() => _status = s.$1),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(isEdit ? Icons.save : Icons.add),
                  label: Text(isEdit ? 'Save Changes' : 'Add to Fleet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 68, 68),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
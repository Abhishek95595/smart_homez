import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../models/property_hierarchy.dart';
import '../../theme/app_theme.dart';

class PropertyFormResult {
  final String name;
  final String address;
  final String category;
  final String propertyType;
  final String timezone;
  final String currency;
  final String? businessStart;
  final String? businessEnd;

  const PropertyFormResult({
    required this.name,
    required this.address,
    required this.category,
    required this.propertyType,
    required this.timezone,
    required this.currency,
    this.businessStart,
    this.businessEnd,
  });
}

class FloorFormResult {
  final String name;
  final int level;

  const FloorFormResult({required this.name, required this.level});
}

class RoomFormResult {
  final String name;
  final String type;

  const RoomFormResult({required this.name, required this.type});
}

class DeviceFormResult {
  final String name;
  final DeviceType type;
  final String macAddress;
  final String? propertyId;
  final String? floorId;
  final String? roomId;
  final String? roomName;

  const DeviceFormResult({
    required this.name,
    required this.type,
    required this.macAddress,
    this.propertyId,
    this.floorId,
    this.roomId,
    this.roomName,
  });
}

Future<PropertyFormResult?> showPropertyForm(
  BuildContext context, {
  ManagedProperty? property,
  required bool Function(String value) nameExists,
}) {
  return Navigator.push<PropertyFormResult>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          _PropertyFormPage(property: property, nameExists: nameExists),
    ),
  );
}

Future<FloorFormResult?> showFloorForm(
  BuildContext context, {
  ManagedFloor? floor,
  required bool Function(String name, int level) floorExists,
}) {
  return showDialog<FloorFormResult>(
    context: context,
    builder: (_) => _FloorForm(floor: floor, floorExists: floorExists),
  );
}

Future<RoomFormResult?> showRoomForm(
  BuildContext context, {
  ManagedRoom? room,
  required bool Function(String value) nameExists,
}) {
  return showDialog<RoomFormResult>(
    context: context,
    builder: (_) => _RoomForm(room: room, nameExists: nameExists),
  );
}

Future<DeviceFormResult?> showDeviceForm(
  BuildContext context, {
  Device? device,
  required bool Function(String value) nameExists,
  required bool Function(String value) macExists,
  bool showLocationFields = false,
  List<ManagedProperty> properties = const [],
  List<ManagedFloor> floors = const [],
  List<ManagedRoom> rooms = const [],
  String? initialPropertyId,
  String? initialFloorId,
  String? initialRoomId,
}) {
  return showDialog<DeviceFormResult>(
    context: context,
    builder: (_) => _DeviceForm(
      device: device,
      nameExists: nameExists,
      macExists: macExists,
      showLocationFields: showLocationFields,
      properties: properties,
      floors: floors,
      rooms: rooms,
      initialPropertyId: initialPropertyId,
      initialFloorId: initialFloorId,
      initialRoomId: initialRoomId,
    ),
  );
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

String? _optionalName(String? value, String label) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (text.length < 2) return '$label must have at least 2 characters';
  if (text.length > 60) return '$label must be 60 characters or fewer';
  return null;
}

class _PropertyFormPage extends StatefulWidget {
  final ManagedProperty? property;
  final bool Function(String value) nameExists;

  const _PropertyFormPage({this.property, required this.nameExists});

  @override
  State<_PropertyFormPage> createState() => _PropertyFormPageState();
}

class _PropertyFormPageState extends State<_PropertyFormPage> {
  static const _residentialTypes = <String, IconData>{
    'House': Icons.home_rounded,
    'Apartment': Icons.apartment_rounded,
    'Villa': Icons.villa_rounded,
    'Farmhouse': Icons.agriculture_rounded,
  };
  static const _commercialTypes = <String, IconData>{
    'Office': Icons.business_center_rounded,
    'Retail store': Icons.storefront_rounded,
    'Warehouse': Icons.warehouse_rounded,
    'Co-working': Icons.groups_rounded,
  };
  static const _timezones = <String>[
    'Asia/Kolkata',
    'UTC',
    'America/New_York',
    'Europe/London',
  ];
  static const _currencies = <String>['INR', 'USD', 'EUR', 'GBP'];

  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late String _category;
  late String _propertyType;
  late String _timezone;
  late String _currency;
  late String _businessStart;
  late String _businessEnd;

  bool get _isCommercial => _category == 'Commercial';

  Map<String, IconData> get _types =>
      _isCommercial ? _commercialTypes : _residentialTypes;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.property?.name);
    _address = TextEditingController(text: widget.property?.address);
    _category = widget.property?.category ?? 'Residential';
    _propertyType =
        widget.property?.propertyType ??
        (_category == 'Commercial' ? 'Office' : 'House');
    _timezone = widget.property?.timezone ?? 'Asia/Kolkata';
    _currency = widget.property?.currency ?? 'INR';
    _businessStart = widget.property?.businessStart ?? '09:00';
    _businessEnd = widget.property?.businessEnd ?? '18:00';
    _name.addListener(_refreshPreview);
    _address.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _name.removeListener(_refreshPreview);
    _address.removeListener(_refreshPreview);
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  void _setCategory(String value) {
    if (_category == value) return;
    setState(() {
      _category = value;
      _propertyType = value == 'Commercial' ? 'Office' : 'House';
    });
  }

  Future<void> _pickBusinessTime({required bool start}) async {
    final source = start ? _businessStart : _businessEnd;
    final parts = source.split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 9,
        minute: int.tryParse(parts.last) ?? 0,
      ),
    );
    if (selected == null || !mounted) return;
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:'
        '${selected.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (start) {
        _businessStart = value;
      } else {
        _businessEnd = value;
      }
    });
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      PropertyFormResult(
        name: _name.text.trim(),
        address: _address.text.trim(),
        category: _category,
        propertyType: _propertyType,
        timezone: _timezone,
        currency: _currency,
        businessStart: _isCommercial ? _businessStart : null,
        businessEnd: _isCommercial ? _businessEnd : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.property != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit property' : 'Add a new property'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(editing ? 'Save changes' : 'Create'),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final form = _buildForm(wide);
          final preview = _PropertyLivePreview(
            name: _name.text.trim(),
            address: _address.text.trim(),
            category: _category,
            propertyType: _propertyType,
            icon: _types[_propertyType] ?? Icons.home_work_rounded,
            businessStart: _isCommercial ? _businessStart : null,
            businessEnd: _isCommercial ? _businessEnd : null,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              wide ? 32 : 16,
              16,
              wide ? 32 : 16,
              40,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Center(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: form),
                          const SizedBox(width: 22),
                          SizedBox(width: 340, child: preview),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [form, const SizedBox(height: 20), preview],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(bool wide) {
    return Container(
      padding: EdgeInsets.all(wide ? 28 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A14161F),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('Property category'),
            Row(
              children: [
                Expanded(
                  child: _CategoryButton(
                    label: 'Residential',
                    icon: Icons.home_rounded,
                    selected: !_isCommercial,
                    onTap: () => _setCategory('Residential'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CategoryButton(
                    label: 'Commercial',
                    icon: Icons.business_center_rounded,
                    selected: _isCommercial,
                    onTap: () => _setCategory('Commercial'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              _isCommercial
                  ? 'For offices, retail spaces, warehouses and teams.'
                  : 'For houses, apartments, villas and families.',
              style: const TextStyle(color: AppColors.textFaint, fontSize: 12),
            ),
            const SizedBox(height: 22),
            const _FieldLabel('Property name (optional)'),
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: _isCommercial
                    ? 'e.g. AuraBrain HQ'
                    : 'e.g. Lakeview Home',
                prefixIcon: Icon(
                  _types[_propertyType] ?? Icons.home_work_rounded,
                ),
              ),
              validator: (value) {
                final error = _optionalName(value, 'Property name');
                if (error != null) return error;
                final text = value?.trim() ?? '';
                if (text.isNotEmpty && widget.nameExists(text)) {
                  return 'A property with this name already exists';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            const _FieldLabel('Property type'),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 560 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: _types.entries.map((entry) {
                    final selected = _propertyType == entry.key;
                    return _PropertyTypeTile(
                      label: entry.key,
                      icon: entry.value,
                      selected: selected,
                      onTap: () => setState(() => _propertyType = entry.key),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 22),
            const _FieldLabel('Address'),
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '123 Main Street, City',
                prefixIcon: Icon(Icons.location_on_outlined),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Address is required';
                if (text.length < 5) return 'Enter a valid address';
                if (text.length > 160) {
                  return 'Address must be 160 characters or fewer';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            if (wide)
              Row(
                children: [
                  Expanded(child: _timezoneField()),
                  const SizedBox(width: 14),
                  Expanded(child: _currencyField()),
                ],
              )
            else ...[
              _timezoneField(),
              const SizedBox(height: 14),
              _currencyField(),
            ],
            if (_isCommercial) ...[
              const SizedBox(height: 22),
              const _FieldLabel('Business hours'),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Opens',
                      value: _businessStart,
                      onTap: () => _pickBusinessTime(start: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'Closes',
                      value: _businessEnd,
                      onTap: () => _pickBusinessTime(start: false),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            const _FieldLabel('Cover photo'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.divider,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Row(
                children: [
                  _UploadIcon(),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Property cover is generated automatically',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'It uses the selected property type and stays editable later.',
                          style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Divider(),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    widget.property == null
                        ? 'Create property'
                        : 'Save changes',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timezoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Timezone'),
        DropdownButtonFormField<String>(
          initialValue: _timezone,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.schedule_rounded),
          ),
          items: _timezones
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) => setState(() => _timezone = value ?? _timezone),
        ),
      ],
    );
  }

  Widget _currencyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Currency'),
        DropdownButtonFormField<String>(
          initialValue: _currency,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.currency_rupee_rounded),
          ),
          items: _currencies
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) => setState(() => _currency = value ?? _currency),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyTypeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PropertyTypeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 25,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule_rounded),
        ),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _UploadIcon extends StatelessWidget {
  const _UploadIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Icon(Icons.image_outlined, color: AppColors.textFaint),
    );
  }
}

class _PropertyLivePreview extends StatelessWidget {
  final String name;
  final String address;
  final String category;
  final String propertyType;
  final IconData icon;
  final String? businessStart;
  final String? businessEnd;

  const _PropertyLivePreview({
    required this.name,
    required this.address,
    required this.category,
    required this.propertyType,
    required this.icon,
    this.businessStart,
    this.businessEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _PreviewDot(),
            SizedBox(width: 7),
            Text(
              'LIVE PREVIEW',
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 11.5,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1014161F),
                blurRadius: 32,
                offset: Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 116,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFE7C2), Color(0xFFFFB98A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        icon,
                        size: 44,
                        color: AppColors.textPrimary.withValues(alpha: 0.35),
                      ),
                    ),
                    const Positioned(top: 12, right: 12, child: _DraftPill()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Untitled property' : name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$category · $propertyType',
                      style: const TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            address.isEmpty ? 'Address not added yet' : address,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (businessStart != null && businessEnd != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Business hours: $businessStart–$businessEnd',
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Expanded(
                          child: _PreviewStat(value: '0', label: 'Floors'),
                        ),
                        Expanded(
                          child: _PreviewStat(value: '0', label: 'Rooms'),
                        ),
                        Expanded(
                          child: _PreviewStat(value: '0', label: 'Devices'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD6E4FF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: Color(0xFF2B4C8C),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  category == 'Commercial'
                      ? 'After creation, add floors and workspaces, then assign access schedules.'
                      : 'After creation, add floors and rooms from the property hierarchy.',
                  style: const TextStyle(
                    color: Color(0xFF2B4C8C),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewDot extends StatelessWidget {
  const _PreviewDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DraftPill extends StatelessWidget {
  const _DraftPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Draft',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String value;
  final String label;

  const _PreviewStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textFaint, fontSize: 10.5),
        ),
      ],
    );
  }
}

class _FloorForm extends StatefulWidget {
  final ManagedFloor? floor;
  final bool Function(String name, int level) floorExists;

  const _FloorForm({this.floor, required this.floorExists});

  @override
  State<_FloorForm> createState() => _FloorFormState();
}

class _FloorFormState extends State<_FloorForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _level;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.floor?.name);
    _level = TextEditingController(text: widget.floor?.level.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: widget.floor == null ? 'Add Floor' : 'Edit Floor',
      formKey: _key,
      onSave: () {
        if (!_key.currentState!.validate()) return;
        Navigator.pop(
          context,
          FloorFormResult(
            name: _name.text,
            level: int.parse(_level.text.trim()),
          ),
        );
      },
      children: [
        TextFormField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Floor name (optional)',
            hintText: 'Generated from the floor number if blank',
          ),
          validator: (value) => _optionalName(value, 'Floor name'),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _level,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            labelText: 'Floor number',
            hintText: 'Use 0 for ground floor',
          ),
          validator: (value) {
            final level = int.tryParse(value?.trim() ?? '');
            if (level == null) return 'Enter a valid whole number';
            if (level < -5 || level > 250) {
              return 'Floor number must be between -5 and 250';
            }
            final enteredName = _name.text.trim();
            final resolvedName = enteredName.isEmpty
                ? widget.floor?.name ?? 'Floor $level'
                : enteredName;
            if (widget.floorExists(resolvedName, level)) {
              return 'This floor name or number already exists';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _RoomForm extends StatefulWidget {
  final ManagedRoom? room;
  final bool Function(String value) nameExists;

  const _RoomForm({this.room, required this.nameExists});

  @override
  State<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends State<_RoomForm> {
  static const _types = [
    'Living Room',
    'Bedroom',
    'Kitchen',
    'Bathroom',
    'Dining Room',
    'Office',
    'Garage',
    'Utility',
    'Other',
  ];

  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _type;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.room?.name);
    _type = _types.contains(widget.room?.type) ? widget.room!.type : 'Other';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: widget.room == null ? 'Add Room' : 'Edit Room',
      formKey: _key,
      onSave: () {
        if (!_key.currentState!.validate()) return;
        Navigator.pop(context, RoomFormResult(name: _name.text, type: _type));
      },
      children: [
        TextFormField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Room name (optional)',
            hintText: 'Generated from the selected room type if blank',
          ),
          validator: (value) {
            final error = _optionalName(value, 'Room name');
            if (error != null) return error;
            final text = value?.trim() ?? '';
            if (text.isNotEmpty && widget.nameExists(text)) {
              return 'A room with this name already exists on this floor';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Room type'),
          items: _types
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) => setState(() => _type = value ?? 'Other'),
        ),
      ],
    );
  }
}

class _DeviceForm extends StatefulWidget {
  final Device? device;
  final bool Function(String value) nameExists;
  final bool Function(String value) macExists;
  final bool showLocationFields;
  final List<ManagedProperty> properties;
  final List<ManagedFloor> floors;
  final List<ManagedRoom> rooms;
  final String? initialPropertyId;
  final String? initialFloorId;
  final String? initialRoomId;

  const _DeviceForm({
    this.device,
    required this.nameExists,
    required this.macExists,
    required this.showLocationFields,
    required this.properties,
    required this.floors,
    required this.rooms,
    this.initialPropertyId,
    this.initialFloorId,
    this.initialRoomId,
  });

  @override
  State<_DeviceForm> createState() => _DeviceFormState();
}

class _DeviceFormState extends State<_DeviceForm> {
  static const _unassigned = '__unassigned__';

  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mac;
  late DeviceType _type;
  String? _propertyId;
  String? _floorId;
  String? _roomId;

  List<ManagedFloor> get _availableFloors => _propertyId == null
      ? const []
      : widget.floors
            .where((floor) => floor.propertyId == _propertyId)
            .toList();

  List<ManagedRoom> get _availableRooms => _floorId == null
      ? const []
      : widget.rooms.where((room) => room.floorId == _floorId).toList();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.device?.name);
    _mac = TextEditingController(text: widget.device?.macAddress);
    _type = widget.device?.type ?? DeviceType.light;
    _propertyId =
        widget.initialPropertyId ??
        (widget.device?.buildingId.isNotEmpty == true
            ? widget.device!.buildingId
            : null);
    _floorId = widget.initialFloorId ?? widget.device?.floorId;
    _roomId = widget.initialRoomId ?? widget.device?.roomId;
  }

  @override
  void dispose() {
    _name.dispose();
    _mac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: widget.device == null ? 'Add Device' : 'Edit Device',
      formKey: _key,
      onSave: () {
        if (!_key.currentState!.validate()) return;
        Navigator.pop(
          context,
          DeviceFormResult(
            name: _name.text,
            type: _type,
            macAddress: _mac.text,
            propertyId: _propertyId,
            floorId: _floorId,
            roomId: _roomId,
            roomName: _availableRooms
                .where((room) => room.id == _roomId)
                .firstOrNull
                ?.name,
          ),
        );
      },
      children: [
        TextFormField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Device name (optional)',
            hintText: 'Generated from the device type if blank',
          ),
          validator: (value) {
            final error = _optionalName(value, 'Device name');
            if (error != null) return error;
            final text = value?.trim() ?? '';
            if (text.isNotEmpty && widget.nameExists(text)) {
              return 'A device with this name already exists in this room';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<DeviceType>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Device type'),
          items: DeviceType.values
              .map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _type = value ?? _type),
        ),
        if (widget.showLocationFields) ...[
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Location (optional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey('property_${_propertyId ?? _unassigned}'),
            initialValue: _propertyId ?? _unassigned,
            decoration: const InputDecoration(
              labelText: 'Property',
              prefixIcon: Icon(Icons.home_work_outlined),
            ),
            items: [
              const DropdownMenuItem(
                value: _unassigned,
                child: Text('Not assigned'),
              ),
              ...widget.properties.map(
                (property) => DropdownMenuItem(
                  value: property.id,
                  child: Text(property.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _propertyId = value == _unassigned ? null : value;
                _floorId = null;
                _roomId = null;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'floor_${_propertyId ?? _unassigned}_'
              '${_floorId ?? _unassigned}',
            ),
            initialValue: _floorId ?? _unassigned,
            decoration: const InputDecoration(
              labelText: 'Floor',
              prefixIcon: Icon(Icons.layers_outlined),
            ),
            items: [
              const DropdownMenuItem(
                value: _unassigned,
                child: Text('Not assigned'),
              ),
              ..._availableFloors.map(
                (floor) => DropdownMenuItem(
                  value: floor.id,
                  child: Text(floor.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: _propertyId == null
                ? null
                : (value) {
                    setState(() {
                      _floorId = value == _unassigned ? null : value;
                      _roomId = null;
                    });
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'room_${_floorId ?? _unassigned}_'
              '${_roomId ?? _unassigned}',
            ),
            initialValue: _roomId ?? _unassigned,
            decoration: const InputDecoration(
              labelText: 'Room',
              prefixIcon: Icon(Icons.meeting_room_outlined),
            ),
            items: [
              const DropdownMenuItem(
                value: _unassigned,
                child: Text('Not assigned'),
              ),
              ..._availableRooms.map(
                (room) => DropdownMenuItem(
                  value: room.id,
                  child: Text(room.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: _floorId == null
                ? null
                : (value) => setState(
                    () => _roomId = value == _unassigned ? null : value,
                  ),
          ),
        ],
        const SizedBox(height: 14),
        TextFormField(
          controller: _mac,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'MAC address (optional)',
            hintText: 'AA:BB:CC:DD:EE:FF',
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return null;
            final valid = RegExp(
              r'^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$',
            ).hasMatch(text);
            if (!valid) return 'Enter a valid MAC address';
            if (widget.macExists(text)) {
              return 'This MAC address is already registered';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _FormDialog extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSave;
  final List<Widget> children;

  const _FormDialog({
    required this.title,
    required this.formKey,
    required this.onSave,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(children: children),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: onSave, child: const Text('Save')),
      ],
    );
  }
}

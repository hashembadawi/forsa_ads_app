import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/ui/notifications.dart';
import '../../../data/models/app_options.dart';
import '../../screens/map_picker_screen.dart';

class Step2AdDetails extends StatefulWidget {
  final Map<String, dynamic> adData;
  final AppOptions options;
  final Function(String key, dynamic value) onDataChanged;
  final bool showErrors;

  const Step2AdDetails({
    super.key,
    required this.adData,
    required this.options,
    required this.onDataChanged,
    this.showErrors = false,
  });

  @override
  State<Step2AdDetails> createState() => _Step2AdDetailsState();
}

class _Step2AdDetailsState extends State<Step2AdDetails> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  final LocationService _locationService = LocationService();
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.adData['adTitle']);
    _priceController = TextEditingController(
      text: widget.adData['price']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.adData['description'],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null && mounted) {
        widget.onDataChanged('location', {
          'type': 'Point',
          'coordinates': [position.longitude, position.latitude],
        });

        Notifications.showSnack(
          context,
          'تم تحديد موقعك الحالي بنجاح',
          type: NotificationType.success,
          icon: Icons.check_circle,
        );
      } else if (mounted) {
        Notifications.showSnack(
          context,
          'تعذر الحصول على الموقع. تأكد من تفعيل GPS ومنح الصلاحيات',
          type: NotificationType.warning,
          icon: Icons.warning,
        );
      }
    } catch (e) {
      if (mounted) {
        Notifications.showSnack(
          context,
          'حدث خطأ في الحصول على الموقع',
          type: NotificationType.error,
          icon: Icons.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _pickLocationFromMap() async {
    // Get current location as initial if available, otherwise use Aleppo, Syria
    LatLng? initialLocation;
    final locationData = widget.adData['location'];
    if (locationData != null && locationData['coordinates'] != null) {
      final coords = locationData['coordinates'] as List;
      if (coords.length == 2 && (coords[0] != 0.0 || coords[1] != 0.0)) {
        initialLocation = LatLng(coords[1], coords[0]); // lat, lng
      }
    }
    // If no location set, default will be Aleppo (set in MapPickerScreen)

    final result = await Navigator.of(context).push<Map<String, double>>(
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(initialLocation: initialLocation),
      ),
    );

    if (result != null && mounted) {
      widget.onDataChanged('location', {
        'type': 'Point',
        'coordinates': [result['longitude']!, result['latitude']!],
      });

      Notifications.showSnack(
        context,
        'تم تحديد الموقع من الخريطة بنجاح',
        type: NotificationType.success,
        icon: Icons.check_circle,
      );
    }
  }


  bool _isLocationSelected() {
    final locationData = widget.adData['location'];
    if (locationData != null && locationData['coordinates'] != null) {
      final coords = locationData['coordinates'] as List;
      if (coords.length == 2 && (coords[0] != 0.0 || coords[1] != 0.0)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
      // Filter major areas based on selected province
      final selectedProvinceId = widget.adData['cityId'];
      final filteredMajorAreas = selectedProvinceId != null
          ? widget.options.majorAreas.where((area) => area.provinceId == selectedProvinceId).toList()
          : <dynamic>[];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ad Title
          TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'عنوان الإعلان',
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            errorText: widget.showErrors && (_titleController.text.trim().isEmpty) ? 'يرجى إدخال عنوان الإعلان' : null,
          ),
          onChanged: (value) => widget.onDataChanged('adTitle', value),
        ),
        const SizedBox(height: 12),

        // Price and Currency Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'السعر',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  errorText: widget.showErrors && (widget.adData['price'] == null || (widget.adData['price'] is num && (widget.adData['price'] as num) <= 0)) ? 'يرجى إدخال السعر' : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  final price = double.tryParse(value);
                  widget.onDataChanged('price', price);
                },
                // show error below when attempted
                // Note: errorText for TextFormField requires setting decoration; use a separate check above
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                  value: widget.adData['currencyId'],
                  decoration: InputDecoration(
                    labelText: 'العملة',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    errorText: widget.showErrors && (widget.adData['currencyId'] == null) ? 'اختر العملة' : null,
                  ),
                isExpanded: true,
                menuMaxHeight: 300,
                selectedItemBuilder: (context) {
                  return widget.options.currencies.map((currency) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        currency.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList();
                },
                items: widget.options.currencies.map((currency) {
                  return DropdownMenuItem<int>(
                    value: currency.id,
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        currency.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  final selectedCurrency = widget.options.currencies.firstWhere((curr) => curr.id == value);
                  widget.onDataChanged('currencyId', value);
                  widget.onDataChanged('currencyName', selectedCurrency.name);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // City Selection
        DropdownButtonFormField<int>(
          value: widget.adData['cityId'],
          decoration: InputDecoration(
            labelText: 'المحافظة',
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            errorText: widget.showErrors && (widget.adData['cityId'] == null) ? 'اختر المحافظة' : null,
          ),
            items: widget.options.provinces.map((province) {
              return DropdownMenuItem<int>(
                value: province.id,
                child: Text(province.name),
              );
            }).toList(),
          onChanged: (value) {
              final selectedProvince = widget.options.provinces.firstWhere((prov) => prov.id == value);
            widget.onDataChanged('cityId', value);
              widget.onDataChanged('cityName', selectedProvince.name);
              // Reset region when province changes
              widget.onDataChanged('regionId', null);
              widget.onDataChanged('regionName', null);
          },
        ),
        const SizedBox(height: 12),

        // Region Selection
        DropdownButtonFormField<int>(
          value: widget.adData['regionId'],
          decoration: InputDecoration(
            labelText: 'المنطقة',
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
              hintText: selectedProvinceId == null ? 'اختر المحافظة أولاً' : 'اختر المنطقة',
              errorText: widget.showErrors && (widget.adData['regionId'] == null) ? 'اختر المنطقة' : null,
          ),
            items: filteredMajorAreas.map((area) {
              return DropdownMenuItem<int>(
                value: area.id,
                child: Text(area.name),
              );
            }).toList(),
          onChanged: selectedProvinceId == null ? null : (value) {
              if (value != null) {
                final selectedArea = filteredMajorAreas.firstWhere((area) => area.id == value);
                widget.onDataChanged('regionId', value);
                widget.onDataChanged('regionName', selectedArea.name);
              }
          },
        ),
        const SizedBox(height: 12),

        // Location Selection Section
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label at the top like TextField
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
                child: Row(
                  children: [
                    Text(
                      'تحديد الموقع',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    if (_isLocationSelected())
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Buttons
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                          icon: _isLoadingLocation 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location, size: 20),
                          label: const Text('موقعي الحالي'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _pickLocationFromMap,
                          icon: const Icon(Icons.map_outlined, size: 20),
                          label: const Text('من الخريطة'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'وصف المنتج',
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            alignLabelWithHint: true,
            errorText: widget.showErrors && (_descriptionController.text.trim().isEmpty) ? 'يرجى إدخال وصف الإعلان' : null,
          ),
          maxLines: 4,
          onChanged: (value) => widget.onDataChanged('description', value),
        ),
      ],
    ),
    );
  }

}

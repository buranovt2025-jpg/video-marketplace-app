import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/services/location_service.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';

class LocationPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    Key? key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  }) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final LocationService _locationService = Get.find<LocationService>();
  final _addressController = TextEditingController();
  
  double _latitude = 41.2995; // Default: Tashkent
  double _longitude = 69.2401;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
    }
    if (widget.initialLatitude != null) {
      _latitude = widget.initialLatitude!;
    }
    if (widget.initialLongitude != null) {
      _longitude = widget.initialLongitude!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isLoading = false;
        });
        Get.snackbar(
          'location'.tr,
          'location_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        setState(() {
          _error = 'location_error'.tr;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openInMaps() {
    _locationService.openLocationInMaps(
      lat: _latitude,
      lng: _longitude,
      label: _addressController.text.isNotEmpty 
          ? _addressController.text 
          : 'selected_location'.tr,
    );
  }

  void _confirmLocation() {
    if (_addressController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'enter_address'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.back(result: {
      'address': _addressController.text,
      'latitude': _latitude,
      'longitude': _longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'select_location'.tr,
          style: AppUI.h2,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppUI.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map preview placeholder
            _buildMapPreview(),
            const SizedBox(height: 24),

            // Current location button
            _buildGetLocationButton(),
            const SizedBox(height: 24),

            // Coordinates display
            _buildCoordinatesCard(),
            const SizedBox(height: 24),

            // Address input
            Text(
              'delivery_address'.tr,
              style: AppUI.h2,
            ),
            const SizedBox(height: 12),
            _buildAddressInput(),
            const SizedBox(height: 16),

            // Info text
            _buildInfoCard(),
            const SizedBox(height: 24),

            // View in maps button
            _buildViewInMapsButton(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 200,
      decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
      child: Stack(
        children: [
          // Map placeholder with grid
          ClipRRect(
            borderRadius: BorderRadius.circular(AppUI.radiusL),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[850]!,
                    Colors.grey[900]!,
                  ],
                ),
              ),
              child: CustomPaint(
                size: const Size(double.infinity, 200),
                painter: GridPainter(),
              ),
            ),
          ),
          // Center pin
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: primaryColor,
                  size: 48,
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          // Coordinates overlay
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Text(
                '${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _getCurrentLocation,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.my_location, color: Colors.white),
        label: Text(
          _isLoading ? 'getting_location'.tr : 'use_current_location'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        style: AppUI.primaryButton().copyWith(
          backgroundColor: const WidgetStatePropertyAll(primaryColor),
          disabledBackgroundColor: WidgetStatePropertyAll(Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildCoordinatesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pin_drop, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'coordinates'.tr,
                style: AppUI.h2.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCoordinateField(
                  label: 'latitude'.tr,
                  value: _latitude,
                  onChanged: (val) => setState(() => _latitude = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCoordinateField(
                  label: 'longitude'.tr,
                  value: _longitude,
                  onChanged: (val) => setState(() => _longitude = val),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoordinateField({
    required String label,
    required double value,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppUI.muted.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value.toStringAsFixed(6),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            filled: true,
            fillColor: surfaceColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppUI.radiusM),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (text) {
            final parsed = double.tryParse(text);
            if (parsed != null) {
              onChanged(parsed);
            }
          },
        ),
      ],
    );
  }

  Widget _buildAddressInput() {
    return TextFormField(
      controller: _addressController,
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'enter_full_address'.tr,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUI.radiusM),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 40),
          child: const Icon(Icons.home, color: primaryColor),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppUI.radiusL),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'location_info'.tr,
              style: AppUI.muted.copyWith(color: primaryColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewInMapsButton() {
    return OutlinedButton.icon(
      onPressed: _openInMaps,
      icon: const Icon(Icons.map),
      label: Text('view_in_maps'.tr),
      style: AppUI.outlineButton(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirmLocation,
            style: AppUI.primaryButton(),
            child: Text(
              'confirm_location'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for grid background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[800]!.withOpacity(0.3)
      ..strokeWidth = 1;

    const spacing = 30.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

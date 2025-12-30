import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/services/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

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
    final initialAddress = widget.initialAddress;
    if (initialAddress != null) {
      _addressController.text = initialAddress;
    }

    final initialLatitude = widget.initialLatitude;
    if (initialLatitude != null) {
      _latitude = initialLatitude;
    }

    final initialLongitude = widget.initialLongitude;
    if (initialLongitude != null) {
      _longitude = initialLongitude;
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Stack(
        children: [
          // Map placeholder with grid
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                const Icon(
                  Icons.location_on,
                  color: primaryColor,
                  size: 48,
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.5),
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
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinatesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pin_drop, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'coordinates'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value.toStringAsFixed(6),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
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
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, bottom: 40),
          child: Icon(Icons.home, color: primaryColor),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'location_info'.tr,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 12,
              ),
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
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.grey[700]!),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'confirm_location'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
      ..color = Colors.grey[800]!.withValues(alpha: 0.3)
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

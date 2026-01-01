import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';

class ProductReviewsSheet extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductReviewsSheet({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductReviewsSheet> createState() => _ProductReviewsSheetState();
}

class _ProductReviewsSheetState extends State<ProductReviewsSheet> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  final TextEditingController _text = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  int _rating = 0;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getProductReviews(widget.productId);
      final rawItems = data['items'];
      final items = rawItems is List ? rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      String msg = e.toString();
      if (e is ApiException && (e.statusCode == 404 || e.statusCode == 405 || e.statusCode == 501)) {
        msg = 'reviews_not_supported'.tr;
      }
      setState(() {
        _error = msg;
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_controller.isLoggedIn) {
      Get.snackbar('login_required'.tr, 'login_to_continue'.tr, snackPosition: SnackPosition.BOTTOM);
      Get.to(() => const MarketplaceLoginScreen());
      return;
    }
    if (_rating < 1 || _rating > 5) {
      Get.snackbar('error'.tr, 'select_rating'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ApiService.createProductReview(
        widget.productId,
        rating: _rating,
        text: _text.text,
      );
      _text.clear();
      setState(() => _rating = 0);
      await _load();
      Get.snackbar('success'.tr, 'thank_you_review'.tr, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'reviews'.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: primaryColor),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(_error!, style: const TextStyle(color: primaryColor)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: Text('refresh'.tr),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                    ),
                  ],
                ),
              )
            else
              _buildList(),
            const SizedBox(height: 12),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 12),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text('no_reviews_yet'.tr, style: TextStyle(color: Colors.grey[500])),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _items.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey[850], height: 1),
        itemBuilder: (context, i) {
          final r = _items[i];
          final name = (r['author_name'] ?? 'user'.tr).toString();
          final rating = (r['rating'] is num) ? (r['rating'] as num).toInt() : int.tryParse((r['rating'] ?? '').toString()) ?? 0;
          final text = (r['text'] ?? '').toString();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    _Stars(value: rating),
                  ],
                ),
                if (text.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(text, style: TextStyle(color: Colors.grey[300], height: 1.25)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('your_rating'.tr, style: TextStyle(color: Colors.grey[400])),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final active = i < _rating;
            return IconButton(
              onPressed: _submitting ? null : () => setState(() => _rating = i + 1),
              icon: Icon(active ? Icons.star : Icons.star_border, color: active ? Colors.amber : Colors.grey[600]),
            );
          }),
        ),
        TextField(
          controller: _text,
          enabled: !_submitting,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'review_hint'.tr,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: buttonColor ?? primaryColor),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Text('send_review'.tr),
          ),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  final int value;
  const _Stars({required this.value});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final active = i < v;
        return Icon(active ? Icons.star : Icons.star_border, size: 14, color: active ? Colors.amber : Colors.grey[600]);
      }),
    );
  }
}


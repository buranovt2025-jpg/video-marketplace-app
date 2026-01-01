import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/utils/money.dart';

class SellerVerificationScreen extends StatefulWidget {
  const SellerVerificationScreen({Key? key}) : super(key: key);

  @override
  State<SellerVerificationScreen> createState() => _SellerVerificationScreenState();
}

class _SellerVerificationScreenState extends State<SellerVerificationScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  
  String _filter = 'pending'; // pending, verified, rejected
  bool _isLoading = false;
  
  // Demo data for verification requests
  final List<Map<String, dynamic>> _verificationRequests = [
    {
      'id': '1',
      'seller_id': 'seller1',
      'seller_name': 'Textile Store',
      'seller_email': 'textile@demo.com',
      'business_name': 'Textile Plus LLC',
      'inn': '123456789012',
      'document_type': 'Registration certificate',
      'document_url': 'https://example.com/doc1.pdf',
      'status': 'pending',
      'submitted_at': '2025-12-27T10:00:00',
      'products_count': 45,
      'total_sales': 1250000,
    },
    {
      'id': '2',
      'seller_id': 'seller2',
      'seller_name': 'Wholesale Fruits',
      'seller_email': 'fruits@demo.com',
      'business_name': 'Sole proprietor Ivanov A.A.',
      'inn': '987654321098',
      'document_type': 'Passport + Tax ID',
      'document_url': 'https://example.com/doc2.pdf',
      'status': 'pending',
      'submitted_at': '2025-12-26T15:30:00',
      'products_count': 28,
      'total_sales': 890000,
    },
    {
      'id': '3',
      'seller_id': 'seller3',
      'seller_name': 'Electronics 24',
      'seller_email': 'electronics@demo.com',
      'business_name': 'TechnoMarket LLC',
      'inn': '456789012345',
      'document_type': 'Registration certificate',
      'document_url': 'https://example.com/doc3.pdf',
      'status': 'verified',
      'submitted_at': '2025-12-20T09:00:00',
      'verified_at': '2025-12-21T14:00:00',
      'products_count': 120,
      'total_sales': 5600000,
    },
    {
      'id': '4',
      'seller_id': 'seller4',
      'seller_name': 'Suspicious store',
      'seller_email': 'suspicious@demo.com',
      'business_name': 'Unknown',
      'inn': '000000000000',
      'document_type': 'No documents',
      'document_url': null,
      'status': 'rejected',
      'submitted_at': '2025-12-15T12:00:00',
      'rejected_at': '2025-12-16T10:00:00',
      'rejection_reason': 'Invalid documents',
      'products_count': 5,
      'total_sales': 0,
    },
  ];

  List<Map<String, dynamic>> get _filteredRequests {
    return _verificationRequests.where((r) => r['status'] == _filter).toList();
  }

  Future<void> _verifyeSeller(String requestId) async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    final index = _verificationRequests.indexWhere((r) => r['id'] == requestId);
    if (index != -1) {
      setState(() {
        _verificationRequests[index]['status'] = 'verified';
        _verificationRequests[index]['verified_at'] = DateTime.now().toIso8601String();
      });
    }
    
    setState(() => _isLoading = false);
    
    Get.snackbar(
      'success'.tr,
      'seller_verified'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> _rejectSeller(String requestId) async {
    final reasonController = TextEditingController();
    
    final reason = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('rejection_reason'.tr, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'enter_reason'.tr,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
            child: Text('reject_action'.tr),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    final index = _verificationRequests.indexWhere((r) => r['id'] == requestId);
    if (index != -1) {
      setState(() {
        _verificationRequests[index]['status'] = 'rejected';
        _verificationRequests[index]['rejected_at'] = DateTime.now().toIso8601String();
        _verificationRequests[index]['rejection_reason'] = reason;
      });
    }
    
    setState(() => _isLoading = false);
    
    Get.snackbar(
      'info'.tr,
      'verification_request_rejected'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'seller_verification'.tr,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('pending', 'pending_verification'.tr, Icons.hourglass_empty),
                const SizedBox(width: 8),
                _buildFilterChip('verified', 'verified_plural'.tr, Icons.verified),
                const SizedBox(width: 8),
                _buildFilterChip('rejected', 'rejected_plural'.tr, Icons.cancel),
              ],
            ),
          ),
          
          // Stats
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  _verificationRequests.where((r) => r['status'] == 'pending').length.toString(),
                  'awaiting'.tr,
                  primaryColor,
                ),
                _buildStat(
                  _verificationRequests.where((r) => r['status'] == 'verified').length.toString(),
                  'verified_plural'.tr,
                  Colors.green,
                ),
                _buildStat(
                  _verificationRequests.where((r) => r['status'] == 'rejected').length.toString(),
                  'rejected_plural'.tr,
                  primaryColor,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // List
          Expanded(
            child: _filteredRequests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filter == 'pending' ? Icons.inbox : 
                          _filter == 'verified' ? Icons.verified_user : Icons.cancel,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_requests'.tr,
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRequests.length,
                    itemBuilder: (context, index) {
                      return _buildRequestCard(_filteredRequests[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'];
    final statusColor = status == 'pending'
        ? primaryColor
        : status == 'verified'
            ? Colors.green
            : primaryColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: Icon(Icons.store, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['seller_name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        request['seller_email'],
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status == 'pending'
                        ? 'pending_verification'.tr
                        : status == 'verified'
                            ? 'verified_status'.tr
                            : 'rejected_status'.tr,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('business_name'.tr, request['business_name']),
                _buildDetailRow('inn'.tr, request['inn']),
                _buildDetailRow('document_type'.tr, request['document_type']),
                _buildDetailRow('products_count'.tr, '${request['products_count']}'),
                _buildDetailRow('sales'.tr, formatShortMoneyWithCurrency(asDouble(request['total_sales']))),
                if (status == 'rejected' && request['rejection_reason'] != null)
                  _buildDetailRow('rejection_reason_label'.tr, request['rejection_reason'], isError: true),
              ],
            ),
          ),
          
          // Actions for pending requests
          if (status == 'pending')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _rejectSeller(request['id']),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text('reject_action'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _verifyeSeller(request['id']),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text('verify'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? primaryColor : Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

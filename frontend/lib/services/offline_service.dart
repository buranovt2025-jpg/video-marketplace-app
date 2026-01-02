import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineAction {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  OfflineAction({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      id: json['id'] as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static const String _offlineActionsKey = 'offline_actions';

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Stream<ConnectivityResult> get connectivityStream {
    return Connectivity().onConnectivityChanged;
  }

  Future<void> saveOfflineAction(OfflineAction action) async {
    final prefs = await SharedPreferences.getInstance();
    final actionsJson = prefs.getStringList(_offlineActionsKey) ?? [];
    actionsJson.add(jsonEncode(action.toJson()));
    await prefs.setStringList(_offlineActionsKey, actionsJson);
  }

  Future<List<OfflineAction>> getOfflineActions() async {
    final prefs = await SharedPreferences.getInstance();
    final actionsJson = prefs.getStringList(_offlineActionsKey) ?? [];
    return actionsJson
        .map((json) => OfflineAction.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeOfflineAction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final actionsJson = prefs.getStringList(_offlineActionsKey) ?? [];
    final actions = actionsJson
        .map((json) => OfflineAction.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .where((action) => action.id != id)
        .map((action) => jsonEncode(action.toJson()))
        .toList();
    await prefs.setStringList(_offlineActionsKey, actions);
  }

  Future<void> clearOfflineActions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineActionsKey);
  }

  Future<void> saveQrScanOffline({
    required String orderId,
    required String qrData,
    required String scanType,
  }) async {
    final action = OfflineAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'qr_scan',
      data: {
        'orderId': orderId,
        'qrData': qrData,
        'scanType': scanType,
      },
      createdAt: DateTime.now(),
    );
    await saveOfflineAction(action);
  }
}

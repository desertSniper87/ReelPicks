import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectionStatusController;

  Stream<bool> get connectionStatus {
    _connectionStatusController ??= StreamController<bool>.broadcast();
    return _connectionStatusController!.stream;
  }

  Future<void> initialize() async {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    // Check initial connection status
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final isConnected = result != ConnectivityResult.none;
    _connectionStatusController?.add(isConnected);
  }

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    if (result == ConnectivityResult.none) {
      return false;
    }
    
    // Additional check by trying to reach a reliable host
    return await _hasInternetConnection();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void dispose() {
    _connectionStatusController?.close();
    _connectionStatusController = null;
  }
}
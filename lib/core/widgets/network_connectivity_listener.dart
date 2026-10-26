import 'dart:async';
import 'package:flutter/material.dart';
import '../network/network_service.dart';
import '../theme/app_colors.dart';

class NetworkConnectivityListener extends StatefulWidget {
  final Widget child;

  const NetworkConnectivityListener({
    super.key,
    required this.child,
  });

  @override
  State<NetworkConnectivityListener> createState() =>
      _NetworkConnectivityListenerState();
}

class _NetworkConnectivityListenerState
    extends State<NetworkConnectivityListener> {
  StreamSubscription<bool>? _subscription;
  bool _isOffline = false;
  bool _showBackOnline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
    _subscription = NetworkService.onConnectivityChanged.listen((hasNet) {
      if (!hasNet && !_isOffline) {
        setState(() {
          _isOffline = true;
          _showBackOnline = false;
        });
      } else if (hasNet && _isOffline) {
        setState(() {
          _isOffline = false;
          _showBackOnline = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showBackOnline = false;
            });
          }
        });
      }
    });
  }

  Future<void> _checkInitialState() async {
    final hasNet = await NetworkService.isConnected();
    if (!hasNet && mounted) {
      setState(() {
        _isOffline = true;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Banner khi Mất mạng (Màu đỏ)
        if (_isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                bottom: false,
                child: Container(
                  color: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Mất kết nối mạng! Vui lòng kiểm tra Wi-Fi hoặc 4G/5G.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Banner khi Có mạng trở lại (Màu xanh)
        if (_showBackOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                bottom: false,
                child: Container(
                  color: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Đã kết nối lại Internet.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

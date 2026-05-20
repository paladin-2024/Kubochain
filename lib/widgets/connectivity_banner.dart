import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/services/connectivity_service.dart';
import '../core/constants/app_colors.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isOnline = true;
  late StreamSubscription<bool> _sub;

  @override
  void initState() {
    super.initState();
    ConnectivityService.isOnline().then((v) {
      if (mounted) setState(() => _isOnline = v);
    });
    _sub = ConnectivityService.onlineStream.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isOnline
              ? const SizedBox.shrink()
              : Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    color: AppColors.error,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + 8,
                      16,
                      8,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HugeIcon(icon: HugeIcons.strokeRoundedWifiOff01, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'No internet connection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 24,
    this.backgroundColor,
  });

  String get _initial => name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final size = radius * 2;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: ApiService.imageUrl(imageUrl!),
                fit: BoxFit.cover,
                placeholder: (_, __) => _Fallback(initial: _initial, bg: bg, size: size),
                errorWidget: (_, __, ___) => _Fallback(initial: _initial, bg: bg, size: size),
              )
            : _Fallback(initial: _initial, bg: bg, size: size),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final String initial;
  final Color bg;
  final double size;

  const _Fallback({required this.initial, required this.bg, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bg, bg.withValues(alpha: 0.7)],
      ),
    ),
    child: Center(
      child: Text(
        initial,
        style: GoogleFonts.sora(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    ),
  );
}

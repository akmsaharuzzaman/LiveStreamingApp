import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Google Sign-In button widget that follows Material Design 3 guidelines
class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? svgPath;
  final String text;
  final bool isLoading;
  final bool isOutlined;

  const CustomButton({
    super.key,
    this.onPressed,
    this.text = 'Continue with Google',
    this.isLoading = false,
    this.svgPath,
    this.isOutlined = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _buildGoogleIcon(svgPath),
              label: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isLoading ? Colors.white70 : Colors.white,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                side: BorderSide(color: colorScheme.outline, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : FilledButton.tonalIcon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _buildGoogleIcon(svgPath),
              label: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isLoading ? Colors.white70 : Colors.white,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
    );
  }

  Widget _buildGoogleIcon(String? iconPath) {
    if (iconPath != null) {
      return SvgPicture.asset(iconPath, width: 20.sp, height: 20.sp);
    }
    return SizedBox.shrink();
  }
}

import 'package:flutter/material.dart';

class AppColor {
  static const Color primary = Color(0xFF31BA36);
  static const Color background = Colors.white;
  static const Color textDark = Colors.black87;

  // Aliases for consistency (AppColors)
  static const Color primaryGreen = primary;
  static const Color backgroundColor = background;
}

// Alias class for backward compatibility
class AppColors {
  static const Color primaryGreen = AppColor.primary;
  static const Color backgroundColor = AppColor.background;
  static const Color textDark = AppColor.textDark;
}

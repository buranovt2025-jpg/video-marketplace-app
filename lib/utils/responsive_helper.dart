import 'package:flutter/material.dart';

/// Responsive helper class for adaptive layouts
class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive value based on screen size
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsiveValue(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// Get responsive horizontal padding
  static double responsiveHorizontalPadding(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 16.0,
      tablet: 32.0,
      desktop: 64.0,
    );
  }

  /// Get number of grid columns
  static int gridColumns(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }

  /// Get card width for grid
  static double cardWidth(BuildContext context) {
    final width = screenWidth(context);
    final columns = gridColumns(context);
    final padding = responsiveHorizontalPadding(context) * 2;
    final spacing = 12.0 * (columns - 1);
    return (width - padding - spacing) / columns;
  }

  /// Get max content width for centered layouts
  static double maxContentWidth(BuildContext context) {
    return responsiveValue(
      context,
      mobile: double.infinity,
      tablet: 720.0,
      desktop: 1200.0,
    );
  }

  /// Get font size multiplier
  static double fontSizeMultiplier(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
  }

  /// Get icon size
  static double iconSize(BuildContext context, {double baseSize = 24}) {
    return baseSize * fontSizeMultiplier(context);
  }

  /// Get button height
  static double buttonHeight(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 48.0,
      tablet: 52.0,
      desktop: 56.0,
    );
  }

  /// Get aspect ratio for video cards
  static double videoAspectRatio(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 9 / 16,
      tablet: 9 / 16,
      desktop: 9 / 16,
    );
  }

  /// Get bottom navigation bar height
  static double bottomNavHeight(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 60.0,
      tablet: 70.0,
      desktop: 80.0,
    );
  }
}

/// Responsive wrapper widget
class ResponsiveWrapper extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWrapper({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (ResponsiveHelper.isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

/// Centered content wrapper for web/desktop
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const CenteredContent({
    Key? key,
    required this.child,
    this.maxWidth,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? ResponsiveHelper.maxContentWidth(context);
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? columns;

  const ResponsiveGridView({
    Key? key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.columns,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cols = columns ?? ResponsiveHelper.gridColumns(context);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

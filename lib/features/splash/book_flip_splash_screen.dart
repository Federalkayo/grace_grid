import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../core/theme/app_theme.dart';
import '../../app_shell.dart';

/// A professional 3D Book-Flip Animated Splash Screen for GraceGrid.
///
/// Features:
/// - 3D Perspective Rotation using [Matrix4] along the Y-axis.
/// - Realistic book cover with emerald leather texture, gold foil trim, and luminous logo.
/// - Dynamic page shading & shadow cast mechanics.
/// - Inner parchment page with sacred scripture reveal ("John 1:1").
/// - Seamless scale & fade transition into [AppShell].
class BookFlipSplashScreen extends StatefulWidget {
  final Widget? nextScreen;
  final Duration animationDuration;

  const BookFlipSplashScreen({
    super.key,
    this.nextScreen,
    this.animationDuration = const Duration(milliseconds: 3400),
  });

  @override
  State<BookFlipSplashScreen> createState() => _BookFlipSplashScreenState();
}

class _BookFlipSplashScreenState extends State<BookFlipSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Animation Intervals
  late Animation<double> _fadeInAnimation;
  late Animation<double> _bookScaleAnimation;
  late Animation<double> _flipAnimation;
  late Animation<double> _innerPageGlowAnimation;
  late Animation<double> _zoomToAppAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // 1. Initial fade-in of the background and book (0% -> 22%)
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );

    // 2. Subtle book pop/scale setup (0% -> 25%)
    _bookScaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
      ),
    );

    // 3. 3D Book Cover Flip Angle (22% -> 78%)
    _flipAnimation = Tween<double>(begin: 0.0, end: -math.pi * 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.78, curve: Curves.easeInOutCubicEmphasized),
      ),
    );

    // 4. Inner page glow expansion (45% -> 85%)
    _innerPageGlowAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );

    // 5. Final camera zoom & transition into main application (78% -> 100%)
    _zoomToAppAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.78, 1.0, curve: Curves.easeInOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToApp();
      }
    });

    // Remove native splash and start book flip ONLY AFTER the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {
        // Safe fallback in test environment
      }
      if (mounted) {
        _controller.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToApp() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final targetScreen = widget.nextScreen ?? const AppShell();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _skipAnimation() {
    if (_controller.isAnimating) {
      _controller.stop();
      _navigateToApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    const bookWidth = 260.0;
    const bookHeight = 360.0;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLowest,
      body: GestureDetector(
        onTap: _skipAnimation,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final fadeInVal = _fadeInAnimation.value;
            final scaleVal = _bookScaleAnimation.value;
            final flipAngle = _flipAnimation.value;
            final innerGlowVal = _innerPageGlowAnimation.value;
            final zoomVal = _zoomToAppAnimation.value;

            // Compute overall scale including final zoom
            final totalScale = scaleVal * (1.0 + zoomVal * 1.5);
            final totalOpacity = (fadeInVal * (1.0 - zoomVal)).clamp(0.0, 1.0);

            return Opacity(
              opacity: totalOpacity,
              child: Stack(
                children: [
                  // 1. Ambient Dark Sanctuary Background with Particles & Radial Glow
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.1,
                          colors: [
                            Color(0xFF13221A),
                            Color(0xFF0D1511),
                            Color(0xFF050907),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Floating Aura Glow behind the book
                  Center(
                    child: Container(
                      width: bookWidth * 1.6,
                      height: bookHeight * 1.4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryContainer.withValues(alpha: 0.18 * innerGlowVal),
                            blurRadius: 120,
                            spreadRadius: 40,
                          ),
                          BoxShadow(
                            color: AppTheme.secondaryContainer.withValues(alpha: 0.12 * innerGlowVal),
                            blurRadius: 90,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Centered 3D Book Experience
                  Center(
                    child: Transform.scale(
                      scale: totalScale,
                      child: SizedBox(
                        width: bookWidth,
                        height: bookHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Ground Shadow underneath the book
                            Positioned(
                              bottom: -20,
                              left: -10,
                              right: -10,
                              height: 30,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      blurRadius: 25,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Book Stack Base (Pages underneath cover)
                            _buildOpenBookPageBase(bookWidth, bookHeight, innerGlowVal, flipAngle),

                            // Dynamic Page Shadow Cast onto Right Page during flip
                            if (flipAngle < 0 && flipAngle > -math.pi * 0.9)
                              Positioned(
                                left: bookWidth / 2,
                                top: 0,
                                bottom: 0,
                                width: bookWidth / 2,
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.black.withValues(
                                            alpha: (math.sin(-flipAngle) * 0.45).clamp(0.0, 0.45),
                                          ),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // 3D Flipping Book Cover (Front Cover turning to Back Lining)
                            Positioned(
                              left: 0,
                              top: 0,
                              width: bookWidth / 2,
                              height: bookHeight,
                              child: Transform(
                                alignment: Alignment.centerLeft,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0014) // Perspective depth
                                  ..rotateY(flipAngle),
                                child: flipAngle >= -math.pi / 2
                                    ? _buildFrontCover(bookWidth / 2, bookHeight, flipAngle)
                                    : _buildInnerCoverBack(bookWidth / 2, bookHeight, flipAngle),
                              ),
                            ),

                            // Gold Bookmark Ribbon hanging from center
                            Positioned(
                              left: bookWidth / 2 - 6,
                              top: 0,
                              width: 12,
                              height: bookHeight + 18,
                              child: _buildBookmarkRibbon(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Subtle "Tap to skip" prompt at bottom
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: fadeInVal > 0.8 && zoomVal < 0.2 ? 0.7 : 0.0,
                      child: Text(
                        'Tap anywhere to skip',
                        textAlign: TextAlign.center,
                        style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the Right-side open Scripture Page and Stacked Paper Edges.
  Widget _buildOpenBookPageBase(
      double bookWidth, double bookHeight, double glowVal, double flipAngle) {
    final halfWidth = bookWidth / 2;

    return Row(
      children: [
        // Left Page Base (Revealed as cover opens)
        SizedBox(
          width: halfWidth,
          height: bookHeight,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4EC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                bottomLeft: Radius.circular(5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(-2, 2),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _ParchmentPagePainter(isLeftPage: true),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Align(
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Color(0xFFB8860B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'GRACEGRID',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: const Color(0xFF8B6508).withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CHAPTER I',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Color(0xFF5A4010),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Expanded(
                      child: Text(
                        'The Light shines in the darkness, and the darkness has not overcome it.\n\nEvery good gift and every perfect gift is from above.',
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 10.5,
                          height: 1.6,
                          color: Color(0xFF2C2213),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right Page Base (Main Scripture focus)
        SizedBox(
          width: halfWidth,
          height: bookHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Stacked Page Edges (Paper depth effect on the right)
              Positioned(
                right: -6,
                top: 4,
                bottom: 4,
                width: 6,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE8DFCD),
                        Color(0xFFD4AF37),
                        Color(0xFFC5A028),
                        Color(0xFFB8860B),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
              ),

              // Open Parchment Page
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF7F0),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child: CustomPaint(
                  painter: _ParchmentPagePainter(isLeftPage: false),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Luminous Gold Cross Emblem
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.church_rounded,
                                size: 20,
                                color: Color(0xFF8B6508),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'HOLY BIBLE',
                              style: TextStyle(
                                fontFamily: 'Serif',
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: Color(0xFF8B6508),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Divider(
                                color: Color(0xFFD4AF37),
                                thickness: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Featured Scripture Text
                            const Text(
                              '“In the beginning was the Word, and the Word was with God, and the Word was God.”',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Serif',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                                color: Color(0xFF1E160A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '— JOHN 1:1',
                              style: TextStyle(
                                fontFamily: 'Serif',
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.6,
                                color: Color(0xFFB8860B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the Front Cover (visible during 0° -> -90° rotation).
  Widget _buildFrontCover(double width, double height, double angle) {
    // Light reflection brightness factor based on tilt
    final shadowIntensity = (math.sin(-angle) * 0.4).clamp(0.0, 0.4);

    return Stack(
      children: [
        // Front Cover Leather Base
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B2F25),
                Color(0xFF0F1E17),
                Color(0xFF09140E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gold Foil Double Border
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ),

              // Left Book Spine Metallic Trim
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 12,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF08100B),
                        Color(0xFF1B2F25),
                        Color(0xFF070D09),
                      ],
                    ),
                  ),
                ),
              ),

              // Center Logo & Title Layout
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // High-res Emblem / Logo
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryContainer.withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Image.asset(
                            'assets/images/splash_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppTheme.surfaceContainer,
                              child: const Icon(
                                Icons.church_outlined,
                                color: AppTheme.primaryContainer,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'GRACEGRID',
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.5,
                          color: const Color(0xFFF3E5AB),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 40,
                        height: 1.5,
                        color: const Color(0xFFD4AF37),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'SANCTUARY',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                          color: AppTheme.primary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dynamic Lighting Shading Overlay as Cover rotates
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: shadowIntensity),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the Back of the Cover (visible when cover flips past -90°).
  Widget _buildInnerCoverBack(double width, double height, double angle) {
    // Dynamic shadow intensity on inner cover
    final shadowIntensity = (math.sin(-angle) * 0.35).clamp(0.0, 0.35);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi), // Reverse mirror image
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF14241B),
              Color(0xFF0B140F),
              Color(0xFF060B08),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Inner Satin Lining Pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _SatinLiningPainter(),
              ),
            ),

            // Gold Inner Margin Frame
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
              ),
            ),

            // Shading overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: shadowIntensity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the hanging Emerald Satin Ribbon.
  Widget _buildBookmarkRibbon() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF00E68A),
            Color(0xFF00B36B),
            Color(0xFF006137),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for realistic parchment paper texture and gold margins.
class _ParchmentPagePainter extends CustomPainter {
  final bool isLeftPage;

  _ParchmentPagePainter({required this.isLeftPage});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw inner gold border box
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, borderPaint);

    // Spine inner gradient shadow
    final spineGradient = LinearGradient(
      begin: isLeftPage ? Alignment.centerRight : Alignment.centerLeft,
      end: isLeftPage ? Alignment.centerLeft : Alignment.centerRight,
      colors: [
        Colors.black.withValues(alpha: 0.18),
        Colors.transparent,
      ],
    );

    final spineRect = isLeftPage
        ? Rect.fromLTWH(size.width - 16, 0, 16, size.height)
        : Rect.fromLTWH(0, 0, 16, size.height);

    final spinePaint = Paint()
      ..shader = spineGradient.createShader(spineRect);

    canvas.drawRect(spineRect, spinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter for inner cover satin pattern.
class _SatinLiningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF76FFAF).withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 18.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

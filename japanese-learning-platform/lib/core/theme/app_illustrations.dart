/// 日式插图组件
///
/// 使用 CustomPainter 绘制京都传统风格装饰插图
/// 配合星野京都风格：full-bleed、沉浸感、留白
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 京都鸟居插图
class KyotoToriiIllustration extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const KyotoToriiIllustration({
    super.key,
    this.width = 200,
    this.height = 100,
    this.color = AppColors.shu,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _ToriiPainter(color: color),
    );
  }
}

class _ToriiPainter extends CustomPainter {
  final Color color;

  _ToriiPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final topY = size.height * 0.1;
    final bottomY = size.height * 0.95;
    final pillarWidth = size.width * 0.06;

    // 左柱
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            centerX - size.width * 0.35,
            topY + size.height * 0.15,
            pillarWidth,
            bottomY - topY - size.height * 0.15),
        const Radius.circular(1),
      ),
      fillPaint,
    );

    // 右柱
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            centerX + size.width * 0.35 - pillarWidth,
            topY + size.height * 0.15,
            pillarWidth,
            bottomY - topY - size.height * 0.15),
        const Radius.circular(1),
      ),
      fillPaint,
    );

    // 上横梁（笠木）
    final beamPath = Path()
      ..moveTo(centerX - size.width * 0.42, topY + size.height * 0.08)
      ..quadraticBezierTo(
        centerX,
        topY - size.height * 0.05,
        centerX + size.width * 0.42,
        topY + size.height * 0.08,
      )
      ..lineTo(centerX + size.width * 0.42, topY + size.height * 0.15)
      ..quadraticBezierTo(
        centerX,
        topY + size.height * 0.02,
        centerX - size.width * 0.42,
        topY + size.height * 0.15,
      )
      ..close();
    canvas.drawPath(beamPath, fillPaint);

    // 下横梁（贯）
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - size.width * 0.38,
        topY + size.height * 0.25,
        size.width * 0.76,
        size.height * 0.05,
      ),
      fillPaint,
    );

    // 中间短柱
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - pillarWidth * 0.3,
        topY + size.height * 0.15,
        pillarWidth * 0.6,
        size.height * 0.1,
      ),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 樱花枝插图
class SakuraBranchIllustration extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const SakuraBranchIllustration({
    super.key,
    this.width = 150,
    this.height = 100,
    this.color = const Color(0xFFFFB7C5),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SakuraPainter(color: color),
    );
  }
}

class _SakuraPainter extends CustomPainter {
  final Color color;

  _SakuraPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final branchPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final branchPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..quadraticBezierTo(
          size.width * 0.3, size.height * 0.4, size.width * 0.7, size.height * 0.3);
    canvas.drawPath(branchPath, branchPaint);

    final smallBranch1 = Path()
      ..moveTo(size.width * 0.4, size.height * 0.45)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.25, size.width * 0.55, size.height * 0.2);
    canvas.drawPath(smallBranch1, branchPaint);

    final smallBranch2 = Path()
      ..moveTo(size.width * 0.55, size.height * 0.35)
      ..quadraticBezierTo(
          size.width * 0.7, size.height * 0.5, size.width * 0.8, size.height * 0.55);
    canvas.drawPath(smallBranch2, branchPaint);

    _drawSakuraFlower(canvas, size.width * 0.35, size.height * 0.35, size.width * 0.06, color);
    _drawSakuraFlower(canvas, size.width * 0.55, size.height * 0.2, size.width * 0.055, color.withOpacity(0.9));
    _drawSakuraFlower(canvas, size.width * 0.7, size.height * 0.3, size.width * 0.06, color.withOpacity(0.95));
    _drawSakuraFlower(canvas, size.width * 0.8, size.height * 0.55, size.width * 0.05, color.withOpacity(0.85));
  }

  void _drawSakuraFlower(Canvas canvas, double cx, double cy, double radius, Color color) {
    final petalPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final centerPaint = Paint()
      ..color = const Color(0xFFFFE4E9)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * 3.14159 / 180;
      final petalX = cx + radius * 0.6 * _cosA(angle);
      final petalY = cy + radius * 0.6 * _sinA(angle);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(petalX, petalY),
            width: radius * 1.2,
            height: radius * 0.8),
        petalPaint,
      );
    }
    canvas.drawCircle(Offset(cx, cy), radius * 0.2, centerPaint);
  }

  double _cosA(double angle) =>
      angle == 0 ? 1 : (angle == 3.14159 ? -1 : 0);
  double _sinA(double angle) {
    if (angle == 0) return 0;
    if (angle == 3.14159 / 2) return 1;
    if (angle == -3.14159 / 2) return -1;
    return 0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 枯山水波纹图案
class KaresansuiPattern extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const KaresansuiPattern({
    super.key,
    this.width = 200,
    this.height = 100,
    this.color = const Color(0xFF9E9E9E),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _KaresansuiPainter(color: color),
    );
  }
}

class _KaresansuiPainter extends CustomPainter {
  final Color color;

  _KaresansuiPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.25)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final centerX = size.width * 0.5;
    final centerY = size.height * 0.6;

    for (int i = 1; i <= 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: size.width * 0.1 * i * 2,
          height: size.height * 0.08 * i * 2,
        ),
        paint,
      );
    }

    final stonePaint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.75, size.height * 0.7),
          width: size.width * 0.07,
          height: size.height * 0.1),
      stonePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.82, size.height * 0.65),
          width: size.width * 0.05,
          height: size.height * 0.08),
      stonePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 青海波纹样装饰边框
class WavePatternBorder extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double waveSize;

  const WavePatternBorder({
    super.key,
    this.width = 100,
    this.height = 40,
    this.color = AppColors.primary,
    this.waveSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _WavePatternPainter(color: color, waveSize: waveSize),
    );
  }
}

class _WavePatternPainter extends CustomPainter {
  final Color color;
  final double waveSize;

  _WavePatternPainter({required this.color, required this.waveSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final rows = (size.height / (waveSize * 0.75)).ceil();
    final cols = (size.width / waveSize).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      final y = row * waveSize * 0.75;
      final offset = row.isOdd ? waveSize * 0.5 : 0;

      for (int col = 0; col < cols; col++) {
        final x = col * waveSize + offset;
        canvas.drawArc(
          Rect.fromCenter(
              center: Offset(x, y), width: waveSize, height: waveSize),
          3.14159,
          3.14159,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 富士山剪影插图
class MtFujiIllustration extends StatelessWidget {
  final double width;
  final double height;
  final Color mountainColor;
  final Color snowColor;

  const MtFujiIllustration({
    super.key,
    this.width = 200,
    this.height = 120,
    this.mountainColor = AppColors.primary,
    this.snowColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _MtFujiPainter(mountainColor: mountainColor, snowColor: snowColor),
    );
  }
}

class _MtFujiPainter extends CustomPainter {
  final Color mountainColor;
  final Color snowColor;

  _MtFujiPainter({required this.mountainColor, required this.snowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final mountainPaint = Paint()
      ..color = mountainColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final snowPaint = Paint()
      ..color = snowColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final centerX = size.width * 0.5;
    final baseY = size.height * 0.95;
    final peakY = size.height * 0.15;

    final mountainPath = Path()
      ..moveTo(centerX - size.width * 0.45, baseY)
      ..quadraticBezierTo(
          centerX - size.width * 0.15, baseY - size.height * 0.35,
          centerX - size.width * 0.05, peakY + size.height * 0.15)
      ..lineTo(centerX, peakY)
      ..lineTo(centerX + size.width * 0.05, peakY + size.height * 0.15)
      ..quadraticBezierTo(
          centerX + size.width * 0.15, baseY - size.height * 0.35,
          centerX + size.width * 0.45, baseY)
      ..close();

    canvas.drawPath(mountainPath, mountainPaint);

    final snowPath = Path()
      ..moveTo(centerX - size.width * 0.08, peakY + size.height * 0.18)
      ..quadraticBezierTo(
          centerX - size.width * 0.02, peakY + size.height * 0.1,
          centerX, peakY + size.height * 0.08)
      ..quadraticBezierTo(
          centerX + size.width * 0.02, peakY + size.height * 0.1,
          centerX + size.width * 0.08, peakY + size.height * 0.18)
      ..quadraticBezierTo(
          centerX + size.width * 0.02, peakY + size.height * 0.14,
          centerX, peakY + size.height * 0.15)
      ..quadraticBezierTo(
          centerX - size.width * 0.02, peakY + size.height * 0.14,
          centerX - size.width * 0.08, peakY + size.height * 0.18)
      ..close();

    canvas.drawPath(snowPath, snowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 家纹风格等级图标
class FamilyCrestLevelIcon extends StatelessWidget {
  final String level;
  final double size;
  final Color color;
  final bool isSelected;

  const FamilyCrestLevelIcon({
    super.key,
    required this.level,
    this.size = 48,
    this.color = AppColors.kincha,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FamilyCrestPainter(
        level: level,
        color: color,
        isSelected: isSelected,
      ),
    );
  }
}

class _FamilyCrestPainter extends CustomPainter {
  final String level;
  final Color color;
  final bool isSelected;

  _FamilyCrestPainter({
    required this.level,
    required this.color,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveColor = isSelected ? color : color.withOpacity(0.4);
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.42;

    // 外圈
    final circlePaint = Paint()
      ..color = effectiveColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(centerX, centerY), radius, circlePaint);

    // 内圈
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.7, circlePaint);

    // 等级文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: level,
        style: TextStyle(
          fontFamily: 'NotoSerifJP',
          fontSize: size.width * 0.32,
          fontWeight: FontWeight.w300,
          color: effectiveColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      (oldDelegate as _FamilyCrestPainter).isSelected != isSelected;
}

/// 装饰性樱花花瓣
class SakuraPetalDecoration extends StatelessWidget {
  final double size;
  final Color color;
  final double rotation;

  const SakuraPetalDecoration({
    super.key,
    this.size = 20,
    this.color = const Color(0xFFFFB7C5),
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        size: Size(size, size),
        painter: _PetalPainter(color: color),
      ),
    );
  }
}

class _PetalPainter extends CustomPainter {
  final Color color;

  _PetalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(
          size.width * 0.9, size.height * 0.3, size.width * 0.5, size.height)
      ..quadraticBezierTo(
          size.width * 0.1, size.height * 0.3, size.width * 0.5, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 全幅 Hero 区域 - 使用渐变 + 装饰图案模拟沉浸式图片区
class HeroImageArea extends StatelessWidget {
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final Widget? illustration;
  final String? overlayText;

  const HeroImageArea({
    super.key,
    this.height = 300,
    this.primaryColor = AppColors.primary,
    this.secondaryColor = AppColors.primaryDark,
    this.illustration,
    this.overlayText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 渐变背景
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.08),
                  secondaryColor.withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // 青海波底纹
          Positioned.fill(
            child: WavePatternBorder(
              width: 2000,
              height: height,
              color: primaryColor,
            ),
          ),
          // 插图
          if (illustration != null)
            Center(child: illustration!),
          // 文字
          if (overlayText != null)
            Positioned(
              bottom: 40,
              right: 60,
              child: Text(
                overlayText!,
                style: TextStyle(
                  fontFamily: 'NotoSerifJP',
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: primaryColor.withOpacity(0.4),
                  letterSpacing: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

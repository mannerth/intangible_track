import 'package:flutter/material.dart';

import '../../common/app_theme.dart';
import 'map_viewport_controller.dart';
import 'models.dart';

/// 地区绘制信息（路径 / 包围盒 / 质心，map 坐标）
class RegionPaintInfo {
  RegionPaintInfo({
    required this.region,
    required this.path,
    required this.bounds,
    required this.anchor,
  });

  final MapRegion region;
  final Path path;
  final GeoBounds bounds;

  /// 标注锚点（map 坐标）：优先使用数据自带锚点，回退到质心
  final Offset anchor;

  static List<RegionPaintInfo> build(Iterable<MapRegion> regions) => [
    for (final region in regions)
      RegionPaintInfo(
        region: region,
        path: _buildPath(region.geometry),
        bounds: _boundsOf(region),
        anchor: _anchorOf(region),
      ),
  ];

  static Offset _anchorOf(MapRegion region) {
    final anchor = region.labelAnchor;
    if (anchor != null) {
      return Offset(anchor.lon, -anchor.lat);
    }
    return _centroid(region.geometry);
  }

  static GeoBounds _boundsOf(MapRegion region) {
    final b = region.geometry.bounds;
    return GeoBounds(minX: b.minX, minY: b.minY, maxX: b.maxX, maxY: b.maxY);
  }

  static Path _buildPath(RegionGeometry geometry) {
    final path = Path();
    for (final poly in geometry.polygons) {
      for (final ring in poly) {
        if (ring.isEmpty) continue;
        final first = Offset(ring.first.lon, -ring.first.lat);
        path.moveTo(first.dx, first.dy);
        for (final p in ring.skip(1)) {
          path.lineTo(p.lon, -p.lat);
        }
        path.close();
      }
    }
    return path;
  }

  static Offset _centroid(RegionGeometry geometry) {
    var sumX = 0.0, sumY = 0.0, count = 0;
    for (final poly in geometry.polygons) {
      if (poly.isEmpty) continue;
      final ring = poly.first;
      for (var i = 0; i < ring.length; i++) {
        final p = ring[i];
        // 跳过 GeoJSON 闭合环的重复首尾点
        if (i == ring.length - 1 &&
            p.lon == ring.first.lon &&
            p.lat == ring.first.lat) {
          continue;
        }
        sumX += p.lon;
        sumY += -p.lat;
        count++;
      }
    }
    if (count == 0) return Offset.zero;
    return Offset(sumX / count, sumY / count);
  }
}

class MapPainter extends CustomPainter {
  MapPainter({
    required this.paintInfos,
    required this.scale,
    required this.center,
    required this.size,
    required this.selectedKey,
    this.labelMinWidth = 10,
  });

  final List<RegionPaintInfo> paintInfos;
  final double scale;
  final Offset center;
  final Size size;
  final String? selectedKey;
  final double labelMinWidth;

  static const _labelMaxCount = 120;

  /// 名称标签的最小 / 最大字号
  static const double minFontSize = 7;
  static const double maxFontSize = 12;

  @override
  void paint(Canvas canvas, Size _) {
    if (paintInfos.isEmpty || size.isEmpty) return;
    final c = size.center(Offset.zero);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / scale
      ..color = const Color(0xFF1A1A1A);
    final selectedFill = Paint()..color = AppColors.tabHighlight;
    final selectedLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 / scale
      ..color = AppColors.accent;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);
    for (final info in paintInfos) {
      if (info.region.mapKey == selectedKey) {
        canvas.drawPath(info.path, selectedFill);
        canvas.drawPath(info.path, selectedLine);
      } else {
        canvas.drawPath(info.path, linePaint);
      }
    }
    canvas.restore();

    _paintLabels(canvas, c);
  }

  void _paintLabels(Canvas canvas, Offset c) {
    var drawn = 0;
    for (final info in paintInfos) {
      final screenWidth = info.bounds.width * scale;
      if (screenWidth < labelMinWidth) continue;
      if (drawn >= _labelMaxCount) break;
      final pos = Offset(
        (info.anchor.dx - center.dx) * scale + c.dx,
        (info.anchor.dy - center.dy) * scale + c.dy,
      );
      final isSelected = info.region.mapKey == selectedKey;
      final fontSize = adaptiveFontSizeFor(
        info.region.nameZh,
        screenWidth,
        selected: isSelected,
      );
      if (fontSize == null) continue;
      final painter = TextPainter(
        text: TextSpan(
          text: info.region.nameZh,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.accent : const Color(0xFF3A3A3A),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        pos - Offset(painter.width / 2, painter.height / 2),
      );
      drawn++;
    }
  }

  /// 根据地区屏幕宽度计算自适应字号；
  /// 中文按全角、英文按半角估算，取「放得下」的最大字号，
  /// 缩到最小字号仍放不下时返回 null（不显示）。
  static double? adaptiveFontSizeFor(
    String text,
    double screenWidth, {
    bool selected = false,
    double min = minFontSize,
    double max = maxFontSize,
  }) {
    var widthEm = 0.0;
    for (final rune in text.runes) {
      widthEm += _isCjk(rune) ? 1.0 : 0.62;
    }
    if (widthEm <= 0) return null;
    final maxAllowed = selected ? max + 1 : max;
    final fit = screenWidth * 0.92 / widthEm;
    if (fit < min) return null;
    return fit > maxAllowed ? maxAllowed : fit;
  }

  static bool _isCjk(int rune) =>
      (rune >= 0x4E00 && rune <= 0x9FFF) ||
      (rune >= 0x3400 && rune <= 0x4DBF) ||
      (rune >= 0x20000 && rune <= 0x2A6DF);

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) =>
      oldDelegate.paintInfos != paintInfos ||
      oldDelegate.scale != scale ||
      oldDelegate.center != center ||
      oldDelegate.size != size ||
      oldDelegate.selectedKey != selectedKey;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

/// 地图区域包围盒（map 坐标：x=lon, y=-lat）
class GeoBounds {
  const GeoBounds({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  double get width => maxX - minX;
  double get height => maxY - minY;
  Offset get center => Offset((minX + maxX) / 2, (minY + maxY) / 2);

  static GeoBounds of(Iterable<MapRegion> regions) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final r in regions) {
      final b = r.geometry.bounds;
      if (b.minX < minX) minX = b.minX;
      if (b.minY < minY) minY = b.minY;
      if (b.maxX > maxX) maxX = b.maxX;
      if (b.maxY > maxY) maxY = b.maxY;
    }
    if (minX > maxX || minY > maxY) {
      return const GeoBounds(minX: 0, minY: 0, maxX: 1, maxY: 1);
    }
    return GeoBounds(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }
}

/// 地图视口状态：缩放 + 中心点（map 坐标），以及适配参数。
class MapViewportController extends ChangeNotifier {
  MapViewportController({
    this.fitRatio = 0.7,
    this.fitOffset = Offset.zero,
    this.scaleMin,
    this.scaleMax,
  });

  /// 选中地区在视口中的占比，默认 70%
  final double fitRatio;

  /// 选中后中心点的屏幕偏移（单位 px），默认零
  final Offset fitOffset;

  double? scaleMin;
  double? scaleMax;

  double _scale = 1;
  Offset _center = Offset.zero;
  Size _size = Size.zero;
  GeoBounds _mapBounds = const GeoBounds(minX: 0, minY: 0, maxX: 1, maxY: 1);

  double get scale => _scale;
  Offset get center => _center;
  Size get size => _size;
  GeoBounds get mapBounds => _mapBounds;

  void updateSize(Size size) {
    if (size == _size) return;
    _size = size;
    notifyListeners();
  }

  /// 设置地图范围并按模式初始化视口：
  /// 中国模式显示整图；世界模式以 [focusBounds]（中国）为视口中心。
  void configure({
    required GeoBounds allBounds,
    required GeoBounds? focusBounds,
    required MapMode mode,
  }) {
    _mapBounds = allBounds;
    final fitAllScale = _fitScale(allBounds);
    scaleMin ??= fitAllScale * 0.5;
    scaleMax ??= math.max(fitAllScale * 60, 8);
    if (mode == MapMode.china) {
      _fitTo(allBounds);
    } else {
      _scale = _clampScale(fitAllScale);
      _center = focusBounds?.center ?? allBounds.center;
    }
    notifyListeners();
  }

  /// 让指定区域居中并占 [fitRatio]
  void fitRegion(GeoBounds bounds) {
    _fitTo(bounds);
  }

  /// 计算让 [bounds] 居中的目标视图（供动画插值）
  ({double scale, Offset center}) fitTargetFor(GeoBounds bounds) {
    final targetScale = _clampScale(_fitScale(bounds));
    final offset = Offset(
      fitOffset.dx / targetScale,
      fitOffset.dy / targetScale,
    );
    return (scale: targetScale, center: bounds.center + offset);
  }

  void zoomIn() => zoomAt(1.5, _size.center(Offset.zero));

  void zoomOut() => zoomAt(1 / 1.5, _size.center(Offset.zero));

  /// 缩放到绝对 [targetScale]，保持焦点地理点不动
  void zoomTo(double targetScale, Offset focal) {
    if (_size.isEmpty) return;
    final newScale = _clampScale(targetScale);
    final geo = screenToGeo(focal);
    final c = _size.center(Offset.zero);
    _scale = newScale;
    _center = geo - (focal - c) / newScale;
    _clampCenter();
    notifyListeners();
  }

  /// 围绕屏幕焦点 [focal]（相对组件左上角）缩放
  void zoomAt(double factor, Offset focal) {
    zoomTo(_scale * factor, focal);
  }

  void panBy(Offset delta) {
    if (_scale == 0) return;
    _center -= Offset(delta.dx / _scale, delta.dy / _scale);
    _clampCenter();
    notifyListeners();
  }

  /// 供动画逐帧设置视图
  void setView(double scale, Offset center) {
    _scale = _clampScale(scale);
    _center = center;
    notifyListeners();
  }

  /// 地理点 → 屏幕点
  Offset geoToScreen(Offset geo) {
    final c = _size.center(Offset.zero);
    return Offset(
      (geo.dx - _center.dx) * _scale + c.dx,
      (geo.dy - _center.dy) * _scale + c.dy,
    );
  }

  Offset screenToGeo(Offset screen) {
    final c = _size.center(Offset.zero);
    return Offset(
      (screen.dx - c.dx) / _scale + _center.dx,
      (screen.dy - c.dy) / _scale + _center.dy,
    );
  }

  double _fitScale(GeoBounds bounds) {
    if (_size.isEmpty || bounds.width <= 0 || bounds.height <= 0) return 1;
    return math.min(_size.width / bounds.width, _size.height / bounds.height) *
        fitRatio;
  }

  void _fitTo(GeoBounds bounds) {
    if (_size.isEmpty) return;
    _scale = _clampScale(_fitScale(bounds));
    final offset = Offset(fitOffset.dx / _scale, fitOffset.dy / _scale);
    _center = bounds.center + offset;
    _clampCenter();
    notifyListeners();
  }

  double _clampScale(double value) {
    final min = scaleMin ?? 0.1;
    final max = scaleMax ?? 100;
    return value.clamp(min, max);
  }

  void _clampCenter() {
    if (_size.isEmpty) return;
    final margin = Offset(_size.width / 2 / _scale, _size.height / 2 / _scale);
    _center = Offset(
      _center.dx.clamp(
        _mapBounds.minX - margin.dx,
        _mapBounds.maxX + margin.dx,
      ),
      _center.dy.clamp(
        _mapBounds.minY - margin.dy,
        _mapBounds.maxY + margin.dy,
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/app_theme.dart';
import 'map_geometry.dart';
import 'map_painter.dart';
import 'map_viewport_controller.dart';
import 'models.dart';

/// 可交互地图：支持双指缩放、拖动平移、点击选中并自动适配视图。
class InteractiveMap extends StatefulWidget {
  const InteractiveMap({
    super.key,
    required this.mode,
    required this.regions,
    this.selectedKey,
    this.onRegionTap,
    this.controller,
    this.fitRatio = 0.7,
    this.fitOffset = Offset.zero,
    this.showControls = true,
    this.labelMinWidth = 10,
  });

  final MapMode mode;
  final List<MapRegion> regions;
  final String? selectedKey;
  final ValueChanged<MapRegion>? onRegionTap;
  final MapViewportController? controller;

  /// 选中地区占视口比例，默认 70%
  final double fitRatio;

  /// 选中后中心点的屏幕偏移，默认零
  final Offset fitOffset;
  final bool showControls;
  final double labelMinWidth;

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap>
    with SingleTickerProviderStateMixin {
  late final MapViewportController _controller;
  late final AnimationController _anim;

  List<RegionPaintInfo>? _paintInfos;
  GeoBounds? _allBounds;
  GeoBounds? _focusBounds;
  bool _initialized = false;
  Size _lastSize = Size.zero;
  double? _gestureStartScale;
  VoidCallback? _animTick;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        MapViewportController(
          fitRatio: widget.fitRatio,
          fitOffset: widget.fitOffset,
        );
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _refreshPaintData();
  }

  @override
  void dispose() {
    _anim.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.regions, widget.regions)) {
      final oldKeys = {for (final r in oldWidget.regions) r.regionCode};
      final newKeys = {for (final r in widget.regions) r.regionCode};
      if (!setEquals(oldKeys, newKeys)) {
        _refreshPaintData();
        _initialized = false;
      } else {
        // 仅摘要（名称等）变化时刷新绘制数据，不重置视图
        _paintInfos = RegionPaintInfo.build(widget.regions);
      }
    }
    if (oldWidget.mode != widget.mode) {
      _initialized = false;
    } else if (oldWidget.selectedKey != widget.selectedKey &&
        widget.selectedKey != null) {
      _fitToSelected();
    }
  }

  void _refreshPaintData() {
    _paintInfos = RegionPaintInfo.build(widget.regions);
    _allBounds = GeoBounds.of(widget.regions);
    _focusBounds = _findFocusBounds();
  }

  GeoBounds? _findFocusBounds() {
    for (final region in widget.regions) {
      if (region.regionCode == 'CHN') {
        final b = region.geometry.bounds;
        return GeoBounds(
          minX: b.minX,
          minY: b.minY,
          maxX: b.maxX,
          maxY: b.maxY,
        );
      }
    }
    return null;
  }

  void _fitToSelected() {
    final key = widget.selectedKey;
    if (key == null) return;
    final info = _paintInfos
        ?.where((i) => i.region.regionCode == key)
        .firstOrNull;
    if (info != null) _animateTo(info.bounds);
  }

  void _animateTo(GeoBounds bounds) {
    final target = _controller.fitTargetFor(bounds);
    _startAnimation(targetScale: target.scale, targetCenter: target.center);
  }

  void _startAnimation({
    required double targetScale,
    required Offset targetCenter,
  }) {
    final startScale = _controller.scale;
    final startCenter = _controller.center;
    _anim.stop();
    _anim.value = 0;
    if (_animTick != null) _anim.removeListener(_animTick!);
    _animTick = () {
      final t = Curves.easeOutCubic.transform(_anim.value);
      _controller.setView(
        startScale + (targetScale - startScale) * t,
        Offset.lerp(startCenter, targetCenter, t)!,
      );
    };
    _anim.addListener(_animTick!);
    _anim.forward();
  }

  void _resetView({bool animate = false}) {
    final all = _allBounds;
    if (all == null || _controller.size.isEmpty) return;
    final focus = _focusBounds;
    if (widget.mode == MapMode.china) {
      if (animate) {
        _animateTo(all);
      } else {
        _controller.fitRegion(all);
      }
      return;
    }
    final targetScale = _controller.fitTargetFor(all).scale;
    final targetCenter = focus?.center ?? all.center;
    if (animate) {
      _startAnimation(targetScale: targetScale, targetCenter: targetCenter);
    } else {
      _controller.setView(targetScale, targetCenter);
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartScale = _controller.scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final start = _gestureStartScale;
    if (start != null) {
      _controller.zoomTo(start * details.scale, details.localFocalPoint);
    }
    if (details.focalPointDelta != Offset.zero) {
      _controller.panBy(details.focalPointDelta);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _gestureStartScale = null;
  }

  void _onTapUp(TapUpDetails details) {
    if (_controller.size.isEmpty) return;
    final geo = _controller.screenToGeo(details.localPosition);
    final region = hitTestRegion(
      widget.regions,
      geo,
      toleranceMap: 8 / _controller.scale,
    );
    if (region != null) widget.onRegionTap?.call(region);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size != _lastSize) {
          _lastSize = size;
          _controller.updateSize(size);
        }
        if (!_initialized &&
            size.width > 0 &&
            size.height > 0 &&
            _allBounds != null) {
          _initialized = true;
          if (widget.selectedKey != null) {
            _fitToSelected();
          } else {
            _controller.configure(
              allBounds: _allBounds!,
              focusBounds: _focusBounds,
              mode: widget.mode,
            );
          }
        }

        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          onTapUp: _onTapUp,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: MapPainter(
                      paintInfos: _paintInfos ?? const [],
                      scale: _controller.scale,
                      center: _controller.center,
                      size: size,
                      selectedKey: widget.selectedKey,
                      labelMinWidth: widget.labelMinWidth,
                    ),
                  ),
                ),
                if (widget.showControls)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ControlButton(
                          icon: Icons.add,
                          onTap: () => _controller.zoomIn(),
                        ),
                        const SizedBox(height: 6),
                        _ControlButton(
                          icon: Icons.remove,
                          onTap: () => _controller.zoomOut(),
                        ),
                        const SizedBox(height: 6),
                        _ControlButton(
                          icon: Icons.center_focus_strong,
                          onTap: () => _resetView(animate: true),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

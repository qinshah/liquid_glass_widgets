// ignore_for_file: deprecated_member_use
// Shared internal widgets for GlassBottomBar and GlassSearchableBottomBar.
//
// NOT part of the public API — do not export from liquid_glass_widgets.dart.
library;

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import '../../../src/renderer/liquid_glass_renderer.dart';
import '../../../types/glass_quality.dart';
import '../../../utils/draggable_indicator_physics.dart';
import '../../../utils/glass_spring.dart';
import '../../interactive/glass_button.dart';
import '../../shared/adaptive_glass.dart';
import '../../shared/animated_glass_indicator.dart';
import '../glass_bottom_bar.dart'
    show
        GlassBottomBarExtraButton,
        GlassBottomBarTab,
        MaskingQuality,
        JellyClipper;

// =============================================================================
// buildIconShadows — pure utility function (visibleForTesting for unit tests)
// =============================================================================

/// Builds multi-directional icon shadows that simulate a stroke/outline effect.
///
/// Returns `null` (no shadow) when:
/// - [thickness] is null (feature not requested), or
/// - [selected] is true AND [activeIcon] is non-null (distinct active icon
///   is used so outline shadow is not needed in that state).
///
/// Otherwise, generates 8 evenly-spaced [Shadow] offsets around the icon at
/// the given [thickness] radius using 45° increments.
///
/// Extracted from [BottomBarTabItem] to enable isolated unit testing.
@visibleForTesting
List<Shadow>? buildIconShadows({
  required Color iconColor,
  required double? thickness,
  required bool selected,
  required Widget? activeIcon,
}) {
  if (thickness == null || (selected && activeIcon != null)) return null;
  final shadows = <Shadow>[];
  const step = math.pi / 4;
  for (double a = 0; a < math.pi * 2; a += step) {
    shadows.add(Shadow(
      color: iconColor,
      offset: Offset.fromDirection(a, thickness),
    ));
  }
  return shadows;
}

// =============================================================================
// BottomBarTabItem — shared tab item widget
// =============================================================================

/// Renders a single tab item for [GlassBottomBar] and [GlassSearchableBottomBar].
///
/// Previously duplicated as `_BottomBarTab` and `_TabItem`. Single source of truth.
class BottomBarTabItem extends StatelessWidget {
  const BottomBarTabItem({
    required this.tab,
    required this.selected,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.iconSize,
    required this.textStyle,
    required this.labelFontSize,
    required this.iconLabelSpacing,
    required this.glowDuration,
    required this.glowBlurRadius,
    required this.glowSpreadRadius,
    required this.glowOpacity,
    required this.onTap,
    super.key,
  });

  final GlassBottomBarTab tab;
  final bool selected;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final double iconSize;
  final TextStyle? textStyle;

  /// Font size for tab labels when [textStyle] is null.
  ///
  /// Mirrors [iconSize] as an explicit sizing knob. Defaults to 11.
  /// Reduce to 10 for bars with 4+ tabs or long label text.
  final double labelFontSize;
  final double iconLabelSpacing;
  final Duration glowDuration;
  final double glowBlurRadius;
  final double glowSpreadRadius;
  final double glowOpacity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? selectedIconColor : unselectedIconColor;
    final iconWidget = selected ? (tab.activeIcon ?? tab.icon) : tab.icon;

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label ?? 'Tab',
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: iconLabelSpacing,
            children: [
              ExcludeSemantics(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (tab.glowColor != null)
                      Positioned(
                        top: -24,
                        right: -24,
                        left: -24,
                        bottom: -24,
                        child: RepaintBoundary(
                          child: AnimatedContainer(
                            duration: glowDuration,
                            transformAlignment: Alignment.center,
                            curve: Curves.easeOutCirc,
                            transform: selected
                                ? Matrix4.identity()
                                : (Matrix4.identity()
                                  ..scale(0.4)
                                  ..rotateZ(-math.pi)),
                            child: AnimatedOpacity(
                              duration: glowDuration,
                              opacity: selected ? 1 : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tab.glowColor!.withOpacity(
                                        selected ? glowOpacity : 0,
                                      ),
                                      blurRadius: glowBlurRadius,
                                      spreadRadius: glowSpreadRadius,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    IconTheme(
                      data: IconThemeData(
                        color: iconColor,
                        size: iconSize,
                        // Use the extracted top-level function for testability
                        shadows: buildIconShadows(
                          iconColor: iconColor,
                          thickness: tab.thickness,
                          selected: selected,
                          activeIcon: tab.activeIcon,
                        ),
                      ),
                      child: DefaultTextStyle(
                        style: DefaultTextStyle.of(context)
                            .style
                            .copyWith(color: iconColor),
                        child: iconWidget,
                      ),
                    ),
                  ],
                ),
              ),
              if (tab.label != null)
                Text(
                  tab.label!,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle ??
                      TextStyle(
                        color: iconColor,
                        fontSize: labelFontSize,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// BottomBarExtraBtn — shared extra button widget
// =============================================================================

/// Renders the extra action button using [GlassButton].
///
/// Previously duplicated as `_ExtraButton` and `_ExtraBtn`. Single source of truth.
class BottomBarExtraBtn extends StatelessWidget {
  const BottomBarExtraBtn({
    required this.config,
    required this.quality,
    required this.iconColor,
    this.borderRadius,
    super.key,
  });

  final GlassBottomBarExtraButton config;
  final GlassQuality quality;
  final Color iconColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      icon: config.icon,
      onTap: config.onTap,
      label: config.label,
      width: config.size,
      height: config.size,
      quality: quality,
      iconColor: iconColor,
      shape: borderRadius == null
          ? const LiquidOval()
          : LiquidRoundedRectangle(borderRadius: borderRadius!),
    );
  }
}

// =============================================================================
// TabIndicator — draggable pill indicator with spring physics
// =============================================================================

/// Internal widget that manages the draggable indicator with physics.
///
/// Extracted from [GlassBottomBar] to keep the public widget focused on layout
/// and configuration, while this widget owns all gesture, animation, and
/// rendering logic for the tab indicator pill.
///
/// Responsibilities:
/// - Horizontal drag gesture handling ([GestureDetector] + [Listener])
/// - Spring-based alignment animation ([VelocitySpringBuilder])
/// - Jelly deformation during drag ([SpringBuilder] + thickness)
/// - Dual rendering modes: [MaskingQuality.off] and [MaskingQuality.high]
class TabIndicator extends StatefulWidget {
  const TabIndicator({
    required this.childUnselected,
    required this.selectedTabBuilder,
    required this.tabIndex,
    required this.tabCount,
    required this.onTabChanged,
    required this.visible,
    required this.indicatorColor,
    required this.quality,
    required this.barHeight,
    required this.barBorderRadius,
    required this.tabPadding,
    required this.magnification,
    required this.innerBlur,
    required this.maskingQuality,
    this.indicatorSettings,
    this.backgroundKey,
    this.interactionGlowColor,
    this.interactionGlowRadius = 1.5,
    this.interactionScale = 1.0,
    super.key,
  });

  final int tabIndex;
  final int tabCount;
  final bool visible;
  final Widget childUnselected;
  final Widget Function(BuildContext, double, Alignment) selectedTabBuilder;
  final Color? indicatorColor;
  final LiquidGlassSettings? indicatorSettings;
  final ValueChanged<int> onTabChanged;
  final GlassQuality quality;
  final double barHeight;
  final double barBorderRadius;
  final EdgeInsetsGeometry tabPadding;
  final double magnification;
  final double innerBlur;
  final MaskingQuality maskingQuality;
  final GlobalKey? backgroundKey;
  final Color? interactionGlowColor;
  final double interactionGlowRadius;

  /// The scale factor applied by [LiquidStretch] on press.
  ///
  /// Pass `1.0` to disable scaling. Resolved by the parent widget from
  /// [GlassInteractionBehavior] before being forwarded here.
  final double interactionScale;

  @override
  State<TabIndicator> createState() => TabIndicatorState();
}

/// State for [TabIndicator]. Public for testing via `@visibleForTesting`.
@visibleForTesting
class TabIndicatorState extends State<TabIndicator> {
  // Cache fallback indicator color to avoid allocations
  static const _fallbackIndicatorColor =
      Color(0x1AFFFFFF); // white.withValues(alpha: 0.1)

  bool _isDragging = false;

  // Current horizontal alignment of the indicator (-1 to 1)
  late double _xAlign = _computeXAlignmentForTab(widget.tabIndex);

  // Cached shape to avoid recreation on every animation frame
  late LiquidRoundedSuperellipse _barShape =
      LiquidRoundedSuperellipse(borderRadius: widget.barBorderRadius);

  @override
  void didUpdateWidget(covariant TabIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update alignment when tab index or count changes
    if (oldWidget.tabIndex != widget.tabIndex ||
        oldWidget.tabCount != widget.tabCount) {
      setState(() {
        _xAlign = _computeXAlignmentForTab(widget.tabIndex);
      });
    }

    // Update cached shape if border radius changes
    if (oldWidget.barBorderRadius != widget.barBorderRadius) {
      _barShape =
          LiquidRoundedSuperellipse(borderRadius: widget.barBorderRadius);
    }
  }

  /// Converts a tab index to horizontal alignment (-1 to 1).
  double _computeXAlignmentForTab(int tabIndex) {
    return DraggableIndicatorPhysics.computeAlignment(
      tabIndex,
      widget.tabCount,
    );
  }

  /// Converts a global drag position to horizontal alignment (-1 to 1).
  double _getAlignmentFromGlobalPosition(Offset globalPosition) {
    return DraggableIndicatorPhysics.getAlignmentFromGlobalPosition(
      globalPosition,
      context,
      widget.tabCount,
    );
  }

  void _setDragging(Offset globalPosition) {
    setState(() {
      _isDragging = true;
      _xAlign = _getAlignmentFromGlobalPosition(globalPosition);
    });
  }

  void _onDragDown(DragDownDetails details) =>
      _setDragging(details.globalPosition);

  void _onDragStart(DragStartDetails details) =>
      _setDragging(details.globalPosition);

  void _onDragUpdate(DragUpdateDetails details) =>
      _setDragging(details.globalPosition);

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _xAlign = _getAlignmentFromGlobalPosition(details.globalPosition);
      final relativeX = (_xAlign + 1) / 2;
      /*
   relativeX   -  0       ~       1 1+
                  |               |
 targetIndex      0, 1, ···, n-1, n
          */
      final targetIndex = (relativeX * (widget.tabCount - 1))
          .round()
          .clamp(0, widget.tabCount - 1);
      _xAlign = _computeXAlignmentForTab(targetIndex);
      widget.onTabChanged(targetIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final indicatorColor = widget.indicatorColor ??
        theme.textTheme.textStyle.color?.withValues(alpha: .1) ??
        _fallbackIndicatorColor;
    // AnimatedGlassIndicator multiplies by 2 for the glass superellipse shape,
    // but uses the value directly for the background DecoratedBox.
    final backgroundRadius = widget.barBorderRadius * 2; // 64
    final glassRadius =
        widget.barBorderRadius; // 32 → becomes 64 after internal *2

    return LiquidStretch(
      interactionScale: widget.interactionScale,
      stretch: 0.0,
      resistance: 0.08,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragDown: _onDragDown,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: VelocitySpringBuilder(
          value: _xAlign,
          springWhenActive: GlassSpring.interactive(),
          springWhenReleased: GlassSpring.snappy(
            duration: const Duration(milliseconds: 350),
          ),
          active: _isDragging,
          builder: (context, value, velocity, child) {
            final alignment = Alignment(value, 0);
            return SpringBuilder(
              spring: GlassSpring.snappy(
                duration: const Duration(milliseconds: 300),
              ),
              // Keep thickness active while:
              //  - _isDown (tap pressed, 420 ms window for spring travel), OR
              //  - the spring still has meaningful separation from target.
              // Threshold 0.05 (was 0.10) catches the full deceleration tail.
              value: widget.visible && _isDragging ? 1.0 : 0.0,
              builder: (context, thickness, child) {
                // Lazy evaluation optimization: skip expensive calculations when hidden
                if (thickness < 0.01 &&
                    !widget.visible &&
                    widget.maskingQuality == MaskingQuality.high) {
                  // Fast path: indicator is hidden, render simple layout
                  return Container(
                    height: widget.barHeight,
                    decoration: ShapeDecoration(
                      shape: _barShape,
                    ),
                    child: AdaptiveGlass.grouped(
                      quality: widget.quality,
                      shape: _barShape,
                      child: Container(
                        padding: widget.tabPadding,
                        child: widget.childUnselected,
                      ),
                    ),
                  );
                }

                // Calculate jelly transform for the clipper (only when needed)
                final jellyTransform =
                    DraggableIndicatorPhysics.buildJellyTransform(
                  velocity: Offset(velocity, 0),
                  maxDistortion: 0.8,
                  velocityScale: 10,
                );

                // Switch rendering mode based on masking quality
                switch (widget.maskingQuality) {
                  case MaskingQuality.off:
                    return _buildSimpleMode(
                      alignment: alignment,
                      thickness: thickness,
                      velocity: velocity,
                      backgroundRadius: backgroundRadius,
                      glassRadius: glassRadius,
                      indicatorColor: indicatorColor,
                    );

                  case MaskingQuality.high:
                    return _buildHighQualityMode(
                      alignment: alignment,
                      thickness: thickness,
                      velocity: velocity,
                      jellyTransform: jellyTransform,
                      backgroundRadius: backgroundRadius,
                      glassRadius: glassRadius,
                      indicatorColor: indicatorColor,
                    );
                }
              },
            ); // SpringBuilder
          }, // VelocitySpringBuilder builder
        ), // VelocitySpringBuilder
      ),
    ); // Listener
  }

  /// Wraps [child] in a [GlassGlow] sensor if the resolved glow color is
  /// non-transparent. When [GlassInteractionBehavior.none] or [scaleOnly] is
  /// active, the parent passes [Colors.transparent] — we skip the wrapper
  /// entirely to avoid three extra widget/render-object allocations per frame.
  Widget _wrapWithGlow({required Widget child}) {
    final effectiveColor =
        widget.interactionGlowColor ?? const Color(0x1FFFFFFF);
    if (effectiveColor.a == 0) return child;
    return GlassGlow(
      clipper: ShapeBorderClipper(shape: _barShape),
      glowColor: effectiveColor,
      glowRadius: widget.interactionGlowRadius,
      child: child,
    );
  }

  /// Builds simple rendering mode without masking (MaskingQuality.off).
  ///
  /// Only renders tabs once without dual-layer masking. Maximum performance.
  Widget _buildSimpleMode({
    required Alignment alignment,
    required double thickness,
    required double velocity,
    required double backgroundRadius,
    required double glassRadius,
    required Color indicatorColor,
  }) {
    return SizedBox(
      height: widget.barHeight,
      child: _wrapWithGlow(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Glass background (Cached to prevent blur re-rasterization on pill drag)
            Positioned.fill(
              child: RepaintBoundary(
                child: AdaptiveGlass.grouped(
                  quality: widget.quality,
                  shape: _barShape,
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            // Unselected icons above background
            Positioned.fill(
              child: Container(
                padding: widget.tabPadding,
                child: widget.childUnselected,
              ),
            ),

            // Glass indicator
            if (widget.visible && thickness > 0.05)
              AnimatedGlassIndicator(
                velocity: velocity,
                itemCount: widget.tabCount,
                alignment: alignment,
                thickness: thickness,
                quality: widget.quality,
                indicatorColor: indicatorColor,
                isBackgroundIndicator: false,
                borderRadius: thickness < 1 ? backgroundRadius : glassRadius,
                padding: const EdgeInsets.all(4),
                expansion: 14,
                glassSettings: widget.indicatorSettings,
                backgroundKey: widget.backgroundKey,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds high quality rendering mode with jelly masking (MaskingQuality.high).
  ///
  /// Dual-layer rendering with ClipPath for "magic lens" effect.
  Widget _buildHighQualityMode({
    required Alignment alignment,
    required double thickness,
    required double velocity,
    required Matrix4 jellyTransform,
    required double backgroundRadius,
    required double glassRadius,
    required Color indicatorColor,
  }) {
    return SizedBox(
      height: widget.barHeight,
      child: _wrapWithGlow(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Glass Background Layer with ALL content
            // This provides the glass visual/refraction for everything
            // 1. Static Blur Background (Cached)
            Positioned.fill(
              child: RepaintBoundary(
                child: AdaptiveGlass.grouped(
                  quality: widget.quality,
                  shape: _barShape,
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            // 2. Unselected Content Layer (inverse clipped)
            Positioned.fill(
              child: ClipPath(
                clipper: JellyClipper(
                  itemCount: widget.tabCount,
                  alignment: alignment,
                  thickness: thickness,
                  expansion: 14,
                  transform: jellyTransform,
                  borderRadius: thickness < 1 ? backgroundRadius : glassRadius,
                  inverse: true,
                ),
                child: Container(
                  padding: widget.tabPadding,
                  height: widget.barHeight,
                  child: widget.childUnselected,
                ),
              ),
            ),

            // 4. Moving Glass Indicator Layer (provides color highlight)
            AnimatedGlassIndicator(
              velocity: velocity,
              itemCount: widget.tabCount,
              alignment: alignment,
              thickness: thickness,
              quality: widget.quality,
              indicatorColor: indicatorColor,
              isBackgroundIndicator: false,
              borderRadius: thickness < 1 ? backgroundRadius : glassRadius,
              padding: const EdgeInsets.all(4),
              expansion: 14,
              glassSettings: widget.indicatorSettings,
              backgroundKey: widget.backgroundKey,
            ),

            // 5. Selected Content ON TOP (ensures icons/text visible above indicator)
            // Always show to prevent jumping when animation completes
            Positioned.fill(
              child: widget.quality == GlassQuality.minimal
                  ? IgnorePointer(
                      child: ClipPath(
                        clipper: JellyClipper(
                          itemCount: widget.tabCount,
                          alignment: alignment,
                          thickness: thickness,
                          expansion: 14,
                          transform: jellyTransform,
                          borderRadius:
                              thickness < 1 ? backgroundRadius : glassRadius,
                        ),
                        child: Container(
                          padding: widget.tabPadding,
                          height: widget.barHeight,
                          child: widget.selectedTabBuilder(
                              context, thickness, alignment),
                        ),
                      ),
                    )
                  : RepaintBoundary(
                      child: IgnorePointer(
                        child: ClipPath(
                          clipper: JellyClipper(
                            itemCount: widget.tabCount,
                            alignment: alignment,
                            thickness: thickness,
                            expansion: 14,
                            transform: jellyTransform,
                            borderRadius:
                                thickness < 1 ? backgroundRadius : glassRadius,
                          ),
                          child: Container(
                            padding: widget.tabPadding,
                            height: widget.barHeight,
                            child: widget.selectedTabBuilder(
                                context, thickness, alignment),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

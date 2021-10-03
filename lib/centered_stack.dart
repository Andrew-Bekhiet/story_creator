import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CenteredStack extends MultiChildRenderObjectWidget {
  /// Creates a stack layout widget simillar to flutter's Stack,
  ///  but positions its childs from the center instead of top-left
  CenteredStack({
    Key? key,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = StackFit.loose,
    @Deprecated(
      'Use clipBehavior instead. See the migration guide in flutter.dev/go/clip-behavior. '
      'This feature was deprecated after v1.22.0-12.0.pre.',
    )
        this.clipBehavior = Clip.hardEdge,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  /// How to align the non-positioned and partially-positioned children in the
  /// stack.
  ///
  /// The non-positioned children are placed relative to each other such that
  /// the points determined by [alignment] are co-located. For example, if the
  /// [alignment] is [Alignment.topLeft], then the top left corner of
  /// each non-positioned child will be located at the same global coordinate.
  ///
  /// Partially-positioned children, those that do not specify an alignment in a
  /// particular axis (e.g. that have neither `top` nor `bottom` set), use the
  /// alignment to determine how they should be positioned in that
  /// under-specified axis.
  ///
  /// Defaults to [AlignmentDirectional.topStart].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The text direction with which to resolve [alignment].
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// How to size the non-positioned children in the stack.
  ///
  /// The constraints passed into the [Stack] from its parent are either
  /// loosened ([StackFit.loose]) or tightened to their biggest size
  /// ([StackFit.expand]).
  final StackFit fit;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  bool _debugCheckHasDirectionality(BuildContext context) {
    if (alignment is AlignmentDirectional && textDirection == null) {
      assert(debugCheckHasDirectionality(
        context,
        why: "to resolve the 'alignment' argument",
        hint: alignment == AlignmentDirectional.topStart
            ? "The default value for 'alignment' is AlignmentDirectional.topStart, which requires a text direction."
            : null,
        alternative:
            "Instead of providing a Directionality widget, another solution would be passing a non-directional 'alignment', or an explicit 'textDirection', to the $runtimeType.",
      ));
    }
    return true;
  }

  @override
  RenderCenteredStack createRenderObject(BuildContext context) {
    assert(_debugCheckHasDirectionality(context));
    return RenderCenteredStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderCenteredStack renderObject) {
    assert(_debugCheckHasDirectionality(context));
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }
}

class RenderCenteredStack extends RenderStack {
  /// Creates a stack render object.
  ///
  /// By default, the non-positioned children of the stack are aligned by their
  /// top left corners.
  RenderCenteredStack({
    List<RenderBox>? children,
    AlignmentGeometry alignment = AlignmentDirectional.topStart,
    TextDirection? textDirection,
    StackFit fit = StackFit.loose,
    Clip clipBehavior = Clip.hardEdge,
  })  : _alignment = alignment,
        _textDirection = textDirection,
        _fit = fit,
        _clipBehavior = clipBehavior {
    addAll(children);
  }

  bool _hasVisualOverflow = false;

  Alignment? _resolvedAlignment;

  void _resolve() {
    if (_resolvedAlignment != null) return;
    _resolvedAlignment = alignment.resolve(textDirection);
  }

  void _markNeedResolution() {
    _resolvedAlignment = null;
    markNeedsLayout();
  }

  /// How to align the non-positioned or partially-positioned children in the
  /// stack.
  ///
  /// The non-positioned children are placed relative to each other such that
  /// the points determined by [alignment] are co-located. For example, if the
  /// [alignment] is [Alignment.topLeft], then the top left corner of
  /// each non-positioned child will be located at the same global coordinate.
  ///
  /// Partially-positioned children, those that do not specify an alignment in a
  /// particular axis (e.g. that have neither `top` nor `bottom` set), use the
  /// alignment to determine how they should be positioned in that
  /// under-specified axis.
  ///
  /// If this is set to an [AlignmentDirectional] object, then [textDirection]
  /// must not be null.
  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment == value) return;
    _alignment = value;
    _markNeedResolution();
  }

  /// The text direction with which to resolve [alignment].
  ///
  /// This may be changed to null, but only after the [alignment] has been changed
  /// to a value that does not depend on the direction.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _markNeedResolution();
  }

  /// How to size the non-positioned children in the stack.
  ///
  /// The constraints passed into the [RenderCenteredStack] from its parent are either
  /// loosened ([StackFit.loose]) or tightened to their biggest size
  /// ([StackFit.expand]).
  StackFit get fit => _fit;
  StackFit _fit;
  set fit(StackFit value) {
    if (_fit != value) {
      _fit = value;
      markNeedsLayout();
    }
  }

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.hardEdge;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  /// Lays out the positioned `child` according to `alignment` within a Stack of `size`.
  ///
  /// Returns true when the child has visual overflow.
  static bool layoutPositionedChild(RenderBox child,
      StackParentData childParentData, Size size, Alignment alignment) {
    assert(childParentData.isPositioned);
    assert(child.parentData == childParentData);

    bool hasVisualOverflow = false;
    BoxConstraints childConstraints = const BoxConstraints();

    if (childParentData.left != null && childParentData.right != null)
      childConstraints = childConstraints.tighten(
          width: size.width - childParentData.right! - childParentData.left!);
    else if (childParentData.width != null)
      childConstraints = childConstraints.tighten(width: childParentData.width);

    if (childParentData.top != null && childParentData.bottom != null)
      childConstraints = childConstraints.tighten(
          height: size.height - childParentData.bottom! - childParentData.top!);
    else if (childParentData.height != null)
      childConstraints =
          childConstraints.tighten(height: childParentData.height);

    child.layout(childConstraints, parentUsesSize: true);

    late final double x;
    if (childParentData.left != null) {
      x = childParentData.left!;
    } else if (childParentData.right != null) {
      x = size.width - childParentData.right! - child.size.width;
    } else {
      x = alignment.alongOffset(size - child.size as Offset).dx;
    }

    if (x < 0.0 || x + child.size.width > size.width) hasVisualOverflow = true;

    late final double y;
    if (childParentData.top != null) {
      y = childParentData.top!;
    } else if (childParentData.bottom != null) {
      y = size.height - childParentData.bottom! - child.size.height;
    } else {
      y = alignment.alongOffset(size - child.size as Offset).dy;
    }

    if (y < 0.0 || y + child.size.height > size.height)
      hasVisualOverflow = true;

    childParentData.offset =
        Offset(x - (child.size / 2).width, y - (child.size / 2).height);

    return hasVisualOverflow;
  }

  Size _computeSize(
      {required BoxConstraints constraints,
      required ChildLayouter layoutChild}) {
    _resolve();
    assert(_resolvedAlignment != null);
    bool hasNonPositionedChildren = false;
    if (childCount == 0) {
      assert(constraints.biggest.isFinite);
      return constraints.biggest;
    }

    double width = constraints.minWidth;
    double height = constraints.minHeight;

    final BoxConstraints nonPositionedConstraints;
    switch (fit) {
      case StackFit.loose:
        nonPositionedConstraints = constraints.loosen();
        break;
      case StackFit.expand:
        nonPositionedConstraints = BoxConstraints.tight(constraints.biggest);
        break;
      case StackFit.passthrough:
        nonPositionedConstraints = constraints;
        break;
    }

    RenderBox? child = firstChild;
    while (child != null) {
      final StackParentData childParentData =
          child.parentData! as StackParentData;

      if (!childParentData.isPositioned) {
        hasNonPositionedChildren = true;

        final Size childSize = layoutChild(child, nonPositionedConstraints);

        width = math.max(width, childSize.width);
        height = math.max(height, childSize.height);
      }

      child = childParentData.nextSibling;
    }

    final Size size;
    if (hasNonPositionedChildren) {
      size = Size(width, height);
      assert(size.width == constraints.constrainWidth(width));
      assert(size.height == constraints.constrainHeight(height));
    } else {
      size = constraints.biggest;
    }

    assert(size.isFinite);
    return size;
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    _hasVisualOverflow = false;

    size = _computeSize(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.layoutChild,
    );

    assert(_resolvedAlignment != null);
    RenderBox? child = firstChild;
    while (child != null) {
      final StackParentData childParentData =
          child.parentData! as StackParentData;

      if (!childParentData.isPositioned) {
        childParentData.offset =
            _resolvedAlignment!.alongOffset(size - child.size as Offset);
      } else {
        _hasVisualOverflow = layoutPositionedChild(
                child, childParentData, size, _resolvedAlignment!) ||
            _hasVisualOverflow;
      }

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  /// Override in subclasses to customize how the stack paints.
  ///
  /// By default, the stack uses [defaultPaint]. This function is called by
  /// [paint] after potentially applying a clip to contain visual overflow.
  @protected
  void paintStack(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}

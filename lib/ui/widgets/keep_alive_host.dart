import 'package:flutter/widgets.dart';

/// Keeps its subtree alive while it is scrolled out of a lazy list.
///
/// A card placed directly in a lazy list is disposed once it leaves the
/// viewport, which used to reset the prayer card: the loaded schedule and the
/// running countdown were thrown away and a spinner appeared on the way back.
/// Wrapping the card in this widget asks the enclosing list to preserve the
/// element instead, so timers and loaded data survive scrolling.
class KeepAliveHost extends StatefulWidget {
  const KeepAliveHost({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAliveHost> createState() => _KeepAliveHostState();
}

class _KeepAliveHostState extends State<KeepAliveHost>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // Required by the mixin to register the keep-alive handle.
    super.build(context);
    return widget.child;
  }
}

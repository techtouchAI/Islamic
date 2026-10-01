import 'package:flutter/material.dart';

import '../../data/data_manager.dart';
import '../../theme/app_card_theme.dart';

/// One page, one tree: the lineage from Adam to the Seal of the Prophets,
/// the branch of `Abd al-Muttalib into `Abd Allah and Abu Talib, the meeting
/// of the two lights, al-Hasan and al-Husayn, and the chain of the twelve
/// imams, with a supplement of the prophetic lines of Ibrahim and Nuh.
///
/// The tree is data: the entries of the `prophets_tree` section are nodes
/// (`group` says where a node sits, `type` says how it is drawn, `tags` say
/// which filters reach it), so the CMS can correct a name without a release.
/// Filtering hides every node outside the selected tag and collapses the
/// page into a single trunk of the matching nodes.
class ProphetsTreeScreen extends StatefulWidget {
  const ProphetsTreeScreen({
    super.key,
    required this.title,
    required this.fontSizeFactor,
  });

  final String title;
  final double fontSizeFactor;

  /// Identifies the tree body in tests, whichever filter is active.
  static const Key bodyKey = Key('prophetsTreeBody');

  /// The methodological note of the page, matching the content document.
  static const String methodNote =
      'سلسلة الأسماء بين آدم ونوح، وكذلك بعض الأسماء بين إسماعيل وعدنان، '
      'ترد في كتب الأنساب والتاريخ وليست كلها منصوصًا عليها في القرآن؛ '
      'لذلك وُسمت بأنها «نسب تقليدي/مشهور» وليست قطعية.';

  static const String heroSubtitle =
      'هذه الشجرة تجمع النسب الأبوي حيث يكون معروفًا، وتعرض الفروع النبوية '
      'والإمامية بصورة منفصلة عند عدم ثبوت علاقة الأبوة المباشرة.';

  /// Title of the supplement card collecting the prophetic branches.
  static const String supplementTitle =
      'أهم الفروع النبوية المرتبطة بإبراهيم ونوح';

  @override
  State<ProphetsTreeScreen> createState() => _ProphetsTreeScreenState();
}

class _ProphetsTreeScreenState extends State<ProphetsTreeScreen> {
  /// The tag currently filtered on; null shows the whole tree.
  String? _activeTag;

  List<_TreeNode> _nodes = const [];

  @override
  void initState() {
    super.initState();
    DataManager.dbNotifier.addListener(_reload);
    _nodes = _decodeNodes();
  }

  @override
  void dispose() {
    DataManager.dbNotifier.removeListener(_reload);
    super.dispose();
  }

  static List<_TreeNode> _decodeNodes() => DataManager.getItems('prophets_tree')
      .whereType<Map>()
      .map(_TreeNode.fromMap)
      .toList();

  void _reload() {
    if (!mounted) return;
    setState(() => _nodes = _decodeNodes());
  }

  /// The filters offered over the tree, in page order. A node answers a
  /// filter through its `tags`; the first entry always shows everything.
  static const List<_Filter> _filters = [
    _Filter(null, 'الكل'),
    _Filter('prophets', 'الأنبياء والرسل'),
    _Filter('ancestors', 'الخط الأبوي'),
    _Filter('quraish', 'نسب قريش'),
    _Filter('imams', 'الأئمة الاثنا عشر'),
    _Filter('ahl_albayt', 'أهل البيت'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          key: ProphetsTreeScreen.bodyKey,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 44),
          children: [
            _FilterChips(
              filters: _filters,
              activeTag: _activeTag,
              onSelected: (tag) => setState(() => _activeTag = tag),
            ),
            const SizedBox(height: 22),
            if (_activeTag == null)
              ..._fullPage(context, isDark)
            else
              ..._filteredPage(context, isDark),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // The whole tree
  // ------------------------------------------------------------------

  List<Widget> _fullPage(BuildContext context, bool isDark) {
    final trunk = _nodes.where((n) => n.group == 'trunk').toList();
    final branchA = _nodes.where((n) => n.group == 'branch_a').toList();
    final branchB = _nodes.where((n) => n.group == 'branch_b').toList();
    final marriage = _nodes.firstWhere(
      (n) => n.type == 'marriage',
      orElse: () => _TreeNode.empty(),
    );
    final grid = _nodes.where((n) => n.group == 'grid').toList();
    final chain = _nodes.where((n) => n.group == 'chain').toList();
    final supplement = _nodes.where((n) => n.group == 'supplement').toList();

    return [
      _hero(context),
      const SizedBox(height: 24),
      _methodNote(context, isDark),
      const SizedBox(height: 34),
      _spine(
        context,
        gradient: _trunkGradient(isDark),
        children: [
          for (final node in trunk)
            node.type == 'gap'
                ? _gapNote(context, node, isDark)
                : _centeredNode(context, node, isDark),
        ],
      ),
      const SizedBox(height: 10),
      _branch(context, isDark, branchA, branchB),
      const SizedBox(height: 34),
      if (marriage.title.isNotEmpty) _marriageRow(context, marriage, isDark),
      const SizedBox(height: 34),
      _grid(context, isDark, grid),
      const SizedBox(height: 56),
      _chainTitle(context, isDark),
      const SizedBox(height: 36),
      _spine(
        context,
        gradient: _chainGradient(isDark),
        maxWidth: 460,
        children: [for (final node in chain) _chainStep(context, node, isDark)],
      ),
      const SizedBox(height: 70),
      _supplement(context, isDark, supplement),
    ];
  }

  /// The filtered view: a single trunk carrying only the matching nodes.
  List<Widget> _filteredPage(BuildContext context, bool isDark) {
    final tag = _activeTag;
    final matches =
        _nodes.where((n) => !n.structural && n.tags.contains(tag)).toList();
    if (matches.isEmpty) {
      return [
        const SizedBox(height: 60),
        Center(
          child: Text(
            'لا توجد عناصر ضمن هذا التصنيف',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ];
    }
    final filter = _filters.firstWhere((f) => f.tag == tag);
    final accent = _accentForFilter(tag, isDark);
    return [
      Center(
        child: Text(
          filter.label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
              ),
        ),
      ),
      const SizedBox(height: 22),
      _spine(
        context,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.0),
            accent.withValues(alpha: isDark ? 0.5 : 0.35),
            accent.withValues(alpha: isDark ? 0.5 : 0.35),
            accent.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.04, 0.96, 1.0],
        ),
        children: [
          for (final node in matches) _centeredNode(context, node, isDark),
        ],
      ),
    ];
  }

  // ------------------------------------------------------------------
  // Page furniture
  // ------------------------------------------------------------------

  Widget _hero(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.cardColor.contrastTextColor;
    return Column(
      children: [
        const SizedBox(height: 14),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25 * widget.fontSizeFactor,
            fontWeight: FontWeight.w800,
            height: 1.5,
            color: foreground,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _ornamentLine(context)),
            const SizedBox(width: 14),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.6),
                    blurRadius: 14,
                  ),
                ],
              ),
              transform: Matrix4.identity()..rotateZ(3.14159265 / 4),
              transformAlignment: Alignment.center,
            ),
            const SizedBox(width: 14),
            Expanded(child: _ornamentLine(context)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          ProphetsTreeScreen.heroSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14 * widget.fontSizeFactor,
            height: 1.9,
            color: foreground.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _ornamentLine(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = Theme.of(context)
        .cardColor
        .contrastTextColor
        .withValues(alpha: isDark ? 0.3 : 0.22);
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            line.withValues(alpha: 0.0),
            line,
            line.withValues(alpha: 0.0)
          ],
        ),
      ),
    );
  }

  Widget _methodNote(BuildContext context, bool isDark) {
    const gold = Color(0xFFFBBF24);
    final background = Theme.of(context).cardColor;
    final foreground = background.contrastTextColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Color.lerp(background, gold, isDark ? 0.07 : 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            constraints: const BoxConstraints(minHeight: 40),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'ملاحظة منهجية: ',
                    style: TextStyle(
                      color: isDark ? gold : const Color(0xFFB45309),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ProphetsTreeScreen.methodNote,
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 13 * widget.fontSizeFactor,
                height: 1.95,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Nodes
  // ------------------------------------------------------------------

  /// A node of the trunk or of the filtered view: centred under the spine.
  Widget _centeredNode(BuildContext context, _TreeNode node, bool isDark) {
    final Widget child;
    if (node.type == 'ancestor' && node.desc.isEmpty && !node.strong) {
      child = _pillNode(context, node, isDark);
    } else {
      child = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _nodeCard(context, node, isDark),
      );
    }
    return Center(child: child);
  }

  Widget _nodeCard(BuildContext context, _TreeNode node, bool isDark) {
    final accent = _accentForNode(node, isDark);
    final background = Theme.of(context).cardColor;
    final foreground = background.contrastTextColor;
    final isMahdi = node.type == 'mahdi';
    final titleSize =
        node.strong ? 22.0 : (node.group == 'chain' ? 20.0 : 21.0);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: node.desc.isEmpty ? 14 : 17,
      ),
      decoration: BoxDecoration(
        color: isMahdi ? Color.lerp(background, accent, 0.08) : background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.4 : 0.55),
          width: node.strong || isMahdi ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: isMahdi ? 40 : 26,
            offset: const Offset(0, 14),
            spreadRadius: isMahdi ? -18 : -16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (node.badge.isNotEmpty) ...[
            _badge(node.badge, accent, isDark),
            const SizedBox(height: 9),
          ],
          Text(
            node.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize * widget.fontSizeFactor,
              fontWeight: node.strong ? FontWeight.w800 : FontWeight.w700,
              height: 1.55,
              color: isMahdi && isDark ? const Color(0xFFFFF8E6) : foreground,
            ),
          ),
          if (node.desc.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              node.desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13 * widget.fontSizeFactor,
                height: 1.85,
                color: foreground.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The compact bead of an ancestor without a description.
  Widget _pillNode(BuildContext context, _TreeNode node, bool isDark) {
    final accent = _accentForNode(node, isDark);
    final background = Theme.of(context).cardColor;
    final foreground = background.contrastTextColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: isDark ? 0.3 : 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _badge(node.badge, accent, isDark, compact: true),
          const SizedBox(width: 11),
          Text(
            node.title,
            style: TextStyle(
              fontSize: 15 * widget.fontSizeFactor,
              fontWeight: FontWeight.w600,
              color: foreground.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color accent, bool isDark,
      {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 13,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.13 : 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: compact ? 10.5 : 11.5,
          fontWeight: FontWeight.w700,
          height: 1.7,
          color: accent,
        ),
      ),
    );
  }

  Widget _gapNote(BuildContext context, _TreeNode node, bool isDark) {
    final background = Theme.of(context).cardColor;
    final foreground = background.contrastTextColor;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: foreground.withValues(alpha: isDark ? 0.3 : 0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: Text(
          node.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5 * widget.fontSizeFactor,
            height: 1.9,
            color: foreground.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Composition pieces
  // ------------------------------------------------------------------

  /// A vertical spine behind a column of nodes.
  Widget _spine(
    BuildContext context, {
    required LinearGradient gradient,
    required List<Widget> children,
    double maxWidth = 560,
  }) {
    final separated = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) separated.add(const SizedBox(height: 26));
      separated.add(children[i]);
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: gradient,
                  ),
                ),
              ),
            ),
            Column(children: separated),
          ],
        ),
      ),
    );
  }

  LinearGradient _trunkGradient(bool isDark) {
    double a(double v) => v * (isDark ? 1.0 : 0.62);
    const slate = Color(0xFF94A3B8);
    const emerald = Color(0xFF34D399);
    const blue = Color(0xFF60A5FA);
    const gold = Color(0xFFFBBF24);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        slate.withValues(alpha: 0.0),
        slate.withValues(alpha: a(0.45)),
        emerald.withValues(alpha: a(0.55)),
        emerald.withValues(alpha: a(0.55)),
        blue.withValues(alpha: a(0.45)),
        emerald.withValues(alpha: a(0.55)),
        gold.withValues(alpha: a(0.6)),
        gold.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.03, 0.22, 0.46, 0.66, 0.86, 0.98, 1.0],
    );
  }

  LinearGradient _chainGradient(bool isDark) {
    double a(double v) => v * (isDark ? 1.0 : 0.62);
    const blue = Color(0xFF60A5FA);
    const gold = Color(0xFFFBBF24);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        blue.withValues(alpha: a(0.5)),
        blue.withValues(alpha: a(0.5)),
        gold.withValues(alpha: a(0.6)),
      ],
      stops: const [0.0, 0.72, 1.0],
    );
  }

  /// The fork of `Abd al-Muttalib into `Abd Allah and Abu Talib.
  Widget _branch(
    BuildContext context,
    bool isDark,
    List<_TreeNode> branchA,
    List<_TreeNode> branchB,
  ) {
    final lineColor = Theme.of(context)
        .cardColor
        .contrastTextColor
        .withValues(alpha: isDark ? 0.34 : 0.26);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 560;
        final columns = [
          _branchColumn(context, isDark, branchA, lineColor, !narrow),
          _branchColumn(context, isDark, branchB, lineColor, !narrow),
        ];
        return Column(
          children: [
            if (!narrow) ...[
              Container(
                width: 3,
                height: 30,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                width: constraints.maxWidth * 0.5,
                height: 2,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
            if (narrow) ...[
              columns[0],
              const SizedBox(height: 26),
              columns[1],
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: columns[0]),
                  Expanded(child: columns[1]),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _branchColumn(
    BuildContext context,
    bool isDark,
    List<_TreeNode> nodes,
    Color lineColor,
    bool connectors,
  ) {
    final children = <Widget>[];
    if (connectors) {
      children.add(
        Center(
          child: Container(
            width: 2,
            height: 30,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }
    for (var i = 0; i < nodes.length; i++) {
      if (i > 0 || connectors) children.add(const SizedBox(height: 26));
      children.add(
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _nodeCard(context, nodes[i], isDark),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _marriageRow(
    BuildContext context,
    _TreeNode marriage,
    bool isDark,
  ) {
    const rose = Color(0xFFF472B6);
    const blue = Color(0xFF60A5FA);
    const purple = Color(0xFFA855F7);
    return Row(
      children: [
        Expanded(
          child: _dashedLine(rose.withValues(alpha: isDark ? 0.55 : 0.45)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: purple.withValues(alpha: isDark ? 0.14 : 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: purple.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: purple.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 0),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Text(
              marriage.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5 * widget.fontSizeFactor,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFD8B4FE) : purple,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _dashedLine(blue.withValues(alpha: isDark ? 0.55 : 0.45)),
        ),
      ],
    );
  }

  Widget _dashedLine(Color color) {
    return SizedBox(
      height: 2,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color),
      ),
    );
  }

  Widget _grid(BuildContext context, bool isDark, List<_TreeNode> nodes) {
    if (nodes.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          for (final node in nodes) _nodeCard(context, node, isDark),
        ];
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 18),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: cards[i],
                  ),
                ),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 18),
            if (cards.length > 1) Expanded(child: cards[1]),
          ],
        );
      },
    );
  }

  Widget _chainTitle(BuildContext context, bool isDark) {
    const blue = Color(0xFF60A5FA);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  blue.withValues(alpha: 0.0),
                  blue.withValues(alpha: isDark ? 0.5 : 0.35),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 3,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: isDark ? 0.09 : 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: blue.withValues(alpha: 0.3)),
              ),
              child: Text(
                'سلسلة الأئمة الاثني عشر',
                style: TextStyle(
                  fontSize: 13.5 * widget.fontSizeFactor,
                  fontWeight: FontWeight.w700,
                  color: isDark ? blue : const Color(0xFF2563EB),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  blue.withValues(alpha: isDark ? 0.5 : 0.35),
                  blue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A chain step: the imam card with its numbered medallion on top.
  Widget _chainStep(BuildContext context, _TreeNode node, bool isDark) {
    final isMahdi = node.type == 'mahdi';
    const blue = Color(0xFF60A5FA);
    const gold = Color(0xFFFBBF24);
    final ringColor = isMahdi ? gold : blue;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: _nodeCard(context, node, isDark),
        ),
        if (node.step != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: ringColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: ringColor.withValues(alpha: isDark ? 0.55 : 0.4),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _easternArabic(node.step!),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isMahdi && !isDark
                          ? const Color(0xFFB45309)
                          : ringColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _supplement(
    BuildContext context,
    bool isDark,
    List<_TreeNode> entries,
  ) {
    if (entries.isEmpty) return const SizedBox.shrink();
    const gold = Color(0xFFFBBF24);
    final background = Theme.of(context).cardColor;
    final foreground = background.contrastTextColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
      decoration: BoxDecoration(
        color: Color.lerp(background, const Color(0xFF94A3B8), 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: foreground.withValues(alpha: isDark ? 0.18 : 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ProphetsTreeScreen.supplementTitle,
            style: TextStyle(
              fontSize: 20 * widget.fontSizeFactor,
              fontWeight: FontWeight.w700,
              height: 1.6,
              color: foreground,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 76,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: [gold, gold.withValues(alpha: 0.0)],
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Text(
                      '◆',
                      style: TextStyle(
                        fontSize: 9,
                        color: gold.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${entry.title}: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: foreground,
                            ),
                          ),
                          TextSpan(
                            text: entry.desc,
                            style: TextStyle(
                              color: foreground.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 14 * widget.fontSizeFactor,
                        height: 1.95,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Colours
  // ------------------------------------------------------------------

  /// The accent of a node type: bright on dark surfaces, deepened on light
  /// ones so badges and titles keep their contrast.
  Color _accentForNode(_TreeNode node, bool isDark) {
    switch (node.type) {
      case 'prophet':
      case 'messenger':
        return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      case 'lady':
        return isDark ? const Color(0xFFF472B6) : const Color(0xFFDB2777);
      case 'imam':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      case 'husayn':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      case 'mahdi':
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
      default:
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    }
  }

  Color _accentForFilter(String? tag, bool isDark) {
    switch (tag) {
      case 'prophets':
        return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      case 'imams':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      case 'ahl_albayt':
        return isDark ? const Color(0xFFF472B6) : const Color(0xFFDB2777);
      case 'quraish':
      case 'ancestors':
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      default:
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    }
  }

  /// Eastern Arabic numerals for the imam medallions.
  static String _easternArabic(int value) {
    const digits = '٠١٢٣٤٥٦٧٨٩';
    return value.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}

/// One row of filter chips above the tree.
class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.activeTag,
    required this.onSelected,
  });

  final List<_Filter> filters;
  final String? activeTag;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const gold = Color(0xFFFBBF24);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 9),
              child: Material(
                color: filter.tag == activeTag
                    ? gold.withValues(alpha: isDark ? 0.18 : 0.16)
                    : theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: filter.tag == activeTag
                        ? gold.withValues(alpha: 0.6)
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onSelected(filter.tag),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    child: Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: filter.tag == activeTag
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: filter.tag == activeTag
                            ? (isDark ? gold : const Color(0xFFB45309))
                            : theme.cardColor.contrastTextColor
                                .withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A filter offered over the tree: `tag` is null for the show-everything
/// entry.
class _Filter {
  const _Filter(this.tag, this.label);

  final String? tag;
  final String label;
}

/// A node of the tree, decoded from one entry of the section content.
class _TreeNode {
  _TreeNode({
    required this.id,
    required this.title,
    required this.type,
    required this.badge,
    required this.group,
    required this.desc,
    required this.tags,
    this.step,
    this.strong = false,
  });

  factory _TreeNode.fromMap(Map raw) {
    return _TreeNode(
      id: raw['id']?.toString() ?? '',
      title: raw['title']?.toString() ?? '',
      type: raw['type']?.toString() ?? 'ancestor',
      badge: raw['badge']?.toString() ?? '',
      group: raw['group']?.toString() ?? 'trunk',
      desc: raw['desc']?.toString() ?? '',
      tags: raw['tags'] is List
          ? (raw['tags'] as List).map((t) => t.toString()).toList()
          : const <String>[],
      step: raw['step'] is int
          ? raw['step'] as int
          : int.tryParse(raw['step']?.toString() ?? ''),
      strong: raw['strong'] == true,
    );
  }

  /// The node returned when a structural slot is empty.
  factory _TreeNode.empty() => _TreeNode(
        id: '',
        title: '',
        type: 'gap',
        badge: '',
        group: '',
        desc: '',
        tags: const [],
      );

  final String id;
  final String title;
  final String type;
  final String badge;
  final String group;
  final String desc;
  final List<String> tags;
  final int? step;
  final bool strong;

  /// Structural nodes connect the drawing; filters never match them.
  bool get structural =>
      type == 'gap' || type == 'marriage' || type == 'supplement';
}

/// A horizontal dashed line, used on both sides of the marriage label.
class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 7.0;
    const gap = 6.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      var end = x + dash;
      if (end > size.width) end = size.width;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

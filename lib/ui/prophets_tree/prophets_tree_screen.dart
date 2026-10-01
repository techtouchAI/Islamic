import 'package:flutter/material.dart';

import '../../data/data_manager.dart';
import '../../theme/app_card_theme.dart';
import 'prophets_tree_data.dart';

/// One page, one tree: the lineage from Adam to the Seal of the Prophets,
/// the branch of `Abd al-Muttalib into `Abd Allah and Abu Talib, the meeting
/// of the two lights, al-Hasan and al-Husayn, and the chain of the twelve
/// imams, with a supplement of the prophetic lines of Ibrahim and Nuh.
///
/// The tree is data: the entries of the `prophets_tree` section are nodes
/// (`group` says where a node sits, `type` says how it is drawn, `tags` say
/// which filters reach it), so the CMS can correct a name without a release.
/// If the active document still carries the legacy three-article entries, the
/// screen falls back to [kDefaultProphetsTreeNodes] so the full tree and all
/// category filters work immediately.
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

  static List<_TreeNode> _decodeNodes() {
    final raw =
        DataManager.getItems('prophets_tree').whereType<Map>().toList();
    if (raw.isEmpty) {
      if (DataManager.getSections().containsKey('prophets_tree')) {
        return kDefaultProphetsTreeNodes.map(_TreeNode.fromMap).toList();
      }
      return const [];
    }
    final hasStructuredNodes = raw.any(_isStructuredNode);
    final source = hasStructuredNodes ? raw : kDefaultProphetsTreeNodes;
    return source.map(_TreeNode.fromMap).toList();
  }

  static bool _isStructuredNode(Map m) =>
      m.containsKey('type') || m.containsKey('group') || m.containsKey('tags');

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
      const SizedBox(height: 22),
      _methodNote(context, isDark),
      const SizedBox(height: 30),
      if (trunk.isNotEmpty)
        _spine(
          context,
          gradient: _trunkGradient(isDark),
          spacing: 18,
          children: [
            for (final node in trunk)
              node.type == 'gap'
                  ? _gapNote(context, node, isDark)
                  : _centeredNode(context, node, isDark),
          ],
        ),
      if (branchA.isNotEmpty || branchB.isNotEmpty) ...[
        const SizedBox(height: 6),
        _branch(context, isDark, branchA, branchB),
      ],
      if (marriage.title.isNotEmpty) ...[
        const SizedBox(height: 20),
        _marriageRow(context, marriage, isDark),
      ],
      if (grid.isNotEmpty) ...[
        const SizedBox(height: 16),
        _grid(context, isDark, grid),
      ],
      if (chain.isNotEmpty) ...[
        const SizedBox(height: 44),
        _chainTitle(context, isDark),
        const SizedBox(height: 30),
        _spine(
          context,
          gradient: _chainGradient(isDark),
          maxWidth: 460,
          spacing: 24,
          children: [
            for (final node in chain) _chainStep(context, node, isDark),
          ],
        ),
      ],
      if (supplement.isNotEmpty) ...[
        const SizedBox(height: 52),
        _supplement(context, isDark, supplement),
      ],
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
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ];
    }
    final filter = _filters.firstWhere((f) => f.tag == tag);
    final accent = _accentForFilter(tag, isDark);
    return [
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.14 : 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.38)),
          ),
          child: Text(
            '${filter.label} (${_easternArabic(matches.length)})',
            textAlign: TextAlign.center,
            softWrap: true,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
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
        spacing: 18,
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
        const SizedBox(height: 10),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontSize: 24 * widget.fontSizeFactor,
            fontWeight: FontWeight.w800,
            height: 1.5,
            color: foreground,
          ),
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        Text(
          ProphetsTreeScreen.heroSubtitle,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontSize: 13.5 * widget.fontSizeFactor,
            height: 1.85,
            color: foreground.withValues(alpha: 0.74),
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
            line.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _methodNote(BuildContext context, bool isDark) {
    const gold = Color(0xFFFBBF24);
    final background = Theme.of(context).cardColor;
    final foreground = background.contrastTextColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color.lerp(background, gold, isDark ? 0.08 : 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gold.withValues(alpha: 0.34)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                color: gold.withValues(alpha: 0.85),
                width: 4,
              ),
            ),
          ),
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
                    color: foreground.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
            softWrap: true,
            style: TextStyle(
              fontSize: 13 * widget.fontSizeFactor,
              height: 1.9,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Nodes (HTML-faithful `.node-card` design with zero overflow)
  // ------------------------------------------------------------------

  /// A node of the trunk or of the filtered view: centred over the spine.
  Widget _centeredNode(BuildContext context, _TreeNode node, bool isDark) {
    final isLineage = node.type == 'ancestor' || node.type == 'quraish';
    final isCompactLineage = isLineage && node.desc.isEmpty && !node.strong;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isCompactLineage ? 270 : 420),
        child: _nodeCard(
          context,
          node,
          isDark,
          compact: isCompactLineage,
        ),
      ),
    );
  }

  Widget _nodeCard(
    BuildContext context,
    _TreeNode node,
    bool isDark, {
    bool compact = false,
    bool inBranch = false,
    double extraTopPadding = 0,
  }) {
    final accent = _accentForNode(node, isDark);
    final background = Theme.of(context).cardColor;
    final foreground = background.contrastTextColor;
    final isMahdi = node.type == 'mahdi';
    final isStrong = node.strong || isMahdi;

    final double titleBase;
    if (inBranch) {
      titleBase = isStrong ? 16.5 : 15.5;
    } else if (compact) {
      titleBase = 16.5;
    } else if (isStrong) {
      titleBase = 20.5;
    } else if (node.group == 'chain') {
      titleBase = 19.0;
    } else {
      titleBase = 19.5;
    }

    final horizontalPad = inBranch ? 10.0 : (compact ? 16.0 : 18.0);
    final double verticalPad;
    if (compact) {
      verticalPad = 11.0;
    } else if (node.desc.isEmpty) {
      verticalPad = 13.0;
    } else {
      verticalPad = inBranch ? 12.0 : 15.0;
    }

    final double topAlpha;
    final double shadowAlpha;
    if (isMahdi) {
      topAlpha = isDark ? 0.16 : 0.12;
      shadowAlpha = isDark ? 0.38 : 0.24;
    } else if (isStrong) {
      topAlpha = isDark ? 0.11 : 0.08;
      shadowAlpha = isDark ? 0.28 : 0.16;
    } else {
      topAlpha = isDark ? 0.07 : 0.045;
      shadowAlpha = isDark ? 0.18 : 0.1;
    }
    final bottomAlpha =
        isMahdi ? (isDark ? 0.06 : 0.04) : (isDark ? 0.025 : 0.015);
    final borderAlpha =
        isStrong ? (isDark ? 0.68 : 0.62) : (isDark ? 0.38 : 0.42);
    final topTint = Color.lerp(background, accent, topAlpha)!;
    final bottomTint = Color.lerp(background, accent, bottomAlpha)!;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topTint, bottomTint],
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(
          color: accent.withValues(alpha: borderAlpha),
          width: isStrong ? 1.8 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: shadowAlpha),
            blurRadius: isMahdi ? 32 : (compact ? 16 : 22),
            offset: Offset(0, compact ? 8 : 11),
            spreadRadius: isMahdi ? -12 : -14,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top luminous bar matching `.node-card::before` in the HTML design.
          Container(
            height: isStrong ? 3.5 : 2.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.1),
                  accent.withValues(alpha: isStrong ? 0.95 : 0.75),
                  accent.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPad,
              verticalPad + extraTopPadding,
              horizontalPad,
              verticalPad,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (node.badge.isNotEmpty) ...[
                  _badge(
                    node.badge,
                    accent,
                    isDark,
                    compact: compact || inBranch,
                  ),
                  SizedBox(height: compact ? 6 : 8),
                ],
                Text(
                  node.title,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: titleBase * widget.fontSizeFactor,
                    fontWeight: isStrong ? FontWeight.w800 : FontWeight.w700,
                    height: 1.45,
                    color: isMahdi && isDark
                        ? const Color(0xFFFFF8E6)
                        : foreground,
                  ),
                ),
                if (node.desc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 1,
                    color: accent.withValues(alpha: 0.22),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    node.desc,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontSize:
                          (inBranch ? 12.0 : 13.0) * widget.fontSizeFactor,
                      height: 1.75,
                      color: foreground.withValues(alpha: 0.74),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(
    String text,
    Color accent,
    bool isDark, {
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 2.5 : 3.5,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontSize: compact ? 10.0 : 11.0,
          fontWeight: FontWeight.w700,
          height: 1.45,
          color: accent,
        ),
      ),
    );
  }

  Widget _gapNote(BuildContext context, _TreeNode node, bool isDark) {
    const gold = Color(0xFFFBBF24);
    final background = Theme.of(context).cardColor;
    final foreground = background.contrastTextColor;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Color.lerp(background, gold, isDark ? 0.06 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: gold.withValues(alpha: isDark ? 0.38 : 0.42),
          ),
        ),
        child: Text(
          node.title,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontSize: 12 * widget.fontSizeFactor,
            fontWeight: FontWeight.w600,
            height: 1.7,
            color: foreground.withValues(alpha: 0.78),
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
    double spacing = 22,
  }) {
    final separated = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) separated.add(SizedBox(height: spacing));
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
    double a(double v) => v * (isDark ? 1.0 : 0.65);
    const slate = Color(0xFF94A3B8);
    const emerald = Color(0xFF34D399);
    const blue = Color(0xFF60A5FA);
    const gold = Color(0xFFFBBF24);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        slate.withValues(alpha: 0.0),
        emerald.withValues(alpha: a(0.55)),
        slate.withValues(alpha: a(0.48)),
        emerald.withValues(alpha: a(0.55)),
        blue.withValues(alpha: a(0.48)),
        gold.withValues(alpha: a(0.62)),
        gold.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.06, 0.28, 0.5, 0.74, 0.96, 1.0],
    );
  }

  LinearGradient _chainGradient(bool isDark) {
    double a(double v) => v * (isDark ? 1.0 : 0.65);
    const blue = Color(0xFF60A5FA);
    const gold = Color(0xFFFBBF24);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        blue.withValues(alpha: a(0.52)),
        blue.withValues(alpha: a(0.52)),
        gold.withValues(alpha: a(0.65)),
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
        .withValues(alpha: isDark ? 0.36 : 0.28);
    return LayoutBuilder(
      builder: (context, constraints) {
        final veryNarrow = constraints.maxWidth < 280;
        final compactCols = constraints.maxWidth < 480;
        final columns = [
          _branchColumn(
            context,
            isDark,
            branchA,
            lineColor,
            !veryNarrow,
            compactCols,
          ),
          _branchColumn(
            context,
            isDark,
            branchB,
            lineColor,
            !veryNarrow,
            compactCols,
          ),
        ];
        return Column(
          children: [
            if (!veryNarrow) ...[
              Container(
                width: 3,
                height: 22,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.52,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
            if (veryNarrow) ...[
              columns[0],
              const SizedBox(height: 18),
              columns[1],
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: columns[0]),
                  const SizedBox(width: 10),
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
    bool compactCols,
  ) {
    final children = <Widget>[];
    if (connectors) {
      children.add(
        Center(
          child: Container(
            width: 2.5,
            height: 20,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }
    for (var i = 0; i < nodes.length; i++) {
      if (i > 0) {
        children.add(
          Center(
            child: Container(
              width: 2.5,
              height: 18,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }
      children.add(
        _nodeCard(
          context,
          nodes[i],
          isDark,
          inBranch: compactCols,
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
        const SizedBox(width: 10),
        Flexible(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: purple.withValues(alpha: isDark ? 0.15 : 0.11),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: purple.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: purple.withValues(alpha: 0.32),
                  blurRadius: 20,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Text(
              marriage.title,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontSize: 12.5 * widget.fontSizeFactor,
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: isDark ? const Color(0xFFD8B4FE) : purple,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
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
    final lineColor = Theme.of(context)
        .cardColor
        .contrastTextColor
        .withValues(alpha: isDark ? 0.34 : 0.26);
    return LayoutBuilder(
      builder: (context, constraints) {
        final veryNarrow = constraints.maxWidth < 280;
        final compactCols = constraints.maxWidth < 480;
        final cards = [
          for (final node in nodes)
            _nodeCard(context, node, isDark, inBranch: compactCols),
        ];
        if (veryNarrow || cards.length == 1) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                cards[i],
              ],
            ],
          );
        }
        return Column(
          children: [
            Container(
              width: 2.5,
              height: 16,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.52,
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 2.5,
                        height: 14,
                        decoration: BoxDecoration(
                          color: lineColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      cards[0],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 2.5,
                        height: 14,
                        decoration: BoxDecoration(
                          color: lineColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      cards[1],
                    ],
                  ),
                ),
              ],
            ),
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
        const SizedBox(width: 12),
        Flexible(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: blue.withValues(alpha: isDark ? 0.11 : 0.09),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: blue.withValues(alpha: 0.36)),
            ),
            child: Text(
              'سلسلة الأئمة الاثني عشر',
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontSize: 13.5 * widget.fontSizeFactor,
                fontWeight: FontWeight.w700,
                color: isDark ? blue : const Color(0xFF2563EB),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: _nodeCard(
                context,
                node,
                isDark,
                extraTopPadding: node.step != null ? 10 : 0,
              ),
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
                          color:
                              ringColor.withValues(alpha: isDark ? 0.55 : 0.4),
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
        ),
      ),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Color.lerp(background, const Color(0xFF94A3B8), 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gold.withValues(alpha: isDark ? 0.28 : 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gold.withValues(alpha: 0.1),
                  gold,
                  gold.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ProphetsTreeScreen.supplementTitle,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 19 * widget.fontSizeFactor,
                    fontWeight: FontWeight.w800,
                    height: 1.55,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 18),
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: background.withValues(
                          alpha: isDark ? 0.55 : 0.75,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: foreground.withValues(
                            alpha: isDark ? 0.1 : 0.08,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '◆',
                              style: TextStyle(
                                fontSize: 9,
                                color: gold.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${entry.title}: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? gold
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                  TextSpan(
                                    text: entry.desc,
                                    style: TextStyle(
                                      color: foreground.withValues(alpha: 0.82),
                                    ),
                                  ),
                                ],
                              ),
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 13.5 * widget.fontSizeFactor,
                                height: 1.85,
                              ),
                            ),
                          ),
                        ],
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

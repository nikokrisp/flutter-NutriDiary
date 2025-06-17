import 'package:flutter/material.dart';
import 'package:flutter_nutridiary/data/model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_nutridiary/providers/item_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final itemProvider = Provider.of<ItemProvider>(context);
        final favoriteItems = itemProvider.favoriteFoodItems;
        final allInsightItems = itemProvider.allInsightItems;

        // Determine which insight items to show
        List<InsightItem> displayedInsightItems;
        if (favoriteItems.isEmpty) {
          // Show 3 random insight items if no favorite items
          displayedInsightItems = List.from(allInsightItems)..shuffle();
          displayedInsightItems = displayedInsightItems.take(3).toList();
        } else {
          // Show relevant insight items based on favorite items
          final favoriteFoodIds = favoriteItems.map((item) => item.foodId).toSet();
          displayedInsightItems = allInsightItems
              .where((insight) => favoriteFoodIds.contains(insight.foodId))
              .toList();
        }

        return Column(
          children: [
            Container(
              color: Theme.brightnessOf(context) == Brightness.light
                  ? Colors.white.withAlpha(200)
                  : Colors.black.withAlpha(200), // half-opaque background for dark mode
              height: constraints.maxHeight * 0.1,
              width: constraints.maxWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Insight',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    TextSpan(
                      text: '\nToday',
                      style: TextStyle(
                        color: theme.brightness == Brightness.light
                            ? Colors.grey[600]
                            : Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: displayedInsightItems.map((item) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withAlpha(225)
                              : Colors.black.withAlpha(225), // half-opaque background for dark mode
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: InsightItemWidget(item: item, invertColors: true),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1.25,
                        indent: 12,
                        endIndent: 12,
                        color: Color.fromARGB(255, 200, 200, 200),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class InsightItemWidget extends StatefulWidget {
  final InsightItem item;
  final bool invertColors;

  const InsightItemWidget({super.key, required this.item, this.invertColors = false});

  @override
  InsightItemWidgetState createState() => InsightItemWidgetState();
}

class InsightItemWidgetState extends State<InsightItemWidget> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _openLink() async {
    if (!await launchUrl(Uri.parse(widget.item.source), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch ${widget.item.source}');
    }
    ScaffoldMessenger.of(context.mounted ? context : context).showSnackBar(SnackBar(content: Text('Opening link...')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool invert = widget.invertColors;
    final Color mainTextColor = invert
        ? (theme.brightness == Brightness.light ? Colors.white : Colors.black)
        : theme.textTheme.bodyLarge?.color ?? Colors.black;
    final Color subTextColor = invert
        ? (theme.brightness == Brightness.light ? Colors.white70 : Colors.black87)
        : theme.textTheme.bodyMedium?.color ?? Colors.black54;
    final Color cardColor = invert
        ? (theme.brightness == Brightness.light ? Colors.black87.withAlpha(180) : Colors.white70.withAlpha(180))
        : theme.cardColor;
    final Color sourceColor = invert
        ? (theme.brightness == Brightness.light ? Colors.white : Colors.black)
        : const Color.fromARGB(255, 95, 95, 95);
    return GestureDetector(
      onTap: _toggleExpand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1) The top container (was the list tile)
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Center the title vertically
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(backgroundImage: AssetImage(widget.item.imageUrl), radius: 35),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8), // Remove top/bottom padding for true centering
                    child: Text(
                      widget.item.name,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainTextColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 2) The rest of the widgets in a column, with padding
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.description,
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: subTextColor),
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 5),
                  Text("Source: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: sourceColor)),
                  GestureDetector(
                    onTap: _openLink,
                    child: Text(
                      widget.item.source,
                      style: TextStyle(decoration: TextDecoration.underline, decorationColor: sourceColor, fontSize: 16, color: sourceColor),
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
}
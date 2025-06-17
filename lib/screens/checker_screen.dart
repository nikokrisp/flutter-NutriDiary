import 'package:flutter/material.dart';
import 'package:flutter_nutridiary/providers/app_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_nutridiary/providers/item_provider.dart';
import 'package:flutter_nutridiary/providers/page_index_provider.dart';

class CheckerScreen extends StatefulWidget {
  const CheckerScreen({super.key});

  @override
  CheckerScreenState createState() => CheckerScreenState();
}

class CheckerScreenState extends State<CheckerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<FoodItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    final foodProvider = Provider.of<ItemProvider>(context, listen: false);
    _filteredItems = foodProvider.allFoodItems; // Initialize with all items
    _searchController.addListener(_filterItems);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pageIndexProvider = Provider.of<PageIndexProvider>(context);
    if (pageIndexProvider.openSearchBar) {
      _searchFocusNode.requestFocus();
      pageIndexProvider.resetSearchBarTrigger();
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    setState(() {
      _filteredItems = itemProvider.allFoodItems
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showDetailsDialog(BuildContext context, FoodItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(item.imageUrl),
                  radius: 50,
                ),
                const SizedBox(height: 20),
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Nutritional Information (per 100g):",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Calories: ${item.calories} kcal",
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        Text(
                          "Sugar: ${item.sugar} g",
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        Text(
                          "Fat: ${item.fat} g",
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Carbohydrates: ${item.carbo} g",
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        Text(
                          "Protein: ${item.protein} g",
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        Text(
                          "Sodium: ${item.sodium} mg",
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              color:Color(0xFFFFEDCC).withAlpha(225),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color:Colors.black.withAlpha(20),
                    borderRadius: BorderRadius.circular(2.4),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        color: Colors.black.withAlpha(150),
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.black.withAlpha(150),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) {
                      _filterItems();
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: _filteredItems.map((item) {
                  final isFavorite = itemProvider.isFavoriteFood(item);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? Colors.black.withAlpha(60)
                                  : Colors.white.withAlpha(80),
                              width: 1.0,
                            ),
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text(item.description),
                            leading: CircleAvatar(backgroundImage: AssetImage(item.imageUrl)),
                            trailing: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                                size: 36,
                              ),
                              onPressed: () async {
                                final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
                                if (appStateProvider.isLoggedIn && appStateProvider.currentUserId != null) {
                                  itemProvider.toggleFavoriteFood(item);
                                }
                                setState(() {
                                  _filteredItems = itemProvider.allFoodItems
                                      .where((filteredItem) => filteredItem.name.toLowerCase().contains(_searchController.text.toLowerCase()))
                                      .toList();
                                });
                              },
                            ),
                            onTap: () => _showDetailsDialog(context, item),
                          ),
                        ),
                      ],
                    ),
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

class FoodItemWidget extends StatefulWidget {
  final FoodItem item;

  const FoodItemWidget({super.key, required this.item});

  @override
  FoodItemWidgetState createState() => FoodItemWidgetState();
}

class FoodItemWidgetState extends State<FoodItemWidget> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _showDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.item.imageUrl),
                  radius: 50,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.item.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.item.description,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(widget.item.name, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
      subtitle: GestureDetector(
        onTap: _showDetailsDialog,
        child: Text(
          widget.item.description,
          style: TextStyle(fontSize: 20, color: theme.textTheme.bodyMedium?.color),
        ),
      ),
      leading: CircleAvatar(backgroundImage: AssetImage(widget.item.imageUrl), radius: 50),
      trailing: InkWell(
        onTap: _toggleFavorite,
        child: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border_outlined,
          color: _isFavorite ? Colors.red : theme.iconTheme.color,
        ),
      ),
      tileColor: theme.cardColor,
      minVerticalPadding: 20,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_nutridiary/providers/page_index_provider.dart';
import 'package:flutter_nutridiary/providers/item_provider.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

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
    final pageIndexProvider = Provider.of<PageIndexProvider>(context);
    final favoriteItems = itemProvider.favoriteFoodItems;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: favoriteItems.isNotEmpty
                  ? ListView(
                      children: favoriteItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 1.6,
                                    color: Theme.of(context).dividerColor.withAlpha(123),
                                  ),
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: ListTile(
                                  title: Text(item.name),
                                  subtitle: Text(item.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                                  leading: CircleAvatar(backgroundImage: AssetImage(item.imageUrl), radius: 30),
                                  trailing: IconButton(
                                    icon: Icon(Icons.arrow_forward_ios, color: Theme.of(context).iconTheme.color),
                                    onPressed: () => _showDetailsDialog(context, item),
                                  ),
                                  onTap: () => _showDetailsDialog(context, item),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  minVerticalPadding: 16,
                                  dense: false,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withAlpha(204),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withAlpha(123),
                          ),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 32.0),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "There's no favorite food yet.",
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).brightness == Brightness.light
                                    ? Colors.black87
                                    : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                pageIndexProvider.setIndex(0); // Navigate to CheckerScreen
                                pageIndexProvider.triggerSearchBar(); // Trigger search bar
                              },
                              child: Text(
                                "Try adding a new food!",
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.blue,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class FavFoodItemWidget extends StatelessWidget {
  const FavFoodItemWidget({super.key, required this.item});

  final FoodItem item;

  void _showDetailsDialog(BuildContext context) {
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
                const SizedBox(height: 10),
                Text(
                  item.description,
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
      title: Text(item.name, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
      subtitle: GestureDetector(
        onTap: () => _showDetailsDialog(context),
        child: Text(
          item.description,
          style: TextStyle(fontSize: 20, color: theme.textTheme.bodyMedium?.color),
        ),
      ),
      leading: CircleAvatar(backgroundImage: AssetImage(item.imageUrl), radius: 50),
      trailing: IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color),
            onPressed: () => _showDetailsDialog(context),
          ),
      tileColor: theme.cardColor,
      minVerticalPadding: 20,
    );
  }
}
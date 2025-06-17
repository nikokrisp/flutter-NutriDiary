// for model assets

class FoodItem {
  final int foodId;
  final String name;
  final String description;
  final String imageUrl;
  final double calories;
  final double sugar;
  final double fat;
  final double carbo;
  final double protein;
  final double fiber;

  FoodItem({
    required this.foodId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.calories,
    required this.sugar,
    required this.fat,
    required this.carbo,
    required this.protein,
    required this.fiber,
  });
}

class InsightItem {
  final int foodId;
  final int insightId;
  final String name;
  final String description;
  final String imageUrl;
  final String source;

  InsightItem({
    required this.foodId,
    required this.insightId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.source,
  });
}
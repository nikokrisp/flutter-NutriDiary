import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/item_provider.dart';
import '../providers/daily_meal_provider.dart';

class AddAmountPlan extends StatefulWidget {
  final List<int> foodIds;
  final bool hasPlan; // <-- Add this
  const AddAmountPlan({super.key, required this.foodIds, required this.hasPlan});

  @override
  State<AddAmountPlan> createState() => _AddAmountPlanState();
}

class _AddAmountPlanState extends State<AddAmountPlan> {
  final Map<int, int> amounts = {};

  @override
  void initState() {
    super.initState();
    for (var id in widget.foodIds) {
      amounts[id] = 0;
    }
  }

  bool get allFilled => amounts.length == widget.foodIds.length && amounts.values.every((v) => v > 0);

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final dailyMealProvider = Provider.of<DailyMealProvider>(context, listen: false);
    final items = itemProvider.allFoodItems.where((item) => widget.foodIds.contains(item.foodId)).toList();
    return Scaffold(
      appBar: AppBar(title: Text("Add the Food Amounts")),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final item = items[idx];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade200,
                        child: ClipOval(
                          child: Image.asset(item.imageUrl, width: 54, height: 54, fit: BoxFit.cover),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(item.name, style: TextStyle(fontSize: 20)),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  onPressed: (amounts[item.foodId] ?? 0) >= 99
                                      ? null
                                      : () {
                                          setState(() {
                                            if ((amounts[item.foodId] ?? 0) < 99) {
                                              amounts[item.foodId] = (amounts[item.foodId] ?? 0) + 1;
                                            }
                                          });
                                        },
                                ),
                                SizedBox(
                                  width: 28,
                                  child: _AmountInputField(
                                    value: amounts[item.foodId] ?? 0,
                                    onChanged: (n) {
                                      setState(() {
                                        amounts[item.foodId] = n;
                                      });
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  onPressed: (amounts[item.foodId] ?? 0) <= 0
                                      ? null
                                      : () {
                                          setState(() {
                                            if ((amounts[item.foodId] ?? 0) > 0) {
                                              amounts[item.foodId] = (amounts[item.foodId] ?? 1) - 1;
                                            }
                                          });
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            height: 80,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(220, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: allFilled
                      ? Colors.green
                      : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                onPressed: allFilled
                    ? () async {
                        if (widget.hasPlan) {
                          // Remove SharedPreferences cache for today
                          final prefs = await SharedPreferences.getInstance();
                          final today = DateTime.now();
                          final todayKey = "tempDailyItems_${today.year}_${today.month}_${today.day}";
                          await prefs.remove(todayKey);
                          await prefs.remove('tempDailyItems_lastFetched');
                          await dailyMealProvider.clearDailyItems();
                        }
                        for (var entry in amounts.entries) {
                          await dailyMealProvider.postDailyItem(
                            DailyItem(foodId: entry.key, amount: entry.value),
                          );
                        }
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).popUntil((route) => route.isFirst); // Pop with result to trigger refresh
                        }
                      }
                    : null,
                child: Text("Create the Plan!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreatePlanPage extends StatefulWidget {
  final bool hasPlan;

  const CreatePlanPage({super.key, required this.hasPlan});

  @override
  State<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage> {
  bool allFoodExpanded = true;
  bool yourFoodExpanded = true;
  final Set<int> checkedFoodIds = {};

  void toggleAllFood() {
    setState(() {
      allFoodExpanded = !allFoodExpanded;
    });
  }

  void toggleYourFood() {
    setState(() {
      yourFoodExpanded = !yourFoodExpanded;
    });
  }

  void clearChecked() {
    setState(() {
      checkedFoodIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final allFoodItems = itemProvider.allFoodItems;
    final favoriteFoodItems = itemProvider.favoriteFoodItems;
    final checkedList = allFoodItems.where((item) => checkedFoodIds.contains(item.foodId)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(
        widget.hasPlan
          ? "Change your Daily Plan"
          : "Create a Daily Plan"
      )),
      body: Column(
        children: [
          // Top scrollable part
          Expanded(
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.grey[200],
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // All Food Section
                    GestureDetector(
                      onTap: toggleAllFood,
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("All Food", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Icon(allFoodExpanded ? Icons.expand_less : Icons.expand_more),
                          ],
                        ),
                      ),
                    ),
                    if (allFoodExpanded)
                      Column(
                        children: allFoodItems.map((item) => GestureDetector(
                          onTap: () {
                            setState(() {
                              if (checkedFoodIds.contains(item.foodId)) {
                                checkedFoodIds.remove(item.foodId);
                              } else {
                                checkedFoodIds.add(item.foodId);
                              }
                            });
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.grey.shade200,
                              child: ClipOval(
                                child: Image.asset(item.imageUrl, width: 44, height: 44, fit: BoxFit.cover),
                              ),
                            ),
                            title: Text(item.name),
                            trailing: Checkbox(
                              value: checkedFoodIds.contains(item.foodId),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    checkedFoodIds.add(item.foodId);
                                  } else {
                                    checkedFoodIds.remove(item.foodId);
                                  }
                                });
                              },
                            ),
                          ),
                        )).toList(),
                      ),
                    // Your Food Section
                    GestureDetector(
                      onTap: toggleYourFood,
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Your Food", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Icon(yourFoodExpanded ? Icons.expand_less : Icons.expand_more),
                          ],
                        ),
                      ),
                    ),
                    if (yourFoodExpanded)
                      Column(
                        children: favoriteFoodItems.map((item) => GestureDetector(
                          onTap: () {
                            setState(() {
                              if (checkedFoodIds.contains(item.foodId)) {
                                checkedFoodIds.remove(item.foodId);
                              } else {
                                checkedFoodIds.add(item.foodId);
                              }
                            });
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.grey.shade200,
                              child: ClipOval(
                                child: Image.asset(item.imageUrl, width: 44, height: 44, fit: BoxFit.cover),
                              ),
                            ),
                            title: Text(item.name),
                            trailing: Checkbox(
                              value: checkedFoodIds.contains(item.foodId),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    checkedFoodIds.add(item.foodId);
                                  } else {
                                    checkedFoodIds.remove(item.foodId);
                                  }
                                });
                              },
                            ),
                          ),
                        )).toList(),
                      ),
                    const SizedBox(height: 80), // leave space for the bar
                  ],
                ),
              ),
            ),
          ),
          // Bottom bar (static height, always present)
          Container(
            height: 80,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surface,
            child: checkedList.isNotEmpty
                ? Row(
                    children: [
                      GestureDetector(
                        onTap: clearChecked,
                        child: Row(
                          children: [
                            Icon(Icons.close, color: Theme.of(context).colorScheme.error, size: 30),
                            SizedBox(width: 16),
                            Text('${checkedList.length}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          ],
                        ),
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddAmountPlan(foodIds: checkedList.map((e) => e.foodId).toList(), hasPlan: widget.hasPlan)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary),
                        ),
                      ),
                    ],
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _AmountInputField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _AmountInputField({required this.value, required this.onChanged});

  @override
  State<_AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<_AmountInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _AmountInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value.toString() != _controller.text) {
      _controller.text = widget.value.toString();
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 2,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        border: OutlineInputBorder(),
      ),
      onChanged: (val) {
        if (val.isEmpty) {
          widget.onChanged(0);
          _controller.text = '0';
          _controller.selection = TextSelection.fromPosition(TextPosition(offset: 1));
          return;
        }
        if (val.length > 2) {
          _controller.text = val.substring(0, 2);
          _controller.selection = TextSelection.fromPosition(TextPosition(offset: 2));
          return;
        }
        final n = int.tryParse(val) ?? 0;
        if (n >= 0 && n <= 99) {
          widget.onChanged(n);
        }
      },
      onFieldSubmitted: (_) {
        // Do not unfocus
        _focusNode.unfocus();
      },
    );
  }
}

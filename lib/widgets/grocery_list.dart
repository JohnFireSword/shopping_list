import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_max/data/categories.dart';
import 'package:shopping_max/models/category.dart';

import 'package:shopping_max/models/grocery_item.dart';
import 'package:shopping_max/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'shopping-app-cb4cf-default-rtdb.firebaseio.com', 'shopping-list.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch grocery items. Please try again later.');
    }

    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _loadedItems = _loadItems();
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https('shopping-app-cb4cf-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      // Optional: Show error message
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (snapshot.hasData) {
            _groceryItems = snapshot.data!; // Store the fetched list
          }

          if (_groceryItems.isEmpty) {
            return const Center(child: Text('No items added yet.'));
          }

          return ListView.builder(
            itemCount: _groceryItems.length,
            itemBuilder: (ctx, index) => Dismissible(background: Container(color: Colors.red,),direction: DismissDirection.endToStart,
              key: ValueKey(_groceryItems[index].id),
              onDismissed: (direction) {
                _removeItem(_groceryItems[index]);
              },
              child: ListTile(
                title: Text(_groceryItems[index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: _groceryItems[index].category.color,
                ),
                trailing: Text(_groceryItems[index].quantity.toString()),
              ),
            ),
          );
        },
      ),
    );
  }
}

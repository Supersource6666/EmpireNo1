import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/feedback_service.dart';
import '../services/food_storage_service.dart';

class CustomFoodPage extends StatefulWidget {
  const CustomFoodPage({super.key});

  @override
  State<CustomFoodPage> createState() => _CustomFoodPageState();
}

class _CustomFoodPageState extends State<CustomFoodPage> {
  List<FoodItem> _foods = [];
  bool _isLoading = true;
  bool _showTableView = false;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    try {
      final foods = await FoodStorageService.loadFoodsFromFile();
      setState(() {
        _foods = foods;
        _isLoading = false;
      });
      // print('✅ 加载自定义美食: ${foods.length} 个');
    } catch (e) {
      print('❌ Error loading foods: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFoods() async {
    try {
      await FoodStorageService.saveFoodsToFile(_foods);
      FeedbackService.playSuccessSound();
      FeedbackService.successVibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
    } catch (e) {
      print('Error saving foods: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败')),
      );
    }
  }

  void _deleteFood(int index) async {
    final food = _foods[index];
    setState(() {
      _foods.removeAt(index);
    });
    await _saveFoods();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除 "${food.name}"'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            setState(() {
              _foods.insert(index, food);
            });
            await _saveFoods();
          },
        ),
      ),
    );
  }

  void _addFood(FoodItem food) async {
    setState(() {
      _foods.add(food);
    });
    await _saveFoods();
  }

  void _showAddFoodDialog() {
    final nameController = TextEditingController();
    final emojiController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加新美食'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '美食名称'),
              ),
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(labelText: '表情符号'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: '分类'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  emojiController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写必要信息')),
                );
                return;
              }

              final newFood = FoodItem(
                name: nameController.text,
                emoji: emojiController.text,
                category: categoryController.text,
                description: descriptionController.text,
              );

              _addFood(newFood);
              Navigator.pop(context);
              FeedbackService.playSuccessSound();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_foods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无自定义美食',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showAddFoodDialog,
              child: const Text('添加第一个美食'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _foods.length,
      itemBuilder: (context, index) {
        final food = _foods[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Text(
              food.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            title: Text(
              food.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.category),
                const SizedBox(height: 4),
                Text(
                  food.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteFood(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              '共 ${_foods.length} 个美食',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_foods.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('暂无美食数据'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('序号')),
                    DataColumn(label: Text('表情')),
                    DataColumn(label: Text('名称')),
                    DataColumn(label: Text('分类')),
                    DataColumn(label: Text('描述')),
                    DataColumn(label: Text('操作')),
                  ],
                  rows: List<DataRow>.generate(
                    _foods.length,
                    (index) {
                      final food = _foods[index];
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(
                            food.emoji,
                            style: const TextStyle(fontSize: 20),
                          )),
                          DataCell(Text(food.name)),
                          DataCell(Text(food.category)),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Text(
                                food.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: '删除',
                              onPressed: () => _deleteFood(index),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义美食'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_showTableView ? Icons.list : Icons.table_chart),
            tooltip: _showTableView ? '切换列表视图' : '切换表格视图',
            onPressed: () {
              setState(() {
                _showTableView = !_showTableView;
              });
            },
          ),
          if (_foods.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: '清空所有',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认清空'),
                    content: const Text('确定要清空所有自定义美食吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FoodStorageService.clearCustomFoods();
                          setState(() {
                            _foods.clear();
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已清空所有自定义美食')),
                          );
                        },
                        child: const Text('清空', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showTableView
              ? _buildTableView()
              : _buildListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFoodDialog,
        tooltip: '添加美食',
        child: const Icon(Icons.add),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/food_item.dart';
import '../services/food_storage_service.dart';
import '../services/feedback_service.dart';

class CustomFoodPage extends StatefulWidget {
  const CustomFoodPage({Key? key}) : super(key: key);

  @override
  State<CustomFoodPage> createState() => _CustomFoodPageState();
}

class _CustomFoodPageState extends State<CustomFoodPage> {
  List<FoodItem> _customFoods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomFoods();
  }

  Future<void> _loadCustomFoods() async {
    final foods = await FoodStorageService.getCustomFoods();
    setState(() {
      _customFoods = foods;
      _isLoading = false;
    });
  }

  Future<String> _getStoragePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/custom_foods.txt';
    } catch (e) {
      return '无法获取路径';
    }
  }

  Future<void> _addFood() async {
    final result = await showDialog<FoodItem>(
      context: context,
      builder: (context) => const AddFoodDialog(),
    );

    if (result != null) {
      await FoodStorageService.saveCustomFood(result);
      FeedbackService.playSuccessSound();
      FeedbackService.successVibrate();
      _loadCustomFoods();
    }
  }

  Future<void> _deleteFood(FoodItem food) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${food.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final index = _customFoods.indexOf(food);
      await FoodStorageService.deleteCustomFood(index);
      FeedbackService.playClickSound();
      FeedbackService.lightVibrate();
      _loadCustomFoods();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义美食'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '查看存储位置',
            onPressed: () async {
              final filePath = await _getStoragePath();
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('存储位置'),
                    content: SelectableText(
                      '自定义美食保存在：\n\n$filePath',
                      style: const TextStyle(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('使用说明'),
                  content: const Text(
                    '• 点击右下角"+"按钮添加新美食\n'
                    '• 滑动删除已添加的美食\n'
                    '• 自定义美食会在所有抽签模式中显示\n'
                    '• 自定义美食自动保存到txt文件',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('知道了'),
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
          : _customFoods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '还没有自定义美食',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '点击右下角"+"按钮添加',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _customFoods.length,
                  itemBuilder: (context, index) {
                    final food = _customFoods[index];
                    return Dismissible(
                      key: Key(food.name + food.emoji),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认删除'),
                            content: Text('确定要删除 "${food.name}" 吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  '删除',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        await FoodStorageService.deleteCustomFood(index);
                        FeedbackService.playClickSound();
                        FeedbackService.lightVibrate();
                        setState(() {
                          _customFoods.removeAt(index);
                        });
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: Text(
                            food.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                          title: Text(
                            food.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${food.category} • ${food.description}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFood,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddFoodDialog extends StatefulWidget {
  const AddFoodDialog({Key? key}) : super(key: key);

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final food = FoodItem(
        name: _nameController.text.trim(),
        emoji: _emojiController.text.trim(),
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      Navigator.pop(context, food);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加美食'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '例如：麻辣烫',
                  prefixIcon: Icon(Icons.restaurant),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入美食名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emojiController,
                decoration: const InputDecoration(
                  labelText: 'Emoji',
                  hintText: '例如：🍜',
                  prefixIcon: Icon(Icons.emoji_emotions),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入一个Emoji表情';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: '分类',
                  hintText: '例如：中餐',
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入美食分类';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  hintText: '例如：辣味十足，暖心暖胃',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入美食描述';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('添加'),
        ),
      ],
    );
  }
}

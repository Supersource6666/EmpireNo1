import 'package:flutter/material.dart';

class ScheduleHelperPage extends StatefulWidget {
  const ScheduleHelperPage({super.key});

  @override
  State<ScheduleHelperPage> createState() => _ScheduleHelperPageState();
}

class _ScheduleHelperPageState extends State<ScheduleHelperPage> {
  final List<Map<String, dynamic>> todos = [];
  final TextEditingController _controller = TextEditingController();
  String _selectedPerson = 'A';

  void _addTodo() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      todos.add({
        'task': _controller.text.trim(),
        'person': _selectedPerson,
        'done': false,
      });
      _controller.clear();
    });
  }

  void _toggleDone(int index) {
    setState(() {
      todos[index]['done'] = !todos[index]['done'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日程助手')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: '输入待办事项...'),
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedPerson,
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('人员A')),
                    DropdownMenuItem(value: 'B', child: Text('人员B')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPerson = v);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTodo,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return ListTile(
                  leading: Checkbox(
                    value: todo['done'],
                    onChanged: (_) => _toggleDone(index),
                  ),
                  title: Text(
                    todo['task'],
                    style: TextStyle(
                      decoration: todo['done'] ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text('分工：人员${todo['person']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        todos.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

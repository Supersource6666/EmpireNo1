import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/schedule_service.dart';
import 'package:uuid/uuid.dart';

class ScheduleHelperPage extends StatefulWidget {
  const ScheduleHelperPage({super.key});

  @override
  State<ScheduleHelperPage> createState() => _ScheduleHelperPageState();
}

class _ScheduleHelperPageState extends State<ScheduleHelperPage> {
  late ScheduleService _scheduleService;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  final List<String> _assignees = ['人员A', '人员B', '人员C', '人员D'];
  final List<String> _priorities = ['高', '中', '低'];
  String _selectedAssignee = '人员A';
  String _selectedPriority = '中';
  String _filterAssignee = '';
  String _filterPriority = '';
  bool _showCompleted = true;
  int _currentTabIndex = 0;
  bool _useChineseLocale = true;

  @override
  void initState() {
    super.initState();
    _scheduleService = ScheduleService();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _scheduleService.init();
    setState(() {});
  }

  String _formatDate(DateTime date) {
    if (_useChineseLocale) {
      final months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
      return '${date.year}年${months[date.month - 1]}${date.day}日';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  String _formatMonthYear(DateTime date) {
    if (_useChineseLocale) {
      final months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
      return '${date.year}年${months[date.month - 1]}';
    } else {
      return DateFormat('MMMM yyyy').format(date);
    }
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedAssignee = _selectedAssignee;
    String selectedPriority = _selectedPriority;
    ScheduleTime? selectedTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加新事件'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedAssignee,
                decoration: const InputDecoration(
                  labelText: 'Assignee',
                  border: OutlineInputBorder(),
                ),
                items: _assignees.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => selectedAssignee = v ?? selectedAssignee,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => selectedPriority = v ?? selectedPriority,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  selectedTime == null
                      ? '选择时间'
                      : '时间: ${selectedTime.toString()}',
                ),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    selectedTime = ScheduleTime(hour: time.hour, minute: time.minute);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title cannot be empty')),
                );
                return;
              }

              final event = ScheduleEvent(
                id: const Uuid().v4(),
                date: _selectedDate,
                title: titleController.text.trim(),
                description: descController.text.trim(),
                assignee: selectedAssignee,
                priority: selectedPriority.toLowerCase(),
                time: selectedTime,
              );

              await _scheduleService.addEvent(event);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEventDetailsDialog(ScheduleEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${DateFormat('MMM dd, yyyy').format(event.date)}'),
              if (event.time != null)
                Text('Time: ${event.time.toString()}'),
              const SizedBox(height: 12),
              Text('Assignee: ${event.assignee}'),
              Text('Priority: ${event.priority.substring(0, 1).toUpperCase()}${event.priority.substring(1)}'),
              Text('Status: ${event.completed ? 'Completed' : 'Pending'}'),
              const SizedBox(height: 12),
              if (event.description.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(event.description),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _scheduleService.deleteEvent(event.id);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              final updated = event.copyWith(completed: !event.completed);
              await _scheduleService.updateEvent(updated);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: Text(event.completed ? 'Mark Pending' : 'Mark Completed'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<ScheduleEvent> _getFilteredEvents() {
    var events = _scheduleService.getEventsForDate(_selectedDate);

    if (!_showCompleted) {
      events = events.where((e) => !e.completed).toList();
    }

    if (_filterAssignee.isNotEmpty) {
      events = events.where((e) => e.assignee == _filterAssignee).toList();
    }

    if (_filterPriority.isNotEmpty) {
      events = events.where((e) => e.priority == _filterPriority.toLowerCase()).toList();
    }

    return events;
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        Container(
          color: Colors.blue.shade50,
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildDayHeaderRow(),
                  _buildCalendarGrid(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeaderRow() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: days.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final year = _focusedDate.year;
    final month = _focusedDate.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingDayOfWeek = firstDay.weekday % 7;

    final days = <Widget>[];

    // 添加空白占位符
    for (int i = 0; i < startingDayOfWeek; i++) {
      days.add(Container());
    }

    // 添加日期
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final eventCount = _scheduleService.getEventCountForDate(date);
      final completedCount = _scheduleService.getCompletedCountForDate(date);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;

      days.add(
        GestureDetector(
          onTap: () {
            setState(() => _selectedDate = date);
          },
          onLongPress: () {
            setState(() => _selectedDate = date);
            _showAddEventDialog();
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.toString(),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    if (eventCount > 0)
                      Text(
                        '$completedCount/$eventCount',
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? Colors.white70 : Colors.grey,
                        ),
                      ),
                  ],
                ),
                if (eventCount > 0 && !isSelected)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: eventCount == completedCount ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        eventCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: days,
    );
  }

  Widget _buildEventsListView() {
    final filteredEvents = _getFilteredEvents();

    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No events for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Checkbox(
              value: event.completed,
              onChanged: (_) async {
                final updated = event.copyWith(completed: !event.completed);
                await _scheduleService.updateEvent(updated);
                setState(() {});
              },
            ),
            title: Text(
              event.title,
              style: TextStyle(
                decoration: event.completed ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${event.assignee} • ${event.priority.toUpperCase()}'),
                if (event.time != null)
                  Text('Time: ${event.time.toString()}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Details'),
                  onTap: () => _showEventDetailsDialog(event),
                ),
                PopupMenuItem(
                  child: const Text('Delete'),
                  onTap: () async {
                    await _scheduleService.deleteEvent(event.id);
                    setState(() {});
                  },
                ),
              ],
            ),
            onTap: () => _showEventDetailsDialog(event),
          ),
        );
      },
    );
  }

  Widget _buildStatsView() {
    final allEvents = _scheduleService.events;
    final completedEvents = _scheduleService.getCompletedEvents();
    final pendingEvents = _scheduleService.getPendingEvents();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '总体统计',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('事件总计', allEvents.length.toString(), Colors.blue),
                        _buildStatItem('已完成', completedEvents.length.toString(), Colors.green),
                        _buildStatItem('待处理', pendingEvents.length.toString(), Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '按负责人',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...?_assignees.map((assignee) {
              final count = _scheduleService.getEventsByAssignee(assignee).length;
              return ListTile(
                title: Text(assignee),
                trailing: Text(count.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              '按优先级',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._priorities.map((priority) {
              final count = _scheduleService.getEventsByPriority(priority.toLowerCase()).length;
              return ListTile(
                title: Text(priority),
                trailing: Text(count.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日程助手'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(12),
            child: Text(
              'Selected: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildCalendarView(),
                _buildEventsListView(),
                _buildStatsView(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '日历',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '事件',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '统计',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

Widget _buildStatItem(String label, String value, Color color) {
  return Column(
    children: [
      Text(
        value,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}


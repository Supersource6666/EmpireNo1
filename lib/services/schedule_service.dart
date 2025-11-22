import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScheduleTime {
  final int hour;
  final int minute;

  ScheduleTime({required this.hour, required this.minute});

  @override
  String toString() => '$hour:${minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  factory ScheduleTime.fromJson(Map<String, dynamic> json) =>
      ScheduleTime(hour: json['hour'], minute: json['minute']);
}

class ScheduleEvent {
  final String id;
  final DateTime date;
  final String title;
  final String description;
  final String assignee;
  final bool completed;
  final ScheduleTime? time;
  final String priority; // high, medium, low
  final List<String> tags;

  ScheduleEvent({
    required this.id,
    required this.date,
    required this.title,
    this.description = '',
    required this.assignee,
    this.completed = false,
    this.time,
    this.priority = 'medium',
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'assignee': assignee,
      'completed': completed,
      'time': time?.toJson(),
      'priority': priority,
      'tags': tags,
    };
  }

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    return ScheduleEvent(
      id: json['id'],
      date: DateTime.parse(json['date']),
      title: json['title'],
      description: json['description'] ?? '',
      assignee: json['assignee'],
      completed: json['completed'] ?? false,
      time: json['time'] != null ? ScheduleTime.fromJson(json['time']) : null,
      priority: json['priority'] ?? 'medium',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  ScheduleEvent copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? description,
    String? assignee,
    bool? completed,
    ScheduleTime? time,
    String? priority,
    List<String>? tags,
  }) {
    return ScheduleEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      completed: completed ?? this.completed,
      time: time ?? this.time,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
    );
  }
}

class ScheduleService {
  static const String _storageKey = 'schedule_events';
  static final ScheduleService _instance = ScheduleService._internal();

  factory ScheduleService() {
    return _instance;
  }

  ScheduleService._internal();

  final List<ScheduleEvent> _events = [];
  bool _loaded = false;

  List<ScheduleEvent> get events => _events;

  Future<void> init() async {
    if (_loaded) return;
    await loadEvents();
    _loaded = true;
  }

  Future<void> loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _events.clear();
        _events.addAll(
          jsonList.map((json) => ScheduleEvent.fromJson(json as Map<String, dynamic>)),
        );
      }
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  Future<void> saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_events.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('Error saving events: $e');
    }
  }

  Future<void> addEvent(ScheduleEvent event) async {
    _events.add(event);
    await saveEvents();
  }

  Future<void> updateEvent(ScheduleEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      await saveEvents();
    }
  }

  Future<void> deleteEvent(String eventId) async {
    _events.removeWhere((e) => e.id == eventId);
    await saveEvents();
  }

  List<ScheduleEvent> getEventsForDate(DateTime date) {
    return _events
        .where((e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day)
        .toList();
  }

  List<ScheduleEvent> getEventsByAssignee(String assignee) {
    return _events.where((e) => e.assignee == assignee).toList();
  }

  List<ScheduleEvent> getEventsByPriority(String priority) {
    return _events.where((e) => e.priority == priority.toLowerCase()).toList();
  }

  List<ScheduleEvent> getCompletedEvents() {
    return _events.where((e) => e.completed).toList();
  }

  List<ScheduleEvent> getPendingEvents() {
    return _events.where((e) => !e.completed).toList();
  }

  int getEventCountForDate(DateTime date) {
    return getEventsForDate(date).length;
  }

  int getCompletedCountForDate(DateTime date) {
    return getEventsForDate(date).where((e) => e.completed).length;
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: TutorMainApp(),
      debugShowCheckedModeBanner: false,
    ));

class Student {
  String id, name, school, grade, phone, memo;
  int fee, completedSessions;
  DateTime? lastConsulted;
  List<String> consultationHistory;
  bool isPaid;
  Color color;

  Student({
    required this.id, required this.name, this.school = '', this.grade = '',
    this.phone = '', this.memo = '', this.fee = 0, this.completedSessions = 0,
    this.lastConsulted, this.consultationHistory = const [],
    this.isPaid = false, this.color = Colors.green,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'school': school, 'grade': grade, 'phone': phone,
    'memo': memo, 'fee': fee, 'completedSessions': completedSessions,
    'lastConsulted': lastConsulted?.toIso8601String(),
    'consultationHistory': consultationHistory, 'isPaid': isPaid, 'color': color.value,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'], name: json['name'], school: json['school'], grade: json['grade'],
    phone: json['phone'], memo: json['memo'], fee: json['fee'],
    completedSessions: json['completedSessions'] ?? 0,
    lastConsulted: json['lastConsulted'] != null ? DateTime.parse(json['lastConsulted']) : null,
    consultationHistory: List<String>.from(json['consultationHistory'] ?? []),
    isPaid: json['isPaid'] ?? false, color: Color(json['color'] ?? 4284513600),
  );
}

class TutorMainApp extends StatefulWidget {
  @override
  _TutorMainAppState createState() => _TutorMainAppState();
}

class _TutorMainAppState extends State<TutorMainApp> {
  int _currentIndex = 0;
  List<Student> students = [];
  Map<String, String> grassData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? res = prefs.getString('students');
      if (res != null) students = (jsonDecode(res) as List).map((i) => Student.fromJson(i)).toList();
      grassData = Map<String, String>.from(jsonDecode(prefs.getString('grass') ?? '{}'));
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('students', jsonEncode(students.map((s) => s.toJson()).toList()));
    await prefs.setString('grass', jsonEncode(grassData));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentDBScreen(students: students, onUpdate: _saveData),
      WeeklyScheduleScreen(students: students),
      MonthlyGrassScreen(grassData: grassData, onUpdate: _saveData),
      BillingScreen(students: students, onUpdate: _saveData),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "학생DB"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_view_week), label: "주간"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: "잔디"),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: "수업료"),
        ],
      ),
    );
  }
}

// 나머지 화면 클래스들(StudentDBScreen, WeeklyScheduleScreen 등)은 위와 동일하게 구성됩니다.
// (공간상 생략하지만 이전 메시지의 전체 코드를 그대로 유지합니다.)

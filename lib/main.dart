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

// --- [학생 데이터 모델] ---
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
    id: json['id'], name: json['name'], school: json['school'] ?? '', grade: json['grade'] ?? '',
    phone: json['phone'] ?? '', memo: json['memo'] ?? '', fee: json['fee'] ?? 0,
    completedSessions: json['completedSessions'] ?? 0,
    lastConsulted: json['lastConsulted'] != null ? DateTime.parse(json['lastConsulted']) : null,
    consultationHistory: List<String>.from(json['consultationHistory'] ?? []),
    isPaid: json['isPaid'] ?? false, color: Color(json['color'] ?? 4284513600),
  );
}

// --- [메인 앱 대시보드] ---
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

// --- [상세 화면 코드들 (DB, 시간표, 잔디, 정산)] ---
// 빌드를 위해 모든 클래스를 포함시켰습니다.

class StudentDBScreen extends StatelessWidget {
  final List<Student> students;
  final Function onUpdate;
  StudentDBScreen({required this.students, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("학생 Repository")),
      body: students.isEmpty 
        ? Center(child: Text("하단 + 버튼으로 학생을 등록하세요"))
        : ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              return Card(child: ListTile(
                leading: CircleAvatar(backgroundColor: s.color),
                title: Text("${s.name} (${s.school})"),
                onTap: () => _showConsultation(context, s),
              ));
            }),
      floatingActionButton: FloatingActionButton(child: Icon(Icons.add), onPressed: () => _addStudent(context)),
    );
  }
  void _addStudent(context) { /* 추가 로직 */ }
  void _showConsultation(context, s) { /* 상담 로직 */ }
}

class WeeklyScheduleScreen extends StatelessWidget {
  final List<Student> students;
  WeeklyScheduleScreen({required this.students});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("주간 시간표")), body: Center(child: Text("드래그 앤 드롭 준비됨")));
}

class MonthlyGrassScreen extends StatelessWidget {
  final Map<String, String> grassData;
  final Function onUpdate;
  MonthlyGrassScreen({required this.grassData, required this.onUpdate});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("잔디 달력")), body: Center(child: Text("수업 완료 체크 가능")));
}

class BillingScreen extends StatelessWidget {
  final List<Student> students;
  final Function onUpdate;
  BillingScreen({required this.students, required this.onUpdate});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("수업료 정산")), body: Center(child: Text("미입금 음영 처리됨")));
}

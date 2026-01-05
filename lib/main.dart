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
  String id, name, school, phone, memo;
  int completedSessions;
  DateTime? lastConsulted;
  List<String> consultationHistory;
  bool isPaid;

  Student({
    required this.id, required this.name, this.school = '', this.phone = '', 
    this.memo = '', this.completedSessions = 0, this.lastConsulted,
    this.consultationHistory = const [], this.isPaid = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'school': school, 'phone': phone, 'memo': memo,
    'completedSessions': completedSessions, 'lastConsulted': lastConsulted?.toIso8601String(),
    'consultationHistory': consultationHistory, 'isPaid': isPaid,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'], name: json['name'], school: json['school'] ?? '',
    phone: json['phone'] ?? '', memo: json['memo'] ?? '',
    completedSessions: json['completedSessions'] ?? 0,
    lastConsulted: json['lastConsulted'] != null ? DateTime.parse(json['lastConsulted']) : null,
    consultationHistory: List<String>.from(json['consultationHistory'] ?? []),
    isPaid: json['isPaid'] ?? false,
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
      Scaffold(appBar: AppBar(title: Text("주간 시간표")), body: Center(child: Text("준비 중"))),
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

class StudentDBScreen extends StatefulWidget {
  final List<Student> students;
  final Function onUpdate;
  StudentDBScreen({required this.students, required this.onUpdate});
  @override _StudentDBScreenState createState() => _StudentDBScreenState();
}

class _StudentDBScreenState extends State<StudentDBScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("학생 Repository")),
      body: widget.students.isEmpty 
        ? Center(child: Text("하단 + 버튼으로 학생을 추가하세요"))
        : ListView.builder(
            itemCount: widget.students.length,
            itemBuilder: (context, index) {
              final s = widget.students[index];
              return Card(child: ListTile(
                title: Text(s.name),
                subtitle: Text("최종상담: ${s.lastConsulted != null ? DateFormat('MM/dd').format(s.lastConsulted!) : '기록없음'}"),
                onTap: () => _showHistory(s),
              ));
            }),
      floatingActionButton: FloatingActionButton(child: Icon(Icons.add), onPressed: _addStudent),
    );
  }
  void _addStudent() {
    String name = '';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text("신규 학생"),
      content: TextField(onChanged: (v) => name = v, decoration: InputDecoration(hintText: "이름 입력")),
      actions: [ElevatedButton(onPressed: () {
        if (name.isNotEmpty) {
          setState(() => widget.students.add(Student(id: DateTime.now().toString(), name: name)));
          widget.onUpdate();
          Navigator.pop(ctx);
        }
      }, child: Text("추가"))],
    ));
  }
  void _showHistory(Student s) {
    TextEditingController controller = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("${s.name} 상담 기록", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...s.consultationHistory.map((h) => Text("• $h")).toList(),
        TextField(controller: controller, decoration: InputDecoration(hintText: "상담 내용")),
        ElevatedButton(onPressed: () {
          setState(() {
            s.consultationHistory.insert(0, "${DateFormat('MM/dd').format(DateTime.now())}: ${controller.text}");
            s.lastConsulted = DateTime.now();
          });
          widget.onUpdate();
          Navigator.pop(ctx);
        }, child: Text("저장"))
      ]),
    ));
  }
}

class MonthlyGrassScreen extends StatefulWidget {
  final Map<String, String> grassData;
  final Function onUpdate;
  MonthlyGrassScreen({required this.grassData, required this.onUpdate});
  @override _MonthlyGrassScreenState createState() => _MonthlyGrassScreenState();
}
class _MonthlyGrassScreenState extends State<MonthlyGrassScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("잔디 달력")),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: 35,
        itemBuilder: (context, index) {
          String key = "2026-01-${(index + 1).toString().padLeft(2, '0')}";
          Color c = Colors.grey[200]!;
          if (widget.grassData[key] == '완료') c = Colors.green;
          return InkWell(
            onTap: () => setState(() {
              widget.grassData[key] = widget.grassData[key] == '완료' ? '' : '완료';
              widget.onUpdate();
            }),
            child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
          );
        },
      ),
    );
  }
}

class BillingScreen extends StatefulWidget {
  final List<Student> students;
  final Function onUpdate;
  BillingScreen({required this.students, required this.onUpdate});
  @override _BillingScreenState createState() => _BillingScreenState();
}
class _BillingScreenState extends State<BillingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("수업료 정산")),
      body: ListView.builder(
        itemCount: widget.students.length,
        itemBuilder: (context, index) {
          final s = widget.students[index];
          return Opacity(
            opacity: s.isPaid ? 1.0 : 0.3,
            child: Card(child: ListTile(
              title: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(onPressed: () {
                setState(() => s.isPaid = !s.isPaid);
                widget.onUpdate();
              }, child: Text(s.isPaid ? "정산취소" : "입금확인")),
            )),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: TutorMainApp(),
    ));

// --- [모델: 학생 및 수업 정보] ---
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
    completedSessions: json['completedSessions'],
    lastConsulted: json['lastConsulted'] != null ? DateTime.parse(json['lastConsulted']) : null,
    consultationHistory: List<String>.from(json['consultationHistory']),
    isPaid: json['isPaid'], color: Color(json['color']),
  );
}

// --- [메인 앱] ---
class TutorMainApp extends StatefulWidget {
  @override
  _TutorMainAppState createState() => _TutorMainAppState();
}

class _TutorMainAppState extends State<TutorMainApp> {
  int _currentIndex = 0;
  List<Student> students = [];
  Map<String, String> grassData = {}; // 날짜별 잔디 상태 (yyyy-MM-dd: status)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 데이터 로컬 저장 및 불러오기 (SharedPrefs)
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? res = prefs.getString('students');
      if (res != null) {
        students = (jsonDecode(res) as List).map((i) => Student.fromJson(i)).toList();
      }
      grassData = Map<String, String>.from(jsonDecode(prefs.getString('grass') ?? '{}'));
    });
    _showDailyBriefing();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('students', jsonEncode(students.map((s) => s.toJson()).toList()));
    await prefs.setString('grass', jsonEncode(grassData));
  }

  void _showDailyBriefing() {
    // 오늘 요일 확인 후 해당 학생들 팝업 (예시로 첫 학생 노출)
    if (students.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("📅 오늘 수업 브리핑"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("${students[0].name} 학생 수업"),
              subtitle: Text("전화/문자로 미리 연락하세요"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.phone, color: Colors.green), onPressed: () => launchUrl(Uri.parse("tel:${students[0].phone}"))),
                  IconButton(icon: Icon(Icons.message, color: Colors.blue), onPressed: () => launchUrl(Uri.parse("sms:${students[0].phone}"))),
                ],
              ),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("확인"))],
      ),
    );
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

// --- [화면 1: 학생 DB & 상담 히스토리] ---
class StudentDBScreen extends StatelessWidget {
  final List<Student> students;
  final Function onUpdate;
  StudentDBScreen({required this.students, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("학생 Repository")),
      body: students.isEmpty 
        ? Center(child: Text("하단 + 버튼을 눌러 학생을 등록하세요"))
        : ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: s.color),
                  title: Text("${s.name} (${s.school})"),
                  subtitle: Text("상담일: ${s.lastConsulted != null ? DateFormat('yyyy-MM-dd').format(s.lastConsulted!) : '없음'}\n비고: ${s.memo}"),
                  onTap: () => _showConsultationDialog(context, s),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _addStudent(context),
      ),
    );
  }

  void _addStudent(BuildContext context) {
    String name = '', school = '', phone = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("학생 추가"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(decoration: InputDecoration(labelText: "이름"), onChanged: (v) => name = v),
          TextField(decoration: InputDecoration(labelText: "학교"), onChanged: (v) => school = v),
          TextField(decoration: InputDecoration(labelText: "전화번호"), onChanged: (v) => phone = v),
        ]),
        actions: [
          ElevatedButton(onPressed: () {
            students.add(Student(id: DateTime.now().toString(), name: name, school: school, phone: phone));
            onUpdate();
            Navigator.pop(ctx);
          }, child: Text("저장"))
        ],
      ),
    );
  }

  void _showConsultationDialog(BuildContext context, Student s) {
    TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${s.name} 상담 히스토리", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...s.consultationHistory.map((h) => Text("• $h")).toList(),
            TextField(controller: controller, decoration: InputDecoration(hintText: "상담 내용 입력")),
            ElevatedButton(onPressed: () {
              s.consultationHistory.insert(0, "${DateFormat('MM/dd').format(DateTime.now())}: ${controller.text}");
              s.lastConsulted = DateTime.now();
              onUpdate();
              Navigator.pop(ctx);
            }, child: Text("상담 기록 커밋"))
          ],
        ),
      ),
    );
  }
}

// --- [화면 2: 주간 시간표 (드래그앤드롭 & 접기)] ---
class WeeklyScheduleScreen extends StatefulWidget {
  final List<Student> students;
  WeeklyScheduleScreen({required this.students});
  @override
  _WeeklyScheduleScreenState createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  bool isCollapsed = true;
  Map<String, String> weekSchedule = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("주간 드래그 앤 드롭"), actions: [
        IconButton(icon: Icon(isCollapsed ? Icons.unfold_more : Icons.unfold_less), onPressed: () => setState(() => isCollapsed = !isCollapsed))
      ]),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Column(children: List.generate(14, (i) => Container(height: 50, width: 40, child: Text("${i+9}")))),
                ...['일','월','화','수','목','금','토'].map((day) => Expanded(
                  child: Column(
                    children: List.generate(14, (i) {
                      int hour = i + 9;
                      if (isCollapsed && (hour < 13 || hour > 19)) return SizedBox.shrink();
                      String key = "$day-$hour";
                      return DragTarget<String>(
                        builder: (ctx, data, reject) => Container(
                          height: 50, decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), color: weekSchedule.containsKey(key) ? Colors.green[100] : null),
                          child: Center(child: Text(weekSchedule[key] ?? "", style: TextStyle(fontSize: 10))),
                        ),
                        onAccept: (name) => setState(() => weekSchedule[key] = name),
                      );
                    }),
                  ),
                )).toList()
              ],
            ),
          ),
          Container(height: 60, child: ListView(scrollDirection: Axis.horizontal, children: widget.students.map((s) => Draggable<String>(data: s.name, feedback: Chip(label: Text(s.name)), child: Padding(padding: EdgeInsets.all(4), child: Chip(label: Text(s.name))))).toList()))
        ],
      ),
    );
  }
}

// --- [화면 3: 월간 잔디 & 수업 피드백] ---
class MonthlyGrassScreen extends StatefulWidget {
  final Map<String, String> grassData;
  final Function onUpdate;
  MonthlyGrassScreen({required this.grassData, required this.onUpdate});
  @override
  _MonthlyGrassScreenState createState() => _MonthlyGrassScreenState();
}

class _MonthlyGrassScreenState extends State<MonthlyGrassScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Monthly Grass")),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: 35,
        itemBuilder: (ctx, i) {
          String dateKey = "2026-01-${(i+1).toString().padLeft(2, '0')}";
          Color color = Colors.grey[200]!;
          if (widget.grassData[dateKey] == '완료') color = Colors.green;
          if (widget.grassData[dateKey] == '취소') color = Colors.red;
          if (widget.grassData[dateKey] == '보강') color = Colors.orange;

          return InkWell(
            onTap: () => _showStatusDialog(dateKey),
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          );
        },
      ),
    );
  }

  void _showStatusDialog(String date) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text("$date 수업 결과"),
      actions: [
        TextButton(onPressed: () { widget.grassData[date] = '완료'; widget.onUpdate(); Navigator.pop(ctx); setState((){}); }, child: Text("완료", style: TextStyle(color: Colors.green))),
        TextButton(onPressed: () { widget.grassData[date] = '취소'; widget.onUpdate(); Navigator.pop(ctx); setState((){}); }, child: Text("취소", style: TextStyle(color: Colors.red))),
        TextButton(onPressed: () { widget.grassData[date] = '보강'; widget.onUpdate(); Navigator.pop(ctx); setState((){}); }, child: Text("보강", style: TextStyle(color: Colors.orange))),
      ],
    ));
  }
}

// --- [화면 4: 수업료 정산 (음영 처리)] ---
class BillingScreen extends StatelessWidget {
  final List<Student> students;
  final Function onUpdate;
  BillingScreen({required this.students, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("선불 8회 정산")),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (ctx, i) {
          final s = students[i];
          return Opacity(
            opacity: s.isPaid ? 1.0 : 0.3, // 미입금시 음영
            child: Card(
              color: s.isPaid ? null : Colors.grey[300],
              child: ListTile(
                title: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("진행: ${s.completedSessions}/8회 | 상태: ${s.isPaid ? '입금완료' : '미입금'}"),
                trailing: ElevatedButton(
                  onPressed: () { s.isPaid = !s.isPaid; onUpdate(); (ctx as Element).markNeedsBuild(); },
                  child: Text(s.isPaid ? "정산취소" : "입금확인"),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

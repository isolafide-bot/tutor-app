import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData(primarySwatch: Colors.green),
      home: TutorMainApp(),
    ));

// --- [Data Models] ---
class Student {
  String name, school, grade, phone, memo;
  int fee;
  DateTime? lastConsulted;
  List<String> consultationHistory;
  bool isPaid; // 입금 여부 (선불 8회 기준)
  int completedSessions; // 8회 중 현재 몇 회 했는지
  Color color;

  Student({
    required this.name, this.school = '', this.grade = '', 
    this.phone = '', this.memo = '', this.fee = 0,
    this.lastConsulted, this.consultationHistory = const [],
    this.isPaid = false, this.completedSessions = 0,
    this.color = Colors.green,
  });
}

class Lesson {
  final String studentName;
  final String day; // 일~토
  final int hour;
  final int duration; // 분 단위

  Lesson(this.studentName, this.day, this.hour, this.duration);
}

// --- [Main App Structure] ---
class TutorMainApp extends StatefulWidget {
  @override
  _TutorMainAppState createState() => _TutorMainAppState();
}

class _TutorMainAppState extends State<TutorMainApp> {
  int _currentIndex = 0;
  List<Student> students = [
    Student(name: "김철수", school: "한국고", grade: "2학년", phone: "01012345678", isPaid: false, memo: "수학 가형"),
    Student(name: "이영희", school: "서울중", grade: "3학년", phone: "01098765432", isPaid: true, memo: "기초 영어"),
  ];
  List<Lesson> weeklySchedule = [];

  @override
  void initState() {
    super.initState();
    // 앱 실행 시 당일 브리핑 팝업 시뮬레이션
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDailyBriefing());
  }

  void _showDailyBriefing() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("📅 오늘 수업 브리핑"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("14:00 - 김철수"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.phone, color: Colors.green), onPressed: () {}),
                  IconButton(icon: Icon(Icons.message, color: Colors.blue), onPressed: () {}),
                ],
              ),
            )
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("확인"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentDBScreen(students: students),
      WeeklyScheduleScreen(students: students, schedule: weeklySchedule),
      MonthlyGrassScreen(),
      BillingScreen(students: students),
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

// --- [Screen 1: 학생 DB (상담 히스토리 포함)] ---
class StudentDBScreen extends StatelessWidget {
  final List<Student> students;
  StudentDBScreen({required this.students});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("학생 Repository")),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final s = students[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: s.color),
              title: Text("${s.name} (${s.school} ${s.grade})"),
              subtitle: Text("최종상담: ${s.lastConsulted ?? '없음'}\n비고: ${s.memo}"),
              onTap: () => _showHistory(context, s),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: Icon(Icons.add)),
    );
  }

  void _showHistory(BuildContext context, Student s) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("${s.name} 상담 히스토리", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(child: ListView(children: s.consultationHistory.map((h) => Text("• $h")).toList())),
            TextField(decoration: InputDecoration(hintText: "상담 내용 입력")),
            ElevatedButton(onPressed: () {}, child: Text("상담 기록 커밋"))
          ],
        ),
      ),
    );
  }
}

// --- [Screen 2: 주간 시간표 (드래그앤드롭 & 접기)] ---
class WeeklyScheduleScreen extends StatefulWidget {
  final List<Student> students;
  final List<Lesson> schedule;
  WeeklyScheduleScreen({required this.students, required this.schedule});

  @override
  _WeeklyScheduleScreenState createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  bool isCollapsed = true;
  final List<String> days = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("주간 Workflow"), actions: [
        IconButton(icon: Icon(isCollapsed ? Icons.unfold_more : Icons.unfold_less), 
        onPressed: () => setState(() => isCollapsed = !isCollapsed))
      ]),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                children: [
                  Column(children: List.generate(14, (i) => Container(height: 60, width: 40, child: Text("${i+9}시")))),
                  ...days.map((day) => Expanded(
                    child: Column(
                      children: List.generate(14, (hourIndex) {
                        int hour = hourIndex + 9;
                        if (isCollapsed && (hour < 13 || hour > 18)) return SizedBox.shrink();
                        return DragTarget<String>(
                          builder: (context, data, reject) => Container(
                            height: 60, decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!)),
                            child: Center(child: Text("")),
                          ),
                          onAccept: (name) => _confirmRepeat(name, day, hour),
                        );
                      }),
                    ),
                  )).toList()
                ],
              ),
            ),
          ),
          Container(
            height: 80, color: Colors.grey[100],
            child: ListView(scrollDirection: Axis.horizontal, 
            children: widget.students.map((s) => Draggable<String>(data: s.name, 
            feedback: Material(child: Chip(label: Text(s.name))), child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(label: Text(s.name)),
            ))).toList()),
          )
        ],
      ),
    );
  }

  void _confirmRepeat(String name, String day, int hour) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text("일정 반복"), content: Text("매주 반복할까요?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text("이번주만")),
        ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text("매주 반복")),
      ],
    ));
  }
}

// --- [Screen 3: 월간 잔디 달력] ---
class MonthlyGrassScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Monthly Contribution")),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: 31,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: index % 5 == 0 ? Colors.green[700] : (index % 12 == 0 ? Colors.red[400] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(4)
            ),
          );
        },
      ),
    );
  }
}

// --- [Screen 4: 수업료 정산 (미입금 음영)] ---
class BillingScreen extends StatelessWidget {
  final List<Student> students;
  BillingScreen({required this.students});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Billing & Payments")),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final s = students[index];
          return Opacity(
            opacity: s.isPaid ? 1.0 : 0.4, // 미입금 시 음영 처리
            child: Card(
              color: s.isPaid ? Colors.white : Colors.grey[300],
              child: ListTile(
                title: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("8회 선불 기준 / 현재 ${s.completedSessions}회 완료"),
                trailing: s.isPaid ? Icon(Icons.check_circle, color: Colors.green) : Text("미입금", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }
}

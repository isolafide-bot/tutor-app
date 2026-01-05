import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(MaterialApp(
  theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
  home: StudentListScreen(),
));

// 학생 데이터 모델
class Student {
  String name, school, grade, phone, memo;
  int fee, completedSessions;
  DateTime? lastConsulted;
  List<String> consultationHistory;
  bool isPaid;

  Student({
    required this.name, this.school = '', this.grade = '',
    this.phone = '', this.memo = '', this.fee = 0,
    this.completedSessions = 0, this.lastConsulted,
    this.consultationHistory = const [], this.isPaid = false,
  });

  // 저장을 위한 JSON 변환
  Map<String, dynamic> toJson() => {
    'name': name, 'school': school, 'grade': grade, 'phone': phone,
    'memo': memo, 'fee': fee, 'completedSessions': completedSessions,
    'lastConsulted': lastConsulted?.toIso8601String(),
    'consultationHistory': consultationHistory, 'isPaid': isPaid,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    name: json['name'], school: json['school'], grade: json['grade'],
    phone: json['phone'], memo: json['memo'], fee: json['fee'],
    completedSessions: json['completedSessions'],
    lastConsulted: json['lastConsulted'] != null ? DateTime.parse(json['lastConsulted']) : null,
    consultationHistory: List<String>.from(json['consultationHistory']),
    isPaid: json['isPaid'],
  );
}

class StudentListScreen extends StatefulWidget {
  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Student> students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents(); // 앱 켜면 저장된 학생 불러오기
  }

  // 폰에 데이터 저장 (shared_preferences 사용)
  Future<void> _saveStudents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_db', jsonEncode(students.map((s) => s.toJson()).toList()));
  }

  // 폰에서 데이터 불러오기
  Future<void> _loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('student_db');
    if (data != null) {
      setState(() {
        students = (jsonDecode(data) as List).map((i) => Student.fromJson(i)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("학생 DB (상담 관리)")),
      body: students.isEmpty
          ? Center(child: Text("등록된 학생이 없습니다.\n우측 하단 +를 눌러 추가하세요."))
          : ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final s = students[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text("${s.name} (${s.school} ${s.grade})", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("최종 상담: ${s.lastConsulted != null ? DateFormat('yyyy-MM-dd').format(s.lastConsulted!) : '기록 없음'}\n비고: ${s.memo}"),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => _showStudentDetail(s),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStudentDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  // 학생 추가 팝업
  void _addStudentDialog() {
    String name = '', school = '', grade = '', phone = '', memo = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("신규 학생 등록"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(decoration: InputDecoration(labelText: "이름*"), onChanged: (v) => name = v),
              TextField(decoration: InputDecoration(labelText: "학교"), onChanged: (v) => school = v),
              TextField(decoration: InputDecoration(labelText: "학년"), onChanged: (v) => grade = v),
              TextField(decoration: InputDecoration(labelText: "연락처"), onChanged: (v) => phone = v),
              TextField(decoration: InputDecoration(labelText: "비고"), onChanged: (v) => memo = v),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("취소")),
          ElevatedButton(onPressed: () {
            if (name.isNotEmpty) {
              setState(() => students.add(Student(name: name, school: school, grade: grade, phone: phone, memo: memo)));
              _saveStudents();
              Navigator.pop(ctx);
            }
          }, child: Text("저장")),
        ],
      ),
    );
  }

  // 상세 정보 및 상담 기록 관리
  void _showStudentDetail(Student s) {
    TextEditingController _memoController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${s.name} 학생 상세", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Divider(),
            Text("상담 히스토리", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ...s.consultationHistory.map((h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text("• $h", style: TextStyle(fontSize: 13)),
            )).toList(),
            SizedBox(height: 10),
            TextField(
              controller: _memoController,
              decoration: InputDecoration(hintText: "상담 내용을 입력하세요", border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_memoController.text.isNotEmpty) {
                    setState(() {
                      s.consultationHistory.insert(0, "${DateFormat('yyyy-MM-dd').format(DateTime.now())}: ${_memoController.text}");
                      s.lastConsulted = DateTime.now();
                    });
                    _saveStudents();
                    Navigator.pop(ctx);
                  }
                },
                child: Text("상담 내용 저장 (Commit)"),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

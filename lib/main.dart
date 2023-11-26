import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Employee Attendance Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Day {
  final String day;
  String status;

  Color backgroundColor; //property for background color

  Day(this.day, this.status, this.backgroundColor);

}

class _MyHomePageState extends State<MyHomePage> {
  String selectedMonth = 'January';
  List<Day> days = [];
  late Future<List<Map<String, String>>> attendanceData;

  @override
  void initState() {
    super.initState();
    attendanceData = fetchAttendanceDataFromApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Attendance'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Selected Month: $selectedMonth',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            value: selectedMonth,
            onChanged: (String? newValue) {
              setState(() {
                selectedMonth = newValue!;
                days = generateDays(selectedMonth, []);
              });
            },
            items: <String>[
              'January',
              'February',
              'March',
              'April',
              'May',
              'June',
              'July',
              'August',
              'September',
              'October',
              'November',
              'December',
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Attendance in $selectedMonth:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: FutureBuilder(
              future: attendanceData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  days = generateDays(selectedMonth, snapshot.data ?? []);

                  return SingleChildScrollView(
                    child: Column(
                      children: days.map((day) {
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(day.day),
                            subtitle: Text(day.status),
                            tileColor: day.backgroundColor, // Set the background color
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, String>>> fetchAttendanceDataFromApi() async {
    final apiUrl = 'http://192.168.0.104/demophp/index.php?employee_id=1';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return List<Map<String, String>>.from(data.map((entry) {
          print(' main response: $entry[status]');
          if (entry is Map<String, dynamic>) {
            return {
              'attendance_date': entry['attendance_date'].toString(),
              'status': entry['status'].toString() ?? 'Present',
            };
          } else {
            throw FormatException('Invalid entry format: $entry');
          }
        }));
      } else {
        throw Exception('Failed to load attendance data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  List<Day> generateDays(String month,
      List<Map<String, String>> attendanceData) {
    Map<String, int> monthMap = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };

    DateTime lastDayOfMonth = DateTime(DateTime
        .now()
        .year, monthMap[month]! + 1, 0);

    List<Day> generatedDays = List.generate(lastDayOfMonth.day, (index) {
      String defaultStatus = 'Absent';
      Color defaultBackgroundColor = Colors.yellow; // Default background color for Absent

      DateTime currentDate = DateTime(DateTime
          .now()
          .year, monthMap[month]!, index + 1);
      String formattedDate = currentDate.toIso8601String().substring(
          0, 10); // Use 'yyyy-MM-dd' format

      Map<String, String>? dayData = attendanceData.firstWhere((
          data) => data['attendance_date'] == formattedDate, orElse: () => {});

      if (dayData.isNotEmpty) {
        defaultStatus = dayData['status'] ?? 'Absent';
        defaultBackgroundColor = defaultStatus == 'Present' ? Colors.green : Colors.yellow;
      }

      print('Generated Day ${index +
          1} - Date: $formattedDate, Status: $defaultStatus');
      return Day('${index + 1}', defaultStatus, defaultBackgroundColor);
    });

    return generatedDays;
  }
}

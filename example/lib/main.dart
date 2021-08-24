import 'package:flutter/material.dart';
import 'package:flutter_datepickers/flutter_datepickers.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
          Locale('zh'),
          Locale('fr'),
          Locale('es'),
          Locale('de'),
          Locale('ru'),
          Locale('ja'),
          Locale('ar'),
          Locale('fa'),
          Locale("es"),
        ],
        theme: ThemeData(
            primarySwatch: Colors.indigo,
            accentColor: Colors.pinkAccent
        ),
        home: PickerPage()
    );
  }
}


class PickerPage extends StatefulWidget {
  @override
  _PickerPageState createState() => _PickerPageState();
}

class _PickerPageState extends State<PickerPage> {
  DateTime? selectedMonthDate;
  DateTime? selectedYearDate;

  @override
  void initState() {
    super.initState();
  }

  void _showMonthPicker() {
    FlutterDatepickers.showMonthPicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 1, 5),
      lastDate: DateTime(DateTime.now().year + 1, 9),
      initialDate: selectedMonthDate ?? DateTime.now(),
      locale: Locale("es"),
    ).then((date) {
      if (date != null) {
        setState(() => selectedMonthDate = date);
      }
    });
  }

  void _showYearPicker() {
    FlutterDatepickers.showYearPicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5, 5),
      lastDate: DateTime(DateTime.now().year + 5, 9),
      initialDate: selectedYearDate ?? DateTime.now(),
      locale: Locale("es"),
    ).then((date) {
      if (date != null) {
        setState(() => selectedYearDate = date);
      }
    });
  }

  String _dateString(DateTime? date, [bool showMonth = true]) {
    if (date == null) return 'None';

    return showMonth
        ? "${date.year}-${date.month}"
        : "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Month and Year Picker Example App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_dateString(selectedMonthDate), style: TextStyle(fontSize: 20)),
                if (selectedMonthDate != null)
                  Text('($selectedMonthDate)', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _showMonthPicker,
                  child: Text('Open month picker'),
                )
              ],
            ),
            SizedBox(height: 50),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_dateString(selectedYearDate), style: TextStyle(fontSize: 20)),
                if (selectedYearDate != null)
                  Text('($selectedYearDate)', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _showYearPicker,
                  child: Text('Open year picker'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

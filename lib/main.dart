import 'package:flutter/material.dart';
import 'package:RoutineCare/pages/home_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
void main() async {
  await Hive.initFlutter();
  await Hive.openBox("Routine_Database");
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      theme: ThemeData(primarySwatch: Colors.pink),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:routine_care/pages/home_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
void main() async {
  await Hive.initFlutter();
  await Hive.openBox("Routine_Database");
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      theme: ThemeData(primarySwatch: Colors.pink),
    );
  }
}*/

/*import 'package:flutter/material.dart';
import 'package:routine_care/pages/home_page.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox("Routine_Database");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const myBlack = Color(0xFF000000); // Pure black with alpha 255

    return MaterialApp(
      theme: ThemeData(
        primarySwatch: MaterialColor(
          myBlack.value, // Pass the integer value of the color
          {
            50: myBlack.withOpacity(0.1), // Adjust shades (optional)
            100: myBlack.withOpacity(0.2),
          },
        ),
      ),
      home: const HomePage(),
    );
  }
}
*/

/*import 'package:flutter/material.dart';
import 'package:routine_care/pages/home_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
void main() async {
  await Hive.initFlutter();
  await Hive.openBox("Routine_Database");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final myBlack = const Color(0xFF000000); // Pure black with alpha 255

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: MaterialColor(myBlack, { // Create MaterialColor with myBlack
          50: Colors.black.withOpacity(0.1), // Adjust shades (optional)
          100: Colors.black.withOpacity(0.2),
        }),
      ),
      home: const HomePage(),
    );
  }
}
runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      final myCustomColor = const Color.fromARGB(255, 21, 74, 208);
      theme: ThemeData(primarySwatch: MaterialColor(myCustomColor)),

    );
  }
}*/
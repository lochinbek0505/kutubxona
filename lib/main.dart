import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kutubxona/HomePage.dart';
import 'LoginScreen.dart';
import 'MembersManagementPage.dart';
import 'UploadBookPage.dart';
import 'edit_my_books_page.dart';
import 'local_user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var check = false;

  void ch() async {
    var data = await LocalUserService.getUser();
    print(data);

    check = data != null;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ch();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kutubxona',
      debugShowCheckedModeBanner: false,
      home: check ? HomePage() : LoginScreen(),
    );
  }
}

// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'firebase_options.dart'; // Import the generated file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('theme_mode') ?? false;
    });
  }

  void _toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('theme_mode', _isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyse💛',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: MainPage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

class MainPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const MainPage({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late ConnectivityResult _previousResult;
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _previousResult = ConnectivityResult.none;
    _initConnectivity();
    _initBatteryMonitor();
    _setupAuthListener();

    _screens = <Widget>[
      SignInPage(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
      SignUpPage(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
      Calculator(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
    ];
  }

  Future<void> _initConnectivity() async {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != _previousResult) {
        _previousResult = result;
        String message = result == ConnectivityResult.none ? 'No internet connection' : 'Connected to the internet';
        Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT, timeInSecForIosWeb: 5);
      }
    } as void Function(List<ConnectivityResult> event)?);
  }

  void _initBatteryMonitor() {
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((BatteryState state) async {
      if (state == BatteryState.charging) {
        int batteryLevel = await _battery.batteryLevel;
        if (batteryLevel >= 90) {
          FlutterRingtonePlayer().play(
            android: AndroidSounds.notification,
            ios: IosSounds.glass,
            looping: false,
            volume: 0.1,
            asAlarm: false,
          );
          Fluttertoast.showToast(msg: 'Battery is charged above 90%', toastLength: Toast.LENGTH_SHORT, timeInSecForIosWeb: 5);
        }
      }
    });
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _selectedIndex = 2; // Redirect to Calculator or any other screen after sign-in
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyse💛'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.purple,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.login, color: _selectedIndex == 0 ? Colors.purple : Colors.grey),
              title: Text('Sign In', style: TextStyle(color: _selectedIndex == 0 ? Colors.purple : Colors.grey)),
              tileColor: _selectedIndex == 0 ? Colors.purple[50] : null,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: Icon(Icons.person_add, color: _selectedIndex == 1 ? Colors.purple : Colors.grey),
              title: Text('Sign Up', style: TextStyle(color: _selectedIndex == 1 ? Colors.purple : Colors.grey)),
              tileColor: _selectedIndex == 1 ? Colors.purple[50] : null,
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: Icon(Icons.calculate, color: _selectedIndex == 2 ? Colors.purple : Colors.grey),
              title: Text('Calculator', style: TextStyle(color: _selectedIndex == 2 ? Colors.purple : Colors.grey)),
              tileColor: _selectedIndex == 2 ? Colors.purple[50] : null,
              onTap: () => _onItemTapped(2),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: 'Sign In',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Sign Up',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: _onItemTapped,
      ),
    );
  }
}

class SignInPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const SignInPage({super.key, required this.toggleTheme, required this.isDarkMode});

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn(clientId: '32191230194-62u5adr0s81nnrt787pcgeug6b28gqa6.apps.googleusercontent.com').signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    void signIn() async {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        Fluttertoast.showToast(msg: 'Signed in successfully', timeInSecForIosWeb: 5);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode)),
        );
      } on FirebaseAuthException catch (e) {
        Fluttertoast.showToast(msg: e.message ?? 'Sign in failed', timeInSecForIosWeb: 5);
      }
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sign In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await signInWithGoogle();
                    Fluttertoast.showToast(msg: 'Signed in with Google', timeInSecForIosWeb: 5);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode)),
                    );
                  } catch (e) {
                    Fluttertoast.showToast(msg: 'Google sign-in failed: $e', timeInSecForIosWeb: 5);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Sign In with Google',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage(toggleTheme: toggleTheme, isDarkMode: isDarkMode)),
                  );
                },
                child: const Text(
                  'Don\'t have an account? Sign Up',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const SignUpPage({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    void signUp() async {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        Fluttertoast.showToast(msg: 'Signed up successfully', timeInSecForIosWeb: 5);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignInPage(toggleTheme: toggleTheme, isDarkMode: isDarkMode)),
        );
      } on FirebaseAuthException catch (e) {
        Fluttertoast.showToast(msg: e.message ?? 'Sign up failed', timeInSecForIosWeb: 5);
      }
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sign Up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInPage(toggleTheme: toggleTheme, isDarkMode: isDarkMode)),
                  );
                },
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Calculator extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const Calculator({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  CalculatorState createState() => CalculatorState();
}

class CalculatorState extends State<Calculator> {
  String output = "0";
  String input = "";
  List<String> inputs = [];
  double result = 0.0;
  String operand = "";

  void buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "CLEAR") {
        output = "0";
        input = "";
        inputs.clear();
        result = 0.0;
        operand = "";
      } else if (buttonText == "DEL") {
        if (output.isNotEmpty) {
          output = output.substring(0, output.length - 1);
          if (output.isEmpty) {
            output = "0";
          }
          input = input.substring(0, input.length - 1);
        }
      } else if (buttonText == "+" || buttonText == "-" || buttonText == "/" || buttonText == "X") {
        if (output.isNotEmpty && !["+", "-", "/", "X"].contains(output[output.length - 1])) {
          inputs.add(output);
          inputs.add(buttonText);
          operand = buttonText;
          output = "0";
          input = inputs.join(" ");
        }
      } else if (buttonText == ".") {
        if (output.contains(".")) {
          return;
        } else {
          output += buttonText;
        }
      } else if (buttonText == "=") {
        if (output.isNotEmpty && !["+", "-", "/", "X"].contains(output[output.length - 1])) {
          inputs.add(output);
          result = _calculateResult(inputs);
          output = result.toString();
          input = "${inputs.join(" ")} = $output";
          inputs.clear();
          operand = "";
        }
      } else {
        if (output == "0") {
          output = buttonText;
        } else {
          output += buttonText;
        }
      }

      if (buttonText != "=" && buttonText != "CLEAR" && !["+", "-", "/", "X"].contains(buttonText)) {
        input += buttonText;
      }
    });
  }

  double _calculateResult(List<String> inputs) {
    double result = double.parse(inputs[0]);
    for (int i = 1; i < inputs.length; i += 2) {
      double nextNum = double.parse(inputs[i + 1]);
      switch (inputs[i]) {
        case "+":
          result += nextNum;
          break;
        case "-":
          result -= nextNum;
          break;
        case "X":
          result *= nextNum;
          break;
        case "/":
          result /= nextNum;
          break;
      }
    }
    return result;
  }

  Widget buildButton(String buttonText, Color color) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(24.0),
          side: BorderSide(width: 2, color: color),
        ),
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        onPressed: () => buttonPressed(buttonText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.pink[50],
      child: Column(children: <Widget>[
        Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                input,
                style: const TextStyle(
                  fontSize: 24.0,
                  color: Colors.grey,
                ),
              ),
              Text(
                output,
                style: const TextStyle(
                  fontSize: 48.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: Divider(),
        ),
        Column(children: [
          Row(children: [
            buildButton("7", Colors.black),
            buildButton("8", Colors.black),
            buildButton("9", Colors.black),
            buildButton("/", Colors.orange),
          ]),
          Row(children: [
            buildButton("4", Colors.black),
            buildButton("5", Colors.black),
            buildButton("6", Colors.black),
            buildButton("X", Colors.orange),
          ]),
          Row(children: [
            buildButton("1", Colors.black),
            buildButton("2", Colors.black),
            buildButton("3", Colors.black),
            buildButton("-", Colors.orange),
          ]),
          Row(children: [
            buildButton(".", Colors.black),
            buildButton("0", Colors.black),
            buildButton("DEL", Colors.red),
            buildButton("+", Colors.orange),
          ]),
          Row(children: [
            buildButton("CLEAR", Colors.red),
            buildButton("=", Colors.green),
          ]),
        ]),
      ]),
    );
  }
}

class MainScreen extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const MainScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MyApp()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text(
              'Welcome to your Dashboard! Have a Nice Day!!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

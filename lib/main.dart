import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/pb.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initPb();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'UTFPR Solicitações',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: kDarkBlue),
        home: pb.authStore.isValid ? const HomeScreen() : const LoginScreen(),
      );
}

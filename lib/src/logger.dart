import 'package:ansicolor/ansicolor.dart';

AnsiPen yellowPen = AnsiPen()..yellow();
AnsiPen redPen = AnsiPen()..red();

class Logger {
  void info(String s) {
    // ignore: avoid_print
    print('buxing: $s');
  }

  void warn(String s) {
    // ignore: avoid_print
    print(yellowPen(s));
  }

  void error(String s) {
    // ignore: avoid_print
    print(redPen(s));
  }
}

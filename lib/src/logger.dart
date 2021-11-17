import 'package:ansicolor/ansicolor.dart';

AnsiPen yellowPen = AnsiPen()..yellow();
AnsiPen redPen = AnsiPen()..red();

enum LogLevel { verbose, info, warning, error }

class Logger {
  final LogLevel level;

  Logger({this.level = LogLevel.verbose});

  void verbose(String s) {
    _p(_s(s), LogLevel.verbose);
  }

  void info(String s) {
    _p(_s(s), LogLevel.info);
  }

  void warn(String s) {
    _p(yellowPen(_s(s)), LogLevel.warning);
  }

  void error(String s) {
    _p(redPen(_s(s)), LogLevel.error);
  }

  String _s(String s) {
    return 'buxing: $s';
  }

  void _p(String s, LogLevel lv) {
    if (lv.index >= level.index) {
      // ignore: avoid_print
      print(s);
    }
  }
}

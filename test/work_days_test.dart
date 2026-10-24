import 'package:flutter_test/flutter_test.dart';
import 'package:ono/screens/day_screen.dart';

void main() {
  test('work days read as people say them', () {
    expect(workDaysLabel(const [1, 2, 3, 4, 5]), 'Mon–Fri');
    expect(workDaysLabel(const [7, 1, 2, 3, 4]), 'Sun–Thu');
    expect(workDaysLabel(const [6, 7, 1]), 'Sat–Mon');
    expect(workDaysLabel(const [1, 3, 6]), 'Mon, Wed, Sat');
    expect(workDaysLabel(const [2, 3]), 'Tue, Wed');
    expect(workDaysLabel(const [1, 2, 3, 4, 5, 6, 7]), 'Every day');
  });
}

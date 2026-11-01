import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_charts.dart';
import '../widgets/ono_ui.dart';

/// Monthly money check-in: in, out, set aside, one decision.
class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  final _income = TextEditingController();
  final _spent = TextEditingController();
  final _savings = TextEditingController();
  final _decision = TextEditingController();
  final _worry = TextEditingController();
  final _owns = TextEditingController();
  final _owes = TextEditingController();
  bool _loaded = false;
  late int _month;

  static String _num(num? v) =>
      v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    _month = system.moneyMonthDefault;
    _fill(system);
  }

  void _fill(PersonalSystemProvider system) {
    final c = system.moneyCheckFor(_month);
    for (final t in [_income, _spent, _savings, _decision, _worry, _owns, _owes]) {
      t.clear();
    }
    if (c != null) {
      _income.text = _num(c.number('income'));
      _spent.text = _num(c.number('spent'));
      _savings.text = _num(c.number('savings'));
      _decision.text = c.str('decision') ?? '';
      _worry.text = c.str('worry') ?? '';
      _owns.text = _num(c.number('owns'));
      _owes.text = _num(c.number('owes'));
    }
  }

  @override
  void dispose() {
    for (final c in [_income, _spent, _savings, _decision, _worry, _owns, _owes]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      parseAmount(c.text);


  Widget _field(TextEditingController c, String label, {bool number = true, String hint = ''}) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextField(
          controller: c,
          keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          onChanged: (_) => setState(() {}),
          style: AppText.body(color: AppColors.white),
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final income = _parse(_income), spent = _parse(_spent), savings = _parse(_savings);
    final rate = income == null || income <= 0 || spent == null ? null : (income - spent) / income;
    final buffer = savings == null || spent == null || spent <= 0 ? null : savings / spent;
    final history = system.logsOf('money_check');
    final owns = _parse(_owns), owes = _parse(_owes);
    final net = owns == null ? null : owns - (owes ?? 0);
    final series = system.netWorthSeries;
    return OnoPage(
      showBack: true,
      eyebrow: 'Month $_month · money check-in',
      title: 'Where the money went',
      subtitle:
          'Ten minutes a month, in your own currency. Seeing it clearly is most of the work. ${system.syncsToCloud ? 'The numbers sync to your account like the rest of your data; the coach only sees your savings rate and buffer.' : 'The numbers stay on this device.'}',
      bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
        if (income == null || spent == null) {
          toast(context, 'Add what came in and what went out.');
          return;
        }
        system.saveMoneyCheck(
            month: _month,
            income: income,
            spent: spent,
            savings: savings,
            decision: _decision.text,
            worry: _worry.text,
            owns: owns,
            owes: owes);
        FocusManager.instance.primaryFocus?.unfocus();
        toast(context, 'Saved. Next one in a month.');
      }),
      children: [
        if (system.programMonth > 1 && system.dayOfMonth <= 5) ...[
          const SizedBox(height: 10),
          Segmented(
            labels: const ['Last month', 'This month'],
            index: _month == system.programMonth ? 1 : 0,
            onChanged: (i) => setState(() {
              _month = system.programMonth - 1 + i;
              _fill(system);
            }),
          ),
        ],
        _field(_income, _month == system.programMonth ? 'Came in this month' : 'Came in last month'),
        _field(_spent, _month == system.programMonth ? 'Went out this month' : 'Went out last month'),
        _field(_savings, 'Set aside in total (optional)', hint: 'Savings you could reach in an emergency'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: StatTile(rate == null ? '—' : '${(rate * 100).round()}', 'saved', unit: '%')),
            Expanded(
                child: StatTile(buffer == null ? '—' : buffer.toStringAsFixed(1), 'months of buffer')),
          ],
        ),
        if (buffer != null && buffer < 3)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('A common first target is three months of spending set aside.',
                style: AppText.small()),
          ),
        const SectionHeader('One decision'),
        _field(_decision, 'Change or keep next month', number: false,
            hint: 'e.g. Cancel two subscriptions'),
        _field(_worry, 'A money worry (optional)', number: false),
        const SectionHeader('What you own and owe'),
        Text('Optional, once a month: a rough total is enough. It stays with you — the coach never sees it.',
            style: AppText.small()),
        _field(_owns, 'Own in total', hint: 'Savings, investments, home, car — what they\'re worth'),
        _field(_owes, 'Owe in total (optional)', hint: 'Mortgage, loans, cards'),
        if (net != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Net worth: ${formatAmount(net)}',
                key: const Key('money-net'), style: AppText.heading()),
          ),
        if (series.length > 1) ...[
          const SectionHeader('Net worth over time'),
          TrendLine(points: series, color: AppColors.accent, format: formatAmount),
          const SizedBox(height: 6),
          Text(
              '${_signed(series.last.y - series[series.length - 2].y)} since the month before'
              '${series.length > 2 ? ' · ${_signed(series.last.y - series.first.y)} since ${shortDate(series.first.x)}' : ''}',
              key: const Key('money-net-change'),
              style: AppText.small(color: AppColors.white)),
        ],
        if (history.length > 1) ...[
          const SectionHeader('Savings rate by month'),
          for (final h in history.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                  '${shortDate(h.date)}: ${system.savingsRate(h) == null ? '—' : '${(system.savingsRate(h)! * 100).round()}%'}',
                  style: AppText.small(color: AppColors.white)),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

String _signed(double v) => '${v >= 0 ? '+' : '−'}${formatAmount(v.abs())}';

/// "12,500" or "-3,250.5": whole thousands grouped, no currency (it's theirs).
String formatAmount(double v) {
  final neg = v < 0;
  final a = v.abs();
  final whole = a.truncate().toString();
  final grouped = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  final cents = ((a - a.truncate()) * 100).round();
  return '${neg ? '-' : ''}$grouped${cents == 0 ? '' : '.${cents.toString().padLeft(2, '0')}'}';
}

/// Accepts "1500,50", "1.234,50", "1,234.50" and "1 234": the last
/// separator followed by one or two digits is the decimal point.
double? parseAmount(String raw) {
  final t = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
  final m = RegExp(r'[.,](\d{1,2})$').firstMatch(t);
  if (m == null) return double.tryParse(t.replaceAll(RegExp(r'[.,]'), ''));
  final whole = t.substring(0, m.start).replaceAll(RegExp(r'[.,]'), '');
  return double.tryParse('${whole.isEmpty ? '0' : whole}.${m.group(1)}');
}

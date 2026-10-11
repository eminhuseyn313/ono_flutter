import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
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
  bool _loaded = false;

  static String _num(num? v) =>
      v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    final c = system.moneyCheckFor(system.programMonth);
    if (c != null) {
      _income.text = _num(c.number('income'));
      _spent.text = _num(c.number('spent'));
      _savings.text = _num(c.number('savings'));
      _decision.text = c.str('decision') ?? '';
      _worry.text = c.str('worry') ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_income, _spent, _savings, _decision, _worry]) {
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
    return OnoPage(
      showBack: true,
      eyebrow: 'Month ${system.programMonth} · money check-in',
      title: 'Where the money went',
      subtitle:
          'Ten minutes a month, in your own currency. Seeing it clearly is most of the work; the numbers stay on your phone.',
      bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
        if (income == null || spent == null) {
          toast(context, 'Add what came in and what went out.');
          return;
        }
        system.saveMoneyCheck(
            income: income, spent: spent, savings: savings, decision: _decision.text, worry: _worry.text);
        FocusManager.instance.primaryFocus?.unfocus();
        toast(context, 'Saved. Next one in a month.');
      }),
      children: [
        _field(_income, 'Came in this month'),
        _field(_spent, 'Went out this month'),
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
        _field(_decision, 'What will you change or keep next month?', number: false),
        _field(_worry, 'Anything worrying you about money? (optional)', number: false),
        if (history.length > 1) ...[
          const SectionHeader('Savings rate by month'),
          for (final h in history.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                  'Month ${h.number('month')}: ${system.savingsRate(h) == null ? '—' : '${(system.savingsRate(h)! * 100).round()}%'}',
                  style: AppText.small(color: AppColors.white)),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
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

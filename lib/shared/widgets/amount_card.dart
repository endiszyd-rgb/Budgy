import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'animated_amount.dart';
import 'hover_lift.dart';

class AmountCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  /// Karta wyróżniona (np. bilans) — delikatne tło w kolorze [color]
  /// zamiast neutralnej karty.
  final bool hero;

  const AmountCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.hero = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return HoverLift(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: hero
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(isDark ? 0.22 : 0.12),
                    color.withOpacity(isDark ? 0.08 : 0.03),
                  ],
                ),
              )
            : const BoxDecoration(),
        child: Card(
          color: hero ? Colors.transparent : null,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.elasticOut,
                      builder: (context, value, _) => Transform.scale(
                        scale: value,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withOpacity(isDark ? 0.22 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedAmount(
                  amount: amount,
                  format: formatter.format,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

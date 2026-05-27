import 'package:flutter/material.dart';

class BadgeProgress extends StatelessWidget {
  final int atual;
  final int total;
  final bool compact;

  const BadgeProgress({
    super.key,
    required this.atual,
    required this.total,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = total > 0 ? (atual / total).clamp(0.0, 1.0) : 0.0;
    final textStyle = TextStyle(
      fontSize: compact ? 10 : 12,
      color: Colors.grey,
      fontWeight: FontWeight.w600,
    );
    final minHeight = compact ? 4.0 : 6.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE5E7EB),
            color: const Color(0xFF2563EB),
            minHeight: minHeight,
          ),
        ),
        SizedBox(width: compact ? 6 : 8),
        Text('$atual/$total', style: textStyle),
      ],
    );
  }
}

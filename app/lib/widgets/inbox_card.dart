import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/time_formatter.dart';

class InboxCard extends StatelessWidget {
  const InboxCard({super.key, required this.item});

  final Map<String, String> item;

  @override
  Widget build(BuildContext context) {
    final deviceName = item['device_name'] ?? '';
    final color = AppColors.forDevice(deviceName);
    final content = item['content'] ?? '';
    final createdAt = item['created_at'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                deviceName.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              if (createdAt != null)
                Text(
                  formatTimestamp(context, DateTime.parse(createdAt)),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
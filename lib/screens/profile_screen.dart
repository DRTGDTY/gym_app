import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nutrition_provider.dart';
import '../models/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionState = ref.watch(nutritionProvider);
    final profile = nutritionState.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('个人资料')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar placeholder
            const CircleAvatar(radius: 40, backgroundColor: Color(0xFF4CAF50), child: Icon(Icons.person, size: 40, color: Colors.black)),
            const SizedBox(height: 16),
            Text(
              '健身管理',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${profile.heightCm.toStringAsFixed(0)} cm | ${profile.weightKg.toStringAsFixed(1)} kg | ${profile.age}岁',
              style: const TextStyle(color: Colors.grey),
            ),
            if (profile.bodyFatPercent != null)
              Text(
                '体脂: ${profile.bodyFatPercent!.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(profile.goal.label, style: const TextStyle(color: Color(0xFF4CAF50))),
            ),
            const SizedBox(height: 20),

            // Body stats
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('身高', '${profile.heightCm.toStringAsFixed(0)} cm'),
                    const Divider(color: Colors.grey),
                    _infoRow('体重', '${profile.weightKg.toStringAsFixed(1)} kg'),
                    const Divider(color: Colors.grey),
                    _infoRow('年龄', '${profile.age} 岁'),
                    const Divider(color: Colors.grey),
                    _infoRow('BMI', profile.bmi.toStringAsFixed(1)),
                    const Divider(color: Colors.grey),
                    _infoRow('活动水平', profile.activityLevel.label),
                    const Divider(color: Colors.grey),
                    _infoRow('目标', profile.goal.label),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

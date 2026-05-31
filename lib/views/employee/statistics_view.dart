import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/employee_controller.dart';

class StatisticsView extends StatelessWidget {
  final EmployeeController employeeController = Get.find<EmployeeController>();

  StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Distribution',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Number of updates posted per area',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 300,
              child: Obx(() {
                final distribution = employeeController
                    .getContentDistributionByArea();
                if (distribution.isEmpty) {
                  return const Center(
                    child: Text('No content available for statistics.'),
                  );
                }
                return PieChart(
                  PieChartData(
                    sections: _generateSections(
                      _sortedDistribution(distribution),
                    ),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(Map<String, int> distribution) {
    final colors = [
      Colors.teal,
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.purple,
    ];

    int index = 0;
    return distribution.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Obx(() {
      final distribution = _sortedDistribution(
        employeeController.getContentDistributionByArea(),
      );
      if (distribution.isEmpty) return const SizedBox();

      final colors = [
        Colors.teal,
        Colors.orange,
        Colors.blue,
        Colors.red,
        Colors.purple,
      ];

      int index = 0;
      return Column(
        children: distribution.entries.map((entry) {
          final color = colors[index % colors.length];
          index++;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.key.capitalizeFirst}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '${entry.value} Posts',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Map<String, int> _sortedDistribution(Map<String, int> distribution) {
    final entries = distribution.entries.toList()
      ..sort((a, b) {
        final countComparison = b.value.compareTo(a.value);
        if (countComparison != 0) return countComparison;
        return a.key.compareTo(b.key);
      });

    return Map.fromEntries(entries);
  }
}

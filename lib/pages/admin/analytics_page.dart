import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:real_estate/models/enums.dart';

// Please add fl_chart to your pubspec.yaml file:
// dependencies:
//   fl_chart: ^0.63.0

enum TimePeriod { overall, monthly, weekly }

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  TimePeriod _selectedPeriod = TimePeriod.overall;

  /// Fetches time-series data for a given collection and time period.
  Future<List<FlSpot>> _fetchAnalyticsData(String collectionName) async {
    DateTime startDate;
    switch (_selectedPeriod) {
      case TimePeriod.weekly:
        startDate = DateTime.now().subtract(const Duration(days: 7));
        break;
      case TimePeriod.monthly:
        startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      default:
      // For overall view, we don't need a start date, we fetch all.
        startDate = DateTime.fromMicrosecondsSinceEpoch(0);
        break;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('created_at', isGreaterThanOrEqualTo: startDate)
        .get();

    // Grouping data by date
    final Map<int, int> dataByDay = {};
    for (var doc in querySnapshot.docs) {
      final timestamp = doc.get('created_at') as Timestamp;
      final date = timestamp.toDate();
      final day = date.day;
      dataByDay.update(day, (value) => value + 1, ifAbsent: () => 1);
    }

    // Creating a list of FlSpot for the graph
    final List<FlSpot> spots = [];
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final day = date.day;
      final count = dataByDay[day] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }
    return spots;
  }

  /// Fetches the total number of users and counts by role.
  Future<Map<String, int>> _fetchUserCounts() async {
    final Map<String, int> counts = {
      'total': 0,
      'buyer': 0,
      'owner': 0,
      'agent': 0,
    };

    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    counts['total'] = usersSnapshot.docs.length;

    for (var doc in usersSnapshot.docs) {
      final userRole = doc.get('user_role') as String;
      if (userRole == UserRole.buyer.name) {
        counts['buyer'] = (counts['buyer'] ?? 0) + 1;
      } else if (userRole == UserRole.owner.name) {
        counts['owner'] = (counts['owner'] ?? 0) + 1;
      } else if (userRole == UserRole.agent.name) {
        counts['agent'] = (counts['agent'] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Fetches the total number of properties.
  Future<int> _fetchPropertyCount() async {
    final propertiesSnapshot = await FirebaseFirestore.instance.collection('properties').get();
    return propertiesSnapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPeriodButton(context, TimePeriod.weekly),
              _buildPeriodButton(context, TimePeriod.monthly),
              _buildPeriodButton(context, TimePeriod.overall),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: Future.wait([
              _fetchUserCounts(),
              _fetchAnalyticsData('users'),
              _fetchAnalyticsData('properties'),
              _fetchPropertyCount(),
            ]),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final userCounts = snapshot.data![0] as Map<String, int>;
              final userSpots = snapshot.data![1] as List<FlSpot>;
              final propertySpots = snapshot.data![2] as List<FlSpot>;
              final totalProperties = snapshot.data![3] as int;

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildCountCard(
                    title: 'Total Users',
                    count: userCounts['total']!,
                    icon: Icons.people,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallCountCard(
                          title: 'Buyers',
                          count: userCounts['buyer']!,
                          icon: Icons.person_search,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSmallCountCard(
                          title: 'Owners',
                          count: userCounts['owner']!,
                          icon: Icons.house,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSmallCountCard(
                          title: 'Agents',
                          count: userCounts['agent']!,
                          icon: Icons.person_pin_circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCountCard(
                    title: 'Total Properties',
                    count: totalProperties,
                    icon: Icons.home_work,
                  ),
                  const SizedBox(height: 32),
                  _buildGraphCard('User Sign-ups', userSpots),
                  _buildGraphCard('New Properties', propertySpots),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(BuildContext context, TimePeriod period) {
    final bool isSelected = _selectedPeriod == period;
    final String label = period.name.replaceFirst(period.name[0], period.name[0].toUpperCase());

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Theme.of(context).primaryColor,
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.white,
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
      child: Text(label),
    );
  }

  Widget _buildGraphCard(String title, List<FlSpot> spots) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard({required String title, required int count, required IconData icon}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCountCard({required String title, required int count, required IconData icon}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

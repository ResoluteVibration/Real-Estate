// lib/pages/admin/admin_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:real_estate/pages/admin/analytics_page.dart';
import 'package:real_estate/pages/admin/property_management_page.dart';
import 'package:real_estate/pages/admin/user_management_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.onBackground,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.home), text: 'Properties'),
              Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
          ),
        ),
        body: const TabBarView(
          children: [
            UserManagementPage(),
            PropertyManagementPage(),
            AnalyticsPage(),
          ],
        ),
      ),
    );
  }
}
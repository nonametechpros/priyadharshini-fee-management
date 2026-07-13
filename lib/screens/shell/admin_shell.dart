import 'package:flutter/material.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../dashboard/reports_screen.dart';
import '../profile/profile_screen.dart';
import '../staff/staff_management_screen.dart';
import '../students/student_list_screen.dart';
import 'app_shell.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Priyadarsini Fee App',
      tabs: [
        ShellTab(label: 'Dashboard', icon: Icons.dashboard_outlined, screen: AdminDashboardScreen()),
        ShellTab(label: 'Students', icon: Icons.groups_outlined, screen: StudentListScreen()),
        ShellTab(label: 'Staff', icon: Icons.badge_outlined, screen: StaffManagementScreen()),
        ShellTab(label: 'Reports', icon: Icons.assessment_outlined, screen: ReportsScreen()),
        ShellTab(label: 'Profile', icon: Icons.person_outline, screen: ProfileScreen()),
      ],
    );
  }
}

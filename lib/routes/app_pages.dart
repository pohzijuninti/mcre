import 'package:get/get.dart';
import '../views/auth/login_screen.dart';
import '../views/admin/admin_dashboard.dart';
import '../views/employee/employee_dashboard.dart';
import '../views/employer/employer_dashboard.dart';
import '../controllers/admin_controller.dart';
import '../controllers/employee_controller.dart';
import '../controllers/chat_controller.dart';

class AppPages {
  static const INITIAL = '/login';

  static final routes = [
    GetPage(
      name: '/login',
      page: () => LoginScreen(),
    ),
    GetPage(
      name: '/admin-dashboard',
      page: () => AdminDashboard(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AdminController());
        Get.lazyPut(() => EmployeeController());
        Get.lazyPut(() => ChatController());
      }),
    ),
    GetPage(
      name: '/employee-dashboard',
      page: () => EmployeeDashboard(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => EmployeeController());
        Get.lazyPut(() => ChatController());
      }),
    ),
    GetPage(
      name: '/employer-dashboard',
      page: () => EmployerDashboard(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => EmployeeController());
        Get.lazyPut(() => ChatController());
      }),
    ),
  ];
}

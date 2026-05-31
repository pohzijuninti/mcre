import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/firebase_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(FirebaseService(), permanent: true);
    Get.put(AuthController(), permanent: true);
  }
}

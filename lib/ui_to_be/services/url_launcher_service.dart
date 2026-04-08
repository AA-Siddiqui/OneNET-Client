import 'package:url_launcher/url_launcher.dart';
import '../config/app_constants.dart';

class UrlLauncherService {
  static Future<void> openPortal() async {
    await _launch(AppConstants.portalUrl);
  }

  static Future<void> openSignup() async {
    await _launch(AppConstants.portalSignupUrl);
  }

  static Future<void> openResetPassword() async {
    await _launch(AppConstants.portalResetPasswordUrl);
  }

  static Future<void> openAccount() async {
    await _launch(AppConstants.portalAccountUrl);
  }

  static Future<void> openPlans() async {
    await _launch(AppConstants.portalPlansUrl);
  }

  static Future<void> openDownloads() async {
    await _launch(AppConstants.portalDownloadsUrl);
  }

  static Future<void> openSupport() async {
    await _launch(AppConstants.supportUrl);
  }

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

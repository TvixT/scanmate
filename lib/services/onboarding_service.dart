import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class OnboardingService {
  static const String _onboardingCompleteKey = 'onboarding_completed';
  static const String _permissionsAskedKey = 'permissions_asked';
  
  /// Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_onboardingCompleteKey) ?? false;
      Logger.info('Onboarding completion status: $completed');
      return completed;
    } catch (e) {
      Logger.error('Error checking onboarding status: $e');
      return false;
    }
  }
  
  /// Mark onboarding as completed
  static Future<void> markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
      Logger.info('Onboarding marked as completed');
    } catch (e) {
      Logger.error('Error marking onboarding complete: $e');
    }
  }
  
  /// Check if permissions have been asked before
  static Future<bool> hasAskedPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final asked = prefs.getBool(_permissionsAskedKey) ?? false;
      Logger.info('Permissions asked status: $asked');
      return asked;
    } catch (e) {
      Logger.error('Error checking permissions asked status: $e');
      return false;
    }
  }
  
  /// Mark permissions as asked
  static Future<void> markPermissionsAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionsAskedKey, true);
      Logger.info('Permissions marked as asked');
    } catch (e) {
      Logger.error('Error marking permissions as asked: $e');
    }
  }
  
  /// Reset onboarding state (for testing/debug)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompleteKey);
      await prefs.remove(_permissionsAskedKey);
      Logger.info('Onboarding state reset');
    } catch (e) {
      Logger.error('Error resetting onboarding: $e');
    }
  }
}

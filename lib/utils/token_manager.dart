import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakai/config.dart';

class TokenManager {
  static Future<String?> getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');
    
    if (accessToken == null || refreshToken == null) {
      return null;
    }
    
    // Access Token 만료 시간 체크
    final tokenExpiryString = prefs.getString('token_expiry');
    bool needsRefresh = false;
    
    if (tokenExpiryString != null) {
      try {
        final expiryTime = DateTime.parse(tokenExpiryString);
        final now = DateTime.now();
        
        // Access Token이 만료되었거나 5분 이내에 만료될 예정이면 갱신 필요
        if (now.isAfter(expiryTime) || now.isAfter(expiryTime.subtract(Duration(minutes: 5)))) {
          needsRefresh = true;
        }
      } catch (e) {
        print('Error parsing token expiry: $e');
        needsRefresh = true;
      }
    } else {
      needsRefresh = true;
    }
    
    // 토큰 갱신 시도
    if (needsRefresh) {
      final refreshSuccess = await _refreshAccessToken(prefs, refreshToken);
      if (!refreshSuccess) {
        await _clearLoginData(prefs);
        return null;
      }
      // 갱신된 토큰 반환
      return prefs.getString('access_token');
    }
    
    return accessToken;
  }
  
  static Future<bool> _refreshAccessToken(SharedPreferences prefs, String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/public/auth/refreshToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        final expiresIn = data['expiresIn'] as int?;
        
        if (newAccessToken != null) {
          await prefs.setString('access_token', newAccessToken);
          
          // 새로운 만료 시간 저장
          final now = DateTime.now();
          final expiryTime = expiresIn != null 
              ? now.add(Duration(seconds: expiresIn))
              : now.add(const Duration(hours: 1));
          await prefs.setString('token_expiry', expiryTime.toIso8601String());
          
          print('Access token refreshed successfully');
          return true;
        }
      }
      
      print('Failed to refresh token: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }
  
  static Future<void> _clearLoginData(SharedPreferences prefs) async {
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
    await prefs.remove('is_onboarded');
    await prefs.remove('token_expiry');
    await prefs.remove('last_login');
    await prefs.remove('current_chapter');
    await prefs.remove('current_course');
  }
}


import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://hunarhub-pakistan-api-henna.vercel.app';

  final String token;

  ApiService({required this.token});

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data is Map &&
        data['success'] == true) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data is Map ? data['message'] ?? 'Login failed' : 'Login failed',
    );
  }

  // AUTHENTICATION HEADERS
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // CREATE CV
  Future<Map<String, dynamic>> createCV({
    required String title,
    required String cvType,
    required String templateName,
    required Map<String, dynamic> content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cv'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'cv_type': cvType,
        'template_name': templateName,
        'content': content,
      }),
    );

    return _handleResponse(response);
  }

  // GET ALL CVS
  Future<Map<String, dynamic>> getCVs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cv'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // UPDATE CV
  Future<Map<String, dynamic>> updateCV({
    required String id,
    required String title,
    required String cvType,
    required String templateName,
    required Map<String, dynamic> content,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/cv/$id'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'cv_type': cvType,
        'template_name': templateName,
        'content': content,
      }),
    );

    return _handleResponse(response);
  }

  // DELETE CV
  Future<Map<String, dynamic>> deleteCV(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cv/$id'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // HANDLE API RESPONSES
  Map<String, dynamic> _handleResponse(http.Response response) {
    final dynamic data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data is Map
          ? data['message'] ?? 'API request failed'
          : 'API request failed',
    );
  }
}

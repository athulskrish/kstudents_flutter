import 'package:flutter_test/flutter_test.dart';
import 'package:kerala_tech_reach/services/api_service.dart';

void main() {
  group('ApiService', () {
    final apiService = ApiService();

    test('getUniversities returns a list', () async {
      final universities = await apiService.getUniversities();
      expect(universities, isA<List>());
    });
  });
} 
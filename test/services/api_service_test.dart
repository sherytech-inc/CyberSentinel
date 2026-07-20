import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cybersentinel/services/api_service.dart';

void main() {
  group('ApiService HTML Error Detection', () {
    late HttpServer server;
    late String url;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      url = 'http://${server.address.host}:${server.port}';
      ApiService.setBaseUrl(url);

      server.listen((HttpRequest request) {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write('<!DOCTYPE html><html><body>Flutter App</body></html>')
          ..close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('should return typed error when receiving HTML from API', () async {
      final response = await ApiService.getDashboardStats();
      expect(response['error'], isTrue);
      expect(response['message'], contains('Received HTML response'));
    });
  });
}

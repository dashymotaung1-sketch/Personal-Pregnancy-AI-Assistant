import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/data.dart';

void main() async {
  final router = Router();

  // Home endpoint
  router.get('/', (Request req) {
    return Response.ok(jsonEncode({"message": "Welcome to Pregnancy AI Assistant!"}),
        headers: {'Content-Type': 'application/json'});
  });

  // Get pregnancy stages
  router.get('/stages', (Request req) {
    return Response.ok(jsonEncode(stages),
        headers: {'Content-Type': 'application/json'});
  });

  // Get daily tips
  router.get('/tips', (Request req) {
    return Response.ok(jsonEncode(tips),
        headers: {'Content-Type': 'application/json'});
  });

  // Example: Get info for a specific week
  router.get('/stages/<week>', (Request req, String week) {
    final weekInt = int.tryParse(week);
    if (weekInt == null || weekInt < 1 || weekInt > stages.length) {
      return Response.notFound(jsonEncode({"error": "Week not found"}));
    }
    return Response.ok(jsonEncode(stages[weekInt - 1]),
        headers: {'Content-Type': 'application/json'});
  });

  // Start server
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server running on http://${server.address.address}:${server.port}');
}
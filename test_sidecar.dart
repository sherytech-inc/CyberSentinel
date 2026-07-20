import 'dart:io';
import 'package:cybersentinel/core/sidecar/sidecar_manager.dart';

void main() async {
  print('Testing SidecarManager...');
  final manager = SidecarManager();
  
  await manager.start();
  print('Sidecar started on port: ${manager.port}');
  print('Local token: ${manager.localToken}');
  
  print('Waiting 3 seconds...');
  await Future.delayed(Duration(seconds: 3));
  
  print('Stopping sidecar...');
  manager.stop();
  print('Sidecar stopped.');
  exit(0);
}

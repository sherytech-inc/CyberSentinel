import 'dart:io';
import 'package:cybersentinel/core/sidecar/sidecar_manager.dart';

void main() async {
  final manager = SidecarManager();
  print('Starting sidecar...');
  await manager.start();
  print('Is running: ${manager.isRunning}');
  print('Port: ${manager.port}');
  print('Local Token: ${manager.localToken}');

  // Wait a bit to see if it stays up
  await Future.delayed(Duration(seconds: 3));

  // check process
  final res = await Process.run('lsof', ['-i', 'TCP:${manager.port}']);
  print('lsof output:\n${res.stdout}');

  exit(0);
}

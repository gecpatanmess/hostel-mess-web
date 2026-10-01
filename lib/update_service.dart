import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static final _supabase = Supabase.instance.client;

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Web platform doesn't need APK / App Store update logic
      if (kIsWeb) return;

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Fetch latest version from Supabase
      final response = await _supabase
          .from('app_updates')
          .select('version, apk_url, ios_url, is_mandatory')
          .eq('id', 1)
          .maybeSingle();

      if (response == null) return;

      final latestVersion = (response['version'] ?? '1.0.0') as String;
      final apkUrl = (response['apk_url'] ?? '') as String;
      final iosUrl = (response['ios_url'] ?? apkUrl) as String;
      final isMandatory = (response['is_mandatory'] ?? false) as bool;

      // Compare versions
      if (_isUpdateAvailable(currentVersion, latestVersion)) {
        if (context.mounted) {
          _showUpdateDialog(
            context: context,
            version: latestVersion,
            apkUrl: apkUrl,
            iosUrl: iosUrl,
            isMandatory: isMandatory,
          );
        }
      }
    } catch (e) {
      debugPrint("Update check error: $e");
    }
  }

  static bool _isUpdateAvailable(String current, String latest) {
    try {
      final v1 = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final v2 = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      for (int i = 0; i < 3; i++) {
        final currentPart = i < v1.length ? v1[i] : 0;
        final latestPart = i < v2.length ? v2[i] : 0;
        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
    } catch (_) {}
    return false;
  }

  static void _showUpdateDialog({
    required BuildContext context,
    required String version,
    required String apkUrl,
    required String iosUrl,
    required bool isMandatory,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (BuildContext context) {
        return UpdateDialogWidget(
          version: version,
          apkUrl: apkUrl,
          iosUrl: iosUrl,
          isMandatory: isMandatory,
        );
      },
    );
  }
}

class UpdateDialogWidget extends StatefulWidget {
  final String version;
  final String apkUrl;
  final String iosUrl;
  final bool isMandatory;

  const UpdateDialogWidget({
    super.key,
    required this.version,
    required this.apkUrl,
    required this.iosUrl,
    required this.isMandatory,
  });

  @override
  State<UpdateDialogWidget> createState() => _UpdateDialogWidgetState();
}

class _UpdateDialogWidgetState extends State<UpdateDialogWidget> {
  bool isDownloading = false;
  double progress = 0.0;
  String statusMessage = "";

  Future<void> _handleUpdate() async {
    if (Platform.isIOS) {
      // iOS: Open App Store / TestFlight link
      final Uri uri = Uri.parse(widget.iosUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch update link.")),
          );
        }
      }
    } else if (Platform.isAndroid) {
      // Android: In-App Download and Install
      await _downloadAndInstallAndroid();
    }
  }

  Future<void> _downloadAndInstallAndroid() async {
    setState(() {
      isDownloading = true;
      statusMessage = "Downloading update...";
      progress = 0.0;
    });

    try {
      // Use temporary directory - compatible with ALL Android versions (Android 5.0 to 14+)
      // without needing WRITE_EXTERNAL_STORAGE permission on Android 10+
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/app_update_${widget.version}.apk';
      final file = File(filePath);

      // Remove existing temp update file if present
      if (await file.exists()) {
        await file.delete();
      }

      final dio = Dio();
      await dio.download(
        widget.apkUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              progress = received / total;
            });
          }
        },
      );

      setState(() {
        statusMessage = "Opening installer...";
      });

      // Launch native Android Package Installer via OpenFilex
      final result = await OpenFilex.open(filePath);
      debugPrint("Installer launch result: ${result.message}");

      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open installer: ${result.message}")),
        );
      }
    } catch (e) {
      debugPrint("Download error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to download update. Please try again.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
        if (!widget.isMandatory) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return PopScope(
      canPop: !widget.isMandatory && !isDownloading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: Color(0xFFB74300)),
            SizedBox(width: 10),
            Text('Update Available', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version (${widget.version}) of the app is available.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (isDownloading) ...[
              LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFFB74300),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    statusMessage,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ] else ...[
              Text(
                isIOS
                    ? 'Tap below to update from the App Store.'
                    : 'Download and install the latest features directly.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        actions: [
          if (!widget.isMandatory && !isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later', style: TextStyle(color: Colors.grey)),
            ),
          if (!isDownloading)
            ElevatedButton(
              onPressed: _handleUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB74300),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isIOS ? 'Open App Store' : 'Update Now'),
            ),
        ],
      ),
    );
  }
}

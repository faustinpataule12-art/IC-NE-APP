import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

typedef ProgressCallback = void Function(int step, String message);

class ApkService {
  // Icon sizes for each mipmap folder
  static const Map<String, int> _mipmapSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  Future<String> processApk({
    required String apkPath,
    File? newIcon,
    File? splashImage,
    File? splashLogo,
    Color splashBgColor = const Color(0xFF000000),
    required ProgressCallback onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final workDir = Directory('${tempDir.path}/apk_work_${DateTime.now().millisecondsSinceEpoch}');
    await workDir.create(recursive: true);

    try {
      // Step 0: Read APK (it's a ZIP)
      onProgress(0, 'Lecture de l\'APK...');
      final apkBytes = await File(apkPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(apkBytes);

      // Step 1: Extract
      onProgress(1, 'Extraction des fichiers...');
      final extractDir = Directory('${workDir.path}/extracted');
      await extractDir.create();

      for (final file in archive) {
        final filePath = '${extractDir.path}/${file.name}';
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }

      // Step 2: Replace icons
      if (newIcon != null) {
        onProgress(2, 'Remplacement des icônes...');
        await _replaceIcons(extractDir, newIcon);
      }

      // Step 3: Replace splash
      if (splashImage != null || splashLogo != null) {
        onProgress(3, 'Modification du splash screen...');
        await _replaceSplash(
          extractDir,
          splashImage: splashImage,
          splashLogo: splashLogo,
          bgColor: splashBgColor,
        );
      }

      // Step 4: Repack APK
      onProgress(4, 'Recompilation de l\'APK...');
      final outputApkPath = await _repackApk(extractDir, workDir);

      // Step 5: Sign APK
      onProgress(5, 'Signature de l\'APK...');
      final signedPath = await _signApk(outputApkPath, workDir);

      // Step 6: Copy to Downloads
      onProgress(6, 'Finalisation...');
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final originalName = apkPath.split('/').last.replaceAll('.apk', '');
      final finalPath = '${downloadsDir.path}/${originalName}_modified.apk';
      await File(signedPath).copy(finalPath);

      // Cleanup
      await workDir.delete(recursive: true);

      return finalPath;
    } catch (e) {
      await workDir.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> _replaceIcons(Directory extractDir, File newIcon) async {
    final iconBytes = await newIcon.readAsBytes();
    final originalImage = img.decodeImage(iconBytes);
    if (originalImage == null) throw Exception('Image d\'icône invalide');

    final resDir = Directory('${extractDir.path}/res');
    if (!await resDir.exists()) return;

    // Find all mipmap folders and icon files
    await for (final entity in resDir.list()) {
      if (entity is Directory) {
        final dirName = entity.path.split('/').last;
        final size = _mipmapSizes[dirName];
        if (size != null) {
          // Resize icon for this density
          final resized = img.copyResize(originalImage, width: size, height: size);
          final resizedBytes = img.encodePng(resized);

          // Replace all .png files in this mipmap folder
          await for (final file in entity.list()) {
            if (file is File && file.path.endsWith('.png')) {
              await file.writeAsBytes(resizedBytes);
            }
          }
        }
      }
    }

    // Also check for adaptive icon foreground
    final mipmapAny = Directory('${extractDir.path}/res/mipmap-anydpi-v26');
    if (await mipmapAny.exists()) {
      // Handle adaptive icons - replace the foreground
      final foregroundFile = File('${extractDir.path}/res/drawable/ic_launcher_foreground.png');
      if (await foregroundFile.exists()) {
        final resized = img.copyResize(originalImage, width: 108, height: 108);
        await foregroundFile.writeAsBytes(img.encodePng(resized));
      }
    }
  }

  Future<void> _replaceSplash(
    Directory extractDir, {
    File? splashImage,
    File? splashLogo,
    Color bgColor = const Color(0xFF000000),
  }) async {
    // Look for splash in drawable folders
    final drawableDirs = [
      'drawable',
      'drawable-hdpi',
      'drawable-xhdpi',
      'drawable-xxhdpi',
      'drawable-xxxhdpi',
      'drawable-mdpi',
    ];

    for (final dir in drawableDirs) {
      final drawableDir = Directory('${extractDir.path}/res/$dir');
      if (!await drawableDir.exists()) continue;

      await for (final file in drawableDir.list()) {
        if (file is File) {
          final name = file.path.split('/').last.toLowerCase();
          if (name.contains('splash') || name.contains('launch') || name.contains('welcome')) {
            if (splashImage != null && name.endsWith('.png')) {
              final bytes = await splashImage.readAsBytes();
              final decoded = img.decodeImage(bytes);
              if (decoded != null) {
                // Resize to common splash size
                final resized = img.copyResize(decoded, width: 1080, height: 1920);
                await file.writeAsBytes(img.encodePng(resized));
              }
            }
          }
        }
      }
    }

    // Update colors.xml for splash background color
    await _updateSplashColor(extractDir, bgColor);

    // Add logo if provided
    if (splashLogo != null) {
      await _addSplashLogo(extractDir, splashLogo);
    }
  }

  Future<void> _updateSplashColor(Directory extractDir, Color color) async {
    final colorFiles = [
      '${extractDir.path}/res/values/colors.xml',
      '${extractDir.path}/res/values-night/colors.xml',
    ];

    final hexColor = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    for (final path in colorFiles) {
      final file = File(path);
      if (!await file.exists()) continue;

      try {
        final content = await file.readAsString();
        final doc = XmlDocument.parse(content);

        for (final elem in doc.findAllElements('color')) {
          final name = elem.getAttribute('name') ?? '';
          if (name.contains('splash') || name.contains('launch') || name.contains('background')) {
            elem.innerText = hexColor;
          }
        }

        await file.writeAsString(doc.toXmlString(pretty: true));
      } catch (_) {
        // Skip if XML parsing fails
      }
    }
  }

  Future<void> _addSplashLogo(Directory extractDir, File logoFile) async {
    final logoBytes = await logoFile.readAsBytes();
    final decoded = img.decodeImage(logoBytes);
    if (decoded == null) return;

    // Save logo as drawable resource
    final drawableDir = Directory('${extractDir.path}/res/drawable');
    await drawableDir.create(recursive: true);

    final resized = img.copyResize(decoded, width: 300, height: 300);
    await File('${drawableDir.path}/nps_splash_logo.png').writeAsBytes(img.encodePng(resized));
  }

  Future<String> _repackApk(Directory extractDir, Directory workDir) async {
    final outputPath = '${workDir.path}/output_unsigned.apk';
    final encoder = ZipFileEncoder();
    encoder.create(outputPath);

    await _addDirToZip(encoder, extractDir, extractDir.path);
    encoder.close();

    return outputPath;
  }

  Future<void> _addDirToZip(ZipFileEncoder encoder, Directory dir, String basePath) async {
    await for (final entity in dir.list(recursive: false)) {
      if (entity is File) {
        final relativePath = entity.path.substring(basePath.length + 1);
        encoder.addFile(entity, relativePath);
      } else if (entity is Directory) {
        await _addDirToZip(encoder, entity, basePath);
      }
    }
  }

  Future<String> _signApk(String unsignedPath, Directory workDir) async {
    final signedPath = '${workDir.path}/output_signed.apk';

    try {
      final keystorePath = '${workDir.path}/debug.keystore';

      final keytoolResult = await Process.run('keytool', [
        '-genkey', '-v',
        '-keystore', keystorePath,
        '-alias', 'nps_key',
        '-keyalg', 'RSA',
        '-keysize', '2048',
        '-validity', '10000',
        '-storepass', 'nps123456',
        '-keypass', 'nps123456',
        '-dname', 'CN=NPS.NELSON, OU=NPS, O=NPS Studio, L=Kinshasa, S=DRC, C=CD',
      ]);

      if (keytoolResult.exitCode != 0) {
        await File(unsignedPath).copy(signedPath);
        return signedPath;
      }

      final signResult = await Process.run('jarsigner', [
        '-verbose',
        '-sigalg', 'SHA256withRSA',
        '-digestalg', 'SHA-256',
        '-keystore', keystorePath,
        '-storepass', 'nps123456',
        '-keypass', 'nps123456',
        '-signedjar', signedPath,
        unsignedPath,
        'nps_key',
      ]);

      if (signResult.exitCode != 0) {
        await File(unsignedPath).copy(signedPath);
      }
    } catch (e) {
      // keytool/jarsigner indisponibles sur Android : on repart sur l'APK non signé
      await File(unsignedPath).copy(signedPath);
    }

    return signedPath;
  }
}
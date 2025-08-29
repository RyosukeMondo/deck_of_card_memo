#!/usr/bin/env dart

import 'dart:io';
import 'dart:typed_data';

void main() async {
  final modelsDir = Directory('assets/cards/models');
  
  if (!modelsDir.existsSync()) {
    print('❌ Models directory not found: ${modelsDir.path}');
    return;
  }
  
  final glbFiles = modelsDir
      .listSync()
      .where((file) => file.path.endsWith('.glb'))
      .cast<File>()
      .toList();
      
  print('🔍 Found ${glbFiles.length} GLB files');
  print('');
  
  int validFiles = 0;
  int invalidFiles = 0;
  
  for (final file in glbFiles) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSize = file.lengthSync();
    
    if (fileSize == 0) {
      print('❌ $fileName - Empty file (0 bytes)');
      invalidFiles++;
      continue;
    }
    
    // Check GLB header (should start with "glTF")
    try {
      final bytes = file.readAsBytesSync();
      final header = String.fromCharCodes(bytes.take(4));
      
      if (header == 'glTF') {
        print('✅ $fileName - Valid GLB (${_formatFileSize(fileSize)})');
        validFiles++;
      } else {
        print('⚠️  $fileName - Invalid GLB header: "$header" (${_formatFileSize(fileSize)})');
        invalidFiles++;
      }
    } catch (e) {
      print('❌ $fileName - Error reading file: $e');
      invalidFiles++;
    }
  }
  
  print('');
  print('📊 Summary:');
  print('   Valid GLB files: $validFiles');
  print('   Invalid/Error files: $invalidFiles');
  print('   Total files: ${validFiles + invalidFiles}');
  
  if (invalidFiles > 0) {
    print('');
    print('⚠️  Some GLB files may be corrupted or invalid.');
    print('   This could cause 3D viewer loading issues.');
  } else {
    print('');
    print('🎉 All GLB files appear to be valid!');
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}
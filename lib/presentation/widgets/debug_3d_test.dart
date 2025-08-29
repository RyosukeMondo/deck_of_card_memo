import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

/// Simple test widget to debug flutter_3d_controller issues
class Debug3DTest extends StatelessWidget {
  const Debug3DTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('3D Controller Debug Test'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Info panel
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🧪 Flutter 3D Controller Test', 
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Package: flutter_3d_controller'),
                Text('Platform: Web (Chrome)'),
                Text('Expected: model-viewer web component'),
                SizedBox(height: 8),
                Text('If you see a red border but no 3D model, the issue is:'),
                Text('1. GLB file format/content problem, or'),
                Text('2. flutter_3d_controller web compatibility issue'),
              ],
            ),
          ),

          // Test 1: Basic Flutter3DViewer with our GLB
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.red[100],
                    width: double.infinity,
                    child: Text('Test 1: Our GLB File', 
                                style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      child: Flutter3DViewer(
                        src: 'assets/cards/models/ca.glb',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Test 2: Try with a known working online GLB (if possible)
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.blue[100],
                    width: double.infinity,
                    child: Text('Test 2: Simple Fallback', 
                                style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.threed_rotation, size: 64, color: Colors.blue),
                            SizedBox(height: 8),
                            Text('3D Model would appear here'),
                            SizedBox(height: 8),
                            Text('Check browser console for errors', 
                                 style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controls
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Open browser console for debugging
                    print('🧪 [Debug] Check browser DevTools Console for model-viewer errors');
                    print('🧪 [Debug] Look for CORS, GLB format, or WebGL errors');
                  },
                  icon: Icon(Icons.bug_report),
                  label: Text('Log Debug Info'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Back to App'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
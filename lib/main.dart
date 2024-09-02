import 'dart:io';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final asset = 'assets/glb/dayo/source/Dayo.glb';
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: ARView(
          onARViewCreated: _onARViewCreated,
          planeDetectionConfig: PlaneDetectionConfig.horizontal,
        ),
      ),
    );
  }

  @override
  void dispose() {
    arSessionManager.dispose();
    super.dispose();
  }

  Future<void> _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) async {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;
    this.arSessionManager.onInitialize(
          handlePans: true,
          handleRotation: true,
          showWorldOrigin: true,
          customPlaneTexturePath: 'assets/triangle.png',
        );
    this.arObjectManager.onInitialize();
    this.arSessionManager.onPlaneOrPointTap = _onPlaneOrPointTapped;
  }

  Future<void> _onPlaneOrPointTapped(
    List<ARHitTestResult> hitTestResults,
  ) async {
    final singleHitTestResult = hitTestResults
        .firstWhere((result) => result.type == ARHitTestResultType.plane);
    final newAnchor =
        ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
    final didAddAnchor = await arAnchorManager.addAnchor(newAnchor);
    if (didAddAnchor == true) {
      await _copyAssetModelsToDocumentDirectory();
      final newNode = ARNode(
        type: NodeType.fileSystemAppFolderGLB,
        uri: asset,
        scale: vector.Vector3(0.5, 0.5, 0.5),
        position: vector.Vector3(0.0, 0.0, 0.0),
        rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
      );
      final didAddNodeToAnchor =
          await arObjectManager.addNode(newNode, planeAnchor: newAnchor);
      if (didAddNodeToAnchor == false) {
        arSessionManager.onError('Adding Node to Anchor failed');
      }
    } else {
      arSessionManager.onError('Adding Anchor failed');
    }
  }

  Future<void> _copyAssetModelsToDocumentDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final docDirPath = docDir.path;
    final file = File('$docDirPath/$asset');
    final assetBytes = await rootBundle.load('assets/glb/${asset}');
    final buffer = assetBytes.buffer;
    await file.writeAsBytes(
      buffer.asUint8List(assetBytes.offsetInBytes, assetBytes.lengthInBytes),
    );
  }
}

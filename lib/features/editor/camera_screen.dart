import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../theme/wasurenagusa_theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  /// Returns the captured file path, or null if cancelled.
  static Future<String?> show(BuildContext context) {
    return Navigator.push<String?>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CameraScreen(),
      ),
    );
  }

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _initializing = true;
  bool _capturing = false;
  String? _error;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(index: _cameraIndex);
    }
  }

  Future<void> _initCamera({int index = 0}) async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No cameras found on this device.';
          _initializing = false;
        });
        return;
      }

      _cameraIndex = index.clamp(0, _cameras.length - 1);
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _controller = controller;
      await controller.initialize();

      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize camera: $e';
          _initializing = false;
        });
      }
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_capturing) return;

    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (mounted) Navigator.pop(context, file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
        setState(() => _capturing = false);
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    await _initCamera(index: nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ─────────────────────
          if (_initializing)
            Center(child: CircularProgressIndicator(color: colors.accent))
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            )
          else
            Center(child: CameraPreview(_controller!)),

          // ── Top bar ────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context, null),
                  tooltip: 'Cancel',
                ),
              ),
            ),
          ),

          // ── Bottom controls ────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Switch camera
                    if (_cameras.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.flip_camera_android_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _initializing ? null : _switchCamera,
                        tooltip: 'Switch camera',
                      )
                    else
                      const SizedBox(width: 48),

                    // Shutter button
                    GestureDetector(
                      onTap: _initializing || _capturing ? null : _capture,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _capturing ? Colors.white60 : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54, width: 4),
                        ),
                        child: _capturing
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black54,
                                ),
                              )
                            : null,
                      ),
                    ),

                    // Spacer to balance the switch button
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

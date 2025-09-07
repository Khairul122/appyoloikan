import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageProcessingService {
  static final ImageProcessingService _instance = ImageProcessingService._internal();
  factory ImageProcessingService() => _instance;
  ImageProcessingService._internal();

  static Future<Uint8List> convertCameraImageInIsolate(CameraImage cameraImage) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_isolateEntryPoint, receivePort.sendPort);
    
    final sendPort = await receivePort.first as SendPort;
    final responsePort = ReceivePort();
    
    sendPort.send([cameraImage, responsePort.sendPort]);
    
    return await responsePort.first as Uint8List;
  }

  static void _isolateEntryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    
    await for (final message in port) {
      final cameraImage = message[0] as CameraImage;
      final responsePort = message[1] as SendPort;
      
      try {
        final result = _convertCameraImage(cameraImage);
        responsePort.send(result);
      } catch (e) {
        responsePort.send(Uint8List(0));
      }
    }
  }

  static Uint8List _convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420ToRGB(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888ToRGB(cameraImage);
    } else {
      throw UnsupportedError('Unsupported image format');
    }
  }

  static Uint8List _convertYUV420ToRGB(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];
    
    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;
    
    final image = img.Image(width: width, height: height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);
        
        if (yIndex >= yBuffer.length || uvIndex >= uBuffer.length || uvIndex >= vBuffer.length) {
          continue;
        }
        
        final yValue = yBuffer[yIndex];
        final uValue = uBuffer[uvIndex];
        final vValue = vBuffer[uvIndex];
        
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).clamp(0, 255).toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();
        
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    
    return Uint8List.fromList(img.encodeJpg(image));
  }

  static Uint8List _convertBGRA8888ToRGB(CameraImage cameraImage) {
    final bytes = cameraImage.planes[0].bytes;
    final width = cameraImage.width;
    final height = cameraImage.height;
    
    final image = img.Image(width: width, height: height);
    
    for (int i = 0, j = 0; i < bytes.length && j < width * height; i += 4, j++) {
      final x = j % width;
      final y = j ~/ width;
      
      final r = bytes[i + 2];
      final g = bytes[i + 1];
      final b = bytes[i];
      
      image.setPixelRgb(x, y, r, g, b);
    }
    
    return Uint8List.fromList(img.encodeJpg(image));
  }
}
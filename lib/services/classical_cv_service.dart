import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/enhanced_detection_result.dart';

class ClassicalCVService {
  static const int imageSize = 224;
  static const int textureSize = 128;

  Future<VisualFeatures> analyzeImage(File imageFile) async {
    try {
      // Load image using Flutter's built-in capabilities
      Uint8List imageBytes = await imageFile.readAsBytes();
      ui.Image? image = await _loadImageFromBytes(imageBytes);

      if (image == null) {
        return _createFallbackVisualFeatures();
      }

      // Analyze different visual features
      EdgeFeatures edgeFeatures = await _analyzeEdges(image);
      ColorFeatures colorFeatures = await _analyzeColors(image);
      TextureFeatures textureFeatures = await _analyzeTexture(image);

      return VisualFeatures(
        edgeFeatures: edgeFeatures,
        colorFeatures: colorFeatures,
        textureFeatures: textureFeatures,
      );
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      return _createFallbackVisualFeatures();
    }
  }

  Future<VisualFeatures> analyzeImageFromBytes(Uint8List imageBytes) async {
    try {
      ui.Image? image = await _loadImageFromBytes(imageBytes);

      if (image == null) {
        return _createFallbackVisualFeatures();
      }

      EdgeFeatures edgeFeatures = await _analyzeEdges(image);
      ColorFeatures colorFeatures = await _analyzeColors(image);
      TextureFeatures textureFeatures = await _analyzeTexture(image);

      return VisualFeatures(
        edgeFeatures: edgeFeatures,
        colorFeatures: colorFeatures,
        textureFeatures: textureFeatures,
      );
    } catch (e) {
      debugPrint('Error analyzing image from bytes: $e');
      return _createFallbackVisualFeatures();
    }
  }

  Future<ui.Image?> _loadImageFromBytes(Uint8List bytes) async {
    try {
      // Create a codec from bytes
      ui.Codec codec = await ui.instantiateImageCodec(bytes);

      // Get the first frame
      ui.FrameInfo frameInfo = await codec.getNextFrame();

      return frameInfo.image;
    } catch (e) {
      debugPrint('Error loading image from bytes: $e');
      return null;
    }
  }

  Future<ui.Image?> _loadImageFromFile(File imageFile) async {
    try {
      Uint8List bytes = await imageFile.readAsBytes();
      return await _loadImageFromBytes(bytes);
    } catch (e) {
      debugPrint('Error loading image from file: $e');
      return null;
    }
  }

  Future<EdgeFeatures> _analyzeEdges(ui.Image image) async {
    try {
      // Simple edge analysis using gradient calculation
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return _createFallbackEdgeFeatures();
      }

      int width = image.width;
      int height = image.height;

      // Calculate edge density (simplified)
      double edgeCount = 0;
      int totalPixels = 0;

      for (int y = 1; y < height - 1; y += 5) {
        for (int x = 1; x < width - 1; x += 5) {
          // Get 3x3 neighborhood
          List<int> neighbors = [];
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              int pixelIndex = ((x + dx) + width * (y + dy)) * 4;
              int r = byteData.getUint8(pixelIndex);
              int g = byteData.getUint8(pixelIndex + 1);
              int b = byteData.getUint8(pixelIndex + 2);
              neighbors.add((r + g + b) ~/ 3);
            }
          }

          // Simple edge detection using threshold
          int center = neighbors[4];
          bool isEdge = false;
          for (int i = 0; i < neighbors.length; i++) {
            if (i != 4 && (neighbors[i] - center).abs() > 30) {
              isEdge = true;
              break;
            }
          }

          if (isEdge) edgeCount++;
          totalPixels++;
        }
      }

      double edgeDensity = totalPixels > 0 ? edgeCount / totalPixels : 0.0;

      return EdgeFeatures(
        edgeDensity: edgeDensity,
        edgeDistribution: _calculateEdgeDistribution(edgeDensity),
        edgeConsistency: edgeDensity > 0.1 ? 0.8 : 0.3,
        edgeSharpness: edgeDensity * 2.0,
        edgeMetrics: {
          'edge_density': edgeDensity,
          'edge_count': edgeCount.toDouble(),
          'total_pixels': totalPixels.toDouble(),
        },
      );
    } catch (e) {
      debugPrint('Error analyzing edges: $e');
      return _createFallbackEdgeFeatures();
    }
  }

  double _calculateEdgeDistribution(double edgeDensity) {
    // Simple distribution calculation
    if (edgeDensity < 0.1) return 0.3; // Too few edges
    if (edgeDensity < 0.3) return 0.8; // Good distribution
    if (edgeDensity > 0.5) return 0.6; // Too many edges (possible noise)
    return 0.7; // Medium distribution
  }

  Future<ColorFeatures> _analyzeColors(ui.Image image) async {
    try {
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return _createFallbackColorFeatures();
      }

      int width = image.width;
      int height = image.height;

      // Calculate color statistics
      int totalR = 0, totalG = 0, totalB = 0;
      int pixelCount = 0;
      Map<int, int> histogram = {};

      for (int y = 0; y < height; y += 10) {
        for (int x = 0; x < width; x += 10) {
          int pixelIndex = (x + width * y) * 4;
          int r = byteData.getUint8(pixelIndex);
          int g = byteData.getUint8(pixelIndex + 1);
          int b = byteData.getUint8(pixelIndex + 2);

          totalR += r;
          totalG += g;
          totalB += b;
          pixelCount++;

          int gray = ((r + g + b) ~/ 3);
          histogram[gray] = (histogram[gray] ?? 0) + 1;
        }
      }

      // Calculate color variance
      double meanR = pixelCount > 0 ? totalR / pixelCount : 0;
      double meanG = pixelCount > 0 ? totalG / pixelCount : 0;
      double meanB = pixelCount > 0 ? totalB / pixelCount : 0;

      double variance = 0;
      if (pixelCount > 0) {
        for (int y = 0; y < height; y += 10) {
          for (int x = 0; x < width; x += 10) {
            int pixelIndex = (x + width * y) * 4;
            int r = byteData.getUint8(pixelIndex);
            int g = byteData.getUint8(pixelIndex + 1);
            int b = byteData.getUint8(pixelIndex + 2);

            variance += pow(r - meanR, 2) + pow(g - meanG, 2) + pow(b - meanB, 2);
          }
        }
        variance /= (pixelCount / 100); // Account for sampling
      }

      // Calculate saturation
      double totalSaturation = 0;
      for (int y = 0; y < height; y += 20) {
        for (int x = 0; x < width; x += 20) {
          int pixelIndex = (x + width * y) * 4;
          int r = byteData.getUint8(pixelIndex);
          int g = byteData.getUint8(pixelIndex + 1);
          int b = byteData.getUint8(pixelIndex + 2);

          int maxVal = max(r, max(g, b));
          int minVal = min(r, min(g, b));
          double saturation = maxVal == 0 ? 0 : (maxVal - minVal) / maxVal;
          totalSaturation += saturation;
        }
      }

      return ColorFeatures(
        colorVariance: variance / (255 * 255 * 3), // Normalize
        saturationProfile: _categorizeSaturation(totalSaturation / (pixelCount ~/ 400)),
        lightingPattern: _analyzeLightingPattern(meanR, meanG, meanB),
        colorfulness: _calculateColorfulness(histogram),
        colorMetrics: {
          'mean_r': meanR,
          'mean_g': meanG,
          'mean_b': meanB,
          'pixel_count': pixelCount.toDouble(),
          'saturation_avg': totalSaturation / (pixelCount ~/ 400),
        },
      );
    } catch (e) {
      debugPrint('Error analyzing colors: $e');
      return _createFallbackColorFeatures();
    }
  }

  String _categorizeSaturation(double saturation) {
    if (saturation > 0.6) return 'high';
    if (saturation > 0.3) return 'medium';
    if (saturation > 0.1) return 'low';
    return 'very_low';
  }

  String _analyzeLightingPattern(double meanR, double meanG, double meanB) {
    double brightness = (meanR + meanG + meanB) / 3;

    if (brightness < 50) return 'dark';
    if (brightness < 100) return 'low_light';
    if (brightness > 200) return 'bright';
    return 'natural';
  }

  double _calculateColorfulness(Map<int, int> histogram) {
    // Simple colorfulness calculation based on histogram distribution
    if (histogram.isEmpty) return 0.0;

    List<int> values = histogram.values.toList();
    int total = values.reduce((a, b) => a + b);

    if (total == 0) return 0.0;

    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;

    return variance / (mean * mean + 1e-6); // Normalized colorfulness
  }

  Future<TextureFeatures> _analyzeTexture(ui.Image image) async {
    try {
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return _createFallbackTextureFeatures();
      }

      int width = image.width;
      int height = image.height;

      // Simple texture analysis using local binary patterns
      double lbpPattern = _calculateLBP(byteData, width, height);
      double noiseLevel = _calculateNoiseLevel(byteData, width, height);
      double compressionArtifacts = _detectCompressionArtifacts(byteData, width, height);
      double textureComplexity = _calculateTextureComplexity(lbpPattern, noiseLevel);

      return TextureFeatures(
        lbpPattern: lbpPattern,
        glcmFeatures: {
          'contrast': _calculateContrast(byteData, width, height),
          'homogeneity': _calculateHomogeneity(byteData, width, height),
          'energy': _calculateEnergy(byteData, width, height),
        },
        noiseProfile: noiseLevel,
        compressionArtifacts: compressionArtifacts,
        textureComplexity: textureComplexity,
        textureMetrics: {
          'lbp_uniformity': lbpPattern,
          'noise_level': noiseLevel,
          'compression_level': compressionArtifacts,
        },
      );
    } catch (e) {
      debugPrint('Error analyzing texture: $e');
      return _createFallbackTextureFeatures();
    }
  }

  double _calculateLBP(ByteData byteData, int width, int height) {
    int uniformPatterns = 0;
    int totalPatterns = 0;

    // Simplified LBP calculation (only sampling some pixels)
    for (int y = 1; y < height - 1; y += 10) {
      for (int x = 1; x < width - 1; x += 10) {
        int center = _getLuminance(byteData, width, x, y);

        // Get 8 neighbors
        List<int> neighbors = [
          _getLuminance(byteData, width, x-1, y-1),
          _getLuminance(byteData, width, x, y-1),
          _getLuminance(byteData, width, x+1, y-1),
          _getLuminance(byteData, width, x+1, y),
          _getLuminance(byteData, width, x+1, y+1),
          _getLuminance(byteData, width, x, y+1),
          _getLuminance(byteData, width, x-1, y+1),
          _getLuminance(byteData, width, x-1, y),
        ];

        // Calculate simplified LBP
        int lbp = 0;
        for (int i = 0; i < 8; i++) {
          if (neighbors[i] >= center) {
            lbp |= (1 << i);
          }
        }

        // Check if uniform pattern (simplified)
        int transitions = 0;
        for (int i = 0; i < 8; i++) {
          int current = (lbp >> i) & 1;
          int next = (lbp >> ((i + 1) % 8)) & 1;
          if (current != next) transitions++;
        }

        if (transitions <= 2) {
          uniformPatterns++;
        }
        totalPatterns++;
      }
    }

    return totalPatterns > 0 ? uniformPatterns / totalPatterns : 0.0;
  }

  int _getLuminance(ByteData byteData, int width, int x, int y) {
    int pixelIndex = (x + width * y) * 4;
    int r = byteData.getUint8(pixelIndex);
    int g = byteData.getUint8(pixelIndex + 1);
    int b = byteData.getUint8(pixelIndex + 2);
    return ((r * 299 + g * 587 + b * 114 + 500) ~/ 1000);
  }

  double _calculateNoiseLevel(ByteData byteData, int width, int height) {
    // Simple noise estimation using local variance
    double totalVariance = 0;
    int sampleCount = 0;

    for (int y = 2; y < height - 2; y += 20) {
      for (int x = 2; x < width - 2; x += 20) {
        // Calculate local variance in 3x3 neighborhood
        List<int> values = [];
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            values.add(_getLuminance(byteData, width, x + dx, y + dy));
          }
        }

        double mean = values.reduce((a, b) => a + b) / values.length;
        double variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;

        totalVariance += variance;
        sampleCount++;
      }
    }

    return sampleCount > 0 ? totalVariance / sampleCount : 0.0;
  }

  double _detectCompressionArtifacts(ByteData byteData, int width, int height) {
    // Simplified compression artifact detection
    int blockBoundaries = 0;
    int totalBoundaries = 0;

    // Check for JPEG-like 8x8 block boundaries
    for (int y = 8; y < height; y += 8) {
      for (int x = 0; x < width; x++) {
        int current = _getLuminance(byteData, width, x, y);
        if (y > 0) {
          int above = _getLuminance(byteData, width, x, y-1);
          if ((current - above).abs() > 20) {
            blockBoundaries++;
          }
          totalBoundaries++;
        }
      }
    }

    return totalBoundaries > 0 ? blockBoundaries / totalBoundaries : 0.0;
  }

  double _calculateTextureComplexity(double lbpPattern, double noiseLevel) {
    // Complexity based on LBP uniformity and noise
    return (lbpPattern * 0.6 + (1.0 - noiseLevel.clamp(0.0, 1.0)) * 0.4).clamp(0.0, 1.0);
  }

  double _calculateContrast(ByteData byteData, int width, int height) {
    double totalContrast = 0;
    int sampleCount = 0;

    for (int y = 0; y < height - 1; y += 10) {
      for (int x = 0; x < width - 1; x += 10) {
        int pixel1 = _getLuminance(byteData, width, x, y);
        int pixel2 = _getLuminance(byteData, width, x + 1, y);
        totalContrast += (pixel2 - pixel1).abs();
        sampleCount++;
      }
    }

    return sampleCount > 0 ? totalContrast / sampleCount : 0.0;
  }

  double _calculateHomogeneity(ByteData byteData, int width, int height) {
    double totalHomogeneity = 0;
    int sampleCount = 0;

    for (int y = 0; y < height - 1; y += 10) {
      for (int x = 0; x < width - 1; x += 10) {
        int pixel1 = _getLuminance(byteData, width, x, y);
        int pixel2 = _getLuminance(byteData, width, x + 1, y);

        double homogeneity = 1.0 / (1.0 + (pixel1 - pixel2).abs());
        totalHomogeneity += homogeneity;
        sampleCount++;
      }
    }

    return sampleCount > 0 ? totalHomogeneity / sampleCount : 0.0;
  }

  double _calculateEnergy(ByteData byteData, int width, int height) {
    double totalEnergy = 0;
    int sampleCount = 0;

    for (int y = 0; y < height; y += 10) {
      for (int x = 0; x < width; x += 10) {
        int pixel = _getLuminance(byteData, width, x, y);
        totalEnergy += pixel * pixel / (255.0 * 255.0);
        sampleCount++;
      }
    }

    return sampleCount > 0 ? totalEnergy / sampleCount : 0.0;
  }

  // Fallback methods
  VisualFeatures _createFallbackVisualFeatures() {
    return VisualFeatures(
      edgeFeatures: _createFallbackEdgeFeatures(),
      colorFeatures: _createFallbackColorFeatures(),
      textureFeatures: _createFallbackTextureFeatures(),
    );
  }

  EdgeFeatures _createFallbackEdgeFeatures() {
    return EdgeFeatures(
      edgeDensity: 0.1,
      edgeDistribution: 0.5,
      edgeConsistency: 0.5,
      edgeSharpness: 0.3,
      edgeMetrics: {'fallback': 1.0},
    );
  }

  ColorFeatures _createFallbackColorFeatures() {
    return ColorFeatures(
      colorVariance: 0.3,
      saturationProfile: 'unknown',
      lightingPattern: 'unknown',
      colorfulness: 0.5,
      colorMetrics: {'fallback': 1.0},
    );
  }

  TextureFeatures _createFallbackTextureFeatures() {
    return TextureFeatures(
      lbpPattern: 0.5,
      glcmFeatures: {
        'contrast': 0.5,
        'homogeneity': 0.5,
        'energy': 0.5,
      },
      noiseProfile: 0.3,
      compressionArtifacts: 0.1,
      textureComplexity: 0.5,
      textureMetrics: {'fallback': 1.0},
    );
  }
}
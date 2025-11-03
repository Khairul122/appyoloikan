# Dependencies Installation Instructions

## Required Dependencies

The enhanced detection system requires the following additional dependencies. Add these to your `pubspec.yaml`:

```yaml
dependencies:
  # Enhanced detection dependencies
  exif: ^3.3.0

  # UI utilities for charts and visualizations
  fl_chart: ^0.68.0
  charts_flutter: ^0.12.0
```

## Installation Steps

1. **Add dependencies to pubspec.yaml:**
   ```yaml
   dependencies:
     flutter:
       sdk: flutter

     # ... existing dependencies

     # Enhanced detection dependencies
     exif: ^3.3.0

     # UI utilities
     fl_chart: ^0.68.0
     charts_flutter: ^0.12.0
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Clean build (if needed):**
   ```bash
   flutter clean
   flutter pub get
   ```

## Updated Complete pubspec.yaml

Here's the complete dependencies section with all required packages:

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8

  get: ^4.6.6
  provider: ^6.0.5
  get_it: ^7.7.0

  camera: ^0.11.2
  image: ^4.2.0
  image_picker: ^1.0.7

  ultralytics_yolo: ^0.1.36
  flutter_vision: ^2.0.0

  permission_handler: ^11.3.1

  flutter_tts: ^4.0.2

  path_provider: ^2.1.2
  path: ^1.8.3
  shared_preferences: ^2.2.2

  flutter_speed_dial: ^7.0.0
  animated_text_kit: ^4.2.2
  flutter_staggered_animations: ^1.1.1
  lottie: ^3.3.1

  # Dependencies for enhanced detection
  exif: ^3.3.0

  # UI utilities
  fl_chart: ^0.68.0
  charts_flutter: ^0.12.0
```

## Troubleshooting

### Issues with charts_flutter
`charts_flutter` package is discontinued but still functional. If you encounter issues, you can:
1. Use `fl_chart` instead (recommended)
2. Or use an alternative charting package

### Version Conflicts
If you encounter version conflicts, try:
```bash
flutter pub deps
flutter pub upgrade
```

### iOS/MacOS Specific
For iOS/MacOS, you might need to update platform-specific dependencies:
```bash
cd ios && pod install
cd ../macos && pod install
```

## Next Steps

After installing dependencies:

1. Run `flutter analyze` to check for any remaining issues
2. Test the enhanced detection functionality
3. Check the integration guide: `INTEGRATION_GUIDE.md`

## Verification

To verify dependencies are correctly installed:

```bash
flutter pub deps --style=tree
```

Look for these packages in the output:
- `exif`
- `fl_chart`
- `charts_flutter`
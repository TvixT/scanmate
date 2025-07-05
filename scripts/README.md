# ScanMate Asset Generation Scripts

This directory contains tools for generating placeholder assets during development.

## Scripts

### generate_placeholders.py
Creates basic placeholder images for app branding:
- **app_icon.png**: 1024x1024 app icon with blue gradient and scanner frame
- **splash_icon.png**: 512x512 transparent splash icon 
- **scanmate_logo.png**: 300x80 text logo for branding

**Requirements**: 
```bash
pip install Pillow
```

**Usage**:
```bash
cd a:\fproject\scanmate
python scripts\generate_placeholders.py
```

**Output**: Creates PNG files in assets/icons/ and assets/images/ directories

## Production Assets

In production, replace the generated placeholder files with professionally designed graphics:

1. **App Icon**: High-quality 1024x1024 PNG with adaptive icon layers
2. **Splash Icon**: 512x512 PNG with transparent background
3. **Logos**: SVG or high-resolution PNG logos for various contexts

## Asset Pipeline

Once production assets are ready:

1. Place final PNG files in correct asset directories
2. Uncomment flutter_launcher_icons configuration in pubspec.yaml
3. Uncomment flutter_native_splash configuration in pubspec.yaml
4. Run: `flutter packages pub run flutter_launcher_icons`
5. Run: `flutter packages pub run flutter_native_splash`
6. Test build: `flutter build apk --debug`

## Design Specifications

See individual asset specification files:
- `assets/icons/app_icon_spec.md`
- `assets/icons/README.md`
- `assets/images/logo_specification.md`

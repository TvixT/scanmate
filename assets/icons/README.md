# ScanMate Placeholder Assets

This directory contains placeholder specifications for ScanMate branding assets.

In a production environment, these would be replaced with actual graphic files:

## Required Assets:
- `app_icon.png` (1024x1024) - Main app icon
- `splash_icon.png` (512x512) - Splash screen icon
- `splash_icon_dark.png` (512x512) - Dark theme splash icon
- `scanmate_logo.png` (300x100) - Horizontal logo
- `scanmate_logo_dark.png` (300x100) - Dark theme logo

## Icon Design Concept:
- Circular/rounded square background with gradient (#2563EB to #1D4ED8)
- Centered scanner viewfinder icon in white
- Business card outline within the viewfinder
- Modern, professional appearance
- High contrast for visibility

## Logo Design Concept:
- "ScanMate" text in clean, modern font
- Scanner icon integrated into the 'S' or as standalone element
- Consistent with app icon styling
- Available in light and dark variants

## Implementation Note:
The app is currently configured to use these assets via flutter_launcher_icons
and flutter_native_splash packages. To complete the branding setup:

1. Create actual PNG files based on these specifications
2. Place them in the assets/icons/ directory
3. Run: flutter pub run flutter_launcher_icons
4. Run: flutter pub run flutter_native_splash:create

For this demo, the app will function with default Flutter branding.

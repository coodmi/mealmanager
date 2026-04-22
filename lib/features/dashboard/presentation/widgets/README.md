# Ads Banner Widget

## Overview
The `AdsBanner` widget displays auto-scrolling advertisement banners on the dashboard, similar to the bKash scroll system. Now with production-ready features and real ad provider integration support.

## Features
- ✅ Auto-scrollable banner (configurable timing)
- ✅ Multiple ads support with smooth transitions
- ✅ Page indicators showing current ad position
- ✅ Configurable banner sizes (50px, 100px, 250px)
- ✅ Click tracking and analytics support
- ✅ URL launcher integration ready
- ✅ Google AdMob integration support
- ✅ Adsterra integration support
- ✅ Custom image ads support
- ✅ Responsive design with animations

## Quick Start

### Basic Usage
```dart
import '../widgets/ads_banner.dart';
import '../widgets/ads_config.dart';

// Standard 320x50 banner
const AdsBanner(
  height: AdsConfig.bannerHeight320x50,
  autoScrollDuration: AdsConfig.autoScrollDuration,
)
```

### Configuration Options
```dart
// Large banner (320x100)
const AdsBanner(height: AdsConfig.bannerHeight320x100)

// Disable auto-scroll
const AdsBanner(
  height: AdsConfig.bannerHeight320x50,
  enableAutoScroll: false,
)

// Custom scroll timing (10 seconds)
const AdsBanner(
  height: AdsConfig.bannerHeight320x50,
  autoScrollDuration: Duration(seconds: 10),
)
```

## Banner Sizes

Standard IAB sizes available in `AdsConfig`:
- **320x50**: Mobile banner (default, recommended)
- **320x100**: Large mobile banner
- **300x250**: Medium rectangle

## Current Implementation

### Sample Ads
The widget currently uses sample ads with:
- Gradient backgrounds
- Title and subtitle text
- Click tracking
- Smooth animations
- Page indicators

### Ad Data Structure
```dart
{
  'id': 'ad_001',
  'image': 'assets/images/ads/ad_placeholder_1.png',
  'color': const Color(0xFFE91E63),
  'title': 'Special Offer!',
  'subtitle': 'Get 50% off on premium',
  'url': 'https://example.com/offer1',
  'provider': 'sample',
}
```

## Integration with Real Ads

### Option 1: Google AdMob
See `INTEGRATION_GUIDE.md` for complete AdMob setup:
1. Add `google_mobile_ads` dependency
2. Configure Android/iOS
3. Initialize AdMob
4. Use `AdMobBannerWidget`

### Option 2: Adsterra
See `INTEGRATION_GUIDE.md` for Adsterra setup:
1. Add `webview_flutter` dependency
2. Get Zone ID from Adsterra
3. Use `AdsterraBanner` widget

### Option 3: Custom Image Ads
1. Add images to `assets/images/ads/`
2. Update `_ads` list in `ads_banner.dart`
3. Optionally fetch from backend API

## Configuration File

Edit `ads_config.dart` to customize:
```dart
class AdsConfig {
  // Banner dimensions
  static const double bannerHeight320x50 = 50.0;
  static const double bannerHeight320x100 = 100.0;
  
  // Timing
  static const Duration autoScrollDuration = Duration(seconds: 5);
  
  // Provider settings
  static const bool useRealAds = false;
  static const String adProvider = 'sample'; // 'admob', 'adsterra', 'sample'
  
  // Ad IDs
  static const String admobBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String adsterraZoneId = 'YOUR_ZONE_ID';
}
```

## Analytics & Tracking

The widget includes click tracking:
```dart
void _trackAdClick(String adId) {
  // Implement your analytics here
  // Firebase Analytics, Google Analytics, etc.
  debugPrint('Ad clicked: $adId');
}
```

## URL Launcher Integration

To open ad URLs, add to `pubspec.yaml`:
```yaml
dependencies:
  url_launcher: ^6.3.0
```

Then update `_handleAdClick`:
```dart
import 'package:url_launcher/url_launcher.dart';

void _handleAdClick(Map<String, dynamic> ad) async {
  _trackAdClick(ad['id'] as String);
  await launchUrl(Uri.parse(ad['url']));
}
```

## Location
The ads banner is displayed on the dashboard after the "Quick Actions" section.

## Files
- `ads_banner.dart` - Main banner widget
- `ads_config.dart` - Configuration constants
- `INTEGRATION_GUIDE.md` - Complete integration guide
- `README.md` - This file

## Next Steps

1. ✅ Choose ad provider (AdMob, Adsterra, or custom)
2. ✅ Follow integration guide for your provider
3. ✅ Add real ad images or configure ad units
4. ✅ Test with test IDs first
5. ✅ Implement analytics tracking
6. ✅ Deploy with production ad IDs

## Support

For detailed integration instructions, see `INTEGRATION_GUIDE.md`.

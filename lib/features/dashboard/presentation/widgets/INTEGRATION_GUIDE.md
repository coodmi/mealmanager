# Ads Banner Integration Guide

## Overview
This guide explains how to integrate real ads into your Flutter app using Google AdMob or Adsterra.

---

## Option 1: Google AdMob Integration

### Step 1: Add Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  google_mobile_ads: ^5.1.0
  url_launcher: ^6.3.0
```

Run:
```bash
flutter pub get
```

### Step 2: Configure AdMob

#### Android Configuration
1. Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <application>
        <!-- AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
    </application>
</manifest>
```

#### iOS Configuration
1. Add to `ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
</array>
```

### Step 3: Initialize AdMob
Update `lib/main.dart`:
```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MealManagerApp());
}
```

### Step 4: Create AdMob Banner Widget
Create `lib/features/dashboard/presentation/widgets/admob_banner.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_config.dart';

class AdMobBannerWidget extends StatefulWidget {
  const AdMobBannerWidget({super.key});

  @override
  State<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdsConfig.admobBannerId,
      size: AdSize.banner, // 320x50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Ad failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Ads',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ],
      ),
    );
  }
}
```

### Step 5: Update Dashboard
Replace `AdsBanner` with `AdMobBannerWidget` in `dashboard_page.dart`:
```dart
// Replace this:
const AdsBanner(
  height: AdsConfig.bannerHeight320x50,
  autoScrollDuration: AdsConfig.autoScrollDuration,
),

// With this:
const AdMobBannerWidget(),
```

### Step 6: Get Real Ad Unit IDs
1. Go to [AdMob Console](https://apps.admob.com/)
2. Create an app
3. Create ad units (Banner)
4. Replace test IDs in `ads_config.dart` with your real IDs

---

## Option 2: Adsterra Integration

### Step 1: Add Dependencies
```yaml
dependencies:
  webview_flutter: ^4.8.0
  url_launcher: ^6.3.0
```

### Step 2: Create Adsterra Banner Widget
Create `lib/features/dashboard/presentation/widgets/adsterra_banner.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'ads_config.dart';

class AdsterraBanner extends StatefulWidget {
  const AdsterraBanner({super.key});

  @override
  State<AdsterraBanner> createState() => _AdsterraBannerState();
}

class _AdsterraBannerState extends State<AdsterraBanner> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_getAdsterraHtml());
  }

  String _getAdsterraHtml() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { margin: 0; padding: 0; }
      </style>
    </head>
    <body>
      <script type="text/javascript">
        atOptions = {
          'key' : '${AdsConfig.adsterraZoneId}',
          'format' : 'iframe',
          'height' : 50,
          'width' : 320,
          'params' : {}
        };
      </script>
      <script type="text/javascript" src="//www.topcreativeformat.com/key/invoke.js"></script>
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Ads',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
```

### Step 3: Get Adsterra Zone ID
1. Sign up at [Adsterra](https://www.adsterra.com/)
2. Create a banner ad unit
3. Get your Zone ID
4. Update `AdsConfig.adsterraZoneId`

---

## Option 3: Custom Image Ads (Current Implementation)

### Using Real Images
1. Add your ad images to `assets/images/ads/`
2. Update `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/ads/
```

3. Update the `_ads` list in `ads_banner.dart`:
```dart
final List<Map<String, dynamic>> _ads = [
  {
    'id': 'ad_001',
    'image': 'assets/images/ads/your_banner_1.png',
    'color': const Color(0xFFE91E63),
    'title': 'Your Product',
    'subtitle': 'Special offer',
    'url': 'https://yourwebsite.com/offer',
    'provider': 'custom',
  },
  // Add more ads...
];
```

### Fetching Ads from Backend
Create an API service to fetch ads dynamically:
```dart
class AdsService {
  Future<List<Map<String, dynamic>>> fetchAds() async {
    final response = await http.get(
      Uri.parse('https://your-api.com/ads'),
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
        json.decode(response.body)['ads'],
      );
    }
    return [];
  }
}
```

---

## Configuration Options

### Banner Sizes
In `ads_config.dart`:
```dart
// Standard IAB sizes
static const double bannerHeight320x50 = 50.0;   // Mobile banner
static const double bannerHeight320x100 = 100.0; // Large mobile banner
static const double bannerHeight300x250 = 250.0; // Medium rectangle
```

### Auto-Scroll Timing
```dart
static const Duration autoScrollDuration = Duration(seconds: 5);
```

### Usage in Dashboard
```dart
// 320x50 banner (recommended for mobile)
const AdsBanner(height: AdsConfig.bannerHeight320x50)

// 320x100 banner (larger)
const AdsBanner(height: AdsConfig.bannerHeight320x100)

// Disable auto-scroll
const AdsBanner(
  height: AdsConfig.bannerHeight320x50,
  enableAutoScroll: false,
)

// Custom scroll duration
const AdsBanner(
  height: AdsConfig.bannerHeight320x50,
  autoScrollDuration: Duration(seconds: 10),
)
```

---

## Analytics Integration

### Track Ad Clicks
Update `_trackAdClick` in `ads_banner.dart`:
```dart
void _trackAdClick(String adId) {
  // Firebase Analytics
  FirebaseAnalytics.instance.logEvent(
    name: 'ad_click',
    parameters: {'ad_id': adId},
  );
  
  // Or custom analytics
  // AnalyticsService.trackEvent('ad_click', {'ad_id': adId});
}
```

---

## Testing

### Test IDs
- **AdMob Test Banner ID**: `ca-app-pub-3940256099942544/6300978111`
- Always use test IDs during development
- Replace with real IDs before production release

### Verify Integration
1. Run app: `flutter run`
2. Check console for ad loading messages
3. Verify ads display correctly
4. Test ad clicks

---

## Best Practices

1. **Ad Placement**: Place ads where they don't disrupt user experience
2. **Loading States**: Show placeholders while ads load
3. **Error Handling**: Gracefully handle ad load failures
4. **Privacy**: Comply with GDPR/CCPA regulations
5. **Ad Frequency**: Don't overwhelm users with too many ads
6. **Performance**: Monitor app performance with ads enabled

---

## Troubleshooting

### Ads Not Showing
- Check internet connection
- Verify ad unit IDs are correct
- Ensure AdMob is initialized
- Check console for error messages
- Verify app is registered in AdMob console

### Ad Load Failures
- Use test IDs first to verify integration
- Check ad inventory availability
- Verify targeting settings in AdMob console

---

## Revenue Optimization

1. **Ad Placement**: Test different positions
2. **Ad Formats**: Try different banner sizes
3. **Refresh Rate**: Balance between revenue and UX
4. **Mediation**: Use AdMob mediation for better fill rates
5. **A/B Testing**: Test different ad configurations

---

## Support

- **AdMob**: [AdMob Help Center](https://support.google.com/admob)
- **Adsterra**: [Adsterra Support](https://adsterra.com/support/)
- **Flutter Ads**: [google_mobile_ads package](https://pub.dev/packages/google_mobile_ads)

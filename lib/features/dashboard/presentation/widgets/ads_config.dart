/// Configuration for ads banner
class AdsConfig {
  // Banner dimensions (standard IAB sizes)
  static const double bannerHeight320x50 = 50.0;
  static const double bannerHeight320x100 = 100.0;
  static const double bannerHeight300x250 = 250.0;

  // Auto-scroll timing
  static const Duration autoScrollDuration = Duration(seconds: 5);
  static const Duration transitionDuration = Duration(milliseconds: 400);

  // Ad provider settings
  static const bool useRealAds = false; // Set to true when integrating real ads
  static const String adProvider = 'sample'; // 'admob', 'adsterra', 'sample'

  // AdMob IDs (replace with your actual IDs)
  static const String admobBannerId =
      'ca-app-pub-3940256099942544/6300978111'; // Test ID

  // Adsterra settings
  static const String adsterraZoneId = 'YOUR_ZONE_ID';
}

import 'package:flutter/material.dart';
import 'dart:async';
import 'ads_config.dart';

class AdsBanner extends StatefulWidget {
  final double height;
  final Duration autoScrollDuration;
  final bool enableAutoScroll;

  const AdsBanner({
    super.key,
    this.height = AdsConfig.bannerHeight320x50,
    this.autoScrollDuration = AdsConfig.autoScrollDuration,
    this.enableAutoScroll = true,
  });

  @override
  State<AdsBanner> createState() => _AdsBannerState();
}

class _AdsBannerState extends State<AdsBanner> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  // Sample ad banners - Replace with actual ad provider data
  // For real ads, fetch from your backend or ad provider API
  final List<Map<String, dynamic>> _ads = [
    {
      'id': 'ad_001',
      'image': 'assets/images/ads/ad_placeholder_1.png',
      'color': const Color(0xFFE91E63),
      'title': 'Special Offer!',
      'subtitle': 'Get 50% off on premium',
      'url': 'https://example.com/offer1',
      'provider': 'sample',
    },
    {
      'id': 'ad_002',
      'image': 'assets/images/ads/ad_placeholder_2.png',
      'color': const Color(0xFF2196F3),
      'title': 'New Feature',
      'subtitle': 'Try our latest update',
      'url': 'https://example.com/feature',
      'provider': 'sample',
    },
    {
      'id': 'ad_003',
      'image': 'assets/images/ads/ad_placeholder_3.png',
      'color': const Color(0xFF4CAF50),
      'title': 'Limited Time',
      'subtitle': 'Exclusive deals inside',
      'url': 'https://example.com/deals',
      'provider': 'sample',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.enableAutoScroll && _ads.length > 1) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(widget.autoScrollDuration, (timer) {
      if (_currentPage < _ads.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: AdsConfig.transitionDuration,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _handleAdClick(Map<String, dynamic> ad) {
    // Track ad click analytics
    _trackAdClick(ad['id'] as String);

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening: ${ad['title']}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // TODO: Open URL in browser or in-app webview
    // You can use url_launcher package:
    // await launchUrl(Uri.parse(ad['url']));
  }

  void _trackAdClick(String adId) {
    // TODO: Implement analytics tracking
    // Example: Firebase Analytics, Google Analytics, etc.
    debugPrint('Ad clicked: $adId');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty) {
      return const SizedBox.shrink();
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
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: _ads.length,
                    itemBuilder: (context, index) {
                      return _buildAdItem(_ads[index]);
                    },
                  ),
                  // Page indicators (only show if multiple ads)
                  if (_ads.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _ads.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPage == index ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdItem(Map<String, dynamic> ad) {
    return GestureDetector(
      onTap: () => _handleAdClick(ad),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ad['color'] as Color,
              (ad['color'] as Color).withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ad['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ad['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

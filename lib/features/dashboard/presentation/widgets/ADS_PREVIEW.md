# Ads Banner Visual Preview

## 📱 How It Looks

### Banner Layout (320x50px)
```
┌─────────────────────────────────────────────────────────┐
│  Ads                                                    │
│  ┌───────────────────────────────────────────────────┐ │
│  │  ○                                          ○      │ │
│  │     Special Offer!                    →           │ │
│  │     Get 50% off on premium                        │ │
│  │                                          ○         │ │
│  │                    ● ○ ○                          │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Features Visible
- **Gradient Background**: Pink to lighter pink (or blue/green for other ads)
- **Decorative Circles**: White semi-transparent circles for visual interest
- **Title**: Bold white text (16px)
- **Subtitle**: Lighter white text (12px)
- **Arrow Icon**: White arrow in rounded container
- **Page Indicators**: 3 dots at bottom (active dot is elongated)

## 🎨 Color Schemes

### Ad 1 - Pink Theme
```
Background: Linear gradient
  - Start: #E91E63 (Pink)
  - End: #E91E63 with 70% opacity
Title: "Special Offer!"
Subtitle: "Get 50% off on premium"
```

### Ad 2 - Blue Theme
```
Background: Linear gradient
  - Start: #2196F3 (Blue)
  - End: #2196F3 with 70% opacity
Title: "New Feature"
Subtitle: "Try our latest update"
```

### Ad 3 - Green Theme
```
Background: Linear gradient
  - Start: #4CAF50 (Green)
  - End: #4CAF50 with 70% opacity
Title: "Limited Time"
Subtitle: "Exclusive deals inside"
```

## 🎬 Animation Behavior

### Auto-Scroll Sequence
```
Second 0-5:   [Ad 1] ● ○ ○
              ↓ (smooth transition)
Second 5-10:  [Ad 2] ○ ● ○
              ↓ (smooth transition)
Second 10-15: [Ad 3] ○ ○ ●
              ↓ (smooth transition)
Second 15-20: [Ad 1] ● ○ ○  (loops back)
```

### Transition Details
- **Duration**: 400ms
- **Curve**: easeInOut
- **Type**: Horizontal slide
- **Indicator**: Animates width from 6px to 20px

## 📐 Dimensions

### Standard Banner (320x50)
```
Width:  320px (full width of container)
Height: 50px
Padding: 16px all sides
Border Radius: 12px
Shadow: 8px blur, 2px offset
```

### Large Banner (320x100)
```
Width:  320px
Height: 100px
Padding: 16px all sides
Border Radius: 12px
Shadow: 8px blur, 2px offset
```

## 🎯 Interactive States

### Normal State
```
┌───────────────────────────────────────┐
│  Special Offer!              →       │
│  Get 50% off on premium              │
└───────────────────────────────────────┘
```

### Hover/Tap State
```
┌───────────────────────────────────────┐
│  Special Offer!              →       │  ← Shows feedback
│  Get 50% off on premium              │
└───────────────────────────────────────┘
  ↓
  SnackBar: "Opening: Special Offer!"
```

## 📱 In Dashboard Context

```
┌─────────────────────────────────────────────┐
│  My Mess                    🌐 🔔          │
│  January 2026                              │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  My Balance                         │   │
│  │  ৳5000                              │   │
│  │  Mess Balance: ৳15000               │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  Monthly Overview                   │   │
│  │  [My] [Mess]                        │   │
│  │  Deposit: ৳2000  Expense: ৳1500     │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  Quick Actions                      │   │
│  │  [Deposit] [Expense] [Withdraw]     │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  Ads                                        │
│  ┌─────────────────────────────────────┐   │ ← NEW!
│  │  Special Offer!              →      │   │
│  │  Get 50% off on premium             │   │
│  │                    ● ○ ○            │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌──────────────┐  ┌──────────────┐       │
│  │ Today's Meal │  │    Bazar     │       │
│  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────┘
```

## 🎨 Design Elements

### Typography
- **"Ads" Label**: 12px, gray, medium weight
- **Ad Title**: 16px, white, bold
- **Ad Subtitle**: 12px, white 90% opacity, regular

### Spacing
- **Margin**: 8px vertical
- **Padding**: 16px all sides
- **Gap between elements**: 4-8px

### Colors
- **Shadow**: Black 8% opacity
- **Indicators (inactive)**: White 50% opacity
- **Indicators (active)**: White 100% opacity
- **Arrow container**: White 20% opacity

### Shapes
- **Banner**: 12px border radius
- **Arrow container**: 8px border radius
- **Indicators**: 3px border radius
- **Decorative circles**: Full circle

## 📊 Size Comparison

### 320x50 (Current - Recommended)
```
┌────────────────────────────────┐
│  Title                    →   │  ← Compact, non-intrusive
│  Subtitle                     │
└────────────────────────────────┘
```

### 320x100 (Large)
```
┌────────────────────────────────┐
│                                │
│  Title                    →   │  ← More prominent
│  Subtitle                     │
│                                │
└────────────────────────────────┘
```

### 300x250 (Medium Rectangle)
```
┌────────────────────────────────┐
│                                │
│                                │
│  Title                    →   │  ← Very prominent
│  Subtitle                     │
│                                │
│                                │
│                                │
└────────────────────────────────┘
```

## 💡 Visual Tips

1. **Current size (50px)** is perfect for mobile - not too intrusive
2. **Gradient backgrounds** make ads visually appealing
3. **Page indicators** clearly show which ad is active
4. **Smooth animations** provide professional feel
5. **Arrow icon** indicates ads are clickable

## 🎯 Customization Examples

### Change to Large Banner
```dart
const AdsBanner(height: AdsConfig.bannerHeight320x100)
```
Result: Banner becomes 100px tall with more breathing room

### Change Colors
```dart
// In ads_banner.dart
'color': const Color(0xFFFF9800), // Orange
```
Result: Orange gradient background instead of pink

### Add More Ads
```dart
// Add to _ads list
{
  'id': 'ad_004',
  'color': const Color(0xFF9C27B0), // Purple
  'title': 'Premium Features',
  'subtitle': 'Unlock all features',
}
```
Result: 4 ads cycling, indicators show ● ○ ○ ○

## 📱 Responsive Behavior

- **Small screens**: Banner scales to fit width
- **Large screens**: Banner maintains max width
- **Orientation change**: Adapts smoothly
- **Different densities**: Looks sharp on all displays

## ✨ Polish Details

1. **Shadow**: Adds depth and separation from content
2. **Rounded corners**: Modern, friendly appearance
3. **Gradient**: Adds visual interest
4. **Decorative circles**: Subtle background pattern
5. **Smooth transitions**: Professional feel
6. **Animated indicators**: Clear feedback

---

This preview shows exactly how the ads banner will appear in your app!

# HTTP Cleartext Permission Fix

## Problem
The web game was showing the error: `net::ERR_CLEARTEXT_NOT_PERMITTED`

This error occurs because:
1. **Android Security Policy**: By default, Android 9+ blocks HTTP (cleartext) traffic for security
2. **WebView Restrictions**: WebView enforces HTTPS-only policy unless explicitly configured
3. **Network Security**: The game server uses HTTP instead of HTTPS

## Solution Applied

### 1. Network Security Configuration
Created `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">147.93.103.135</domain>
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
    </domain-config>
</network-security-config>
```

This configuration:
- **Allows HTTP traffic** to the game server (147.93.103.135)
- **Permits localhost** for development/testing
- **Includes emulator IPs** (10.0.2.2) for testing

### 2. AndroidManifest.xml Updates
Updated the application tag to include:

```xml
<application 
    android:label="DLStarLive" 
    android:icon="@mipmap/ic_launcher" 
    android:networkSecurityConfig="@xml/network_security_config" 
    android:usesCleartextTraffic="true">
```

**Added attributes:**
- `android:networkSecurityConfig="@xml/network_security_config"` - References our security config
- `android:usesCleartextTraffic="true"` - Explicitly allows HTTP traffic

### 3. WebView Configuration Improvements
Enhanced WebView setup with:

```dart
_webViewController = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setBackgroundColor(const Color(0x00000000))
  ..enableZoom(false)
  ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
```

**Improvements:**
- **Disabled zoom** for better game experience
- **Set user agent** to ensure compatibility
- **Fixed URL usage** to use dynamic `completeUrl` instead of hardcoded URL

## Security Considerations

### Production Recommendations
For production apps, consider:

1. **Use HTTPS**: Request the game server to support HTTPS
```dart
// Preferred production URL
'https://games.yourdomain.com/greedy-stars/?user_id=${userId}'
```

2. **Specific Domain Config**: Only allow specific domains
```xml
<domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="false">147.93.103.135</domain>
    <!-- Remove localhost and emulator IPs for production -->
</domain-config>
```

3. **Conditional Configuration**: Use different configs for debug/release
```xml
<!-- For debug builds only -->
<domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="true">147.93.103.135</domain>
    <domain includeSubdomains="true">localhost</domain>
</domain-config>
```

## Testing Steps

### 1. Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### 2. Install and Test
```bash
flutter install
```

### 3. Verify Game Loading
1. Open the app
2. Navigate to live streaming
3. Tap game options
4. Tap "Greedy Stars"
5. Game should load without cleartext error

## Alternative Solutions

### If HTTPS is Available
```dart
// Update the game URL to use HTTPS
showWebGameBottomSheet(
  context,
  gameUrl: 'https://147.93.103.135:8001/game/?spain_time=30&profit=0',
  gameTitle: 'Greedy Stars',
  userId: userId,
);
```

### For Development Only
Add to debug AndroidManifest only:
```xml
<!-- android/app/src/debug/AndroidManifest.xml -->
<application android:usesCleartextTraffic="true" />
```

## Troubleshooting

### Still Getting Cleartext Error?
1. **Check file paths**: Ensure network_security_config.xml is in correct location
2. **Verify AndroidManifest**: Confirm both attributes are added
3. **Clean build**: Run `flutter clean` and rebuild
4. **Check domain**: Ensure game server domain matches config

### Alternative Debugging
Add this to see WebView console logs:
```dart
..setOnConsoleMessage((ConsoleMessage message) {
  debugPrint('WebView Console: ${message.message}');
})
```

### Test on Real Device
Emulators may have different network behavior. Test on physical device for accurate results.

## Files Modified
- ✅ `android/app/src/main/res/xml/network_security_config.xml` (created)
- ✅ `android/app/src/main/AndroidManifest.xml` (updated)
- ✅ `web_game_bottomsheet.dart` (improved WebView config)

The game should now load successfully without the cleartext permission error!

# Web Game Integration Guide

## Overview
The web game bottom sheet allows users to play web-based games directly within your live streaming app. The game opens in a WebView with a clean interface and proper user session management.

## Features
- **Full-screen game experience** with WebView
- **User session management** with dynamic user ID injection
- **Loading states** with progress indicators
- **Error handling** with retry functionality
- **Clean UI** with refresh and close buttons
- **Responsive design** that works on all screen sizes

## Usage

### Basic Usage
```dart
import 'package:your_app/features/live-streaming/presentation/component/web_game_bottomsheet.dart';

// Open the web game
showWebGameBottomSheet(
  context,
  gameUrl: 'http://147.93.103.135:8001/game/?spain_time=30&profit=0',
  gameTitle: 'Greedy Stars',
  userId: 'user123', // Current user's ID
);
```

### Integration with Game Bottom Sheet
The game is already integrated into the main game bottom sheet. When users tap "Greedy Stars":

```dart
_buildGameOption(
  icon: Icons.gamepad,
  label: 'Greedy Stars',
  onTap: () {
    Navigator.pop(context); // Close current bottom sheet
    showWebGameBottomSheet(
      context,
      gameUrl: 'http://147.93.103.135:8001/game/?spain_time=30&profit=0&user_id=2ufXoAdqAY',
      gameTitle: 'Greedy Stars',
      userId: currentUser.id, // Use actual user ID from your app
    );
  },
),
```

### Dynamic User ID Management
The system automatically handles user ID injection:

```dart
// If gameUrl already has user_id parameter, it gets replaced
// If no user_id parameter exists, it gets added
showWebGameBottomSheet(
  context,
  gameUrl: 'http://147.93.103.135:8001/game/?spain_time=30&profit=0',
  gameTitle: 'Greedy Stars',
  userId: userBloc.state.currentUser.id, // Dynamic user ID
);
```

## Game URL Parameters

### Current Parameters
- `spain_time=30` - Game session duration
- `profit=0` - Initial profit/score
- `user_id=2ufXoAdqAY` - User identifier

### Adding More Parameters
You can extend the URL with additional parameters:

```dart
String buildGameUrl({
  required String userId,
  int sessionTime = 30,
  int initialProfit = 0,
  String gameMode = 'normal',
}) {
  return 'http://147.93.103.135:8001/game/'
      '?spain_time=$sessionTime'
      '&profit=$initialProfit'
      '&user_id=$userId'
      '&mode=$gameMode';
}

// Usage
showWebGameBottomSheet(
  context,
  gameUrl: buildGameUrl(
    userId: currentUser.id,
    sessionTime: 60,
    gameMode: 'challenge',
  ),
  gameTitle: 'Greedy Stars Challenge',
  userId: currentUser.id,
);
```

## Integration with User Management

### With BLoC Pattern
```dart
class GameBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        return _buildGameOption(
          icon: Icons.gamepad,
          label: 'Greedy Stars',
          onTap: () {
            if (userState.isLoggedIn) {
              Navigator.pop(context);
              showWebGameBottomSheet(
                context,
                gameUrl: 'http://147.93.103.135:8001/game/?spain_time=30&profit=0',
                gameTitle: 'Greedy Stars',
                userId: userState.currentUser.id,
              );
            } else {
              // Redirect to login
              _showLoginRequired(context);
            }
          },
        );
      },
    );
  }
}
```

### With SharedPreferences
```dart
Future<void> _openGreedyStars(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');
  
  if (userId != null) {
    Navigator.pop(context);
    showWebGameBottomSheet(
      context,
      gameUrl: 'http://147.93.103.135:8001/game/?spain_time=30&profit=0',
      gameTitle: 'Greedy Stars',
      userId: userId,
    );
  } else {
    // Handle no user ID
    _showLoginRequired(context);
  }
}
```

## Error Handling

### Network Issues
The WebView automatically handles network errors and provides:
- Error message display
- Retry functionality
- Loading states

### Game Loading States
- **Loading**: Shows progress indicator while game loads
- **Error**: Shows error message with retry button
- **Success**: Shows the game interface

## Customization

### Styling
You can customize the bottom sheet appearance:

```dart
// In web_game_bottomsheet.dart
Container(
  height: MediaQuery.of(context).size.height * 0.9, // Adjust height
  decoration: BoxDecoration(
    color: const Color(0xFF1A1A2E), // Change background color
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(20.r), // Adjust corner radius
      topRight: Radius.circular(20.r),
    ),
  ),
  // ...
)
```

### Header Customization
```dart
// Add game stats, user balance, etc.
Container(
  padding: EdgeInsets.all(16.w),
  child: Row(
    children: [
      Text(widget.gameTitle),
      Spacer(),
      Text('Balance: \$${userBalance}'), // Add user balance
      // Refresh and close buttons
    ],
  ),
)
```

## Security Considerations

### URL Validation
```dart
bool _isValidGameUrl(String url) {
  return url.startsWith('http://147.93.103.135:8001/') ||
         url.startsWith('https://yourgame.com/');
}

// Use before opening WebView
if (_isValidGameUrl(gameUrl)) {
  showWebGameBottomSheet(context, gameUrl: gameUrl, ...);
} else {
  // Handle invalid URL
}
```

### User Session Security
- Always validate user IDs before injecting into URLs
- Use HTTPS for production game servers
- Implement proper session timeout handling

## Testing

### Local Testing
```dart
// For development/testing
showWebGameBottomSheet(
  context,
  gameUrl: 'http://localhost:3000/game/?user_id=test_user',
  gameTitle: 'Test Game',
  userId: 'test_user',
);
```

### Production URLs
```dart
// For production
showWebGameBottomSheet(
  context,
  gameUrl: 'https://games.yourdomain.com/greedy-stars/?user_id=${userId}',
  gameTitle: 'Greedy Stars',
  userId: userId,
);
```

This implementation provides a robust, user-friendly web game experience within your live streaming app!

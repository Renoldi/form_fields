# Global HTTP Service

A singleton HTTP service for making API requests throughout the app.

## Quick Start

### 1. Import the service
```dart
import 'services/http_service.dart';
```

### 2. Make requests anywhere in your app

```dart
// Simple GET request
final posts = await http.get<List>(
  '/posts',
  parser: (data) => (data as List).map((e) => Post.fromJson(e)).toList(),
);

// POST with data
final newPost = await http.post<Post>(
  '/posts/add',
  data: {
    'title': 'My Post',
    'body': 'This is awesome!',
    'userId': 1,
  },
  parser: (data) => Post.fromJson(data),
);

// PUT to update
final updated = await http.put<Post>(
  '/posts/1',
  data: {'title': 'Updated Title'},
  parser: (data) => Post.fromJson(data),
);

// Download file with progress
await http.download(
  '/images/photo.jpg',
  '/storage/photo.jpg',
  onProgress: (received, total) {
    final progress = (received / total * 100).toStringAsFixed(0);
    print('Download progress: $progress%');
  },
);
```

## Configuration

### Change Base URL
```dart
http.setBaseUrl('https://api.myapp.com');
```

### Set Authorization Token
```dart
http.setAuthToken('your-jwt-token');
// Or with custom prefix
http.setAuthToken('your-token', prefix: 'Token');
```

### Add Custom Headers
```dart
http.setHeader('X-Custom-Header', 'value');
```

### Clear Auth Token
```dart
http.clearAuthToken();
```

## Advanced Usage

### Access Dio Instance Directly
```dart
import 'services/http_service.dart';

final dio = HttpService.instance.dio;
// Use dio directly for advanced features
```

### Custom Instance
```dart
final customService = HttpService(
  baseUrl: 'https://api.custom.com',
  connectTimeout: Duration(seconds: 5),
  headers: {'X-API-Key': 'secret'},
);
```

## Features

✅ **Singleton Pattern** - One global instance throughout the app
✅ **Automatic Retry** - Exponential backoff for failed requests
✅ **Type Safe** - Generic methods with custom parsers
✅ **Progress Tracking** - Download progress callbacks
✅ **Token Management** - Auto-updates auth tokens on login/logout
✅ **Configurable** - Change base URL, headers, timeouts

## Retry Logic

The service automatically retries failed requests with exponential backoff:
- Initial delay: 300ms
- Max retries: 2 (3 total attempts)
- Delay multiplier: 2x
- Retries on: Timeouts, connection errors, 5xx responses

## Integration with AppStateNotifier

The service is automatically integrated with app authentication:

```dart
// When user logs in
appState.loginWithDummy(username, password);
// → Auth token is automatically set in httpClient

// When user logs out
appState.logout();
// → Auth token is automatically cleared from httpClient
```

## Example: Fetching Data in a Widget

```dart
class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Product> products = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    
    try {
      final result = await http.get<Map<String, dynamic>>('/products');
      final productList = (result['products'] as List)
          .map((json) => Product.fromJson(json))
          .toList();
      
      setState(() {
        products = productList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load products';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return CircularProgressIndicator();
    if (error != null) return Text(error!);
    
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) => ProductTile(products[index]),
    );
  }
}
```

class DeityImageHelper {
  // Base URL for deity images - replace with your actual image hosting service
  static const String baseImageUrl = 'https://your-image-host.com/deities/';
  
  // Helper method to get image URL for a deity
  static String? getImageUrl(String deityId) {
    // You can customize this logic based on your image naming convention
    // For example: 'durga.jpg', 'ganesha.png', etc.
    return '$baseImageUrl$deityId.jpg';
  }
  
  // Alternative: Direct image URLs (replace with actual URLs)
  static const Map<String, String> deityImageUrls = {
    'durga': 'https://example.com/images/durga.jpg',
    'ganesha': 'https://t3.ftcdn.net/jpg/06/71/05/56/240_F_671055678_2fOeZrYXVlG1ZZK5MXAheQEBA66iyi7o.jpg',
    'hanuman': 'https://example.com/images/hanuman.jpg',
    'krishna': 'https://example.com/images/krishna.jpg',
    'lakshmi': 'https://example.com/images/lakshmi.jpg',
    'narasimha': 'https://example.com/images/narasimha.jpg',
    'parvati': 'https://example.com/images/parvati.jpg',
    'radha': 'https://example.com/images/radha.jpg',
    'ram': 'https://example.com/images/ram.jpg',
    'saraswati': 'https://example.com/images/saraswati.jpg',
    'shani': 'https://example.com/images/shani.jpg',
    'shiv': 'https://example.com/images/shiv.jpg',
    'sita': 'https://example.com/images/sita.jpg',
    'vishnu': 'https://example.com/images/vishnu.jpg',
  };
  
  // Method to get image URL from the map
  static String? getImageUrlFromMap(String deityId) {
    return deityImageUrls[deityId];
  }
}

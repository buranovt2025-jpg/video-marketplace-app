// Demo Mode Configuration
// Set to true to run app with mock data (no Firebase required)
const bool DEMO_MODE = true;

// Demo user data
const String DEMO_USER_ID = 'demo_user_123';
const String DEMO_USER_NAME = 'Demo User';
const String DEMO_USER_EMAIL = 'demo@example.com';
const String DEMO_USER_PHOTO = 'https://i.pravatar.cc/150?img=3';

// Demo videos data
final List<Map<String, dynamic>> demoVideos = [
  {
    'id': 'video_1',
    'uid': 'demo_user_123',
    'username': 'Demo User',
    'profilePhoto': 'https://i.pravatar.cc/150?img=3',
    'videoUrl': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'thumbnail': 'https://picsum.photos/200/300?random=1',
    'caption': 'Демо видео #1 - Природа',
    'songName': 'Demo Song',
    'likes': ['user1', 'user2', 'user3'],
    'commentCount': 5,
    'shareCount': 2,
  },
  {
    'id': 'video_2',
    'uid': 'user_456',
    'username': 'Test Creator',
    'profilePhoto': 'https://i.pravatar.cc/150?img=5',
    'videoUrl': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    'thumbnail': 'https://picsum.photos/200/300?random=2',
    'caption': 'Демо видео #2 - Бабочка',
    'songName': 'Nature Sounds',
    'likes': ['user1'],
    'commentCount': 3,
    'shareCount': 1,
  },
  {
    'id': 'video_3',
    'uid': 'demo_user_123',
    'username': 'Demo User',
    'profilePhoto': 'https://i.pravatar.cc/150?img=3',
    'videoUrl': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'thumbnail': 'https://picsum.photos/200/300?random=3',
    'caption': 'Ещё одно демо видео',
    'songName': 'Cool Track',
    'likes': [],
    'commentCount': 0,
    'shareCount': 0,
  },
];

// Demo users for search
final List<Map<String, dynamic>> demoUsers = [
  {
    'uid': 'demo_user_123',
    'name': 'Demo User',
    'email': 'demo@example.com',
    'profilePhoto': 'https://i.pravatar.cc/150?img=3',
  },
  {
    'uid': 'user_456',
    'name': 'Test Creator',
    'email': 'test@example.com',
    'profilePhoto': 'https://i.pravatar.cc/150?img=5',
  },
  {
    'uid': 'user_789',
    'name': 'Sample User',
    'email': 'sample@example.com',
    'profilePhoto': 'https://i.pravatar.cc/150?img=8',
  },
];

// Demo comments
final List<Map<String, dynamic>> demoComments = [
  {
    'id': 'comment_1',
    'username': 'Test Creator',
    'comment': 'Отличное видео!',
    'datePublished': DateTime.now().subtract(Duration(hours: 2)),
    'likes': ['user1', 'user2'],
    'profilePhoto': 'https://i.pravatar.cc/150?img=5',
    'uid': 'user_456',
  },
  {
    'id': 'comment_2',
    'username': 'Sample User',
    'comment': 'Круто! 🔥',
    'datePublished': DateTime.now().subtract(Duration(minutes: 30)),
    'likes': [],
    'profilePhoto': 'https://i.pravatar.cc/150?img=8',
    'uid': 'user_789',
  },
];

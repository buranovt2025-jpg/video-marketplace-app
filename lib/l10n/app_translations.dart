import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ru_RU': {
      // Navigation
      'feed': 'Лента',
      'search': 'Поиск',
      'create': 'Создать',
      'orders': 'Заказы',
      'profile': 'Профиль',
      
      // Auth
      'login': 'Войти',
      'register': 'Регистрация',
      'email': 'Email',
      'password': 'Пароль',
      'forgot_password': 'Забыли пароль?',
      'no_account': 'Нет аккаунта?',
      'have_account': 'Уже есть аккаунт?',
      'sign_up': 'Зарегистрироваться',
      'sign_in': 'Войти',
      
      // Roles
      'seller': 'Продавец',
      'buyer': 'Покупатель',
      'courier': 'Курьер',
      'admin': 'Админ',
      
      // Orders
      'new_orders': 'Новые',
      'active_orders': 'Активные',
      'completed_orders': 'Завершённые',
      'order_status': 'Статус заказа',
      'accept': 'Принять',
      'reject': 'Отклонить',
      'deliver': 'Доставить',
      'pickup': 'Забрать',
      
      // Products
      'add_product': 'Добавить товар',
      'product_name': 'Название товара',
      'price': 'Цена',
      'description': 'Описание',
      'quantity': 'Количество',
      'in_stock': 'В наличии',
      'out_of_stock': 'Нет в наличии',
      
      // Cart
      'cart': 'Корзина',
      'checkout': 'Оформить заказ',
      'total': 'Итого',
      'empty_cart': 'Корзина пуста',
      
      // Profile
      'edit_profile': 'Редактировать профиль',
      'settings': 'Настройки',
      'logout': 'Выйти',
      'language': 'Язык',
      'my_cabinet': 'Мой кабинет',
      'statistics': 'Статистика',
      'favorites': 'Избранное',
      'addresses': 'Адреса',
      'earnings': 'Заработок',
      
      // Courier
      'available_orders': 'Доступные заказы',
      'my_deliveries': 'Мои доставки',
      'online': 'На смене',
      'offline': 'Не на смене',
      'take_order': 'Взять заказ',
      
      // Admin
      'dashboard': 'Панель управления',
      'users': 'Пользователи',
      'content': 'Контент',
      'verification': 'Верификация',
      'complaints': 'Жалобы',
      
      // Common
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'edit': 'Редактировать',
      'loading': 'Загрузка...',
      'error': 'Ошибка',
      'success': 'Успешно',
      'confirm': 'Подтвердить',
      'back': 'Назад',
      'next': 'Далее',
      'done': 'Готово',
      'problem_with_order': 'Проблема с заказом',
      'report_problem': 'Сообщить о проблеме',
    },
    
    'uz_UZ': {
      // Navigation
      'feed': 'Lenta',
      'search': 'Qidirish',
      'create': 'Yaratish',
      'orders': 'Buyurtmalar',
      'profile': 'Profil',
      
      // Auth
      'login': 'Kirish',
      'register': 'Ro\'yxatdan o\'tish',
      'email': 'Email',
      'password': 'Parol',
      'forgot_password': 'Parolni unutdingizmi?',
      'no_account': 'Akkauntingiz yo\'qmi?',
      'have_account': 'Akkauntingiz bormi?',
      'sign_up': 'Ro\'yxatdan o\'tish',
      'sign_in': 'Kirish',
      
      // Roles
      'seller': 'Sotuvchi',
      'buyer': 'Xaridor',
      'courier': 'Kuryer',
      'admin': 'Admin',
      
      // Orders
      'new_orders': 'Yangi',
      'active_orders': 'Faol',
      'completed_orders': 'Tugallangan',
      'order_status': 'Buyurtma holati',
      'accept': 'Qabul qilish',
      'reject': 'Rad etish',
      'deliver': 'Yetkazish',
      'pickup': 'Olish',
      
      // Products
      'add_product': 'Mahsulot qo\'shish',
      'product_name': 'Mahsulot nomi',
      'price': 'Narx',
      'description': 'Tavsif',
      'quantity': 'Miqdor',
      'in_stock': 'Mavjud',
      'out_of_stock': 'Mavjud emas',
      
      // Cart
      'cart': 'Savat',
      'checkout': 'Buyurtma berish',
      'total': 'Jami',
      'empty_cart': 'Savat bo\'sh',
      
      // Profile
      'edit_profile': 'Profilni tahrirlash',
      'settings': 'Sozlamalar',
      'logout': 'Chiqish',
      'language': 'Til',
      'my_cabinet': 'Mening kabinetim',
      'statistics': 'Statistika',
      'favorites': 'Sevimlilar',
      'addresses': 'Manzillar',
      'earnings': 'Daromad',
      
      // Courier
      'available_orders': 'Mavjud buyurtmalar',
      'my_deliveries': 'Mening yetkazishlarim',
      'online': 'Ish vaqtida',
      'offline': 'Ish vaqtida emas',
      'take_order': 'Buyurtmani olish',
      
      // Admin
      'dashboard': 'Boshqaruv paneli',
      'users': 'Foydalanuvchilar',
      'content': 'Kontent',
      'verification': 'Tasdiqlash',
      'complaints': 'Shikoyatlar',
      
      // Common
      'save': 'Saqlash',
      'cancel': 'Bekor qilish',
      'delete': 'O\'chirish',
      'edit': 'Tahrirlash',
      'loading': 'Yuklanmoqda...',
      'error': 'Xato',
      'success': 'Muvaffaqiyatli',
      'confirm': 'Tasdiqlash',
      'back': 'Orqaga',
      'next': 'Keyingi',
      'done': 'Tayyor',
      'problem_with_order': 'Buyurtma bilan muammo',
      'report_problem': 'Muammo haqida xabar berish',
    },
    
    'en_US': {
      // Navigation
      'feed': 'Feed',
      'search': 'Search',
      'create': 'Create',
      'orders': 'Orders',
      'profile': 'Profile',
      
      // Auth
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot password?',
      'no_account': 'Don\'t have an account?',
      'have_account': 'Already have an account?',
      'sign_up': 'Sign Up',
      'sign_in': 'Sign In',
      
      // Roles
      'seller': 'Seller',
      'buyer': 'Buyer',
      'courier': 'Courier',
      'admin': 'Admin',
      
      // Orders
      'new_orders': 'New',
      'active_orders': 'Active',
      'completed_orders': 'Completed',
      'order_status': 'Order Status',
      'accept': 'Accept',
      'reject': 'Reject',
      'deliver': 'Deliver',
      'pickup': 'Pickup',
      
      // Products
      'add_product': 'Add Product',
      'product_name': 'Product Name',
      'price': 'Price',
      'description': 'Description',
      'quantity': 'Quantity',
      'in_stock': 'In Stock',
      'out_of_stock': 'Out of Stock',
      
      // Cart
      'cart': 'Cart',
      'checkout': 'Checkout',
      'total': 'Total',
      'empty_cart': 'Cart is empty',
      
      // Profile
      'edit_profile': 'Edit Profile',
      'settings': 'Settings',
      'logout': 'Logout',
      'language': 'Language',
      'my_cabinet': 'My Cabinet',
      'statistics': 'Statistics',
      'favorites': 'Favorites',
      'addresses': 'Addresses',
      'earnings': 'Earnings',
      
      // Courier
      'available_orders': 'Available Orders',
      'my_deliveries': 'My Deliveries',
      'online': 'Online',
      'offline': 'Offline',
      'take_order': 'Take Order',
      
      // Admin
      'dashboard': 'Dashboard',
      'users': 'Users',
      'content': 'Content',
      'verification': 'Verification',
      'complaints': 'Complaints',
      
      // Common
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'confirm': 'Confirm',
      'back': 'Back',
      'next': 'Next',
      'done': 'Done',
      'problem_with_order': 'Problem with order',
      'report_problem': 'Report Problem',
    },
  };
}

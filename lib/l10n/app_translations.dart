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
      
      // Location
      'select_location': 'Выбрать локацию',
      'location': 'Локация',
      'location_updated': 'Локация обновлена',
      'location_error': 'Не удалось получить локацию',
      'selected_location': 'Выбранная локация',
      'delivery_address': 'Адрес доставки',
      'enter_address': 'Введите адрес',
      'enter_full_address': 'Введите полный адрес (улица, дом, квартира)',
      'location_info': 'Курьер увидит ваш адрес и сможет открыть навигатор',
      'use_current_location': 'Использовать текущую локацию',
      'getting_location': 'Получение локации...',
      'coordinates': 'Координаты',
      'latitude': 'Широта',
      'longitude': 'Долгота',
      'view_in_maps': 'Открыть в картах',
      'confirm_location': 'Подтвердить локацию',
      'change_location': 'Изменить локацию',
      
      // Favorites
      'add_to_favorites': 'Добавить в избранное',
      'remove_from_favorites': 'Удалить из избранного',
      'no_favorites': 'Нет избранных товаров',
      
      // QR Codes
      'scan_qr': 'Сканировать QR',
      'show_qr': 'Показать QR',
      'pickup_qr': 'QR для получения',
      'delivery_qr': 'QR для доставки',
      'qr_scan_instruction': 'Покажите этот QR-код для сканирования',
      'scan_pickup_instruction': 'Отсканируйте QR-код продавца для получения товара',
      'scan_delivery_instruction': 'Отсканируйте QR-код курьера для подтверждения доставки',
      'qr_scanned_success': 'QR-код отсканирован!',
      'invalid_qr': 'Неверный QR-код',
      'wrong_qr_type': 'Неверный тип QR-кода',
      'wrong_order_qr': 'QR-код от другого заказа',
      'scan_error': 'Ошибка сканирования',
      'item_received': 'Товар получен',
      'item_delivered': 'Товар доставлен',
      'confirm_pickup': 'Подтвердить получение',
      'confirm_delivery': 'Подтвердить доставку',
      
      // Search & Categories
      'search_products': 'Поиск товаров...',
      'all_categories': 'Все категории',
      'fruits': 'Фрукты',
      'vegetables': 'Овощи',
      'meat': 'Мясо',
      'dairy': 'Молочные',
      'bakery': 'Выпечка',
      'drinks': 'Напитки',
      'spices': 'Специи',
      'clothes': 'Одежда',
      'electronics': 'Электроника',
      'household': 'Для дома',
      'other': 'Другое',
      'enter_search_query': 'Введите запрос для поиска',
      'no_results': 'Ничего не найдено',
      'nearby_sellers': 'Продавцы рядом',
      
      // Ratings & Reviews
      'rate_order': 'Оценить заказ',
      'rate_seller': 'Оценить продавца',
      'rate_courier': 'Оценить курьера',
      'write_review': 'Написать отзыв',
      'your_rating': 'Ваша оценка',
      'reviews': 'Отзывы',
      'no_reviews': 'Пока нет отзывов',
      'thank_you_review': 'Спасибо за отзыв!',
      
      // Phone & Call
      'phone_number': 'Номер телефона',
      'enter_phone': 'Введите номер телефона',
      'call_seller': 'Позвонить продавцу',
      'call_courier': 'Позвонить курьеру',
      'call_buyer': 'Позвонить покупателю',
      
      // Order History
      'order_history': 'История заказов',
      'all_orders': 'Все заказы',
      'filter_by_status': 'Фильтр по статусу',
      'cancel_order': 'Отменить заказ',
      'cancel_reason': 'Причина отмены',
      'order_cancelled': 'Заказ отменён',
      'cannot_cancel': 'Нельзя отменить заказ',
      
      // Reports & Complaints
      'report_content': 'Пожаловаться',
      'report_reason': 'Причина жалобы',
      'spam': 'Спам',
      'inappropriate': 'Неприемлемый контент',
      'fraud': 'Мошенничество',
      'other_reason': 'Другая причина',
      'report_sent': 'Жалоба отправлена',
      
      // Notifications
      'notifications': 'Уведомления',
      'no_notifications': 'Нет уведомлений',
      'mark_all_read': 'Отметить все как прочитанные',
      
      // Account
      'delete_account': 'Удалить аккаунт',
      'delete_account_confirm': 'Вы уверены, что хотите удалить аккаунт? Это действие нельзя отменить.',
      'account_deleted': 'Аккаунт удалён',
      'reset_password': 'Сбросить пароль',
      'reset_link_sent': 'Ссылка для сброса отправлена на email',
      
      // Verification
      'verified_seller': 'Проверенный продавец',
      'pending_verification': 'На проверке',
      'request_verification': 'Запросить верификацию',
      
      // Buy button
      'buy_now': 'Купить',
      'add_to_cart': 'В корзину',
      
      // Guest mode
      'login_required': 'Требуется вход',
      'welcome': 'Добро пожаловать!',
      'login_to_continue': 'Войдите, чтобы продолжить',
      
      // Nearby sellers
      'nearby_sellers': 'Продавцы рядом',
      'no_nearby_sellers': 'Нет продавцов поблизости',
      'search_radius': 'Радиус поиска',
      
      // Delete account
      'delete_account': 'Удалить аккаунт',
      'delete_account_warning': 'Это действие нельзя отменить',
      'confirm_delete': 'Подтвердить удаление',
      
      // Seller verification
      'seller_verification': 'Верификация продавцов',
      'verify_seller': 'Верифицировать',
      'reject_seller': 'Отклонить',
      
      // Phone call
      'call_seller': 'Позвонить продавцу',
      'call_courier': 'Позвонить курьеру',
      'phone_number': 'Номер телефона',
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
      
      // Location
      'select_location': 'Joylashuvni tanlash',
      'location': 'Joylashuv',
      'location_updated': 'Joylashuv yangilandi',
      'location_error': 'Joylashuvni olishda xato',
      'selected_location': 'Tanlangan joylashuv',
      'delivery_address': 'Yetkazib berish manzili',
      'enter_address': 'Manzilni kiriting',
      'enter_full_address': 'To\'liq manzilni kiriting (ko\'cha, uy, xonadon)',
      'location_info': 'Kuryer manzilingizni ko\'radi va navigatorni ochishi mumkin',
      'use_current_location': 'Joriy joylashuvdan foydalanish',
      'getting_location': 'Joylashuv olinmoqda...',
      'coordinates': 'Koordinatalar',
      'latitude': 'Kenglik',
      'longitude': 'Uzunlik',
      'view_in_maps': 'Xaritada ochish',
      'confirm_location': 'Joylashuvni tasdiqlash',
      'change_location': 'Joylashuvni o\'zgartirish',
      
      // Favorites
      'add_to_favorites': 'Sevimlilarga qo\'shish',
      'remove_from_favorites': 'Sevimlilardan o\'chirish',
      'no_favorites': 'Sevimli mahsulotlar yo\'q',
      
      // QR Codes
      'scan_qr': 'QR skanerlash',
      'show_qr': 'QR ko\'rsatish',
      'pickup_qr': 'Olish uchun QR',
      'delivery_qr': 'Yetkazish uchun QR',
      'qr_scan_instruction': 'Bu QR-kodni skanerlash uchun ko\'rsating',
      'scan_pickup_instruction': 'Tovarni olish uchun sotuvchining QR-kodini skanerlang',
      'scan_delivery_instruction': 'Yetkazishni tasdiqlash uchun kuryerning QR-kodini skanerlang',
      'qr_scanned_success': 'QR-kod skanerlandi!',
      'invalid_qr': 'Noto\'g\'ri QR-kod',
      'wrong_qr_type': 'Noto\'g\'ri QR-kod turi',
      'wrong_order_qr': 'Boshqa buyurtmaning QR-kodi',
      'scan_error': 'Skanerlash xatosi',
      'item_received': 'Tovar qabul qilindi',
      'item_delivered': 'Tovar yetkazildi',
      'confirm_pickup': 'Qabul qilishni tasdiqlash',
      'confirm_delivery': 'Yetkazishni tasdiqlash',
      
      // Search & Categories
      'search_products': 'Mahsulotlarni qidirish...',
      'all_categories': 'Barcha kategoriyalar',
      'fruits': 'Mevalar',
      'vegetables': 'Sabzavotlar',
      'meat': 'Go\'sht',
      'dairy': 'Sut mahsulotlari',
      'bakery': 'Non mahsulotlari',
      'drinks': 'Ichimliklar',
      'spices': 'Ziravorlar',
      'clothes': 'Kiyimlar',
      'electronics': 'Elektronika',
      'household': 'Uy uchun',
      'other': 'Boshqa',
      'enter_search_query': 'Qidirish so\'rovini kiriting',
      'no_results': 'Hech narsa topilmadi',
      'nearby_sellers': 'Yaqin sotuvchilar',
      
      // Ratings & Reviews
      'rate_order': 'Buyurtmani baholash',
      'rate_seller': 'Sotuvchini baholash',
      'rate_courier': 'Kuryerni baholash',
      'write_review': 'Sharh yozish',
      'your_rating': 'Sizning bahoyingiz',
      'reviews': 'Sharhlar',
      'no_reviews': 'Hali sharhlar yo\'q',
      'thank_you_review': 'Sharh uchun rahmat!',
      
      // Phone & Call
      'phone_number': 'Telefon raqami',
      'enter_phone': 'Telefon raqamini kiriting',
      'call_seller': 'Sotuvchiga qo\'ng\'iroq',
      'call_courier': 'Kuryerga qo\'ng\'iroq',
      'call_buyer': 'Xaridorga qo\'ng\'iroq',
      
      // Order History
      'order_history': 'Buyurtmalar tarixi',
      'all_orders': 'Barcha buyurtmalar',
      'filter_by_status': 'Holat bo\'yicha filtrlash',
      'cancel_order': 'Buyurtmani bekor qilish',
      'cancel_reason': 'Bekor qilish sababi',
      'order_cancelled': 'Buyurtma bekor qilindi',
      'cannot_cancel': 'Buyurtmani bekor qilib bo\'lmaydi',
      
      // Reports & Complaints
      'report_content': 'Shikoyat qilish',
      'report_reason': 'Shikoyat sababi',
      'spam': 'Spam',
      'inappropriate': 'Nomaqbul kontent',
      'fraud': 'Firibgarlik',
      'other_reason': 'Boshqa sabab',
      'report_sent': 'Shikoyat yuborildi',
      
      // Notifications
      'notifications': 'Bildirishnomalar',
      'no_notifications': 'Bildirishnomalar yo\'q',
      'mark_all_read': 'Barchasini o\'qilgan deb belgilash',
      
      // Account
      'delete_account': 'Akkauntni o\'chirish',
      'delete_account_confirm': 'Akkauntni o\'chirishni xohlaysizmi? Bu amalni qaytarib bo\'lmaydi.',
      'account_deleted': 'Akkaunt o\'chirildi',
      'reset_password': 'Parolni tiklash',
      'reset_link_sent': 'Tiklash havolasi emailga yuborildi',
      
      // Verification
      'verified_seller': 'Tasdiqlangan sotuvchi',
      'pending_verification': 'Tekshiruvda',
      'request_verification': 'Tasdiqlash so\'rash',
      
      // Buy button
      'buy_now': 'Sotib olish',
      'add_to_cart': 'Savatga',
      
      // Guest mode
      'login_required': 'Kirish talab qilinadi',
      'welcome': 'Xush kelibsiz!',
      'login_to_continue': 'Davom etish uchun kiring',
      
      // Nearby sellers
      'nearby_sellers': 'Yaqindagi sotuvchilar',
      'no_nearby_sellers': 'Yaqinda sotuvchilar yo\'q',
      'search_radius': 'Qidiruv radiusi',
      
      // Seller verification
      'seller_verification': 'Sotuvchilarni tasdiqlash',
      'verify_seller': 'Tasdiqlash',
      'reject_seller': 'Rad etish',
      
      // Phone call
      'call_seller': 'Sotuvchiga qo\'ng\'iroq',
      'call_courier': 'Kuryerga qo\'ng\'iroq',
      'phone_number': 'Telefon raqami',
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
      
      // Location
      'select_location': 'Select Location',
      'location': 'Location',
      'location_updated': 'Location updated',
      'location_error': 'Failed to get location',
      'selected_location': 'Selected location',
      'delivery_address': 'Delivery Address',
      'enter_address': 'Enter address',
      'enter_full_address': 'Enter full address (street, building, apartment)',
      'location_info': 'Courier will see your address and can open navigation',
      'use_current_location': 'Use current location',
      'getting_location': 'Getting location...',
      'coordinates': 'Coordinates',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'view_in_maps': 'View in Maps',
      'confirm_location': 'Confirm Location',
      'change_location': 'Change Location',
      
      // Favorites
      'add_to_favorites': 'Add to favorites',
      'remove_from_favorites': 'Remove from favorites',
      'no_favorites': 'No favorite products',
      
      // QR Codes
      'scan_qr': 'Scan QR',
      'show_qr': 'Show QR',
      'pickup_qr': 'Pickup QR',
      'delivery_qr': 'Delivery QR',
      'qr_scan_instruction': 'Show this QR code for scanning',
      'scan_pickup_instruction': 'Scan seller\'s QR code to confirm pickup',
      'scan_delivery_instruction': 'Scan courier\'s QR code to confirm delivery',
      'qr_scanned_success': 'QR code scanned!',
      'invalid_qr': 'Invalid QR code',
      'wrong_qr_type': 'Wrong QR code type',
      'wrong_order_qr': 'QR code from another order',
      'scan_error': 'Scan error',
      'item_received': 'Item received',
      'item_delivered': 'Item delivered',
      'confirm_pickup': 'Confirm pickup',
      'confirm_delivery': 'Confirm delivery',
      
      // Search & Categories
      'search_products': 'Search products...',
      'all_categories': 'All categories',
      'fruits': 'Fruits',
      'vegetables': 'Vegetables',
      'meat': 'Meat',
      'dairy': 'Dairy',
      'bakery': 'Bakery',
      'drinks': 'Drinks',
      'spices': 'Spices',
      'clothes': 'Clothes',
      'electronics': 'Electronics',
      'household': 'Household',
      'other': 'Other',
      'enter_search_query': 'Enter search query',
      'no_results': 'No results found',
      'nearby_sellers': 'Nearby sellers',
      
      // Ratings & Reviews
      'rate_order': 'Rate order',
      'rate_seller': 'Rate seller',
      'rate_courier': 'Rate courier',
      'write_review': 'Write review',
      'your_rating': 'Your rating',
      'reviews': 'Reviews',
      'no_reviews': 'No reviews yet',
      'thank_you_review': 'Thank you for your review!',
      
      // Phone & Call
      'phone_number': 'Phone number',
      'enter_phone': 'Enter phone number',
      'call_seller': 'Call seller',
      'call_courier': 'Call courier',
      'call_buyer': 'Call buyer',
      
      // Order History
      'order_history': 'Order history',
      'all_orders': 'All orders',
      'filter_by_status': 'Filter by status',
      'cancel_order': 'Cancel order',
      'cancel_reason': 'Cancel reason',
      'order_cancelled': 'Order cancelled',
      'cannot_cancel': 'Cannot cancel order',
      
      // Reports & Complaints
      'report_content': 'Report',
      'report_reason': 'Report reason',
      'spam': 'Spam',
      'inappropriate': 'Inappropriate content',
      'fraud': 'Fraud',
      'other_reason': 'Other reason',
      'report_sent': 'Report sent',
      
      // Notifications
      'notifications': 'Notifications',
      'no_notifications': 'No notifications',
      'mark_all_read': 'Mark all as read',
      
      // Account
      'delete_account': 'Delete account',
      'delete_account_confirm': 'Are you sure you want to delete your account? This action cannot be undone.',
      'account_deleted': 'Account deleted',
      'reset_password': 'Reset password',
      'reset_link_sent': 'Reset link sent to email',
      
      // Verification
      'verified_seller': 'Verified seller',
      'pending_verification': 'Pending verification',
      'request_verification': 'Request verification',
      
      // Buy button
      'buy_now': 'Buy now',
      'add_to_cart': 'Add to cart',
      
      // Guest mode
      'login_required': 'Login required',
      'welcome': 'Welcome!',
      'login_to_continue': 'Login to continue',
    },
  };
}

class AppStrings {
  AppStrings._();

  // App Title
  static const String appTitle = 'أومني لينك - أمين المستودع';
  static const String appSubtitle = 'إدارة وتوثيق طلبات المستودع';

  // Auth & Login
  static const String loginTitle = 'تسجيل الدخول';
  static const String loginSubtitle = 'أدخل بيانات أمين المستودع للمتابعة';
  static const String usernameOrEmail = 'اسم المستخدم أو البريد الإلكتروني';
  static const String password = 'كلمة المرور';
  static const String loginButton = 'دخول';
  static const String loggingIn = 'جارٍ تسجيل الدخول...';
  static const String logout = 'تسجيل الخروج';
  static const String logoutConfirmTitle = 'تأكيد تسجيل الخروج';
  static const String logoutConfirmMessage =
      'هل أنت متأكد من رغبتك في تسجيل الخروج؟';
  static const String loggingOut = 'جارٍ تسجيل الخروج...';
  static const String cancel = 'إلغاء';
  static const String confirm = 'تأكيد';

  // Validation
  static const String fieldRequired = 'هذا الحقل مطلوب';
  static const String passwordTooShort = 'كلمة المرور يجب ألا تقل عن 6 أحرف';

  // Navigation & Tabs
  static const String openOrders = 'الطلبات المفتوحة';
  static const String completedOrders = 'الطلبات المكتملة';
  static const String profile = 'الملف الشخصي';
  static const String details = 'تفاصيل الطلب';

  // Order Details
  static const String orderNumber = 'رقم الطلب';
  static const String customerName = 'اسم العميل';
  static const String customerPhone = 'الهاتف';
  static const String customerWhatsApp = 'واتساب';
  static const String customerAddress = 'العنوان';
  static const String orderTotal = 'إجمالي الطلب';
  static const String remainingAmount = 'المبلغ المتبقي';
  static const String remainingType = 'نوع المتبقي';
  static const String itemsCount = 'عدد المنتجات';
  static const String orderStatus = 'حالة الطلب';
  static const String createdAt = 'تاريخ الإنشاء';
  static const String confirmedAt = 'تاريخ التأكيد';
  static const String shippedAt = 'تاريخ الشحن';
  static const String notAvailable = 'غير متوفر';

  // Sections
  static const String sectionCustomerInfo = 'بيانات العميل';
  static const String sectionItems = 'المنتجات المطلوبة';
  static const String sectionShipmentPhotos = 'صور الشحنة والمنتجات';
  static const String sectionWaybillPhotos = 'صور بوليصة الشحن';
  static const String sku = 'رمز المنتج (SKU)';
  static const String quantity = 'الكمية';

  // Photos & Upload
  static const String addPhotos = 'إضافة صور';
  static const String takePhoto = 'التقاط بالكاميرا';
  static const String chooseFromGallery = 'اختيار من المعرض';
  static const String uploadShipmentPhotos = 'رفع صور الشحنة';
  static const String uploadWaybillPhotos = 'رفع صور البوليصة';
  static const String uploadingPhotos = 'جارٍ رفع الصور...';
  static const String uploadSuccess = 'تم رفع الصور بنجاح';
  static const String retryUpload = 'إعادة المحاولة';
  static const String clearSelection = 'مسح التحديد';
  static const String selectedPhotos = 'الصور المحددة';
  static const String existingPhotos = 'الصور المرفوعة مسبقاً';
  static const String noPhotosYet = 'لا توجد صور مرفوعة حتى الآن';
  static const String noSelectedPhotos = 'لم يتم تحديد صور بعد';
  static const String duplicateImagesFound =
      'تم استبعاد الصور المكررة تلقائياً';
  static const String minShipmentPhotosHint =
      'يجب أن يكون إجمالي صور الشحنة 5 صور على الأقل قبل الرفع.';
  static String minShipmentPhotosRequirement(int remaining) =>
      'متبقي $remaining صور على الأقل لإتمام الرفع (الحد الأدنى 5 صور).';
  static String photosCounter(int current, int min) =>
      '$current / $min صور كحد أدنى';

  // Figma Redesign Strings
  static const String photosTabHeading = 'صور الطلب';
  static const String photosTabSubtitle = 'وثّق الشحنة والبوليصة، ثم ارفع الصور معًا.';
  static const String shipmentPhotosInstruction =
      'صوّر الشحنة من زوايا مختلفة، مع إظهار المنتجات وحالة التغليف بوضوح.';
  static const String waybillPhotosInstruction =
      'أظهر البوليصة كاملة، مع وضوح البيانات والباركود.';
  static const String shipmentPhotosEmptyState =
      'لا توجد صور بعد. ابدأ بتصوير الشحنة.';
  static const String waybillPhotoAdded = 'صورة بوليصة مضافة';
  static const String waybillClarityHint =
      'تأكد من وضوح البيانات قبل الرفع.';
  static const String captureWaybill = 'تصوير البوليصة';
  static const String uploadPhotosReady =
      'الصور جاهزة. راجعها ثم اضغط «رفع الصور».';
  static const String uploadPhotosDisclaimer =
      'لن تُرفع الصور إلا عند الضغط على «رفع الصور».';
  static const String deletePhotoSemantics = 'حذف الصورة';
  static const String deleteWaybillSemantics = 'حذف صورة البوليصة';

  // Pending Photo Uploads & Persistence
  static const String pendingUploadBadge = 'قيد الانتظار';
  static const String savedLocally = 'محفوظة محلياً';
  static const String photosWaitingForWaybill =
      'تم حفظ صور الشحنة محلياً. لإتاحة الرفع، أضف صورة بوليصة الشحن.';
  static const String waybillWaitingForShipment =
      'تم حفظ صورة البوليصة محلياً. لإتاحة الرفع، أكمل صور الشحنة المطلوبة.';
  static const String photosSavedLocallyNotice =
      'الصور محفوظة محلياً على الجهاز، ولن ترفع للخادم إلا بعد اكتمال صور الشحنة والبوليصة.';
  static const String uploadFailureMessage =
      'فشل رفع الصور، يرجى إعادة المحاولة.';
  static const String addWaybillToEnableUpload =
      'لإتاحة الرفع، أضف صورة بوليصة الشحن.';
  static const String noNewPhotosToUpload = 'لا توجد صور جديدة للرفع.';
  static const String addPhotoTile = 'إضافة صورة';
  static const String badgeCompleted = 'مكتمل';
  static const String badgeRequired = 'مطلوب';
  static const String badgeAdded = 'مضافة';
  static const String uploadedWaybillTitle = 'بوليصة شحن مرفوعة';
  static const String uploadedWaybillSubtitle =
      'اضغط على الصورة لمعاينتها بالحجم الكامل.';
  static const String shipmentPhotosSavedLocally =
      'تم حفظ صور الشحنة محلياً على الجهاز.';
  static const String waybillPhotoSavedLocally =
      'تم حفظ صورة البوليصة محلياً على الجهاز.';

  // Read-only info
  static const String completedOrderReadOnly =
      'هذا الطلب مكتمل (تم الشحن أو التسليم)، ولا يمكن إضافة أو تعديل الصور.';

  // Profile details
  static const String workerName = 'الاسم';
  static const String workerEmail = 'البريد الإلكتروني';
  static const String workerPhone = 'رقم الهاتف';
  static const String workerRole = 'الدور الوظيفي';
  static const String workerStatus = 'الحالة الحسابية';
  static const String workerGender = 'الجنس';
  static const String workerCreatedAt = 'تاريخ الانضمام';

  // Statuses (Exact backend translation)
  static const String statusPending = 'قيد الانتظار';
  static const String statusConfirmed = 'مؤكد';
  static const String statusProcessing = 'قيد التجهيز';
  static const String statusShipped = 'تم الشحن';
  static const String statusDelivered = 'تم التسليم';
  static const String statusCancelled = 'إلغيت';
  static const String statusUnknown = 'غير معروف';

  // Empty & Error states
  static const String noOpenOrders = 'لا توجد طلبات مفتوحة حالياً';
  static const String noCompletedOrders = 'لا توجد طلبات مكتملة حالياً';
  static const String retry = 'إعادة المحاولة';
  static const String pullToRefresh = 'اسحب للتحديث';
  static const String loadingMore = 'جارٍ تحميل المزيد...';
  static const String noMoreOrders = 'تم تحميل جميع الطلبات';

  // User-friendly error messages (Never exposing raw exceptions)
  static const String errorGeneric =
      'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.';
  static const String errorNetwork =
      'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت.';
  static const String errorTimeout =
      'انتهت مهلة الاتصال بالخادم، يرجى المحاولة لاحقاً.';
  static const String errorUnauthorized =
      'انتهت جلسة العمل، يرجى إعادة تسجيل الدخول.';
  static const String errorForbidden = 'ليس لديك الصلاحية للقيام بهذا الإجراء.';
  static const String errorNotFound = 'العنصر المطلوب غير موجود.';
  static const String errorServer = 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.';
  static const String errorOrdersLoad = 'حدث خطأ أثناء تحميل الطلبات.';
  static const String errorOrderDetailsLoad =
      'حدث خطأ أثناء تحميل تفاصيل الطلب.';
  static const String errorShipmentUpload =
      'تعذر رفع صور الشحنة، يرجى المحاولة مرة أخرى.';
  static const String errorWaybillUpload = 'حدث خطأ أثناء رفع بوليصة الشحن.';
  static const String errorProfileLoad = 'تعذر تحميل بيانات الملف الشخصي.';

  // Shipping Details
  static const String sectionShippingDetails = 'تفاصيل الشحن';
  static const String shippingCompany = 'شركة الشحن';
  static const String waybillNumber = 'رقم البوليصة';
  static const String trackingUrl = 'رابط التتبع';
  static const String shippingLabelUrl = 'ملصق الشحن';
  static const String viewShippingLabel = 'عرض ملصق الشحن (PDF)';
  static const String shippingStatus = 'حالة الشحن';
  static const String courierCode = 'رمز شركة الشحن';
  static const String noShippingDetails = 'لا توجد تفاصيل شحن إضافية';
  static const String copiedToClipboard = 'تم النسخ إلى الحافظة';
  static const String couldNotLaunchUrl = 'تعذر فتح الرابط';

  // External Warehouse Invoice
  static const String sectionExternalWarehouseInvoice = 'فاتورة المخزن';
  static const String noExternalWarehouseInvoice =
      'لا توجد فواتير مخزن مرفقة لهذا الطلب';
  static const String viewWarehouseInvoicePdf = 'عرض فاتورة المخزن (PDF)';

  // Session Expiration
  static const String sessionExpiredTitle = 'انتهت الجلسة';
  static const String sessionExpiredMessage =
      'انتهت صلاحية جلسة تسجيل الدخول الخاصة بك.\nيرجى تسجيل الدخول مرة أخرى للمتابعة.';
  static const String sessionExpiredButton = 'تسجيل الدخول';

  // Order Status Update
  static const String updateStatusButton = 'تحديث الحالة';
  static const String updateStatusSheetTitle = 'تحديث حالة الطلب';
  static const String updateStatusSheetSubtitle =
      'اختر الحالة الجديدة للطلب';
  static const String statusUpdateSuccess = 'تم تحديث حالة الطلب بنجاح';
  static const String errorStatusUpdate =
      'تعذر تحديث حالة الطلب، يرجى المحاولة مرة أخرى.';
  static const String updatingStatus = 'جارٍ تحديث الحالة...';
  static const String currentStatus = 'الحالة الحالية';
  static const String selectNewStatus = 'اختر حالة جديدة';

  // Cancellation flow
  static const String cancellationSheetTitle = 'تفاصيل الإلغاء';
  static const String cancellationReason = 'سبب الإلغاء';
  static const String cancellationReasonLabel = 'سبب الإلغاء';
  static const String noCancellationReason = 'لم يتم إضافة سبب الإلغاء';
  static const String cancellationReasonHint = 'أدخل سبب الإلغاء...';
  static const String cancellationReasonRequired = 'يرجى إدخال سبب الإلغاء';
  static const String restoreStock = 'إرجاع المنتجات للمخزن';
  static const String restoreStockHint =
      'هل تريد إعادة هذه المنتجات إلى المخزن؟';
  static const String restoreStockYes = 'نعم، أعد للمخزن';
  static const String restoreStockNo = 'لا، لا تعد';
  static const String confirmCancellation = 'تأكيد الإلغاء';
}

class Estate {
  final String id;
  final String name;
  final String address;
  final String? logoUrl;
  final String? description;
  final DateTime createdAt;

  Estate({
    required this.id,
    required this.name,
    required this.address,
    this.logoUrl,
    this.description,
    required this.createdAt,
  });

  factory Estate.fromJson(Map<String, dynamic> json) {
    return Estate(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      logoUrl: json['logo_url'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'logo_url': logoUrl,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Member {
  final String id;
  final String userId;
  final String estateId;
  final String role;
  final String? houseNumber;
  final String? street;
  final bool isVerified;
  final DateTime createdAt;

  Member({
    required this.id,
    required this.userId,
    required this.estateId,
    required this.role,
    this.houseNumber,
    this.street,
    required this.isVerified,
    required this.createdAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      userId: json['user_id'],
      estateId: json['estate_id'],
      role: json['role'],
      houseNumber: json['house_number'],
      street: json['street'],
      isVerified: json['is_verified'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Property {
  final String id;
  final String estateId;
  final String? ownerId;
  final String title;
  final String description;
  final String type;
  final double price;
  final String? priceUnit;
  final int? bedrooms;
  final int? bathrooms;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;

  Property({
    required this.id,
    required this.estateId,
    this.ownerId,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    this.priceUnit,
    this.bedrooms,
    this.bathrooms,
    this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      estateId: json['estate_id'],
      ownerId: json['owner_id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      price: (json['price'] as num).toDouble(),
      priceUnit: json['price_unit'],
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      imageUrl: json['image_url'],
      isAvailable: json['is_available'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Due {
  final String id;
  final String estateId;
  final String name;
  final String? description;
  final double amount;
  final String type;
  final bool isRecurrent;
  final String? recurrenceInterval;
  final DateTime? dueDate;
  final DateTime createdAt;

  Due({
    required this.id,
    required this.estateId,
    required this.name,
    this.description,
    required this.amount,
    required this.type,
    required this.isRecurrent,
    this.recurrenceInterval,
    this.dueDate,
    required this.createdAt,
  });

  factory Due.fromJson(Map<String, dynamic> json) {
    return Due(
      id: json['id'],
      estateId: json['estate_id'],
      name: json['name'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      isRecurrent: json['is_recurrent'],
      recurrenceInterval: json['recurrence_interval'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Payment {
  final String id;
  final String memberId;
  final String dueId;
  final double amount;
  final String status;
  final String? paymentMethod;
  final String? reference;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.memberId,
    required this.dueId,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.reference,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      memberId: json['member_id'],
      dueId: json['due_id'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      paymentMethod: json['payment_method'],
      reference: json['reference'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Wallet {
  final String id;
  final String memberId;
  final double balance;
  final double totalFunded;
  final double totalSpent;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.memberId,
    required this.balance,
    this.totalFunded = 0,
    this.totalSpent = 0,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      memberId: json['member_id'],
      balance: (json['balance'] as num).toDouble(),
      totalFunded: (json['total_funded'] as num?)?.toDouble() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Meeting {
  final String id;
  final String estateId;
  final String title;
  final String? minutes;
  final DateTime meetingDate;
  final DateTime createdAt;

  Meeting({
    required this.id,
    required this.estateId,
    required this.title,
    this.minutes,
    required this.meetingDate,
    required this.createdAt,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'],
      estateId: json['estate_id'],
      title: json['title'],
      minutes: json['minutes'],
      meetingDate: DateTime.parse(json['meeting_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Committee {
  final String id;
  final String estateId;
  final String name;
  final String? description;
  final DateTime createdAt;

  Committee({
    required this.id,
    required this.estateId,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Committee.fromJson(Map<String, dynamic> json) {
    return Committee(
      id: json['id'],
      estateId: json['estate_id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Announcement {
  final String id;
  final String estateId;
  final String title;
  final String content;
  final String? authorId;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.estateId,
    required this.title,
    required this.content,
    this.authorId,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      estateId: json['estate_id'],
      title: json['title'],
      content: json['content'],
      authorId: json['author_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class GuestManifest {
  final String id;
  final String estateId;
  final String visitorName;
  final String? visitorPhone;
  final String? purpose;
  final String? hostMemberId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;

  GuestManifest({
    required this.id,
    required this.estateId,
    required this.visitorName,
    this.visitorPhone,
    this.purpose,
    this.hostMemberId,
    required this.checkInTime,
    this.checkOutTime,
  });

  factory GuestManifest.fromJson(Map<String, dynamic> json) {
    return GuestManifest(
      id: json['id'],
      estateId: json['estate_id'],
      visitorName: json['visitor_name'],
      visitorPhone: json['visitor_phone'],
      purpose: json['purpose'],
      hostMemberId: json['host_member_id'],
      checkInTime: DateTime.parse(json['check_in_time']),
      checkOutTime: json['check_out_time'] != null ? DateTime.parse(json['check_out_time']) : null,
    );
  }
}

class SecurityAlert {
  final String id;
  final String estateId;
  final String title;
  final String description;
  final String severity;
  final bool isActive;
  final DateTime createdAt;

  SecurityAlert({
    required this.id,
    required this.estateId,
    required this.title,
    required this.description,
    required this.severity,
    required this.isActive,
    required this.createdAt,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      id: json['id'],
      estateId: json['estate_id'],
      title: json['title'],
      description: json['description'],
      severity: json['severity'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class PropertyDeal {
  final String id;
  final String estateId;
  final String? sellerId;
  final String title;
  final String description;
  final String dealType;
  final double price;
  final String? propertyType;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  PropertyDeal({
    required this.id,
    required this.estateId,
    this.sellerId,
    required this.title,
    required this.description,
    required this.dealType,
    required this.price,
    this.propertyType,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory PropertyDeal.fromJson(Map<String, dynamic> json) {
    return PropertyDeal(
      id: json['id'],
      estateId: json['estate_id'],
      sellerId: json['seller_id'],
      title: json['title'],
      description: json['description'],
      dealType: json['deal_type'],
      price: (json['price'] as num).toDouble(),
      propertyType: json['property_type'],
      imageUrl: json['image_url'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class MemberAd {
  final String id;
  final String memberId;
  final String title;
  final String description;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  MemberAd({
    required this.id,
    required this.memberId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory MemberAd.fromJson(Map<String, dynamic> json) {
    return MemberAd(
      id: json['id'],
      memberId: json['member_id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Post {
  final String id;
  final String estateId;
  final String? authorId;
  final String category;
  final String? title;
  final String content;
  final List<String> photos;
  final String? videoUrl;
  final List<String> likes;
  final int numComments;
  final bool isPinned;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.estateId,
    this.authorId,
    required this.category,
    this.title,
    required this.content,
    this.photos = const [],
    this.videoUrl,
    this.likes = const [],
    this.numComments = 0,
    this.isPinned = false,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      estateId: json['estate_id'],
      authorId: json['author_id'],
      category: json['category'] ?? 'Update',
      title: json['title'],
      content: json['content'],
      photos: List<String>.from(json['photos'] ?? []),
      videoUrl: json['video_url'],
      likes: List<String>.from(json['likes'] ?? []),
      numComments: json['num_comments'] ?? 0,
      isPinned: json['is_pinned'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Comment {
  final String id;
  final String postId;
  final String? authorId;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    this.authorId,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      authorId: json['author_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Activity {
  final String id;
  final String estateId;
  final String? actorId;
  final String activityType;
  final String description;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.estateId,
    this.actorId,
    required this.activityType,
    required this.description,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      estateId: json['estate_id'],
      actorId: json['actor_id'],
      activityType: json['activity_type'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String? estateId;
  final String type;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    this.estateId,
    required this.type,
    required this.title,
    this.body,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      estateId: json['estate_id'],
      type: json['type'],
      title: json['title'],
      body: json['body'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Invoice {
  final String id;
  final String estateId;
  final String? memberId;
  final String? dueId;
  final double amount;
  final String type;
  final bool isPaid;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.estateId,
    this.memberId,
    this.dueId,
    required this.amount,
    required this.type,
    this.isPaid = false,
    this.dueDate,
    this.paidDate,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      estateId: json['estate_id'],
      memberId: json['member_id'],
      dueId: json['due_id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      isPaid: json['is_paid'] ?? false,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String slug;
  final double priceMonthly;
  final double priceYearly;
  final int maxEstates;
  final int maxMembers;
  final Map<String, dynamic> features;
  final bool isActive;
  final int displayOrder;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.slug,
    required this.priceMonthly,
    required this.priceYearly,
    required this.maxEstates,
    required this.maxMembers,
    this.features = const {},
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      priceMonthly: (json['price_monthly'] as num).toDouble(),
      priceYearly: (json['price_yearly'] as num).toDouble(),
      maxEstates: json['max_estates'] ?? 1,
      maxMembers: json['max_members'] ?? 10,
      features: Map<String, dynamic>.from(json['features'] ?? {}),
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 0,
    );
  }
}

class EstateSubscription {
  final String id;
  final String estateId;
  final String planId;
  final String? paystackSubscriptionCode;
  final String? paystackCustomerCode;
  final String? billingCycle;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  EstateSubscription({
    required this.id,
    required this.estateId,
    required this.planId,
    this.paystackSubscriptionCode,
    this.paystackCustomerCode,
    this.billingCycle,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory EstateSubscription.fromJson(Map<String, dynamic> json) {
    return EstateSubscription(
      id: json['id'],
      estateId: json['estate_id'],
      planId: json['plan_id'],
      paystackSubscriptionCode: json['paystack_subscription_code'],
      paystackCustomerCode: json['paystack_customer_code'],
      billingCycle: json['billing_cycle'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
    );
  }
}

enum UserRole {
  customer,
  designer,
  productionStaff,
  frontDesk,
  contentManager,
  admin;

  bool get isStaff =>
      this == productionStaff ||
      this == frontDesk ||
      this == contentManager;

  bool get isAdmin => this == admin;
  bool get isDesigner => this == designer;
  
  bool get canAccessAdmin => isAdmin || isDesigner || isStaff;

  static UserRole fromString(String value) {
    switch (value) {
      case 'designer':
        return UserRole.designer;
      case 'production_staff':
        return UserRole.productionStaff;
      case 'front_desk':
        return UserRole.frontDesk;
      case 'content_manager':
        return UserRole.contentManager;
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  String toJson() {
    switch (this) {
      case UserRole.designer:
        return 'designer';
      case UserRole.productionStaff:
        return 'production_staff';
      case UserRole.frontDesk:
        return 'front_desk';
      case UserRole.contentManager:
        return 'content_manager';
      case UserRole.admin:
        return 'admin';
      case UserRole.customer:
        return 'customer';
    }
  }
}

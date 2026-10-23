library skeleton;

/// Core
export 'package:skeleton/core/app_core.dart';

/// Guard
export 'package:skeleton/guard/is_connected.dart';
export 'package:skeleton/guard/is_not_connected.dart';

/// Provider
export 'package:skeleton/provider/local_auth.dart';

/// Model
export 'package:skeleton/model/skeleton_config.dart';

/// Utils
export 'package:skeleton/utils/login_identifier.dart';

/// Theme
export 'package:skeleton/theme/auth/auth_theme.dart';
export 'package:skeleton/theme/web/web_skeleton_theme.dart';
export 'package:skeleton/theme/skeleton_theme_keys.dart';

/// View - Page
// Auth
export 'package:skeleton/view/page/auth/login_page.dart';
export 'package:skeleton/view/page/auth/create_account_page.dart';
export 'package:skeleton/view/page/auth/phone_login_page.dart';
export 'package:skeleton/view/page/auth/reset_password_page.dart';

/// Profil Completion
export 'package:skeleton/view/page/profil_completion/default_data.dart';

// Profile
export 'package:skeleton/view/page/profile_parent.dart';
export 'package:skeleton/view/page/profile/settings_page.dart';
export 'package:skeleton/view/page/profile/subnode_page.dart';
export 'package:skeleton/view/page/profile/security/change_phone_page.dart';
export 'package:skeleton/view/page/profile/security/change_email_page.dart';
export 'package:skeleton/view/page/profile/security/change_password_page.dart';

/// Legal information
export 'package:skeleton/view/page/legal-information/legal_information_page.dart';

// Parent
export 'package:skeleton/view/page/logged_user_parent.dart';
export 'package:skeleton/view/page/maybe_logged_user_parent.dart';
export 'package:skeleton/view/page/auth_parent.dart';
export 'package:skeleton/view/page/hero_router.dart';
export 'package:skeleton/view/page/empty_parent.dart';

/// View - Widget

/// External package
export 'package:core_kosmos/core_kosmos.dart';
export 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
export 'package:settings_kosmos/settings_kosmos.dart';
export 'package:firebase_analytics/firebase_analytics.dart';

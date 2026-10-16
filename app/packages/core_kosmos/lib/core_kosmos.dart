///
/// {@inject-html}
/// <a href='#'>Exemple of data</a>
/// {@end-inject-html}
///
///

library core_kosmos;

/// Core
export 'package:core_kosmos/src/core/launcher.dart';

/// Controller
export 'package:core_kosmos/src/controller/metadata_controller.dart';
export 'package:core_kosmos/src/controller/file_image_controller.dart';
export 'package:core_kosmos/src/controller/user_firestore_controller.dart';
export 'package:core_kosmos/src/controller/notif_controller.dart';
export 'package:core_kosmos/src/controller/local_config_controller.dart';
export 'package:core_kosmos/src/controller/geoloc_controller.dart';
export 'package:core_kosmos/src/controller/http_controller.dart';
export 'package:core_kosmos/src/controller/local_auth_controller.dart';
export 'package:core_kosmos/src/controller/hash_controller.dart';
export 'package:core_kosmos/src/controller/event_controller.dart';
export 'package:core_kosmos/src/controller/share_controller.dart';
export 'package:core_kosmos/src/controller/firebase_root_controller.dart';
export 'package:core_kosmos/src/controller/google_map_controller.dart';
export 'package:core_kosmos/src/controller/analytics_controller.dart';
export 'package:core_kosmos/src/controller/os_controller.dart';
export 'package:core_kosmos/src/controller/settings_controller.dart';

/// Config
export 'package:core_kosmos/src/config/config.dart';
export 'package:core_kosmos/src/config/user_config.dart';
export 'package:core_kosmos/src/config/event_config.dart';
export 'package:core_kosmos/src/config/firebase.dart';
export 'package:core_kosmos/src/config/delegate/camera_delegate.dart';
export 'package:core_kosmos/src/config/google_map.dart';
export 'package:core_kosmos/src/config/wechatPickerState/custom_wechat_picker_state.dart';

/// Extension
export 'package:core_kosmos/src/extension/list.dart';
export 'package:core_kosmos/src/extension/num.dart';
export 'package:core_kosmos/src/extension/color.dart';
export 'package:core_kosmos/src/extension/duration.dart';
export 'package:core_kosmos/src/extension/datetime.dart';
export 'package:core_kosmos/src/extension/string.dart';

/// Model
export 'package:core_kosmos/src/model/app_model.dart';
export 'package:core_kosmos/src/model/social_user/social_user.dart';
export 'package:core_kosmos/src/model/user/user.dart';
export 'package:core_kosmos/src/model/location/location_model.dart';
export 'package:core_kosmos/src/model/object/item.dart';
export 'package:core_kosmos/src/model/metadata/metadata_config.dart';
export 'package:core_kosmos/src/model/password/password_quality.dart';
export 'package:core_kosmos/src/model/notification/notification_model.dart';
export 'package:core_kosmos/src/model/enum.dart';
export 'package:core_kosmos/src/model/stripe/stripe_config.dart';
export 'package:core_kosmos/src/model/sized_image/sized_image.dart';
export 'package:core_kosmos/src/model/fileData/file_data.dart';

/// Provider
export 'package:core_kosmos/src/provider/user_provider.dart';
export 'package:core_kosmos/src/provider/notification_stream_status.dart';

/// Responsive
export 'package:core_kosmos/src/responsive/responsive.dart';

/// Theme
export 'package:core_kosmos/src/theme/app_theme.dart';
export 'package:core_kosmos/src/theme/color_scheme.dart';

/// Utils
export 'package:core_kosmos/src/utils/field_validator.dart';
export 'package:core_kosmos/src/utils/platform.dart';
export 'package:core_kosmos/src/utils/core.dart';
export 'package:core_kosmos/src/utils/types.dart';
export 'package:core_kosmos/src/utils/converters/converters.dart';
export 'package:core_kosmos/src/utils/popup.dart';
export 'package:core_kosmos/src/utils/compress_image.dart';
export 'package:core_kosmos/src/utils/converters/location_converters.dart';

/// Other Package
export 'package:easy_localization/easy_localization.dart';
export 'package:get_it/get_it.dart';
export 'package:responsive_framework/responsive_framework.dart';
export 'package:responsive_framework/responsive_wrapper.dart';
export 'package:flutter_screenutil/flutter_screenutil.dart';
export 'package:hooks_riverpod/hooks_riverpod.dart';
export 'package:auto_route/auto_route.dart';
export 'package:image_picker/image_picker.dart' show XFile, ImageSource;
export 'package:file_picker/file_picker.dart' show PlatformFile;
export 'package:core_kosmos/src/extension/context_ext.dart';

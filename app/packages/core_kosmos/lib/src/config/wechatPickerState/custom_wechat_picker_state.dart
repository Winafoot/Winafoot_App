import 'package:core_kosmos/core_kosmos.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class CustomWechatPicker extends PackageConfig {
  CustomWechatPicker({
    this.customWechatPicketState,
  }) : super("wechat_picker");

  final CameraPickerState? customWechatPicketState;
}

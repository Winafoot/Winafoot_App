import 'package:core_kosmos/core_kosmos.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class KosmosCameraDelegate extends CameraPickerTextDelegate {
  const KosmosCameraDelegate() : super();

  @override
  String get languageCode => 'locale'.tr();

  /// Confirm string for the confirm button.
  /// 确认按钮的字段
  @override
  String get confirm => 'package.picker.camera.confirm'.tr();

  /// Tips above the shooting button before shooting.
  /// 拍摄前确认按钮上方的提示文字
  @override
  String get shootingTips => 'package.picker.camera.shootingTips'.tr();

  /// Tips with recording above the shooting button before shooting.
  /// 拍摄前确认按钮上方的提示文字（带录像）
  @override
  String get shootingWithRecordingTips => 'package.picker.camera.shootingWithRecordingTips'.tr();

  /// Tips with only recording above the shooting button before shooting.
  /// 拍摄前确认按钮上方的提示文字（仅录像）
  @override
  String get shootingOnlyRecordingTips => 'package.picker.camera.shootingOnlyRecordingTips'.tr();

  /// Tips with tap recording above the shooting button before shooting.
  /// 拍摄前确认按钮上方的提示文字（点击录像）
  @override
  String get shootingTapRecordingTips => 'package.picker.camera.shootingTapRecordingTips'.tr();

  /// Load failed string for item.
  /// 资源加载失败时的字段
  @override
  String get loadFailed => 'package.picker.camera.loadFailed'.tr();

  /// Default loading string for the dialog.
  /// 加载中弹窗的默认文字
  @override
  String get loading => 'package.picker.camera.loading'.tr();

  /// Saving string for the dialog.
  /// 保存中弹窗的默认文字
  @override
  String get saving => 'package.picker.camera.saving'.tr();

  /// Semantics fields.
  ///
  /// Fields below are only for semantics usage. For customizable these fields,
  /// head over to [EnglishCameraPickerTextDelegate] for better understanding.
  @override
  String get sActionManuallyFocusHint => 'package.picker.camera.sActionManuallyFocusHint'.tr();

  @override
  String get sActionPreviewHint => 'package.picker.camera.sActionPreviewHint'.tr();

  @override
  String get sActionRecordHint => 'package.picker.camera.sActionRecordHint'.tr();

  @override
  String get sActionShootHint => 'package.picker.camera.sActionShootHint'.tr();

  @override
  String get sActionShootingButtonTooltip => 'package.picker.camera.sActionShootingButtonTooltip'.tr();

  @override
  String get sActionStopRecordingHint => 'package.picker.camera.sActionStopRecordingHint'.tr();

  @override
  String sCameraLensDirectionLabel(CameraLensDirection value) {
    switch (value) {
      case CameraLensDirection.front:
        return 'package.picker.camera.front'.tr();
      case CameraLensDirection.back:
        return 'package.picker.camera.back'.tr();
      case CameraLensDirection.external:
        return 'package.picker.camera.external'.tr();
    }
  }

  @override
  String? sCameraPreviewLabel(CameraLensDirection? value) {
    if (value == null) {
      return null;
    }
    return sCameraLensDirectionLabel(value);
  }

  @override
  String sFlashModeLabel(FlashMode mode) {
    final String modeString;
    switch (mode) {
      case FlashMode.off:
        modeString = 'package.picker.camera.off'.tr();
        break;
      case FlashMode.auto:
        modeString = 'package.picker.camera.auto'.tr();
        break;
      case FlashMode.always:
        modeString = 'package.picker.camera.always'.tr();
        break;
      case FlashMode.torch:
        modeString = 'package.picker.camera.torch'.tr();
        break;
    }
    return modeString;
  }

  @override
  String sSwitchCameraLensDirectionLabel(CameraLensDirection value) {
    return sCameraLensDirectionLabel(value);
  }
}

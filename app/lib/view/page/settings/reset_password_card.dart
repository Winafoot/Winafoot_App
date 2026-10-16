// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skeleton/skeleton.dart';
import 'package:wina/view/widget/check_profil_form.dart';

class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({
    super.key,
    this.formKey,
    this.currentPasswordController,
    this.newPasswordController,
    this.confirmPasswordController,
    this.onSuccess,
    this.onError,
  });

  final GlobalKey<FormState>? formKey;
  final TextEditingController? currentPasswordController;
  final TextEditingController? newPasswordController;
  final TextEditingController? confirmPasswordController;
  final VoidCallback? onSuccess;
  final void Function(Object error)? onError;

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  late final GlobalKey<FormState> _formKey;
  TextEditingController? _currentPasswordCtrl;
  TextEditingController? _newPasswordCtrl;
  TextEditingController? _confirmPasswordCtrl;

  bool _ownsCurrent = false;
  bool _ownsNew = false;
  bool _ownsConfirm = false;

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? GlobalKey<FormState>();

    if (widget.currentPasswordController == null) {
      _currentPasswordCtrl = TextEditingController();
      _ownsCurrent = true;
    }
    if (widget.newPasswordController == null) {
      _newPasswordCtrl = TextEditingController();
      _ownsNew = true;
    }
    if (widget.confirmPasswordController == null) {
      _confirmPasswordCtrl = TextEditingController();
      _ownsConfirm = true;
    }
  }

  @override
  void dispose() {
    if (_ownsCurrent) _currentPasswordCtrl?.dispose();
    if (_ownsNew) _newPasswordCtrl?.dispose();
    if (_ownsConfirm) _confirmPasswordCtrl?.dispose();
    super.dispose();
  }

  TextEditingController get _currentPassword =>
      widget.currentPasswordController ?? _currentPasswordCtrl!;
  TextEditingController get _newPassword =>
      widget.newPasswordController ?? _newPasswordCtrl!;
  TextEditingController get _confirmPassword =>
      widget.confirmPasswordController ?? _confirmPasswordCtrl!;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              FormClassicField(
                controller: _currentPassword,
                fieldName: "package.field.auth.actual-password.title".tr(),
                hintText: "package.field.auth.actual-password.hint".tr(),
                isRequired: true,
                isSecretField: true,
                validator: (value) => FieldValidator.fieldNotEmpty(value),
              ),
              sh(14),
              FormClassicField(
                controller: _newPassword,
                fieldName: "package.field.auth.new-password.title".tr(),
                hintText: "package.field.auth.new-password.hint".tr(),
                isRequired: true,
                isSecretField: true,
                validator:
                    (value) => AuthValidator.validPassword(
                      value,
                      const PasswordSecurityConfig(),
                    ),
              ),
              sh(14),
              FormClassicField(
                controller: _confirmPassword,
                fieldName: "package.field.auth.new-repeat-password.title".tr(),
                hintText: "package.field.auth.new-repeat-password.hint".tr(),
                isRequired: true,
                isSecretField: true,
                validator:
                    (value) => AuthValidator.validSamePassword(
                      value,
                      _newPassword.text,
                    ),
              ),
              sh(24),
              CpButton(
                label: 'utils.save'.tr(),
                onTap: () async {
                  if (!(_formKey.currentState?.validate() ?? false)) {
                    PopupAlert.toast(
                      context,
                      FToast().init(context),
                      title: "utils.error".tr(),
                      subtitle: "utils.form-invalid".tr(),
                      type: AlertType.error,
                    );
                    return;
                  }
                  try {
                    User? currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null || currentUser.email == null) {
                      throw Exception('no-current-user');
                    }

                    final credential = EmailAuthProvider.credential(
                      email: currentUser.email!,
                      password: _currentPassword.text,
                    );

                    await currentUser.reauthenticateWithCredential(credential);
                    await currentUser.updatePassword(_newPassword.text);

                    if (!mounted) return;

                    PopupAlert.toast(
                      context,
                      FToast().init(context),
                      title: "utils.success".tr(),
                      subtitle:
                          "package.kosmos-auth.success-change-password".tr(),
                      type: AlertType.success,
                    );
                    widget.onSuccess?.call();
                  } on FirebaseAuthException catch (e) {
                    if (!mounted) return;
                    if (e.code == 'wrong-password') {
                      PopupAlert.toast(
                        context,
                        FToast().init(context),
                        title: "utils.error".tr(),
                        subtitle: "package.kosmos-auth.wrong-password".tr(),
                        type: AlertType.error,
                      );
                    } else {
                      PopupAlert.toast(
                        context,
                        FToast().init(context),
                        title: "utils.error".tr(),
                        subtitle: "utils.error-default".tr(),
                        type: AlertType.error,
                      );
                    }
                    widget.onError?.call(e);
                  } catch (error) {
                    if (!mounted) return;
                    PopupAlert.toast(
                      context,
                      FToast().init(context),
                      title: "utils.error".tr(),
                      subtitle: "utils.error-default".tr(),
                      type: AlertType.error,
                    );
                    widget.onError?.call(error);
                  }
                },
              ),
              sh(12),
              const CpRequiredNote(),
            ],
          ),
        ),
      ],
    );
  }
}

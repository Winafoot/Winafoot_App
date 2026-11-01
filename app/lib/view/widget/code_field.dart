import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/check_profil_form.dart';

/// Nombre de chiffres du code reçu par e-mail (même valeur que `OTP_LENGTH`
/// côté serveur, server/functions/src/utils/otp_code.ts).
const int kEmailCodeLength = 6;

/// Champ de saisie du code à 6 chiffres reçu par e-mail : chiffres espacés et
/// centrés, clavier numérique, collage et suggestion du code par le clavier
/// acceptés. [onCompleted] est appelé dès que les 6 chiffres sont saisis.
class CpCodeField extends StatelessWidget {
  const CpCodeField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onCompleted,
    this.error = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool error;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return CpBox(
      error: error,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        autofillHints: const <String>[AutofillHints.oneTimeCode],
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(kEmailCodeLength),
        ],
        cursorColor: AppColor.primaryColor,
        style: AppThemeStyle.semiBStyle(
          cFs(26),
          AppColor.primaryColor,
        ).copyWith(letterSpacing: cW(10)),
        onChanged: (String value) {
          onChanged?.call(value);
          if (value.length == kEmailCodeLength) onCompleted?.call(value);
        },
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: '••••••',
          hintStyle: AppThemeStyle.regularStyle(
            cFs(26),
            AppColor.divider,
          ).copyWith(letterSpacing: cW(10)),
        ),
      ),
    );
  }
}

/// Lien « Renvoyer le code » avec un compte à rebours : le renvoi est bloqué
/// [seconds] secondes après chaque envoi (le serveur impose le même délai).
class ResendCodeLink extends StatefulWidget {
  const ResendCodeLink({
    super.key,
    required this.onResend,
    this.seconds = 30,
  });

  /// Renvoie le code. Renvoie `true` si l'envoi est parti : le compte à
  /// rebours repart alors de zéro.
  final Future<bool> Function() onResend;
  final int seconds;

  @override
  State<ResendCodeLink> createState() => _ResendCodeLinkState();
}

class _ResendCodeLinkState extends State<ResendCodeLink> {
  late int _remaining = widget.seconds;
  bool _sending = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _tick() async {
    while (!_disposed && _remaining > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (_disposed) return;
      setState(() => _remaining--);
    }
  }

  Future<void> _resend() async {
    if (_sending || _remaining > 0) return;
    setState(() => _sending = true);
    final bool sent = await widget.onResend();
    if (_disposed) return;
    setState(() {
      _sending = false;
      if (sent) _remaining = widget.seconds;
    });
    if (sent) _tick();
  }

  @override
  Widget build(BuildContext context) {
    final bool waiting = _remaining > 0;
    return Center(
      child: GestureDetector(
        onTap: _resend,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: cH(6)),
          child: Text(
            waiting
                ? 'Renvoyer le code dans $_remaining s'
                : (_sending ? 'Envoi…' : 'Renvoyer le code'),
            style: AppThemeStyle.mediumStyle(
              cFs(13),
              waiting ? AppColor.secondaryLabels : AppColor.primaryColor,
            ).copyWith(
              decoration: waiting ? null : TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}

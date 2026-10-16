import 'package:core_kosmos/src/model/stripe/stripeFee/stripe_fees_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stripe_config.freezed.dart';
part 'stripe_config.g.dart';

@freezed
class StripeConfig with _$StripeConfig {
  const factory StripeConfig({
    required String publishableKey,
    String? publishableProdKey,
    @Default(false) bool isProdMode,
    required String merchantIdentifier,
    required String urlScheme,
    @Default([]) List<String> testEmail,
    StripeFeesModel? stripeCommission,

    /// Merchant Data
    String? defaultMerchantName,

    /// iOS only
    @Default(false) enableApplePay,

    /// Android only
    @Default(false) enableGooglePay,
  }) = _StripeConfig;

  factory StripeConfig.fromJson(Map<String, dynamic> json) =>
      _$StripeConfigFromJson(json);
}

import 'package:chessiq/core/services/purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

PurchaseDetails _buildPurchase({
  required String productId,
  required PurchaseStatus status,
  String? purchaseId,
  String? serverVerificationData,
  String? transactionDate,
}) {
  return PurchaseDetails(
    purchaseID: purchaseId,
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local-$productId',
      serverVerificationData: serverVerificationData ?? '',
      source: 'test',
    ),
    transactionDate: transactionDate ?? '1715731200000',
    status: status,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    PurchaseService.instance.dispose();
  });

  test('restore ignores consumables', () async {
    final purchase = _buildPurchase(
      productId: IapProducts.coinPackS,
      purchaseId: 'coin-order-1',
      serverVerificationData: 'coin-token-1',
      status: PurchaseStatus.restored,
    );

    final shouldDeliver = await PurchaseService.instance
        .claimDeliveryForTesting(purchase);

    expect(shouldDeliver, isFalse);
  });

  test(
    'purchased consumables only claim delivery once per transaction',
    () async {
      final purchase = _buildPurchase(
        productId: IapProducts.coinPackL,
        purchaseId: 'coin-order-2',
        serverVerificationData: 'coin-token-2',
        status: PurchaseStatus.purchased,
      );

      expect(
        await PurchaseService.instance.claimDeliveryForTesting(purchase),
        isTrue,
      );
      expect(
        await PurchaseService.instance.claimDeliveryForTesting(purchase),
        isFalse,
      );
    },
  );

  test('restored non-consumables are idempotent', () async {
    final purchase = _buildPurchase(
      productId: IapProducts.academyPass,
      status: PurchaseStatus.restored,
    );

    expect(
      await PurchaseService.instance.claimDeliveryForTesting(purchase),
      isTrue,
    );
    expect(
      await PurchaseService.instance.claimDeliveryForTesting(purchase),
      isFalse,
    );
  });

  test('consumable fingerprint falls back to verification token', () {
    final purchase = _buildPurchase(
      productId: IapProducts.coinPackS,
      status: PurchaseStatus.purchased,
      serverVerificationData: 'coin-token-3',
    );

    expect(
      purchaseDeliveryFingerprint(purchase),
      'purchase:${IapProducts.coinPackS}:coin-token-3',
    );
  });
}

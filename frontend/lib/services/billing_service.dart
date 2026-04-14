// lib/services/billing_service.dart.sample
// Service para la gestión de suscripciones e In-App Purchases (IAP).

import 'dart:async';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

/**
 * BillingService orquestra la comunicación con Google Play Billing.
 * Implementa un flujo de validación cruzada (App -> Store -> Backend).
 */
class BillingService {
  static final BillingService instance = BillingService._();
  BillingService._();

  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;

  /// Inicializa la conexión con la tienda de aplicaciones.
  Future<void> initConnection() async {
    await FlutterInappPurchase.instance.initialize();
    
    // Listeners para actualizaciones de transacciones en tiempo real
    _purchaseUpdatedSubscription = FlutterInappPurchase.purchaseUpdated.listen((item) {
      _handlePurchaseUpdate(item);
    });

    _purchaseErrorSubscription = FlutterInappPurchase.purchaseError.listen((error) {
      // Manejo de errores de pasarela (Cancelaciones, Fallos de pago)
    });
  }

  /**
   * Inicia el proceso de compra para un SKU específico.
   * Maneja el 'Handshake' asíncrono para asegurar que la transacción sea atómica.
   */
  Future<void> comprarPlan(String sku) async {
    try {
      // En la versión privada, aquí se gestiona la lógica de 'offerToken' 
      // para planes base y ofertas de retención.
      await FlutterInappPurchase.instance.requestSubscription(sku);
    } catch (e) {
      // Registro de error en el embudo de conversión
    }
  }

  /**
   * Callback de validación tras éxito en la Store.
   * IMPORTANTE: Implementa 'Server-Side Validation' para evitar fraude.
   */
  Future<void> _handlePurchaseUpdate(PurchasedItem? item) async {
    if (item == null || item.transactionReceipt == null) return;

    // 1. Enviar el receipt al backend de YoVerifico (Node.js)
    // 2. Esperar validación exitosa del servidor
    // 3. Finalizar la transacción en Google Play para evitar auto-reembolsos
    
    await FlutterInappPurchase.instance.finishTransaction(item);
    
    // Notificar a los Providers para desbloquear características Premium
  }

  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    FlutterInappPurchase.instance.finalize();
  }
}
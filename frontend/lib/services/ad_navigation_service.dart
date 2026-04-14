import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Importar SharedPrefs
import '../config.dart';

class AdNavigationService {

  static String get _adUnitId => AdIds.interstitial;

  /// Método "Peaje" asíncrono.
  /// Lee las preferencias igual que MainLayout antes de decidir.
  static Future<void> navegarConAnuncio({
    required BuildContext context,
    required VoidCallback onNext,
  }) async {
    
    // ---------------------------------------------------------
    // 1. LÓGICA RESCATADA DE MAINLAYOUT (PREFERENCIAS)
    // ---------------------------------------------------------
    final sp = await SharedPreferences.getInstance();
    
    // Leemos exactamente la misma variable que usa tu Banner
    final conAnuncios = sp.getBool('con_anuncios') ?? true; 
    
    // Si en MainLayout dice que NO hay anuncios (Premium), aquí tampoco mostramos.
    if (!conAnuncios) {
      onNext();
      return;
    }
    // ---------------------------------------------------------

    // 2. CARGAR Y MOSTRAR ANUNCIO (Si conAnuncios es true)
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onNext(); // 🟢 Navegar al cerrar
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onNext(); // 🟢 Navegar si falla visualización
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('AdMob error: $error'); 
          onNext(); // 🟢 Navegar si falla carga (Internet/No Fill)
        },
      ),
    );
  }
}
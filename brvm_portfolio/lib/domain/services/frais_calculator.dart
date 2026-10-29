/// Calcule les frais SGI en FCFA à partir du montant brut et du taux en points de base.
/// Arrondi à l'entier le plus proche (0,5 vers le haut).
int calculerFrais({required int brut, required int tauxBp}) =>
    (brut * tauxBp + 5000) ~/ 10000;

/// Convertit un taux en pourcentage (chaîne) en points de base.
/// '1,40' ou '1.4' -> 140 ; '1,18' -> 118 ; null si invalide ou hors [0 ; 10%]
int? parseTauxBp(String s) {
  final clean = s.trim().replaceAll(',', '.');
  final v = double.tryParse(clean);
  if (v == null || v < 0 || v > 10) return null;
  return (v * 100).round();
}

/// Montant net total d'un achat = brut + frais
int montantNetAchat(int brut, int frais) => brut + frais;

/// Prix de revient unitaire affiché (arrondi). La valeur stockée reste le coût total.
int prixRevientAffiche(int coutTotal, int quantite) {
  if (quantite <= 0) return 0;
  return (coutTotal / quantite).round();
}

/// Parse un montant FCFA depuis les formats courants.
/// '8,700' -> 8700 ; '8 700' -> 8700 ; '8700' -> 8700 ; '8,70' -> null (alerte)
int? parseFcfa(String raw) {
  final s = raw.replaceAll(String.fromCharCode(160), ' ').trim();
  final ok = RegExp(r'^[0-9]{1,3}([ .,][0-9]{3})+$').hasMatch(s) ||
      RegExp(r'^[0-9]+$').hasMatch(s);
  return ok ? int.parse(s.replaceAll(RegExp(r'[ .,]'), '')) : null;
}

/// Parse une date au format français 'jj/mm/aaaa' -> DateTime.utc.
/// Retourne null si la date est invalide (ex: 31/02/2026).
DateTime? parseDateFr(String s) {
  final p = s.trim().split('/');
  if (p.length != 3) return null;
  if (p[0].length != 2 || p[1].length != 2 || p[2].length != 4) return null;
  final d = int.tryParse(p[0]), m = int.tryParse(p[1]), y = int.tryParse(p[2]);
  if (d == null || m == null || y == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  final dt = DateTime.utc(y, m, d);
  return (dt.day == d && dt.month == m && dt.year == y) ? dt : null;
}

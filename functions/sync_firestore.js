const admin = require('firebase-admin');
const { collecterCoursBRVM } = require('./scraper_brvm');
const fs = require('fs');

let db = null;

try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    let serviceAccount;
    const rawSecret = process.env.FIREBASE_SERVICE_ACCOUNT.trim();
    if (rawSecret.startsWith('{')) {
      serviceAccount = JSON.parse(rawSecret);
    } else {
      try {
        const decoded = Buffer.from(rawSecret, 'base64').toString('utf8');
        serviceAccount = JSON.parse(decoded);
      } catch (e) {
        if (fs.existsSync(rawSecret)) {
          serviceAccount = JSON.parse(fs.readFileSync(rawSecret, 'utf8'));
        } else {
          throw new Error('Impossible de parser FIREBASE_SERVICE_ACCOUNT (ni JSON brut, ni base64, ni fichier valide)');
        }
      }
    }
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    db = admin.firestore();
    console.log('[Sync Firestore] Firebase Admin initialisé via FIREBASE_SERVICE_ACCOUNT.');
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    admin.initializeApp();
    db = admin.firestore();
    console.log('[Sync Firestore] Firebase Admin initialisé via GOOGLE_APPLICATION_CREDENTIALS.');
  } else {
    try {
      admin.initializeApp();
      db = admin.firestore();
      console.log('[Sync Firestore] Firebase Admin initialisé via identifiants par défaut.');
    } catch (e) {
      console.warn('[Sync Firestore] Aucun secret FIREBASE_SERVICE_ACCOUNT détecté. La synchronisation Firestore sera ignorée (seul brvm_cours.json sera produit).');
    }
  }
} catch (err) {
  console.error('[Sync Firestore] Erreur lors de l\'initialisation de Firebase Admin :', err.message);
}

async function synchroniserFirestore(donnees) {
  if (!db) {
    console.warn('[Sync Firestore] Connexion Firestore non configurée, écriture en base ignorée.');
    return;
  }

  const batch = db.batch();

  // 1. Mise à jour de la photo globale instantanée
  const systemeRef = db.doc('systeme/cotations_courantes');
  const titresMap = {};
  for (const titre of donnees.titres) {
    titresMap[titre.code] = {
      code: titre.code,
      nom: titre.nom,
      cours_cloture: titre.cours_cloture,
      cours_veille: titre.cours_veille,
      cours_ouverture: titre.cours_ouverture,
      variation_pct: titre.variation_pct,
      volume: titre.volume,
      date_maj: donnees.date_collecte,
    };
  }

  batch.set(systemeRef, {
    derniere_mise_a_jour: admin.firestore.FieldValue.serverTimestamp(),
    date_collecte_iso: donnees.date_collecte,
    date_maj_source: donnees.date_maj_source,
    statut_seance: donnees.statut_seance,
    nb_titres: donnees.nb_titres,
    erreurs_controles: donnees.erreurs_controles,
    titres: titresMap,
  }, { merge: true });

  await batch.commit();
  console.log(`[Sync Firestore] ✅ ${donnees.titres.length} titres synchronisés dans systeme/cotations_courantes.`);

  // 2. Historisation quotidienne pour les graphiques
  const dateStr = new Date(donnees.date_collecte).toISOString().split('T')[0];
  const historyBatch = db.batch();
  for (const titre of donnees.titres) {
    const historiqueRef = db.doc(`titres/${titre.code}/cours/${dateStr}`);
    historyBatch.set(historiqueRef, {
      code: titre.code,
      date: dateStr,
      cours: titre.cours_cloture,
      cours_veille: titre.cours_veille,
      variation_pct: titre.variation_pct,
      volume: titre.volume,
      cree_le: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  await historyBatch.commit();
  console.log(`[Sync Firestore] ✅ Historique quotidien enregistré pour le ${dateStr}.`);
}

async function main() {
  console.log('[Sync Firestore] Démarrage du script de synchronisation BRVM...');
  const donnees = await collecterCoursBRVM();
  await synchroniserFirestore(donnees);
  console.log('[Sync Firestore] Traitement terminé avec succès.');
}

if (require.main === module) {
  main().catch((err) => {
    console.error('[Sync Firestore] Erreur fatale :', err);
    process.exit(1);
  });
}

module.exports = { synchroniserFirestore, main };

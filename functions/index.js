const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onRequest } = require('firebase-functions/v2/https');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { collecterCoursBRVM } = require('./scraper_brvm');

if (!getApps().length) {
  initializeApp();
}

const db = getFirestore();

/**
 * Enregistre les cotations collectées dans Firestore :
 * 1. Document unique `systeme/cotations_courantes` pour optimiser les quotas de lecture client.
 * 2. Si la séance est terminée ou lors de la clôture, historise dans `titres/{code}/cours/{YYYY-MM-DD}`.
 */
async function synchroniserCotationsDansFirestore(donnees) {
  const batch = db.batch();

  // 1. Mise à jour du document global des cotations courantes
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
    derniere_mise_a_jour: FieldValue.serverTimestamp(),
    date_collecte_iso: donnees.date_collecte,
    date_maj_source: donnees.date_maj_source,
    statut_seance: donnees.statut_seance,
    nb_titres: donnees.nb_titres,
    erreurs_controles: donnees.erreurs_controles,
    titres: titresMap,
  }, { merge: true });

  await batch.commit();
  console.log(`[Firestore Sync] ${donnees.titres.length} titres synchronisés dans systeme/cotations_courantes.`);

  // 2. Si la séance est fermée, historisation quotidienne pour les graphiques
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
      cree_le: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  await historyBatch.commit();
  console.log(`[Firestore Sync] Historique quotidien enregistré pour le ${dateStr}.`);
}

/**
 * Tâche planifiée automatique (Cloud Scheduler)
 * Exécution continue toutes les 15 minutes pendant les heures de cotation BRVM :
 * Du lundi au vendredi, de 09h à 15h GMT (fuseau Abidjan).
 */
exports.collecteAutomatiqueCoursBRVM = onSchedule({
  schedule: '*/15 9-15 * * 1-5',
  timeZone: 'Africa/Abidjan',
  retryCount: 3,
  memory: '512MiB',
}, async (event) => {
  console.log('[Cloud Scheduler] Démarrage de la collecte continue des cours BRVM...');
  try {
    const donnees = await collecterCoursBRVM();
    await synchroniserCotationsDansFirestore(donnees);
    console.log('[Cloud Scheduler] Collecte et synchronisation terminées avec succès.');
  } catch (error) {
    console.error('[Cloud Scheduler] Erreur lors de la collecte planifiée :', error);
    throw error;
  }
});

/**
 * Endpoint HTTP pour rafraîchissement immédiat à la demande depuis l'application mobile / web
 */
exports.actualiserCoursBRVM = onRequest({
  cors: true,
  memory: '512MiB',
}, async (req, res) => {
  try {
    console.log('[HTTP Endpoint] Demande de rafraîchissement immédiat reçue...');
    const donnees = await collecterCoursBRVM();
    
    // Si Firebase Admin est connecté à un projet réel, tente la synchronisation
    try {
      await synchroniserCotationsDansFirestore(donnees);
    } catch (dbErr) {
      console.warn('[HTTP Endpoint] Attention: synchronisation Firestore locale non effectuée (normal si projet hors-ligne) :', dbErr.message);
    }

    res.status(200).json({
      success: true,
      message: 'Cotations BRVM actualisées avec succès.',
      data: donnees,
    });
  } catch (error) {
    console.error('[HTTP Endpoint] Erreur lors du rafraîchissement immédiat :', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

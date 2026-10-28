const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');

const URL_COTATIONS = 'https://www.brvm.org/fr/cours-actions/0';

function parseEntierFCFA(str) {
  if (!str) return 0;
  const clean = str.replace(/[\s\u00A0\u202F]/g, '');
  const val = parseInt(clean, 10);
  return isNaN(val) ? 0 : val;
}

function parseVariationPct(str) {
  if (!str) return 0.0;
  const clean = str.replace('%', '').replace(',', '.').replace(/[\s\u00A0\u202F]/g, '');
  const val = parseFloat(clean);
  return isNaN(val) ? 0.0 : val;
}

/**
 * Normalise les intitulés des colonnes pour un mapping robuste
 */
function normaliserNomEntete(nom) {
  return (nom || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]/g, '');
}

async function collecterCoursBRVM() {
  console.log(`[BRVM Collector] Fetching cotations from ${URL_COTATIONS}...`);
  const response = await fetch(URL_COTATIONS, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml',
      'Accept-Language': 'fr-FR,fr;q=0.9',
    }
  });

  if (!response.ok) {
    throw new Error(`HTTP Error ${response.status}: ${response.statusText}`);
  }

  const html = await response.text();
  const $ = cheerio.load(html);

  // Date de mise à jour affichée
  const dateMajRaw = $('section#block-tools-date-maj').text().trim();
  console.log(`[BRVM Collector] Source Date MAJ: "${dateMajRaw}"`);

  // État de la séance
  const seanceOuverte = $('.seance-ouverte').length > 0;
  const seanceFermee = $('.seance-fermee').length > 0;

  // Trouver la table principale contenant les cotations complètes
  let mainTable = null;
  let headersIndex = {
    symbole: -1,
    nom: -1,
    volume: -1,
    cours_veille: -1,
    cours_ouverture: -1,
    cours_cloture: -1,
    variation: -1,
  };

  $('table').each((i, tbl) => {
    const thElements = $(tbl).find('th');
    if (thElements.length >= 6) {
      const colMap = {};
      thElements.each((colIdx, th) => {
        const text = normaliserNomEntete($(th).text());
        if (text.includes('symbole') || text.includes('code') || text.includes('ticker')) {
          colMap.symbole = colIdx;
        } else if (text.includes('nom') || text.includes('titre') || text.includes('valeur')) {
          colMap.nom = colIdx;
        } else if (text.includes('volume') || text.includes('quantite')) {
          colMap.volume = colIdx;
        } else if (text.includes('veille') || text.includes('precedent')) {
          colMap.cours_veille = colIdx;
        } else if (text.includes('ouverture') || text.includes('open')) {
          colMap.cours_ouverture = colIdx;
        } else if (text.includes('cloture') || text.includes('cours') || text.includes('dernier')) {
          colMap.cours_cloture = colIdx;
        } else if (text.includes('variation') || text.includes('var')) {
          colMap.variation = colIdx;
        }
      });

      if (colMap.symbole !== undefined && (colMap.cours_cloture !== undefined || colMap.cours_veille !== undefined)) {
        mainTable = $(tbl);
        headersIndex = {
          symbole: colMap.symbole ?? 0,
          nom: colMap.nom ?? 1,
          volume: colMap.volume ?? 2,
          cours_veille: colMap.cours_veille ?? 3,
          cours_ouverture: colMap.cours_ouverture ?? 4,
          cours_cloture: colMap.cours_cloture ?? 5,
          variation: colMap.variation ?? 6,
        };
        console.log(`[BRVM Collector] Table principale trouvée (#${i}) avec entêtes identifiées :`, headersIndex);
      }
    }
  });

  if (!mainTable) {
    throw new Error('Impossible de localiser la table des cotations BRVM avec les entêtes attendues.');
  }

  const titres = [];
  const erreursControles = [];

  mainTable.find('tbody tr').each((i, el) => {
    const cols = $(el).find('td');
    if (cols.length < 5) return;

    const code = $(cols[headersIndex.symbole]).text().trim();
    const nom = $(cols[headersIndex.nom]).text().trim();
    const volume = parseEntierFCFA($(cols[headersIndex.volume]).text());
    const coursVeille = parseEntierFCFA($(cols[headersIndex.cours_veille]).text());
    const coursOuverture = headersIndex.cours_ouverture >= 0 
        ? parseEntierFCFA($(cols[headersIndex.cours_ouverture]).text()) 
        : coursVeille;
    const coursCloture = parseEntierFCFA($(cols[headersIndex.cours_cloture]).text());
    
    const varEl = cols[headersIndex.variation];
    const varText = $(varEl).find('span:first').text().trim() || $(varEl).text().trim();
    const variationPct = parseVariationPct(varText);

    // Contrôles de plausibilité par titre
    if (!code || code.length > 10) {
      erreursControles.push(`Symbole invalide à la ligne ${i + 1}: ${code}`);
      return;
    }

    if (coursCloture <= 0 && coursVeille <= 0) {
      erreursControles.push(`Cours invalide pour ${code}: clôture=${coursCloture}, veille=${coursVeille}`);
    }

    titres.push({
      code,
      nom,
      volume,
      cours_veille: coursVeille,
      cours_ouverture: coursOuverture,
      cours_cloture: coursCloture > 0 ? coursCloture : coursVeille,
      variation_pct: variationPct,
    });
  });

  console.log(`[BRVM Collector] Extraits: ${titres.length} titres.`);

  if (titres.length < 40) {
    erreursControles.push(`Alerte couverture: Seulement ${titres.length} titres extraits (attendu ~47-48)`);
  }

  const resultat = {
    date_collecte: new Date().toISOString(),
    date_maj_source: dateMajRaw,
    statut_seance: seanceOuverte ? 'OUVERTE' : (seanceFermee ? 'FERMEE' : 'INCONNU'),
    nb_titres: titres.length,
    entetes_detectees: headersIndex,
    erreurs_controles: erreursControles,
    titres: titres
  };

  const outputPath = path.join(__dirname, 'brvm_cours.json');
  fs.writeFileSync(outputPath, JSON.stringify(resultat, null, 2), 'utf-8');
  console.log(`[BRVM Collector] Fichier enregistré avec succès : ${outputPath}`);

  return resultat;
}

// Exécuter si lancé directement
if (require.main === module) {
  collecterCoursBRVM()
    .then((res) => {
      console.log(`[BRVM Collector] Succès ! ${res.nb_titres} actions traitées.`);
      if (res.erreurs_controles.length > 0) {
        console.warn(`[BRVM Collector] Avertissements :`, res.erreurs_controles);
      }
    })
    .catch((err) => {
      console.error(`[BRVM Collector] Erreur fatale :`, err.message);
      process.exit(1);
    });
}

module.exports = { collecterCoursBRVM, parseEntierFCFA, parseVariationPct };

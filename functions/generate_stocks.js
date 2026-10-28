const fs = require('fs');
const path = require('path');

const data = JSON.parse(fs.readFileSync(path.join(__dirname, 'brvm_cours.json'), 'utf8'));

const secteurs = {
  'SNTS': 'Télécommunications', 'ORAC': 'Télécommunications', 'ONTBF': 'Télécommunications',
  'SGBC': 'Services Financiers', 'ECOC': 'Services Financiers', 'SIBC': 'Services Financiers',
  'BOAC': 'Services Financiers', 'BOAB': 'Services Financiers', 'BOABF': 'Services Financiers',
  'BOAM': 'Services Financiers', 'BOAN': 'Services Financiers', 'BOAS': 'Services Financiers',
  'CBIBF': 'Services Financiers', 'BICC': 'Services Financiers', 'BICB': 'Services Financiers',
  'BBGC': 'Services Financiers', 'NSBC': 'Services Financiers', 'ORGT': 'Services Financiers',
  'ETIT': 'Services Financiers', 'SAFC': 'Services Financiers',
  'CIEC': 'Services Publics', 'SDCC': 'Services Publics',
  'TTLC': 'Distribution & Énergie', 'TTLS': 'Distribution & Énergie', 'SHEC': 'Distribution & Énergie',
  'PALC': 'Agriculture', 'SOGC': 'Agriculture', 'SPHC': 'Agriculture', 'SCRC': 'Agriculture', 'SICC': 'Agriculture',
  'CFAC': 'Consommation Discrétionnaire', 'PRSC': 'Consommation Discrétionnaire', 'BNBC': 'Consommation Discrétionnaire',
  'LNBB': 'Consommation Discrétionnaire', 'SIVC': 'Consommation Discrétionnaire',
  'SLBC': 'Consommation de Base', 'NTLC': 'Consommation de Base', 'ABJC': 'Consommation de Base',
  'UNLC': 'Consommation de Base', 'UNXC': 'Consommation de Base', 'STBC': 'Consommation de Base',
  'CABC': 'Industrie', 'FTSC': 'Industrie', 'SMBC': 'Industrie', 'SDSC': 'Industrie',
  'SEMC': 'Industrie', 'STAC': 'Industrie', 'NEIC': 'Industrie'
};

const lines = data.titres.map(t => {
  const sect = secteurs[t.code] || 'Divers';
  const v = t.cours_veille || t.cours_cloture;
  const c = t.cours_cloture;
  const hist = [
    Math.round(v * 0.98),
    Math.round(v * 0.99),
    v,
    t.cours_ouverture || v,
    c
  ];
  const high = Math.max(c, t.cours_ouverture || c, v);
  const low = Math.min(c, t.cours_ouverture || c, v);
  const safeName = t.nom.replace(/'/g, "\\'");

  return `  Stock(
    code: '${t.code}',
    name: '${safeName}',
    sector: '${sect}',
    currentPrice: ${c},
    previousClosePrice: ${v},
    openingPrice: ${t.cours_ouverture || v},
    dailyVariation: ${t.variation_pct},
    volume: ${t.volume},
    dayHigh: ${high},
    dayLow: ${low},
    historicalPrices: [${hist.join(', ')}],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),`;
});

fs.writeFileSync(path.join(__dirname, 'stocks_generated.dart'), lines.join('\n'), 'utf8');
console.log(`Successfully generated ${lines.length} stocks.`);

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/stock.dart';
import '../../data/repositories/market_repository.dart';

/// Filtres de statut pour le marché
enum StockFilter {
  all('Tous'),
  gainers('Hausses (+)'),
  losers('Baisses (-)');

  final String label;
  const StockFilter(this.label);
}

/// Options de tri pour la liste du marché
enum StockSort {
  variationDesc('Variation décroissante'),
  variationAsc('Variation croissante'),
  codeAsc('Code (A - Z)'),
  priceDesc('Cours le plus élevé');

  final String label;
  const StockSort(this.label);
}

/// Liste intégrale des 48 titres cotés à la BRVM (extraits de la séance en direct)
final List<Stock> kInitialBRVMStocks = [
  Stock(
    code: 'ABJC',
    name: 'SERVAIR ABIDJAN  COTE D\'IVOIRE',
    sector: 'Consommation de Base',
    currentPrice: 3250,
    previousClosePrice: 3200,
    openingPrice: 3200,
    dailyVariation: 1.56,
    volume: 1662,
    dayHigh: 3250,
    dayLow: 3200,
    historicalPrices: [3136, 3168, 3200, 3200, 3250],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'BBGC',
    name: 'BRIDGE BANK GROUP COTE D\'IVOIRE',
    sector: 'Services Financiers',
    currentPrice: 9800,
    previousClosePrice: 9800,
    openingPrice: 9990,
    dailyVariation: -1.95,
    volume: 3179,
    dayHigh: 9990,
    dayLow: 9800,
    historicalPrices: [9604, 9702, 9800, 9990, 9800],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'BICB',
    name: 'BANQUE INTERNATIONALE POUR L’INDUSTRIE ET LE COMMERCE DU BENIN',
    sector: 'Services Financiers',
    currentPrice: 8420,
    previousClosePrice: 8540,
    openingPrice: 8560,
    dailyVariation: -1.41,
    volume: 3803,
    dayHigh: 8560,
    dayLow: 8420,
    historicalPrices: [8369, 8455, 8540, 8560, 8420],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'BICC',
    name: 'BICI COTE D\'IVOIRE',
    sector: 'Services Financiers',
    currentPrice: 32000,
    previousClosePrice: 31500,
    openingPrice: 32000,
    dailyVariation: 0.05,
    volume: 244,
    dayHigh: 32000,
    dayLow: 31500,
    historicalPrices: [30870, 31185, 31500, 32000, 32000],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'BNBC',
    name: 'BERNABE COTE D\'IVOIRE',
    sector: 'Consommation Discrétionnaire',
    currentPrice: 1850,
    previousClosePrice: 1850,
    openingPrice: 1800,
    dailyVariation: 7.25,
    volume: 2793,
    dayHigh: 1850,
    dayLow: 1800,
    historicalPrices: [1813, 1832, 1850, 1800, 1850],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'BOAB',
    name: 'BANK OF AFRICA BENIN',
    sector: 'Services Financiers',
    currentPrice: 9300,
    previousClosePrice: 9300,
    openingPrice: 9280,
    dailyVariation: 0,
    volume: 1991,
    dayHigh: 9300,
    dayLow: 9280,
    historicalPrices: [9114, 9207, 9300, 9280, 9300],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'BOABF',
    name: 'BANK OF AFRICA BURKINA FASO',
    sector: 'Services Financiers',
    currentPrice: 7945,
    previousClosePrice: 7850,
    openingPrice: 8000,
    dailyVariation: -1.91,
    volume: 2083,
    dayHigh: 8000,
    dayLow: 7850,
    historicalPrices: [7693, 7772, 7850, 8000, 7945],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'BOAC',
    name: 'BANK OF AFRICA COTE D\'IVOIRE',
    sector: 'Services Financiers',
    currentPrice: 11940,
    previousClosePrice: 11940,
    openingPrice: 11290,
    dailyVariation: 5.76,
    volume: 6180,
    dayHigh: 11940,
    dayLow: 11290,
    historicalPrices: [11701, 11821, 11940, 11290, 11940],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'BOAM',
    name: 'BANK OF AFRICA MALI',
    sector: 'Services Financiers',
    currentPrice: 5695,
    previousClosePrice: 5700,
    openingPrice: 5700,
    dailyVariation: -0.09,
    volume: 2774,
    dayHigh: 5700,
    dayLow: 5695,
    historicalPrices: [5586, 5643, 5700, 5700, 5695],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'BOAN',
    name: 'BANK OF AFRICA NIGER',
    sector: 'Services Financiers',
    currentPrice: 5100,
    previousClosePrice: 5100,
    openingPrice: 5000,
    dailyVariation: 2,
    volume: 7405,
    dayHigh: 5100,
    dayLow: 5000,
    historicalPrices: [4998, 5049, 5100, 5000, 5100],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'BOAS',
    name: 'BANK OF AFRICA SENEGAL',
    sector: 'Services Financiers',
    currentPrice: 8210,
    previousClosePrice: 8195,
    openingPrice: 8170,
    dailyVariation: 0.18,
    volume: 3453,
    dayHigh: 8210,
    dayLow: 8170,
    historicalPrices: [8031, 8113, 8195, 8170, 8210],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'CABC',
    name: 'SICABLE COTE D\'IVOIRE',
    sector: 'Industrie',
    currentPrice: 2775,
    previousClosePrice: 2775,
    openingPrice: 2975,
    dailyVariation: -7.04,
    volume: 404,
    dayHigh: 2975,
    dayLow: 2775,
    historicalPrices: [2720, 2747, 2775, 2975, 2775],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'CBIBF',
    name: 'CORIS BANK INTERNATIONAL BURKINA FASO',
    sector: 'Services Financiers',
    currentPrice: 32100,
    previousClosePrice: 32000,
    openingPrice: 31500,
    dailyVariation: 2.54,
    volume: 3679,
    dayHigh: 32100,
    dayLow: 31500,
    historicalPrices: [31360, 31680, 32000, 31500, 32100],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'CFAC',
    name: 'CFAO MOTORS COTE D\'IVOIRE',
    sector: 'Consommation Discrétionnaire',
    currentPrice: 1400,
    previousClosePrice: 1400,
    openingPrice: 1410,
    dailyVariation: -1.06,
    volume: 992,
    dayHigh: 1410,
    dayLow: 1400,
    historicalPrices: [1372, 1386, 1400, 1410, 1400],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'CIEC',
    name: 'CIE COTE D\'IVOIRE',
    sector: 'Services Publics',
    currentPrice: 5100,
    previousClosePrice: 5100,
    openingPrice: 5560,
    dailyVariation: -2.86,
    volume: 4910,
    dayHigh: 5560,
    dayLow: 5100,
    historicalPrices: [4998, 5049, 5100, 5560, 5100],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'ECOC',
    name: 'ECOBANK COTE D\'IVOIRE',
    sector: 'Services Financiers',
    currentPrice: 16000,
    previousClosePrice: 15700,
    openingPrice: 15655,
    dailyVariation: -1.54,
    volume: 2271,
    dayHigh: 16000,
    dayLow: 15655,
    historicalPrices: [15386, 15543, 15700, 15655, 16000],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'ETIT',
    name: 'Ecobank Transnational Incorporated TOGO',
    sector: 'Services Financiers',
    currentPrice: 60,
    previousClosePrice: 60,
    openingPrice: 61,
    dailyVariation: -1.64,
    volume: 4959176,
    dayHigh: 61,
    dayLow: 60,
    historicalPrices: [59, 59, 60, 61, 60],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'FTSC',
    name: 'FILTISAC COTE D\'IVOIRE',
    sector: 'Industrie',
    currentPrice: 1800,
    previousClosePrice: 1795,
    openingPrice: 1715,
    dailyVariation: 4.35,
    volume: 1238,
    dayHigh: 1800,
    dayLow: 1715,
    historicalPrices: [1759, 1777, 1795, 1715, 1800],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'LNBB',
    name: 'LOTERIE NATIONALE DU BENIN',
    sector: 'Consommation Discrétionnaire',
    currentPrice: 3845,
    previousClosePrice: 3800,
    openingPrice: 3800,
    dailyVariation: -2.53,
    volume: 125,
    dayHigh: 3845,
    dayLow: 3800,
    historicalPrices: [3724, 3762, 3800, 3800, 3845],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'NEIC',
    name: 'NEI-CEDA COTE D\'IVOIRE',
    sector: 'Industrie',
    currentPrice: 2240,
    previousClosePrice: 2240,
    openingPrice: 2100,
    dailyVariation: 6.67,
    volume: 454,
    dayHigh: 2240,
    dayLow: 2100,
    historicalPrices: [2195, 2218, 2240, 2100, 2240],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'NSBC',
    name: 'NSIA BANQUE COTE D\'IVOIRE',
    sector: 'Services Financiers',
    currentPrice: 19100,
    previousClosePrice: 18895,
    openingPrice: 19000,
    dailyVariation: 0.53,
    volume: 1409,
    dayHigh: 19100,
    dayLow: 18895,
    historicalPrices: [18517, 18706, 18895, 19000, 19100],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'NTLC',
    name: 'NESTLE COTE D\'IVOIRE',
    sector: 'Consommation de Base',
    currentPrice: 13205,
    previousClosePrice: 13210,
    openingPrice: 13695,
    dailyVariation: -3.58,
    volume: 1159,
    dayHigh: 13695,
    dayLow: 13205,
    historicalPrices: [12946, 13078, 13210, 13695, 13205],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'ONTBF',
    name: 'ONATEL BURKINA FASO',
    sector: 'Télécommunications',
    currentPrice: 3000,
    previousClosePrice: 3050,
    openingPrice: 3045,
    dailyVariation: -1.64,
    volume: 4237,
    dayHigh: 3050,
    dayLow: 3000,
    historicalPrices: [2989, 3020, 3050, 3045, 3000],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'ORAC',
    name: 'ORANGE COTE D\'IVOIRE',
    sector: 'Télécommunications',
    currentPrice: 21500,
    previousClosePrice: 21500,
    openingPrice: 20500,
    dailyVariation: 2.38,
    volume: 1740,
    dayHigh: 21500,
    dayLow: 20500,
    historicalPrices: [21070, 21285, 21500, 20500, 21500],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'ORGT',
    name: 'ORAGROUP TOGO',
    sector: 'Services Financiers',
    currentPrice: 2700,
    previousClosePrice: 2660,
    openingPrice: 2660,
    dailyVariation: -0.55,
    volume: 1570,
    dayHigh: 2700,
    dayLow: 2660,
    historicalPrices: [2607, 2633, 2660, 2660, 2700],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'PALC',
    name: 'PALM COTE D\'IVOIRE',
    sector: 'Agriculture',
    currentPrice: 7500,
    previousClosePrice: 7500,
    openingPrice: 7500,
    dailyVariation: 0,
    volume: 2601,
    dayHigh: 7500,
    dayLow: 7500,
    historicalPrices: [7350, 7425, 7500, 7500, 7500],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'PRSC',
    name: 'TRACTAFRIC MOTORS COTE D\'IVOIRE',
    sector: 'Consommation Discrétionnaire',
    currentPrice: 3800,
    previousClosePrice: 3800,
    openingPrice: 3790,
    dailyVariation: 0.26,
    volume: 560,
    dayHigh: 3800,
    dayLow: 3790,
    historicalPrices: [3724, 3762, 3800, 3790, 3800],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SAFC',
    name: 'SAFCA COTE D\'IVOIRE',
    sector: 'Services Financiers',
    currentPrice: 3775,
    previousClosePrice: 3810,
    openingPrice: 3765,
    dailyVariation: -0.92,
    volume: 2052,
    dayHigh: 3810,
    dayLow: 3765,
    historicalPrices: [3734, 3772, 3810, 3765, 3775],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SCRC',
    name: 'SUCRIVOIRE COTE D\'IVOIRE',
    sector: 'Agriculture',
    currentPrice: 2295,
    previousClosePrice: 2295,
    openingPrice: 2225,
    dailyVariation: 3.38,
    volume: 3483,
    dayHigh: 2295,
    dayLow: 2225,
    historicalPrices: [2249, 2272, 2295, 2225, 2295],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SDCC',
    name: 'SODE COTE D\'IVOIRE',
    sector: 'Services Publics',
    currentPrice: 12675,
    previousClosePrice: 12690,
    openingPrice: 12690,
    dailyVariation: -0.12,
    volume: 286,
    dayHigh: 12690,
    dayLow: 12675,
    historicalPrices: [12436, 12563, 12690, 12690, 12675],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SDSC',
    name: 'AFRICA GLOBAL LOGISTICS COTE D\'IVOIRE',
    sector: 'Industrie',
    currentPrice: 2820,
    previousClosePrice: 2820,
    openingPrice: 2800,
    dailyVariation: 0.36,
    volume: 13074,
    dayHigh: 2820,
    dayLow: 2800,
    historicalPrices: [2764, 2792, 2820, 2800, 2820],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SEMC',
    name: 'EVIOSYS PACKAGING SIEM COTE D\'IVOIRE',
    sector: 'Industrie',
    currentPrice: 1495,
    previousClosePrice: 1495,
    openingPrice: 1495,
    dailyVariation: 0,
    volume: 0,
    dayHigh: 1495,
    dayLow: 1495,
    historicalPrices: [1465, 1480, 1495, 1495, 1495],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SGBC',
    name: 'SOCIETE GENERALE COTE D\'IVOIRE',
    sector: 'Services Financiers',
    currentPrice: 38950,
    previousClosePrice: 38950,
    openingPrice: 38950,
    dailyVariation: 0,
    volume: 2850,
    dayHigh: 38950,
    dayLow: 38950,
    historicalPrices: [38171, 38561, 38950, 38950, 38950],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SHEC',
    name: 'VIVO ENERGY COTE D\'IVOIRE',
    sector: 'Distribution & Énergie',
    currentPrice: 2120,
    previousClosePrice: 2130,
    openingPrice: 2140,
    dailyVariation: -0.47,
    volume: 1140,
    dayHigh: 2140,
    dayLow: 2120,
    historicalPrices: [2087, 2109, 2130, 2140, 2120],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SIBC',
    name: 'SOCIETE IVOIRIENNE DE BANQUE COTE D\'IVOIRE',
    sector: 'Services Financiers',
    currentPrice: 8850,
    previousClosePrice: 8800,
    openingPrice: 8890,
    dailyVariation: -0.45,
    volume: 3818,
    dayHigh: 8890,
    dayLow: 8800,
    historicalPrices: [8624, 8712, 8800, 8890, 8850],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SICC',
    name: 'SICOR COTE D\'IVOIRE',
    sector: 'Agriculture',
    currentPrice: 8400,
    previousClosePrice: 8400,
    openingPrice: 8400,
    dailyVariation: 0,
    volume: 0,
    dayHigh: 8400,
    dayLow: 8400,
    historicalPrices: [8232, 8316, 8400, 8400, 8400],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SIVC',
    name: 'ERIUM COTE D’IVOIRE',
    sector: 'Consommation Discrétionnaire',
    currentPrice: 1585,
    previousClosePrice: 1585,
    openingPrice: 1670,
    dailyVariation: -5.09,
    volume: 1919,
    dayHigh: 1670,
    dayLow: 1585,
    historicalPrices: [1553, 1569, 1585, 1670, 1585],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SLBC',
    name: 'SOLIBRA COTE D\'IVOIRE',
    sector: 'Consommation de Base',
    currentPrice: 38705,
    previousClosePrice: 38705,
    openingPrice: 38620,
    dailyVariation: 0,
    volume: 126,
    dayHigh: 38705,
    dayLow: 38620,
    historicalPrices: [37931, 38318, 38705, 38620, 38705],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SMBC',
    name: 'SMB COTE D\'IVOIRE',
    sector: 'Industrie',
    currentPrice: 14700,
    previousClosePrice: 14500,
    openingPrice: 14500,
    dailyVariation: 1.38,
    volume: 568,
    dayHigh: 14700,
    dayLow: 14500,
    historicalPrices: [14210, 14355, 14500, 14500, 14700],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SNTS',
    name: 'SONATEL SENEGAL',
    sector: 'Télécommunications',
    currentPrice: 4100,
    previousClosePrice: 4100,
    openingPrice: 4425,
    dailyVariation: -7.34,
    volume: 3111192,
    dayHigh: 4425,
    dayLow: 4100,
    historicalPrices: [4018, 4059, 4100, 4425, 4100],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SOGC',
    name: 'SOGB COTE D\'IVOIRE',
    sector: 'Agriculture',
    currentPrice: 7505,
    previousClosePrice: 7505,
    openingPrice: 7895,
    dailyVariation: -5,
    volume: 1180,
    dayHigh: 7895,
    dayLow: 7505,
    historicalPrices: [7355, 7430, 7505, 7895, 7505],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'SPHC',
    name: 'SAPH COTE D\'IVOIRE',
    sector: 'Agriculture',
    currentPrice: 8090,
    previousClosePrice: 8005,
    openingPrice: 8000,
    dailyVariation: 1.12,
    volume: 450,
    dayHigh: 8090,
    dayLow: 8000,
    historicalPrices: [7845, 7925, 8005, 8000, 8090],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'STAC',
    name: 'SETAO COTE D\'IVOIRE',
    sector: 'Industrie',
    currentPrice: 1790,
    previousClosePrice: 1795,
    openingPrice: 1795,
    dailyVariation: -0.28,
    volume: 458,
    dayHigh: 1795,
    dayLow: 1790,
    historicalPrices: [1759, 1777, 1795, 1795, 1790],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'STBC',
    name: 'SITAB COTE D\'IVOIRE',
    sector: 'Consommation de Base',
    currentPrice: 21250,
    previousClosePrice: 21200,
    openingPrice: 21200,
    dailyVariation: 0.24,
    volume: 1642,
    dayHigh: 21250,
    dayLow: 21200,
    historicalPrices: [20776, 20988, 21200, 21200, 21250],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'TTLC',
    name: 'TOTALENERGIES MARKETING COTE D\'IVOIRE',
    sector: 'Distribution & Énergie',
    currentPrice: 3000,
    previousClosePrice: 2995,
    openingPrice: 3000,
    dailyVariation: 0.17,
    volume: 5025,
    dayHigh: 3000,
    dayLow: 2995,
    historicalPrices: [2935, 2965, 2995, 3000, 3000],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'TTLS',
    name: 'TOTALENERGIES MARKETING SENEGAL',
    sector: 'Distribution & Énergie',
    currentPrice: 3630,
    previousClosePrice: 3650,
    openingPrice: 3650,
    dailyVariation: -0.55,
    volume: 2325,
    dayHigh: 3650,
    dayLow: 3630,
    historicalPrices: [3577, 3614, 3650, 3650, 3630],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'UNLC',
    name: 'UNILEVER COTE D\'IVOIRE',
    sector: 'Consommation de Base',
    currentPrice: 45200,
    previousClosePrice: 45200,
    openingPrice: 45200,
    dailyVariation: 0,
    volume: 3,
    dayHigh: 45200,
    dayLow: 45200,
    historicalPrices: [44296, 44748, 45200, 45200, 45200],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
  Stock(
    code: 'UNXC',
    name: 'UNIWAX COTE D\'IVOIRE',
    sector: 'Consommation de Base',
    currentPrice: 2000,
    previousClosePrice: 2015,
    openingPrice: 2060,
    dailyVariation: -2.91,
    volume: 22373,
    dayHigh: 2060,
    dayLow: 2000,
    historicalPrices: [1975, 1995, 2015, 2060, 2000],
    lastUpdated: DateTime(2026, 10, 28, 14, 2),
  ),
];

/// Notifier pour l'état de rafraîchissement
class IsMarketRefreshingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setRefreshing(bool val) => state = val;
}

final isMarketRefreshingProvider =
    NotifierProvider<IsMarketRefreshingNotifier, bool>(IsMarketRefreshingNotifier.new);

/// Notifier pour l'horodatage de la dernière mise à jour
class LastMarketUpdateTimeNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void updateTime(DateTime time) => state = time;
}

final lastMarketUpdateTimeProvider =
    NotifierProvider<LastMarketUpdateTimeNotifier, DateTime>(LastMarketUpdateTimeNotifier.new);

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository();
});

/// Notifier pour la liste des actions du marché BRVM
class MarketStocksNotifier extends Notifier<List<Stock>> {
  StreamSubscription<List<Stock>>? _streamSubscription;
  bool _mounted = false;

  @override
  List<Stock> build() {
    _mounted = false;

    // Connexion au flux temps réel Firestore en continu
    final repo = ref.watch(marketRepositoryProvider);
    _streamSubscription?.cancel();
    _streamSubscription = repo.watchMarketQuotes().listen((quotes) {
      if (quotes.isNotEmpty) {
        // Defer to avoid setting state during the synchronous build phase.
        // Stream.value() emits synchronously, which would trigger a re-entrant
        // invalidation of downstream providers (positionByStockCodeProvider)
        // during mount.
        if (!_mounted) {
          Future.microtask(() {
            state = quotes;
            ref.read(lastMarketUpdateTimeProvider.notifier).updateTime(DateTime.now());
          });
        } else {
          state = quotes;
          ref.read(lastMarketUpdateTimeProvider.notifier).updateTime(DateTime.now());
        }
      }
    });

    ref.onDispose(() {
      _streamSubscription?.cancel();
    });

    // Mark as mounted after build completes synchronously
    Future.microtask(() {
      _mounted = true;
      refreshLiveQuotes();
    });

    return kInitialBRVMStocks;
  }

  /// Met à jour manuellement un cours
  void updateStockPrice(String code, int newPrice) {
    state = [
      for (final stock in state)
        if (stock.code.toUpperCase() == code.toUpperCase())
          stock.copyWith(
            currentPrice: newPrice,
            dailyVariation: stock.previousClosePrice > 0
                ? ((newPrice - stock.previousClosePrice) / stock.previousClosePrice) * 100
                : 0.0,
            lastUpdated: DateTime.now(),
          )
        else
          stock,
    ];
    ref.read(lastMarketUpdateTimeProvider.notifier).updateTime(DateTime.now());
  }

  /// Rafraîchit les cours officiels depuis le site BRVM et synchronise Firestore
  Future<RefreshQuotesResult> refreshLiveQuotes() async {
    ref.read(isMarketRefreshingProvider.notifier).setRefreshing(true);
    try {
      final repo = ref.read(marketRepositoryProvider);
      final result = await repo.refreshQuotesFromSource(currentStocks: state);

      if (result.stocks.isNotEmpty) {
        state = result.stocks;
      }
      ref.read(lastMarketUpdateTimeProvider.notifier).updateTime(DateTime.now());
      return result;
    } catch (e) {
      debugPrint('[MarketNotifier] Erreur actualisation cotations : $e');
      return RefreshQuotesResult(
        stocks: state,
        source: RefreshSource.firestoreFallback,
        firestoreUpdated: false,
        errorMessage: e.toString(),
      );
    } finally {
      ref.read(isMarketRefreshingProvider.notifier).setRefreshing(false);
    }
  }
}

final marketStocksProvider =
    NotifierProvider<MarketStocksNotifier, List<Stock>>(MarketStocksNotifier.new);

/// Notifier pour la recherche de titres
class MarketSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final marketSearchQueryProvider =
    NotifierProvider<MarketSearchQueryNotifier, String>(MarketSearchQueryNotifier.new);

/// Notifier pour le filtre de marché
class MarketFilterNotifier extends Notifier<StockFilter> {
  @override
  StockFilter build() => StockFilter.all;

  void selectFilter(StockFilter filter) {
    state = filter;
  }
}

final marketFilterProvider =
    NotifierProvider<MarketFilterNotifier, StockFilter>(MarketFilterNotifier.new);

/// Notifier pour le tri
class MarketSortNotifier extends Notifier<StockSort> {
  @override
  StockSort build() => StockSort.variationDesc;

  void selectSort(StockSort sort) {
    state = sort;
  }
}

final marketSortProvider =
    NotifierProvider<MarketSortNotifier, StockSort>(MarketSortNotifier.new);

/// Provider calculé des actions filtrées et triées
final filteredMarketStocksProvider = Provider<List<Stock>>((ref) {
  final stocks = ref.watch(marketStocksProvider);
  final query = ref.watch(marketSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(marketFilterProvider);
  final sort = ref.watch(marketSortProvider);

  var list = stocks.where((stock) {
    // Filtre de recherche texte
    if (query.isNotEmpty) {
      final matchCode = stock.code.toLowerCase().contains(query);
      final matchName = stock.name.toLowerCase().contains(query);
      final matchSector = stock.sector.toLowerCase().contains(query);
      if (!matchCode && !matchName && !matchSector) return false;
    }

    // Filtre statut
    switch (filter) {
      case StockFilter.all:
        return true;
      case StockFilter.gainers:
        return stock.isGaining;
      case StockFilter.losers:
        return stock.isLosing;
    }
  }).toList();

  // Application du tri
  switch (sort) {
    case StockSort.variationDesc:
      list.sort((a, b) => b.dailyVariation.compareTo(a.dailyVariation));
      break;
    case StockSort.variationAsc:
      list.sort((a, b) => a.dailyVariation.compareTo(b.dailyVariation));
      break;
    case StockSort.codeAsc:
      list.sort((a, b) => a.code.compareTo(b.code));
      break;
    case StockSort.priceDesc:
      list.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
      break;
  }

  return list;
});

/// Provider pour récupérer une action par son code mnémonique
final stockByCodeProvider = Provider.family<Stock?, String>((ref, code) {
  final stocks = ref.watch(marketStocksProvider);
  try {
    return stocks.firstWhere(
      (s) => s.code.toUpperCase() == code.toUpperCase(),
    );
  } catch (_) {
    return null;
  }
});

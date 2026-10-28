/// Modèle représentant un titre coté sur le marché de la BRVM.
class Stock {
  final String code;
  final String name;
  final String sector;
  final int currentPrice;
  final int previousClosePrice;
  final int openingPrice;
  final double dailyVariation;
  final int volume;
  final int dayHigh;
  final int dayLow;
  final List<double> historicalPrices;
  final DateTime lastUpdated;

  const Stock({
    required this.code,
    required this.name,
    required this.sector,
    required this.currentPrice,
    required this.previousClosePrice,
    this.openingPrice = 0,
    required this.dailyVariation,
    this.volume = 0,
    this.dayHigh = 0,
    this.dayLow = 0,
    this.historicalPrices = const [],
    required this.lastUpdated,
  });

  /// Variation en FCFA par rapport au cours de clôture de la veille
  int get variationAmount => currentPrice - previousClosePrice;

  /// Indique si le titre est en hausse aujourd'hui
  bool get isGaining => dailyVariation > 0.0001;

  /// Indique si le titre est en baisse aujourd'hui
  bool get isLosing => dailyVariation < -0.0001;

  /// Indique si le titre est stable
  bool get isNeutral => !isGaining && !isLosing;

  Stock copyWith({
    String? code,
    String? name,
    String? sector,
    int? currentPrice,
    int? previousClosePrice,
    int? openingPrice,
    double? dailyVariation,
    int? volume,
    int? dayHigh,
    int? dayLow,
    List<double>? historicalPrices,
    DateTime? lastUpdated,
  }) {
    return Stock(
      code: code ?? this.code,
      name: name ?? this.name,
      sector: sector ?? this.sector,
      currentPrice: currentPrice ?? this.currentPrice,
      previousClosePrice: previousClosePrice ?? this.previousClosePrice,
      openingPrice: openingPrice ?? this.openingPrice,
      dailyVariation: dailyVariation ?? this.dailyVariation,
      volume: volume ?? this.volume,
      dayHigh: dayHigh ?? this.dayHigh,
      dayLow: dayLow ?? this.dayLow,
      historicalPrices: historicalPrices ?? this.historicalPrices,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

import 'dart:io';
import 'package:test/test.dart';
import 'package:brvm_portfolio/features/pdf_import/data/bici_bourse_statement_parser.dart';

void main() {
  group('BiciBourseStatementParser', () {
    test('extrait fidèlement toutes les positions du relevé BICI Bourse réel', () async {
      final pdfFile = File('../Portfeuille -902501001 (6).pdf');
      final file = pdfFile.existsSync()
          ? pdfFile
          : File('D:/DOSSIER PERSO/ALEX/brvm/Portfeuille -902501001 (6).pdf');
            if (!file.existsSync()) {
        // Ignorer le test d'intégration local si le fichier PDF physique n'est pas présent dans l'environnement de build
        return;
      }

      final bytes = file.readAsBytesSync();
      final result = await BiciBourseStatementParser.parse(bytes);

      expect(result.estValide, isTrue);
      expect(result.erreurBloquante, isNull);
      expect(result.numeroCompte, equals('902501001'));
      expect(result.nomClient, contains('KOUASSI ELISEE KOUAME'));
      expect(result.dateReleve, equals(DateTime(2026, 11, 1)));
      expect(result.soldeEspeces, equals(9347));
      expect(result.lignes.length, equals(7));

      // 1. SCRC
      final scrc = result.lignes[0];
      expect(scrc.codeTitre, equals('SCRC'));
      expect(scrc.isin, equals('CI0000002028'));
      expect(scrc.libelle, equals('SUCRIVOIRE'));
      expect(scrc.quantite, equals(3));
      expect(scrc.prixRevient, equals(3437));
      expect(scrc.cours, equals(2270));

      // 2. SAFC
      final safc = result.lignes[1];
      expect(safc.codeTitre, equals('SAFC'));
      expect(safc.isin, equals('CI0000000022'));
      expect(safc.libelle, equals('SAFCA'));
      expect(safc.quantite, equals(40));
      expect(safc.prixRevient, equals(5354));
      expect(safc.cours, equals(3760));

      // 3. BOAC
      final boac = result.lignes[2];
      expect(boac.codeTitre, equals('BOAC'));
      expect(boac.isin, equals('CI0000000956'));
      expect(boac.libelle, equals('BOA CI'));
      expect(boac.quantite, equals(19));
      expect(boac.prixRevient, equals(12269));
      expect(boac.cours, equals(11700));

      // 4. ETIT (quantité 3 000 formatée "3,000")
      final etit = result.lignes[3];
      expect(etit.codeTitre, equals('ETIT'));
      expect(etit.isin, equals('TG0000000132'));
      expect(etit.libelle, equals('ETI'));
      expect(etit.quantite, equals(3000));
      expect(etit.prixRevient, equals(63));
      expect(etit.cours, equals(63));

      // 5. CIEC
      final ciec = result.lignes[4];
      expect(ciec.codeTitre, equals('CIEC'));
      expect(ciec.isin, equals('CI0000000212'));
      expect(ciec.libelle, equals('CIE CI'));
      expect(ciec.quantite, equals(45));
      expect(ciec.prixRevient, equals(5290));
      expect(ciec.cours, equals(5500));

      // 6. SHEC
      final shec = result.lignes[5];
      expect(shec.codeTitre, equals('SHEC'));
      expect(shec.isin, equals('CI0000000246'));
      expect(shec.libelle, equals('VIVO ENERGY CI'));
      expect(shec.quantite, equals(100));
      expect(shec.prixRevient, equals(1997));
      expect(shec.cours, equals(2115));

      // 7. SIBC
      final sibc = result.lignes[6];
      expect(sibc.codeTitre, equals('SIBC'));
      expect(sibc.isin, equals('CI0000001871'));
      expect(sibc.libelle, equals('SIB'));
      expect(sibc.quantite, equals(50));
      expect(sibc.prixRevient, equals(9228));
      expect(sibc.cours, equals(8805));

      // Conversion en opérations
      final ops = result.lignes.map((l) => l.toOperation(dateReleve: result.dateReleve!)).toList();
      expect(ops.length, equals(7));
      expect(ops.first.stockCode, equals('SCRC'));
      expect(ops.first.quantity, equals(3));
      expect(ops.first.unitPrice, equals(3437));
      expect(ops.first.fees, equals(0));
    });
  });
}

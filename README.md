# BRVM-App — Suivi de Portefeuille & Cotations en Direct 📈

Application moderne de gestion de portefeuille boursier et de suivi des cotations en direct pour la **BRVM (Bourse Régionale des Valeurs Mobilières)** de l'UEMOA.

Développée en **Flutter / Dart** (Web, Android, iOS, Desktop) avec backend serverless **Firebase (Auth & Firestore)** et automatisation sans surcoût via **GitHub Actions**.

---

## ✨ Fonctionnalités Principales

### 📊 Gestion de Portefeuille & Trésorerie
- **Calcul rigoureux du PRU (Prix de Revient Unitaire)** incluant les frais de courtage et taxes selon les normes de la BRVM.
- **Suivi des gains et valorisation en temps réel** : gains du jour, plus-values latentes et réalisées.
- **Gestion complète de la trésorerie** : suivi du solde espèces disponible (dépôts, retraits, achats, ventes).
- **Rapprochement SGI en 1 clic** : comparaison entre le solde calculé par l'application et votre relevé SGI officiel, avec génération automatique d'ajustements comptables.

### 🌐 Cotations en Direct & Historique Réel
- **Collecte autonome dans l'application** : l'app interroge directement le site officiel de la BRVM (`brvm.org`) à chaque ouverture ou actualisation.
- **Repli automatique sur Firestore** : bascule transparente sur la base de données en cas de coupure ou d'indisponibilité du site source.
- **Historique réel sans écrasement** : chaque séance de bourse est archivée cumulativement (conservation de 60 séances), garantissant des graphiques de cours (`fl_chart`) fidèles et vérifiables.
- **Fiches Valeurs détaillées** : visualisation des 48 titres cotés, recherche instantanée, filtres (Hausses, Baisses, Secteurs) et variations de séance.

### 📄 Outils Boursiers Avancés
- **Import automatique de PDF SGI** : reconnaissance intelligente des ordres d'achat/vente et avis d'opérés (BICI Bourse, etc.) via analyse de texte vectorielle.
- **Calculateur de Frais SGI & Marché** : simulation préalable des frais d'intermédiation, commissions BRVM/DC/BR et taxes (TOB/TVA).
- **Contrôleur de validité d'ordre** : vérification des seuils de réservation BRVM (-7,5 % à +7,5 %), pas de cotation et couverture du solde disponible.

### 🔒 Sécurité & Isolation Multi-Utilisateurs
- **Authentification Firebase** : inscription et connexion sécurisées par email / mot de passe.
- **Cloisonnement strict des données** : chaque utilisateur dispose d'un espace hermétique sous `users/{uid}/...` garanti par des règles Firestore rigoureuses.
- **Zéro donnée sensible dans le dépôt** : secrets et clés de service gérés exclusivement par variables chiffrées (GitHub Secrets).

---

## 🏛️ Architecture du Projet

```
.
├── .github/workflows/
│   ├── brvm_collector.yml     # Collecte automatique et synchronisation Firestore (cron GitHub Actions)
│   ├── deploy_web.yml         # Build et déploiement continu sur GitHub Pages
│   └── keepalive.yml          # Maintien des tâches planifiées GitHub toujours actives
├── brvm_portfolio/            # Application Flutter multiplateforme
│   ├── lib/
│   │   ├── core/              # Modèles, constantes, extensions et thème
│   │   ├── data/              # Dépôts de données et service de scraping direct (BrvmScraperService)
│   │   ├── domain/            # Moteurs de calculs purs (PRU, Portefeuille, Rapprochement, Frais)
│   │   └── features/          # Écrans et composants Riverpod (Auth, Portefeuille, Marché, Historique, PDF)
│   └── test/                  # Suite de tests unitaires et d'intégration
├── functions/                 # Moteur Node.js de secours et de synchronisation
│   ├── scraper_brvm.js        # Parser Cheerio du tableau de cotations BRVM
│   ├── sync_firestore.js      # Synchronisation et historisation continue vers Firestore
│   └── brvm_cours.json        # Snapshot JSON horodaté des 48 cotations
├── firebase.json              # Configuration Firebase
└── firestore.rules            # Règles de sécurité Firestore
```

---

## ⚡ Synchronisation des Cotations

L'application bénéficie d'une **double redondance** :

1. **Au niveau de l'App (Client)** : l'application effectue elle-même un scraping direct temps réel dès l'ouverture, avec mise en cache et actualisation de Firestore.
2. **Au niveau du Cloud (GitHub Actions)** : un workflow planifié s'exécute du lundi au vendredi toutes les 15 minutes pendant la séance BRVM (09h00 à 15h30 GMT) pour maintenir la base commune à jour à coût nul.

### Configuration du Secret GitHub pour Firestore

Pour permettre au workflow GitHub Actions d'écrire dans votre base Firestore :

1. Sur la [Console Firebase](https://console.firebase.google.com/) > **Paramètres du projet** > **Comptes de service**.
2. Cliquez sur **Générer une nouvelle clé privée** (télécharge un fichier JSON).
3. Sur votre dépôt GitHub, allez dans **Settings** > **Secrets and variables** > **Actions**.
4. Ajoutez le secret suivant :
   - **Nom** : `FIREBASE_SERVICE_ACCOUNT`
   - **Valeur** : Le contenu complet du fichier JSON téléchargé.

> [!NOTE]
> Même sans ce secret, le workflow GitHub continue de fonctionner en mettant à jour et en versionnant le fichier `functions/brvm_cours.json` dans le dépôt Git.

---

## 🧪 Tests & Qualité de Code

Le projet comporte une suite de tests unitaires couvrant les calculs financiers, le parsing de documents et la collecte :

```bash
cd brvm_portfolio
flutter test
```

---

## 🚀 Démarrage Rapide

### Prérequis
- [Flutter SDK](https://flutter.dev/) (version 3.41+ / Dart 3.11+)
- [Node.js](https://nodejs.org/) (version 20+)

### Lancer l'application Flutter en local
```bash
cd brvm_portfolio
flutter pub get
flutter run -d chrome # ou windows / edge / android
```

### Exécuter le scraper manuellement
```bash
cd functions
npm install
node sync_firestore.js
```

---

## 🛡️ Confidentialité & Bonnes Pratiques

- **Aucune clé privée ni mot de passe** n'est présent dans le code source.
- Les identifiants clients Firebase (`google-services.json` et `firebase_options.dart`) sont limités aux permissions accordées par les règles de sécurité Firestore.
- Les fichiers de tests et fixtures sont rigoureusement anonymisés.

# BRVM-App — Suivi de Portefeuille & Automatisations 📈

Application de gestion de portefeuille boursier et cotations en direct pour la **BRVM (Bourse Régionale des Valeurs Mobilières)** de l'UEMOA.

---

## 🏛️ Architecture du Projet

```
.
├── .github/workflows/
│   └── brvm_collector.yml     # Workflow GitHub Actions automatisé (zéro coût Firebase)
├── brvm_portfolio/            # Application Flutter multiplateforme (Web, Android, iOS)
│   ├── lib/                   # Code source Flutter (Architecture Clean / Riverpod)
│   └── pubspec.yaml
├── functions/                 # Scripts Node.js de scraping et de synchronisation
│   ├── scraper_brvm.js        # Moteur d'extraction des 48 titres du site officiel BRVM
│   ├── sync_firestore.js      # Synchronisation vers Cloud Firestore
│   ├── brvm_cours.json        # Snapshot JSON horodaté des cotations
│   └── package.json
├── firebase.json              # Configuration Firebase Hosting et Firestore
└── firestore.rules            # Règles de sécurité Firestore
```

---

## ⚡ Automatisation & Économie de Coûts (GitHub Actions)

Pour **éliminer les frais** liés aux instances Cloud Functions Gen 2 et à Cloud Scheduler (plan Firebase Blaze payant), la collecte périodique des cotations BRVM est entièrement déléguée à **GitHub Actions** (gratuit jusqu'à 2 000 minutes/mois).

### 🕒 Fréquence d'exécution
- **Automatique** : Du lundi au vendredi, toutes les **15 minutes** de **09h00 à 15h00 GMT** (créneau de séance officielle BRVM).
- **Manuelle** : Déclenchable à tout moment avec le bouton **"Run workflow"** dans l'onglet **Actions** de GitHub.

### 🔑 Configuration du Secret GitHub pour Firestore

Pour autoriser GitHub Actions à écrire dans votre base Firestore :

1. Rendez-vous sur votre console [Firebase Console](https://console.firebase.google.com/) > **Paramètres du projet** > **Comptes de service**.
2. Cliquez sur **Générer une nouvelle clé privée** (télécharge un fichier JSON).
3. Sur votre dépôt GitHub, allez dans **Settings** > **Secrets and variables** > **Actions**.
4. Cliquez sur **New repository secret** :
   - **Name** : `FIREBASE_SERVICE_ACCOUNT`
   - **Value** : Collez l'intégralité du contenu du fichier JSON téléchargé.
5. Validez avec **Add secret**.

> Si le secret n'est pas encore configuré, le workflow s'exécute quand même sans planter en mettant à jour et historisant automatiquement le fichier `brvm_cours.json` dans le dépôt Git !

---

## 🚀 Utilisation locale

### 1. Scraping manuel des cours BRVM
```bash
cd functions
npm install
node scraper_brvm.js
```

### 2. Synchronisation manuelle vers Firestore
```bash
cd functions
node sync_firestore.js
```

### 3. Lancer l'application Flutter
```bash
cd brvm_portfolio
flutter pub get
flutter run -d chrome
```

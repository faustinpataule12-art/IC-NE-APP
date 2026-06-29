# 🎨 ICÔNE-APP by NPS.NELSON

> Personnalise l'icône et le splash screen de n'importe quel APK Android.

![Build APK](https://github.com/faustinpataule12-art/IC-NE-APP/actions/workflows/build.yml/badge.svg)

---

## ✨ Fonctionnalités

- 📦 **Sélectionner un APK** depuis le stockage
- 🖼️ **Remplacer l'icône** dans toutes les résolutions (mdpi → xxxhdpi)
- 🌅 **Personnaliser le splash screen** — image, logo, couleur de fond
- ⚙️ **Recompile + signe automatiquement** l'APK modifié
- 📲 **Installer ou partager** directement depuis l'app

---

## 📲 Télécharger l'APK

Va dans l'onglet **[Releases](../../releases)** et télécharge le dernier `app-release.apk`.

Ou dans **[Actions](../../actions)** → dernier build → télécharge l'artifact.

---

## 🛠️ Compilation manuelle

```bash
# Prérequis : Flutter 3.19+, Java 17
flutter pub get
flutter build apk --release
```

L'APK se trouve dans : `build/app/outputs/flutter-apk/app-release.apk`

---

## 📁 Structure du projet

```
lib/
├── main.dart              # Point d'entrée
├── theme/
│   └── app_theme.dart     # Thème sombre NPS
├── screens/
│   ├── home_screen.dart   # Écran d'accueil
│   ├── editor_screen.dart # Éditeur APK
│   └── result_screen.dart # Résultat
└── services/
    └── apk_service.dart   # Logique de traitement APK
```

---

## 👤 Auteur

**NPS.NELSON**  
📧 nelsonpataule11@gmail.com  
💬 WhatsApp : +243 981 083 202

---

*Propulsé par Flutter • Build automatique via GitHub Actions*
 

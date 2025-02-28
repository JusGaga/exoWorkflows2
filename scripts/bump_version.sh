#!/bin/bash

set -e  # Arrête le script en cas d'erreur

# Vérification du token GitHub
if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ Erreur : GITHUB_TOKEN non défini."
  exit 1
fi

# Vérifier si .version existe, sinon l'initialiser
if [ ! -f .version ]; then
  echo "0.0.0" > .version
fi

# Lire la dernière version
VERSION=$(cat .version)
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# Vérifier si CHANGELOG.md existe, sinon le créer
if [ ! -f CHANGELOG.md ]; then
  echo "# Changelog" > CHANGELOG.md
  echo "" >> CHANGELOG.md
fi

# Déterminer le type de release (basé sur Conventional Commits)
LAST_COMMIT_MSG=$(git log --format=%B -n 1)

if echo "$LAST_COMMIT_MSG" | grep -q "BREAKING CHANGE"; then
  ((MAJOR++))
  MINOR=0
  PATCH=0
  RELEASE_TYPE="major"
elif echo "$LAST_COMMIT_MSG" | grep -Eiq "^feat"; then
  ((MINOR++))
  PATCH=0
  RELEASE_TYPE="minor"
elif echo "$LAST_COMMIT_MSG" | grep -Eiq "^fix"; then
  ((PATCH++))
  RELEASE_TYPE="patch"
else
  echo "ℹ️ Aucun commit significatif détecté. Pas de mise à jour de version."
  exit 0
fi

# Nouvelle version
NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "$NEW_VERSION" > .version
echo "✅ Nouvelle version détectée : $NEW_VERSION ($RELEASE_TYPE)"

# Ajouter la nouvelle version au changelog
echo "## Version $NEW_VERSION - $(date +'%Y-%m-%d')" >> CHANGELOG.md
git log --pretty=format:"- %s (%an)" --no-merges -n 10 >> CHANGELOG.md
echo "" >> CHANGELOG.md

# ✅ Forcer un changement pour éviter "nothing to commit"
echo "" >> CHANGELOG.md

# === DEBUG ===
echo "=== DEBUG : Affichage des fichiers modifiés ==="
git status
git diff .version CHANGELOG.md
echo "==============================================="

# Vérifier s'il y a des changements avant de committer
if git diff --quiet && git diff --staged --quiet; then
  echo "ℹ️ Aucun changement détecté, pas de commit nécessaire."
  exit 0
else
  git add .version CHANGELOG.md
  git commit -m "chore(release): bump version to $NEW_VERSION"
fi

# Vérifier si le tag existe déjà et le supprimer si nécessaire
if git rev-parse "v$NEW_VERSION" >/dev/null 2>&1; then
  echo "⚠️ Tag v$NEW_VERSION existe déjà, suppression en cours..."
  git tag -d "v$NEW_VERSION"  # Supprime le tag en local
  git push --delete origin "v$NEW_VERSION" || true  # Supprime le tag sur GitHub
fi

# Création du nouveau tag et push
git tag -a "v$NEW_VERSION" -m "Version $NEW_VERSION"
git push origin "v$NEW_VERSION"

echo "🚀 Tag v$NEW_VERSION créé et poussé avec succès !"

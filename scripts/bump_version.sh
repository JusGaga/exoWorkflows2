#!/bin/bash

# Vérification si le token est bien défini
if [ -z "$GITHUB_TOKEN" ]; then
  echo "Erreur : GITHUB_TOKEN non défini."
  exit 1
fi

# Récupérer la dernière version
if [ ! -f .version ]; then
  echo "0.0.0" > .version
fi
VERSION=$(cat .version)

# Extraire les parties de la version
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# Déterminer le type de release (basé sur Conventional Commits)
if git log --format=%B -n 1 | grep -q "BREAKING CHANGE"; then
  ((MAJOR++))
  MINOR=0
  PATCH=0
elif git log --format=%B -n 1 | grep -Eiq "^feat"; then
  ((MINOR++))
  PATCH=0
elif git log --format=%B -n 1 | grep -Eiq "^fix"; then
  ((PATCH++))
else
  echo "Aucun commit significatif détecté. Sortie."
  exit 0
fi

# Nouvelle version
NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "$NEW_VERSION" > .version
echo "Nouvelle version: $NEW_VERSION"

# Mettre à jour CHANGELOG.md
echo "## Version $NEW_VERSION - $(date +'%Y-%m-%d')" >> CHANGELOG.md
git log --pretty=format:"- %s (%an)" --no-merges -n 10 >> CHANGELOG.md
echo "" >> CHANGELOG.md

# Commit des changements
git add .version CHANGELOG.md
git commit -m "chore(release): bump version to $NEW_VERSION"

# Création du tag et push
NEW_VERSION=$(cat .version)
git tag -a "v$NEW_VERSION" -m "Version $NEW_VERSION"
git push origin "v$NEW_VERSION"


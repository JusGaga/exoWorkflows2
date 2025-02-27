# Utilise une image de base légère avec Node.js
FROM node:18-alpine

# Définir le dossier de travail dans le conteneur
WORKDIR /app

# Copier uniquement le package.json (optimisation du cache Docker)
COPY package.json ./

# Installer les dépendances nécessaires (ici uniquement Webpack)
RUN npm install

# Copier le reste des fichiers du projet
COPY . .

# Construire le projet (si nécessaire)
RUN npm run build

# Exposer le port (même si ici on n'a pas de serveur)
EXPOSE 3000

# Commande de démarrage (simple console.log)
CMD ["node", "src/index.js"]

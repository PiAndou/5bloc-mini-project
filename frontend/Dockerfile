# build stage
FROM node:lts-alpine as build-stage
# installe un simple serveur http pour servir un contenu statique
# RUN npm install -g http-server
# définit le dossier 'app' comme dossier de travail
WORKDIR /app
# copie 'package.json' et 'package-lock.json' (si disponible)
COPY package.json ./
# installe les dépendances du projet
RUN npm install
# copie les fichiers et dossiers du projet dans le dossier de travail (par exemple : le dossier 'app')
COPY . .
# Effacer le cache
RUN npm cache clean --force
# construit l'app pour la production en la minifiant
RUN npm run build


# production stage
FROM nginx:stable-alpine as production-stage
COPY --from=build-stage /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
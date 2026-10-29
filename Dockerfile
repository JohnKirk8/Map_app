# Stage 1: Build Flutter Web app
FROM instrumentisto/flutter:latest AS build

WORKDIR /app

# Copy dependency configs and fetch packages
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy full source and build for web
COPY . .
RUN flutter build web

# Stage 2: Lightweight Nginx server to serve the build
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY flutter_login/pubspec.* ./
RUN flutter pub get

COPY flutter_login/ ./

ARG MAP_API_BASE_URL
RUN flutter build web --release --dart-define=MAP_API_BASE_URL=${MAP_API_BASE_URL}

FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

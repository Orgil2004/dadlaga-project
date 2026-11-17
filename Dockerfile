
FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    bash \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fSL \
    https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.6-stable.tar.xz \
    -o /tmp/flutter.tar.xz \
    && mkdir -p /opt \
    && tar -xf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz

ENV PATH="/opt/flutter/bin:${PATH}"

RUN git config --global --add safe.directory /opt/flutter
RUN flutter --version

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

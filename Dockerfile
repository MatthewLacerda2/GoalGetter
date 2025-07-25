# Use the official Flutter image as base
FROM dart:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY frontend/pubspec.* ./

# Get dependencies
RUN dart pub get

# Copy the rest of the application
COPY frontend/ .

# Build the Flutter web app
RUN dart pub get
RUN dart run build_runner build --delete-conflicting-outputs
RUN dart compile web build/web -o build/web/main.dart.js

# Use nginx to serve the built web app
FROM nginx:alpine

# Copy the built web app to nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
# Use the official Dart SDK image
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec files first
COPY pubspec.* ./

RUN dart pub get --no-precompile

# Copy the rest of the project
COPY . .

# Expose port for the server
EXPOSE 8080

# Run your server
CMD ["dart", "run", "bin/server.dart"]


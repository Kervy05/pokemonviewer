# Pokémon API Viewer

A beginner-friendly Flutter practical activity for **IT 126 – Module 3, Lesson 4: Communicating with Services**.

This project extends the previous Pokémon Viewer activity. The old version used a JSON map copied into the source code for Octillery (#224). This updated version retrieves Pokémon information from the real PokéAPI.

## Features

- Search for a Pokémon by name (example: `pikachu`, `charizard`, or `octillery`).
- Sends an HTTP GET request to `https://pokeapi.co/api/v2/pokemon/{name}`.
- Decodes the JSON response using `dart:convert`.
- Displays the Pokémon's name, ID, height, weight, abilities, types, and sprite.
- Shows a loading indicator while waiting for the API.
- Displays an error message if the Pokémon does not exist or the request cannot be completed.
- Disables the search button while a request is running.

## Requirements

- Flutter SDK
- Dart SDK (included with Flutter)
- Internet connection
- VS Code or another Flutter-compatible editor

## How to run

1. Open this project folder in VS Code or a terminal.
2. Run:

   ```bash
   flutter pub get
   ```

3. Start the app on an available device, emulator, or supported browser:

   ```bash
   flutter run
   ```

4. Enter a Pokémon name in the search field and press **Search Pokémon**.

The app starts by loading Octillery, the Pokémon used in the previous activity.

## How the application communicates with the API

The application uses the `http` package to send a GET request. The entered Pokémon name is added to the PokéAPI endpoint. When the server returns HTTP status code `200`, the response body is decoded with `jsonDecode()` and converted into a `Pokemon` object.

The app checks the HTTP status code before processing the response. A `404` response means that the Pokémon could not be found. Other unsuccessful status codes are also handled with an error message.

## Error handling

- **Pokémon not found (404):** The app tells the user to check the Pokémon name.
- **Other unsuccessful HTTP responses:** The app displays the server status code in an error message.
- **No internet connection:** The app displays a message asking the user to check the connection.
- **Request timeout:** The app asks the user to try again.
- **Invalid or unexpected JSON:** The app displays a message that the information could not be processed.
- **Repeated requests:** The search button is disabled while a request is in progress.

## Proposed offline strategy

This activity does not implement local database storage, as instructed in the lesson. In a future version, the app could save Pokémon information that the user has already viewed in a local database or cache. If the device becomes offline, the app could show the previously saved information and clearly tell the user that it may not be updated. When internet access becomes available again, the user could refresh the information from the API.

## Main project file

The main application code is in `lib/main.dart`.

## API source

PokéAPI: https://pokeapi.co/

Endpoint pattern:

`https://pokeapi.co/api/v2/pokemon/{name}`

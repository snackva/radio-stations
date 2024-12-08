# Radio Stations Demo App

This is a demo Flutter app that fetches radio stations from the [Radio Browser API](https://www.radio-browser.info/) and allows users to listen to them and save favorites. The app is designed for both iOS and Android platforms.

## YouTube demo

A [demo video](https://youtube.com/shorts/JR9I0tVB_o4) has been provided showing the main functionalities of the app.

## Features

- Fetch and display radio stations from around the world.
- Stream live radio stations.
- Save favorite stations for easy access.

## Requirements

- **Flutter Version**: 3.22.3
- **Platforms**: iOS and Android

## Setup

1. **Clone the Repository**:
   ```bash
   git clone <repository_url>
   cd <repository_folder>
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   - For Android & iOS:
     ```bash
     flutter run
     ```

## Testing the App

Explore the following features:

1. Browse countries from the home page, with paginated lists.
2. Select a country and browse the available radio stations, also paginated.
3. Play a radio station to test streaming functionality.
4. Add stations to favorites and verify persistence.
5. Access favorite stations from the home page.

## API Used

This app uses the [Radio Browser API](https://www.radio-browser.info/), a free service that provides access to radio station data worldwide.
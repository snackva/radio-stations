# Radio Stations Demo App

This is a demo Flutter app that fetches radio stations from the [Radio Browser API](https://www.radio-browser.info/) and allows users to listen to them and save favorites. The app is designed for both iOS and Android platforms.

## V2

The latest repository changes contain the following upgrades:
- A search button that animates a search bar on the stations screen, where the user can filter stations by text. When the search bar is closed, the stations list is refreshed only if the text input has changed from the previous one.

- The routes can now be closed with a drag gesture from any part of the screen that doesn't trigger a scroll (like lists). While dragging the route out, the screen translates and zooms out according to the user's finger position. When the finger is released, the route is closed or kept in place depending on the speed and distance of the drag gesture.

- The countries and stations lists contain subtle animations. When scrolling, the bottom tiles are zoomed out, an animation that suits well devices with rounded screen corners. Also, the countries' station count number and the stations' favorites button shift up and down depending on the position on screen while scrolling, creating a subtle depth-like effect.

- Improvements to the lists pagination have been made.

A [second demo video](https://drive.google.com/file/d/1LvDP3EIvzsRsp6qdlyn_YGXVp1viyrer/view?usp=drive_link) has been provided showing the new functionalities described above.

## Video demo

A [demo video](https://drive.google.com/file/d/1F57mZVjWA1WfnavkNf-DHCm0d-mdy8Uc/view?usp=sharing) has been provided showing the main functionalities of the app.

## Design

The app aesthetics have been inspired by [this Dribbble design](https://dribbble.com/shots/24479926-UI-Exploration-Online-Radio), giving it a minimalistic look with a red accent color.

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

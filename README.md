![CycleHop](Resources/ParisSplashLight.png)

# CycleHop

**Find bikes, wherever you go.**

CycleHop connects to bike-share systems worldwide to get you moving. Find bikes and docks wherever you are, whether you're commuting, exploring, or running errands. Search for a destination and get smart recommendations for nearby docking stations based on distance, bike availability, and direction of travel. Built for the Apple Swift Student Challenge with full offline support.

## Features

**Bikes across your city**  
See stations and availability on a map. Tap any dock to check bikes and free slots in real time, so you always know where to go.

**Collect city stamps**  
Use bike share in a city and collect a stamp. Build your collection as you explore; each city you ride in leaves its mark.

**Open protocol**  
CycleHop is built on open standards. Anyone can contribute a new city or provider. See the [CycleHop Open Standard](STANDARD.md) and provider implementations on GitHub.

- **Multi-city**: London (Santander Cycles), New York (Citi Bike), Paris (Vélib')
- **Map**: Offline OpenStreetMap tiles or Apple Maps, with live station markers
- **Search**: MapKit-powered search for any address or point of interest
- **Layout**: Bottom sheet on iPhone, sidebar on iPad

## Requirements

- iOS 18.1+
- Swift Playgrounds or Xcode

## Getting Started

Open `My App.swiftpm` in Swift Playgrounds or Xcode and run on a simulator or device. The app works fully offline; station data is bundled for the challenge.

## Project Structure

- **Standard/**: Shared types and `BikeShareProvider` protocol (see [STANDARD.md](STANDARD.md))
- **Providers/**: Santander Cycles, Citi Bike, Vélib' (and ExampleProvider template)
- **Views/**: Map, bottom sheet, onboarding, settings, profile, stamps
- **Services/**: BikePointService, StampStore, SearchCompleter, LocationManager
- **Resources/**: Localisations, map tiles, splash art, stamp assets

## Acknowledgements

**OpenStreetMap**  
*Open Data Commons Open Database License (ODbL)*  
Map tiles bundled for offline use are rendered from OpenStreetMap data. OSM is a collaborative project providing freely usable geographic data.  
[openstreetmap.org/copyright](https://www.openstreetmap.org/copyright)

**SVGLoader**  
*Public domain / community snippet*  
A lightweight WKWebView-based SVG-to-UIImage renderer adapted from open-source Swift community code. Used to render crisp SVG illustrations at any display scale.

# RockExplorer - AI Coding Agent Instructions

## Project Overview
RockExplorer is a SwiftUI iOS app that combines education and AR technology for rock exploration. Users can discover virtual rocks on a radar map, collect them via AR scanning, and build their rock collection (Rockdex).

## Architecture Pattern: MVVM + Environment Objects
The app follows a strict MVVM pattern with centralized state management:

- **App Layer**: `RockExplorerApp.swift` creates and injects three main environment objects
- **ViewModels**: `@MainActor` classes conforming to `ObservableObject` (all UI updates on main thread)
- **Services**: Location and data services injected via environment objects
- **Views**: SwiftUI views consuming environment objects via `@EnvironmentObject`

### Critical Dependency Injection Pattern
```swift
// In RockExplorerApp.swift - ALL environment objects must be created at app level
init() {
    let collection = RockCollectionViewModel()
    _collectionViewModel = StateObject(wrappedValue: collection)
    _radarViewModel = StateObject(wrappedValue: RadarViewModel(collection: collection))
}
```

**Rule**: ViewModels that depend on each other must be explicitly injected during app initialization, not created independently in views.

## Core Components

### 1. Rock Data System
- **Model**: `Rock` struct with bilingual fields (Thai/English), location coordinates, and asset references
- **Data Source**: `RockDataStore` with hardcoded fallback data (no external JSON currently)
- **Asset Convention**: Each rock has `assetName` property that maps to:
  - Image: `"Images/Rocks/{assetName}.png"`
  - 3D Model: `"Images/Rocks/{assetName}.usdz"`

### 2. Collection System
- **Persistence**: Uses `UserDefaults` with key `"collected_rock_ids"` to store `Set<Int>`
- **State**: `RockCollectionViewModel` tracks collected vs uncollected rocks
- **Pattern**: All collection state changes go through the ViewModel, never direct UserDefaults access

### 3. Location & Radar System
- **Service**: `LocationService` handles `CLLocationManager` with proper delegate pattern
- **Radar Logic**: `RadarViewModel.prepareRocks()` generates 5 virtual rocks around user location
- **Discovery**: 10-meter proximity triggers rock discovery and collection opportunity

### 4. AR Integration
- **Framework**: Uses `ARKit` + `RealityKit` for 3D rock scanning experience
- **Asset Loading**: Loads `.usdz` files from bundle resources
- **State Management**: AR view handles collection state updates through environment objects

## Navigation Pattern
Uses `NavigationStack` with custom `Destination` enum for type-safe navigation:

```swift
private enum Destination: Hashable {
    case radar, rockdex, credit
    case rockDetail(Rock)  // Associated values for parameterized routes
}
```

**Pattern**: All navigation state is managed in `ContentView` with path binding passed down.

## UI Design System
- **Theme**: Pastel color palette defined in `Color+Theme.swift`
- **Layout**: Heavy use of `VStack`/`HStack` with consistent 16-20pt spacing
- **Animation**: `.easeInOut` transitions with 0.3-0.6 second durations

## Key Development Patterns

### 1. @MainActor Usage
All ViewModels are marked `@MainActor` to ensure UI updates happen on main thread:
```swift
@MainActor
final class RockCollectionViewModel: ObservableObject {
    @Published private(set) var allRocks: [Rock] = RockDataStore.rocks
}
```

### 2. Environment Object Access Pattern
Views access shared state via `@EnvironmentObject`, never creating ViewModels directly:
```swift
struct RadarView: View {
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var radarViewModel: RadarViewModel
}
```

### 3. Coordinate System
- Uses `CLLocationCoordinate2D` for all location data
- Custom encoding/decoding in `Rock` model for JSON compatibility
- 10-meter proximity threshold for radar discovery

## Build Configuration
- **Target iOS**: 26.0+ (likely iOS 16.0+ intended)
- **Swift**: 5.0
- **Bundle ID**: `com.dev.st.school.RockExplorer`
- **Required Capabilities**: Location services, Camera (for AR)

## Testing Structure
- Unit tests: `RockExplorerTests/`
- UI tests: `RockExplorerUITests/`
- **Note**: CoreData persistence layer exists but appears unused (legacy from template)

## Critical Debugging Points
1. **Location Services**: Always check authorization status before radar functionality
2. **AR Availability**: ARKit requires physical device, not simulator
3. **Asset Loading**: 3D models and images must exist in bundle or app crashes
4. **State Sync**: Environment object updates must happen on `@MainActor`

## Resource Management
- Images stored in `RockExplorer/Resources/Images/Rocks/`
- 3D models (`.usdz`) in same directory with matching `assetName`
- All assets referenced programmatically, not in Asset Catalog

When modifying this codebase, always maintain the MVVM + Environment Object pattern and ensure proper `@MainActor` usage for UI state management.
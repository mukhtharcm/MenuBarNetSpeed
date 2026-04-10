# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-04-10

### Changed
- Switched connection detection to a more reliable multi-source approach using `NWPathMonitor` for connectivity and interface type, plus system proxy settings for VPN detection.
- Added clearer connection labels for Wi-Fi, Ethernet, Cellular, and VPN state in the popover.
- Made refresh behavior sleep/wake-aware and added timer tolerance to reduce unnecessary background work.
- Reduced formatter and polling overhead for better efficiency.
- Added release workflow documentation in `RELEASING.md`.

### Fixed
- Fixed notification permission handling when the app bundle identifier is unavailable.
- Stopped incorrectly treating all `.other` network interfaces as VPN connections.

## [1.0.0] - 2026-04-10

### Added
- Redesigned menu bar and popover UI for live download and upload speed.
- Added a settings panel for refresh interval, display mode, network name visibility, and launch at login.
- Added sparkline history, session totals, peak speed tracking, bits-per-second display, and speed threshold alerts.

### Changed
- Improved performance, robustness, and accessibility across the app.
- Redesigned the app icon and simplified DMG packaging.

## [0.1.0-beta.1] - 2026-04-10

### Added
- First prerelease of Net Speed Bar for macOS.
- Automated prerelease publishing through GitHub Actions.

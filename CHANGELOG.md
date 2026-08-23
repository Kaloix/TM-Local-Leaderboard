# Changelog

All notable changes to this project will be documented in this file.

## [v0.2.0] - TBA

### Added
- Added support for zones
- Added statistics window for the current run
- Added statistics about number of runs and time spent on the map
- Added history of global position
- Added options to limit the number of displayed beaten/unbeaten medals
- Added deletion of entries
- Added staring of entries
- Added column for local rank percentage
- Added checkpoint times for custom times
- Improved customizability (font site, background transparency)
- Improved settings structure
- Improved icons and column names

### Fixed
- Removed MLHook from optional dependencies as MLFeedRaceData requires it
- Fixed color of speed delta
- Fixed value of the TimeSinceColumn
- Changed project branding to LocalRecords

## [v0.1.0] - 2026-07-04

### Added
- Initial release of Local Leaderboard.
- Added support for race leaderboard display and local plugin packaging.
- Included dependencies: `MLFeedRaceData`, `NadeoServices`.
- Optional integrations for `ChampionMedals`, `WarriorMedals`, `mapinfo`, and `MLHook`.

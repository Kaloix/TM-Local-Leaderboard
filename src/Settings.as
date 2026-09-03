// Category Data

[Setting name="Record Limit" description="Maximum number of records in the leaderboard" category="Data"]
uint settingDataRecordLimit = 100;

[Setting name="Add PB" description="If the PB should be added if no entries are available" category="Data"]
bool settingDataAddPb = true;

[Setting name="Use Nadeo API" description="If Nadeo's API should be used for estimating positions and fetching global records." category="Data"]
bool settingUseNadeoApi = true;

[Setting name="Read AT CP Times" description="If the plugin should read the checkpoint times from the AT plugin. Requires MLHook." category="Data"]
bool settingReadATCpTimes = true;

// Category Leaderboard - Window
[Setting name="Display Leaderboard Window" description="Show the leaderboard UI" category="Leaderboard - Window"]
bool settingDisplayLeaderboardWindow = true;

[Setting name="Display Title Bar" description="Show the title bar with the plugin name" category="Leaderboard - Window"]
bool settingDisplayLeaderboardTitleBar = false;

[Setting name="Maximum Size" description="Maximum size of the leaderboard window" category="Leaderboard - Window" min=0 max=1000]
int settingDisplayLeaderboardMaxSize = 300;

[Setting name="Background Transparency" description="Transparency of the leaderboard background" category="Leaderboard - Window" min=0.0f max=1.0f]
float settingLeaderboardBackgroundTransparency = 1.0f;

[Setting name="Font Size" description="Font size for the leaderboard and current run info" category="Leaderboard - Window" min=1 max=64]
int settingLeaderboardFontSize = 16;

[Setting name="Display Map Name" description="Show the map name in the leaderboard UI" category="Leaderboard - Window"]
bool settingDisplayLeaderboardMapName = true;

[Setting name="Display Map Author" description="Show the map author in the leaderboard UI" category="Leaderboard - Window"]
bool settingDisplayLeaderboardMapAuthor = true;

[Setting name="Display Statistics" description="Show the statistics section in the leaderboard UI" category="Leaderboard - Window"]
bool settingDisplayLeaderboardStatistics = true;

[Setting name="Display Zone Selection" description="Show the zone selection in the leaderboard UI" category="Leaderboard - Window"]
bool settingDisplayLeaderboardZoneSelection = true;

[Setting name="Display Leaderboard" description="Show the leaderboard UI" category="Leaderboard - Window"]
bool settingDisplayLeaderboard = true;

[Setting name="Display Leaderboard Header" description="Show the header row in the leaderboard" category="Leaderboard - Window"]
bool settingDisplayLeaderboardHeader = true;

// Category Leaderboard - Table
[Setting name="Display Leaderboard Tooltips" description="Show tooltips with additional information when hovering over leaderboard entries" category="Leaderboard - Window"]
bool settingDisplayLeaderboardTooltips = true;

[Setting name="Leaderboard Sorting" description="Sort order for the leaderboard entries" category="Leaderboard - Table"]
LeaderboardSortType settingLeaderboardSortType = LeaderboardSortType::Time;

[Setting name="Leaderboard Sorting Direction" description="Sort direction for the leaderboard entries" category="Leaderboard - Table"]
LeaderboardSortDirection settingLeaderboardSortDirection = LeaderboardSortDirection::Ascending;

[Setting name="Filter Personal Bests" description="Show only previous personal bests in the leaderboard" category="Leaderboard - Table"]
bool settingFilterPersonalBests = false;

[Setting name="Filter Session Bests" description="Show only session bests in the leaderboard" category="Leaderboard - Table"]
bool settingFilterSessionBests = false;

[Setting name="Filter Current Session" description="Show only times of the current session in the leaderboard" category="Leaderboard - Table"]
bool settingFilterSessionCurrent = false;

[Setting name="Number ranks" description="The number of displayed entries for each player" category="Leaderboard - Table"]
uint settingDisplayLeaderboardNumberRanks = 3;

[Setting name="Display Personal Best" description="Show the player's personal best in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardPersonalBest = true;

[Setting name="Display Session Best" description="Show the player's session best in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardSessionBest = true;

[Setting name="Display Newest Copium" description="Show the player's copium time of the last run in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardCopiumNewest = false;

[Setting name="Display Best Copium" description="Show the player's best copium time in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardCopiumFastest = false;

[Setting name="Display Session Copium" description="Show the player's best copium time of the current session in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardCopiumSessionFastest = false;

[Setting name="Display Best Checkpoints Run" description="Show the player's best checkpoints run in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardBestCheckpointsRun = false;

[Setting name="Display Session Best Checkpoints Run" description="Show the player's best checkpoints run of the current session in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardSessionBestCheckpointsRun = false;

[Setting name="Display Best Laps Run" description="Show the player's best laps run in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardBestLapsRun = false;

[Setting name="Display Session Best Laps Run" description="Show the player's best laps run of the current session in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardSessionBestLapsRun = false;

[Setting name="Display Custom Times" description="Show custom times in the leaderboard UI" category="Leaderboard - Table"]
bool settingDisplayLeaderboardCustomTimes = true;

[Setting name="Display Custom Positions" description="Show custom positions in the leaderboard UI" category="Leaderboard - Table"]
bool settingDisplayLeaderboardCustomPositions = true;

[Setting name="Display Starred" description="Show starred runs in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardStarred = true;

[Setting name="Display Medal Author" description="Show the author of medal times in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardMedalAuthor = true;

[Setting name="Display Medal Gold" description="Show the gold medal time in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardMedalGold = true;

[Setting name="Display Medal Silver" description="Show the silver medal time in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardMedalSilver = true;

[Setting name="Display Medal Bronze" description="Show the bronze medal time in the leaderboard" category="Leaderboard - Table"]
bool settingDisplayLeaderboardMedalBronze = true;

[Setting name="Display Medal Champion" description="Show the champion medal time in the leaderboard if the ChampionMedal Plugin is installed" category="Leaderboard - Table"]
bool settingDisplayLeaderboardMedalChampion = true;

[Setting name="Display Medal Warrior" description="Show the warrior medal time in the leaderboard if the WarriorMedal Plugin is installed" category="Leaderboard - Table"]
bool settingDisplayLeaderboardMedalWarrior = true;

[Setting name="Number of Beaten Medals" description="The number of beaten medals listed in the leaderboard." category="Leaderboard - Table" min=0 max=6]
uint settingNumberBeatenMedals = 6;

[Setting name="Number of Unbeaten Medals" description="The number of unbeaten medals listed in the leaderboard." category="Leaderboard - Table" min=0 max=6]
uint settingNumberUnbeatenMedals = 6;

[Setting name="Show Past Global Position" description="Show the past global position in the leaderboard for times slower than the PB" category="Leaderboard - Table"]
bool settingLeaderboardPastGlobalPosition = true;

// Category Colors
[Setting name="Color Delta Better" description="Color for deltas that are better than the comparison time" color category="Colors"]
vec3 settingColorDeltaBetter = vec3(0.47f, 0.47f, 1.0f);

[Setting name="Color Delta Worse" description="Color for deltas that are worse than the comparison time" color category="Colors"]
vec3 settingColorDeltaWorse = vec3(1.0f, 0.47f, 0.47f);

[Setting name="Color Delta Equal" description="Color for deltas that are equal to the comparison time" color category="Colors"]
vec3 settingColorDeltaEqual = vec3(0.66f, 0.66f, 0.66f);

[Setting name="Color Time Best" description="Color for the player's best time in the leaderboard" color category="Colors"]
vec3 settingColorTimeBest = vec3(0.75f, 0.25f, 0.75f);

[Setting name="Color Time Session Best" description="Color for the player's best time of the current session in the leaderboard" color category="Colors"]
vec3 settingColorTimeSessionBest = vec3(0.25f, 0.75f, 0.75f);

[Setting name="Color Time Last" description="Color for the player's last time in the leaderboard" color category="Colors"]
vec3 settingColorTimeLast = vec3(0.5f, 1.0f, 0.0f);

// Category Current Run
[Setting name="Show Current Run" description="Show information about the current run" category="Current Run - Window"]
bool settingShowCurrentRun = false;

[Setting name="Display Title Bar" description="Show the title bar with the plugin name" category="Current Run - Window"]
bool settingCurrentRunDisplayTitleBar = false;

[Setting name="Maximum Size" description="Maximum size of the current run window" category="Current Run - Window" min=0 max=1000]
int settingCurrentRunMaxSize = 300;

[Setting name="Background Transparency" description="Transparency of the current run info" category="Current Run - Window" min=0.0f max=1.0f]
float settingCurrentRunBackgroundTransparency = 1.0f;

[Setting name="Font Size" description="Font size for the leaderboard and current run info" category="Current Run - Window" min=1 max=64]
int settingCurrentRunFontSize = 16;

[Setting name="Position Comparison Type" description="The type of comparison to use for determining the position at each checkpoint" category="Current Run - Table"]
LocalRecords::CheckpointPositionComparison settingCurrentRunCheckpointPosition = LocalRecords::CheckpointPositionComparison::TimeFromStart;

[Setting name="Show Checkpoints" category="Current Run - Table"]
bool settingCurrentRunShowCp = true;

[Setting name="Show Position" category="Current Run - Table"]
bool settingCurrentRunShowPosition = false;

[Setting name="Show Time" category="Current Run - Table"]
bool settingCurrentRunShowTime = true;
[Setting name="Show Time Delta" category="Current Run - Table"]
bool settingCurrentRunShowTimeDelta = true;
[Setting name="Show Time Position" category="Current Run - Table"]
bool settingCurrentRunShowTimePosition = true;

[Setting name="Show No-Respawn Time" category="Current Run - Table"]
bool settingCurrentRunShowTimeNr = false;
[Setting name="Show No-Respawn Time Delta" category="Current Run - Table"]
bool settingCurrentRunShowTimeNrDelta = false;
[Setting name="Show No-Respawn Time Position" category="Current Run - Table"]
bool settingCurrentRunShowTimeNrPosition = false;

[Setting name="Show Speed" category="Current Run - Table"]
bool settingCurrentRunShowSpeed = true;
[Setting name="Show Speed Delta" category="Current Run - Table"]
bool settingCurrentRunShowSpeedDelta = true;
[Setting name="Show Speed Position" category="Current Run - Table"]
bool settingCurrentRunShowSpeedPosition = true;

[Setting name="Show CP Time" category="Current Run - Table"]
bool settingCurrentRunShowCpTime = false;
[Setting name="Show CP Time Delta" category="Current Run - Table"]
bool settingCurrentRunShowCpTimeDelta = false;
[Setting name="Show CP Time Position" category="Current Run - Table"]
bool settingCurrentRunShowCpTimePosition = false;

[Setting name="Show CP No-Respawn Time" category="Current Run - Table"]
bool settingCurrentRunShowCpTimeNr = true;
[Setting name="Show CP No-Respawn Time Delta" category="Current Run - Table"]
bool settingCurrentRunShowCpTimeNrDelta = true;
[Setting name="Show CP No-Respawn Time Position" category="Current Run - Table"]
bool settingCurrentRunShowCpTimeNrPosition = true;

[Setting name="Show Number Respawns" category="Current Run - Table"]
bool settingCurrentRunShowNumberRespawns = false;
[Setting name="Show Number Respawns Delta" category="Current Run - Table"]
bool settingCurrentRunShowNumberRespawnsDelta = false;
[Setting name="Show Number Respawns Position" category="Current Run - Table"]
bool settingCurrentRunShowNumberRespawnsPosition = false;


// Category Debug
[Setting name="Log Debug Info" description="Log debug information in the console" category="Debug"]
bool settingShowDebugInfo = false;

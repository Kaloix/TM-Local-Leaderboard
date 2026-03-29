// Category Data

[Setting name="Record Limit" description="Maximum number of records in the leaderboard" category="Data"]
uint settingDataRecordLimit = 100;

[Setting name="Add PB" description="If the PB should be added if no entries are available" category="Data"]
bool settingDataAddPb = true;

// Category UI
[Setting name="Display Title Bar" description="Show the title bar with the plugin name" category="UI"]
bool settingDisplayLeaderboardTitleBar = false;

[Setting name="Display Map Name" description="Show the map name in the leaderboard UI" category="UI"]
bool settingDisplayLeaderboardMapName = true;

[Setting name="Display Map Author" description="Show the map author in the leaderboard UI" category="UI"]
bool settingDisplayLeaderboardMapAuthor = true;

[Setting name="Display Leaderboard" description="Show the leaderboard UI" category="UI"]
bool settingDisplayLeaderboard = true;

[Setting name="Display Leaderboard Header" description="Show the header row in the leaderboard" category="UI"]
bool settingDisplayLeaderboardHeader = true;

[Setting name="Display Leaderboard Tooltips" description="Show tooltips with additional information when hovering over leaderboard entries" category="UI"]
bool settingDisplayLeaderboardTooltips = true;

[Setting name="Leaderboard Sorting" description="Sort order for the leaderboard entries" category="UI"]
LeaderboardSortType settingLeaderboardSortType = LeaderboardSortType::Time;

[Setting name="Leaderboard Sorting Direction" description="Sort direction for the leaderboard entries" category="UI"]
LeaderboardSortDirection settingLeaderboardSortDirection = LeaderboardSortDirection::Ascending;

[Setting name="Display Medal Column" description="Show the medal column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardMedalColumn = true;

[Setting name="Display Rank Column" description="Show the rank column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardRankColumn = true;

[Setting name="Display Time Column" description="Show the time column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardTimeColumn = true;

[Setting name="Display Delta Column" description="Show the PB delta column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardDeltaPBColumn = true;

[Setting name="Display Last Time Delta Column" description="Show the last time delta column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardDeltaLastColumn = true;

[Setting name="Display Copium Column" description="Show the Copium column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardCopiumColumn = false;

[Setting name="Display Respawns Column" description="Show the Respawns column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardRespawnsColumn = false;

[Setting name="Display Score Number Column" description="Show the score number column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardScoreNumberColumn = false;

[Setting name="Display Session Number Column" description="Show the session number column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardSessionNumberColumn = false;

[Setting name="Display Timestamp Column" description="Show the timestamp column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardTimestampColumn = false;

[Setting name="Display Player Column" description="Show the player column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardPlayerColumn = false;

[Setting name="Display Session Time" description="Show the session time column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardSessionTimeColumn = false;

[Setting name="Display Total Time" description="Show the total time column in the leaderboard" category="UI"]
bool settingDisplayLeaderboardTotalTimeColumn = false;

[Setting name="Display Time Since" description="Show the time since the record was set in the leaderboard" category="UI"]
bool settingDisplayLeaderboardTimeSinceColumn = false;

[Setting name="Filter Personal Bests" description="Show only previous personal bests in the leaderboard" category="UI"]
bool settingFilterPersonalBests = false;

[Setting name="Filter Session Bests" description="Show only session bests in the leaderboard" category="UI"]
bool settingFilterSessionBests = false;

[Setting name="Filter Current Session" description="Show only times of the current session in the leaderboard" category="UI"]
bool settingFilterSessionCurrent = false;

[Setting name="Display Newest Copium" description="Show the player's copium time of the last run in the leaderboard" category="UI"]
bool settingDisplayLeaderboardCopiumNewest = false;

[Setting name="Display Best Copium" description="Show the player's best copium time in the leaderboard" category="UI"]
bool settingDisplayLeaderboardCopiumFastest = false;

[Setting name="Display Session Copium" description="Show the player's best copium time of the current session in the leaderboard" category="UI"]
bool settingDisplayLeaderboardCopiumSessionFastest = false;

[Setting name="Display Medal Author" description="Show the author of medal times in the leaderboard" category="UI"]
bool settingDisplayLeaderboardMedalAuthor = true;

[Setting name="Display Medal Gold" description="Show the gold medal time in the leaderboard" category="UI"]
bool settingDisplayLeaderboardMedalGold = true;

[Setting name="Display Medal Silver" description="Show the silver medal time in the leaderboard" category="UI"]
bool settingDisplayLeaderboardMedalSilver = true;

[Setting name="Display Medal Bronze" description="Show the bronze medal time in the leaderboard" category="UI"]
bool settingDisplayLeaderboardMedalBronze = true;

[Setting name="Display Medal Champion" description="Show the champion medal time in the leaderboard if the ChampionMedal Plugin is installed" category="UI"]
bool settingDisplayLeaderboardMedalChampion = true;

[Setting name="Display Medal Warrior" description="Show the warrior medal time in the leaderboard if the WarriorMedal Plugin is installed" category="UI"]
bool settingDisplayLeaderboardMedalWarrior = true;

[Setting name="Color Delta Better" description="Color for deltas that are better than the comparison time" color category="UI"]
vec3 settingColorDeltaBetter = vec3(0.47f, 0.47f, 1.0f);

[Setting name="Color Delta Worse" description="Color for deltas that are worse than the comparison time" color category="UI"]
vec3 settingColorDeltaWorse = vec3(1.0f, 0.47f, 0.47f);

[Setting name="Color Delta Equal" description="Color for deltas that are equal to the comparison time" color category="UI"]
vec3 settingColorDeltaEqual = vec3(0.66f, 0.66f, 0.66f);

[Setting name="Color Time Best" description="Color for the player's best time in the leaderboard" color category="UI"]
vec3 settingColorTimeBest = vec3(0.75f, 0.25f, 0.75f);

[Setting name="Color Time Session Best" description="Color for the player's best time of the current session in the leaderboard" color category="UI"]
vec3 settingColorTimeSessionBest = vec3(0.25f, 0.75f, 0.75f);

[Setting name="Color Time Last" description="Color for the player's last time in the leaderboard" color category="UI"]
vec3 settingColorTimeLast = vec3(0.5f, 1.0f, 0.0f);

// Category Debug
[Setting name="Show Debug Info" description="Show debug information in the console" category="Debug"]
bool settingShowDebugInfo = false;

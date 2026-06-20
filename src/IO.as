namespace LocalLeaderboard
{

void saveSettings()
{
    string filePath = IO::FromStorageFolder("settings.json");

    auto root = Json::Object();
    root["version"] = Meta::ExecutingPlugin().Version;
    root["settings"] = serializeSettings();

    Json::ToFile(filePath, root);
    LogInfo("Saved settings to " + filePath);
}

void loadSettings() {

    string filePath = IO::FromStorageFolder("settings.json");

    if (!IO::FileExists(filePath))
    {
        // Start with an empty leaderboard if no file exists
        LogInfo("No settings found at " + filePath);
        return;
    }

    auto root = Json::FromFile(filePath);
    deserializeSettings(root["settings"]);

    LogInfo("Loaded settings from " + filePath);
}

void SaveLeaderboard(const State&in state)
{
    if (state.m_CurrentMap == "")
    {
        LogWarning("No map loaded, skipping leaderboard save.");
        return;
    }

    string fileDirectory = buildFileDir();
    string filePath = buildFilePath(state.m_CurrentMap);

    if (!IO::FolderExists(fileDirectory))
    {
        IO::CreateFolder(fileDirectory);
    }

    auto root = Json::Object();
    root["version"] = Meta::ExecutingPlugin().Version;

    auto leaderboard = Json::Object();

    auto entries = Json::Array();

    for (uint i = 0; i < state.m_Leaderboard.m_Entries.Length; i++)
    {
        const auto @entry = @state.m_Leaderboard.m_Entries[i];
        auto entryObj = serializeLeaderboardEntry(entry);
        entries.Add(entryObj);
    }

    leaderboard["entries"] = entries;

    if (state.m_Leaderboard.m_FastestRun !is null)
    {
        leaderboard["fastestRun"] = serializeLeaderboardEntry(state.m_Leaderboard.m_FastestRun);
    }
    if (state.m_Leaderboard.m_FastestCopiumRun !is null)
    {
        leaderboard["fastestCopiumRun"] = serializeLeaderboardEntry(state.m_Leaderboard.m_FastestCopiumRun);
    }
    if (state.m_Leaderboard.m_BestCheckpointsRun !is null)
    {
        leaderboard["bestCheckpointsRun"] = serializeLeaderboardEntry(state.m_Leaderboard.m_BestCheckpointsRun);
    }
    if (state.m_Leaderboard.m_BestLapsRun !is null)
    {
        leaderboard["bestLapsRun"] = serializeLeaderboardEntry(state.m_Leaderboard.m_BestLapsRun);
    }

    leaderboard["totalNumberFinishes"] = state.m_Leaderboard.m_TotalNumberFinishes;
    leaderboard["totalNumberSessions"] = state.m_Leaderboard.m_TotalNumberSessions;
    leaderboard["totalTime"] = state.m_Leaderboard.m_TotalTime;

    root["leaderboard"] = leaderboard;

    // Custom times
    if (state.m_CustomTimeEntries.Length > 0)
    {
        auto customTimeEntries = Json::Array();
        for (uint i = 0; i < state.m_CustomTimeEntries.Length; i++)
        {
            const auto @entry = @state.m_CustomTimeEntries[i];
            auto @entryObj = @serializeCustomTime(entry);
            customTimeEntries.Add(entryObj);
        }
        root["customTimeEntries"] = customTimeEntries;
    }

    // Save file
    Json::ToFile(filePath, root);
    LogDebug("Leaderboard saved to " + filePath);
}

void LoadLeaderboard(State&inout state)
{
    if (state.m_CurrentMap == "")
    {
        LogWarning("No map loaded, skipping leaderboard load.");
        return;
    }

    state.m_Leaderboard = Leaderboard();

    string filePath = buildFilePath(state.m_CurrentMap);

    if (!IO::FileExists(filePath))
    {
        // Start with an empty leaderboard if no file exists
        return;
    }

    // Deserialize the leaderboard data from the file
    auto root = Json::FromFile(filePath);
    auto leaderboard = root["leaderboard"];
    auto entries = leaderboard["entries"];

    if (leaderboard.HasKey("fastestRun"))
    {
        @state.m_Leaderboard.m_FastestRun = @deserializeLeaderboardEntry(leaderboard["fastestRun"]);
    }
    if (leaderboard.HasKey("fastestCopiumRun"))
    {
        @state.m_Leaderboard.m_FastestCopiumRun = @deserializeLeaderboardEntry(leaderboard["fastestCopiumRun"]);
        state.m_Leaderboard.m_FastestCopiumRun.m_Type = LeaderboardEntryType::ScoreCopium;
    }
    if (leaderboard.HasKey("bestCheckpointsRun"))
    {
        @state.m_Leaderboard.m_BestCheckpointsRun = @deserializeLeaderboardEntry(leaderboard["bestCheckpointsRun"]);
        state.m_Leaderboard.m_BestCheckpointsRun.m_Type = LeaderboardEntryType::ScoreBestCheckpoints;
    }
    if (leaderboard.HasKey("bestLapsRun"))
    {
        @state.m_Leaderboard.m_BestLapsRun = @deserializeLeaderboardEntry(leaderboard["bestLapsRun"]);
        state.m_Leaderboard.m_BestLapsRun.m_Type = LeaderboardEntryType::ScoreBestLaps;
    }

    for (uint i = 0; i < entries.Length; i++)
    {
        auto @entry = @deserializeLeaderboardEntry(entries[i]);
        state.m_Leaderboard.AddEntry(@entry);

        if (state.m_Leaderboard.m_FastestRun !is null && state.m_Leaderboard.m_FastestRun.m_ScoreNumber == entry.m_ScoreNumber)
        {
            @state.m_Leaderboard.m_FastestRun = @entry;
        }
    }

    state.m_Leaderboard.m_TotalNumberFinishes = leaderboard["totalNumberFinishes"];
    state.m_Leaderboard.m_TotalNumberSessions = leaderboard["totalNumberSessions"];
    state.m_Leaderboard.m_TotalTime = leaderboard["totalTime"];

    // Custom times
    if (root.HasKey("customTimeEntries"))
    {
        auto customTimeEntries = root["customTimeEntries"];
        for (uint i = 0; i < customTimeEntries.Length; i++)
        {
            auto @entry = @deserializeCustomTime(customTimeEntries[i]);
            state.m_CustomTimeEntries.InsertLast(@entry);
        }
    }
}

Json::Value serializeLeaderboardEntry(const LeaderboardEntry&in entry)
{
    auto entryObj = Json::Object();
    entryObj[IO_KEY::ID] = entry.m_Id;
    if (entry.m_ScoreNumber > 0)
        entryObj[IO_KEY::SCORE_NUMBER] = entry.m_ScoreNumber;
    if (entry.m_SessionNumber > 0)
        entryObj[IO_KEY::SESSION_NUMBER] = entry.m_SessionNumber;
    entryObj[IO_KEY::PLAYER] = entry.m_PlayerName;
    entryObj[IO_KEY::RANK] = entry.m_Rank;
    entryObj[IO_KEY::TIME] = entry.m_Time;
    if (entry.m_TimeNoRespawn != entry.m_Time)
        entryObj[IO_KEY::TIME_NO_RESPAWN] = entry.m_TimeNoRespawn;
    if (entry.m_NumberRespawns > 0)
        entryObj[IO_KEY::NUMBER_RESPAWNS] = entry.m_NumberRespawns;
    if (entry.m_TimeStamp > 0)
        entryObj[IO_KEY::TIMESTAMP] = entry.m_TimeStamp;
    if (entry.m_TimeInTotal > 0)
        entryObj[IO_KEY::TIME_IN_TOTAL] = entry.m_TimeInTotal;
    if (entry.m_TimeInSession > 0)
        entryObj[IO_KEY::TIME_IN_SESSION] = entry.m_TimeInSession;
    if (entry.m_WasPersonalBest)
        entryObj[IO_KEY::WAS_PERSONAL_BEST] = entry.m_WasPersonalBest;
    if (entry.m_WasSessionBest)
        entryObj[IO_KEY::WAS_SESSION_BEST] = entry.m_WasSessionBest;

    auto checkpoints = Json::Array();
    for (uint i = 0; i < entry.m_Checkpoints.Length; i++)    {
        auto cpDataObj = serializeCheckpointData(entry.m_Checkpoints[i]);
        checkpoints.Add(cpDataObj);
    }
    entryObj[IO_KEY::CHECKPOINTS] = checkpoints;

    auto laps = Json::Array();
    for (uint i = 0; i < entry.m_Laps.Length; ++i)
    {
        auto lapDataObj = serializeLapData(entry.m_Laps[i]);
        laps.Add(lapDataObj);
    }
    entryObj[IO_KEY::LAPS] = laps;

    return entryObj;
}

LeaderboardEntry @deserializeLeaderboardEntry(const Json::Value&in entryObj)
{
    auto @entry = LeaderboardEntry();
    entry.m_Id = entryObj[IO_KEY::ID];
    if (entryObj.HasKey(IO_KEY::SCORE_NUMBER))
        entry.m_ScoreNumber = entryObj[IO_KEY::SCORE_NUMBER];
    if (entryObj.HasKey(IO_KEY::SESSION_NUMBER))
        entry.m_SessionNumber = entryObj[IO_KEY::SESSION_NUMBER];
    entry.m_Type = LeaderboardEntryType::Score;
    entry.m_PlayerName = entryObj[IO_KEY::PLAYER];
    entry.m_Rank = entryObj[IO_KEY::RANK];
    entry.m_Time = entryObj[IO_KEY::TIME];
    if (entryObj.HasKey(IO_KEY::TIME_NO_RESPAWN))
        entry.m_TimeNoRespawn = entryObj[IO_KEY::TIME_NO_RESPAWN];
    else
        entry.m_TimeNoRespawn = entry.m_Time;
    if (entryObj.HasKey(IO_KEY::NUMBER_RESPAWNS))
        entry.m_NumberRespawns = entryObj[IO_KEY::NUMBER_RESPAWNS];
    if (entryObj.HasKey(IO_KEY::TIMESTAMP))
        entry.m_TimeStamp = entryObj[IO_KEY::TIMESTAMP];
    if (entryObj.HasKey(IO_KEY::TIME_IN_TOTAL))
        entry.m_TimeInTotal = entryObj[IO_KEY::TIME_IN_TOTAL];
    if (entryObj.HasKey(IO_KEY::TIME_IN_SESSION))
        entry.m_TimeInSession = entryObj[IO_KEY::TIME_IN_SESSION];
    if (entryObj.HasKey(IO_KEY::WAS_PERSONAL_BEST))
        entry.m_WasPersonalBest = entryObj[IO_KEY::WAS_PERSONAL_BEST];
    if (entryObj.HasKey(IO_KEY::WAS_SESSION_BEST))
        entry.m_WasSessionBest = entryObj[IO_KEY::WAS_SESSION_BEST];

    
    int timeFromStart = 0;
    for (uint i = 0; i < entryObj[IO_KEY::CHECKPOINTS].Length; i++)
    {
        auto cpDataObj = entryObj[IO_KEY::CHECKPOINTS][i];
        auto @cpData = @deserializeCheckpointData(cpDataObj);
        timeFromStart += cpData.m_TimeFromPrevious;
        cpData.m_TimeFromStart = timeFromStart;
        entry.m_Checkpoints.InsertLast(@cpData);
    }

    timeFromStart = 0;
    for (uint i = 0; i < entryObj[IO_KEY::LAPS].Length; ++i)
    {
        auto lapDataObj = entryObj[IO_KEY::LAPS][i];
        auto @lapData = @deserializeLapData(lapDataObj);
        timeFromStart += lapData.m_TimeFromPrevious;
        lapData.m_TimeFromStart = timeFromStart;
        entry.m_Laps.InsertLast(@lapData);
    }

    return @entry;
}

Json::Value serializeCheckpointData(const CheckpointData&in cpData)
{
    auto cpDataObj = Json::Object();
    cpDataObj[IO_KEY::TIME_FROM_PREVIOUS] = cpData.m_TimeFromPrevious;
    if (cpData.m_TimeFromPreviousNoRespawn != cpData.m_TimeFromPrevious)
        cpDataObj[IO_KEY::TIME_FROM_PREVIOUS_NO_RESPAWN] = cpData.m_TimeFromPreviousNoRespawn;
    cpDataObj[IO_KEY::SPEED] = cpData.m_Speed;
    if (cpData.m_NumberRespawns > 0)
        cpDataObj[IO_KEY::NUMBER_RESPAWNS] = cpData.m_NumberRespawns;
    return cpDataObj;
}

CheckpointData @deserializeCheckpointData(const Json::Value&in cpDataObj)
{
    auto @cpData = CheckpointData();
    cpData.m_TimeFromPrevious = cpDataObj[IO_KEY::TIME_FROM_PREVIOUS];
    if (cpDataObj.HasKey(IO_KEY::TIME_FROM_PREVIOUS_NO_RESPAWN))
        cpData.m_TimeFromPreviousNoRespawn = cpDataObj[IO_KEY::TIME_FROM_PREVIOUS_NO_RESPAWN];
    else 
        cpData.m_TimeFromPreviousNoRespawn = cpData.m_TimeFromPrevious;
    cpData.m_Speed = cpDataObj[IO_KEY::SPEED];
    if (cpDataObj.HasKey(IO_KEY::NUMBER_RESPAWNS))
        cpData.m_NumberRespawns = cpDataObj[IO_KEY::NUMBER_RESPAWNS];
    return @cpData;
}

Json::Value serializeLapData(const LapData&in lapData)
{
    auto lapDataObj = Json::Object();
    lapDataObj[IO_KEY::TIME_FROM_PREVIOUS] = lapData.m_TimeFromPrevious;
    if (lapData.m_TimeFromPreviousNoRespawn != lapData.m_TimeFromPrevious)
        lapDataObj[IO_KEY::TIME_FROM_PREVIOUS_NO_RESPAWN] = lapData.m_TimeFromPreviousNoRespawn;
    if (lapData.m_NumberRespawns > 0)
        lapDataObj[IO_KEY::NUMBER_RESPAWNS] = lapData.m_NumberRespawns;
    return lapDataObj;
}

LapData @deserializeLapData(const Json::Value&in lapDataObj)
{
    auto @lapData = LapData();
    lapData.m_TimeFromPrevious = lapDataObj[IO_KEY::TIME_FROM_PREVIOUS];
    if (lapDataObj.HasKey(IO_KEY::TIME_FROM_PREVIOUS_NO_RESPAWN))
        lapData.m_TimeFromPreviousNoRespawn = lapDataObj[IO_KEY::TIME_FROM_PREVIOUS_NO_RESPAWN];
    else
        lapData.m_TimeFromPreviousNoRespawn = lapData.m_TimeFromPrevious;
    if (lapDataObj.HasKey(IO_KEY::NUMBER_RESPAWNS))
        lapData.m_NumberRespawns = lapDataObj[IO_KEY::NUMBER_RESPAWNS];
    return @lapData;
}

Json::Value @serializeCustomTime(const LeaderboardEntry&in entry)
{
    auto @entryObj = Json::Object();
    entryObj[IO_KEY::ID] = entry.m_Id;
    entryObj[IO_KEY::PLAYER] = entry.m_PlayerName;
    entryObj[IO_KEY::TIME] = entry.m_Time;
    return @entryObj;
}

LeaderboardEntry @deserializeCustomTime(const Json::Value&in entryObj)
{
    auto @entry = LeaderboardEntry();
    entry.m_Id = entryObj[IO_KEY::ID];
    entry.m_Type = LeaderboardEntryType::CustomTime;
    entry.m_PlayerName = entryObj[IO_KEY::PLAYER];
    entry.m_Time = entryObj[IO_KEY::TIME];
    return @entry;
}

Json::Value @serializeCustomPosition(const LeaderboardEntry&in entry)
{
    auto @entryObj = Json::Object();
    entryObj[IO_KEY::ID] = entry.m_Id;
    entryObj[IO_KEY::PLAYER] = entry.m_PlayerName;
    entryObj[IO_KEY::POSITION] = entry.m_GlobalPosition;
    return @entryObj;
}

LeaderboardEntry @deserializeCustomPostition(const Json::Value&in entryObj)
{
    auto @entry = LeaderboardEntry();
    entry.m_Id = entryObj[IO_KEY::ID];
    entry.m_Type = LeaderboardEntryType::CustomPosition;
    entry.m_PlayerName = entryObj[IO_KEY::PLAYER];
    entry.m_GlobalPosition = entryObj[IO_KEY::POSITION];
    return @entry;
}

Json::Value serializeSettings()
{
    auto settingsObj = Json::Object();

    settingsObj["tableSettings"] = serializeTableSettings();

    // Custom positions
    if (g_State.m_CustomPositionEntries.Length > 0)
    {
        auto customPositionEntries = Json::Array();
        for (uint i = 0; i < g_State.m_CustomPositionEntries.Length; i++)
        {
            const auto @entry = @g_State.m_CustomPositionEntries[i];
            auto @entryObj = @serializeCustomPosition(entry);
            customPositionEntries.Add(entryObj);
        }
        settingsObj["customPositionEntries"] = customPositionEntries;
    }

    return settingsObj;
}

void deserializeSettings(const Json::Value&in settingsObj)
{
    deserializeTableSettings(settingsObj["tableSettings"]);

    // Custom positions
    if (settingsObj.HasKey("customPositionEntries"))
    {
        auto customPositionEntries = settingsObj["customPositionEntries"];
        for (uint i = 0; i < customPositionEntries.Length; i++)
        {
            auto @entry = @deserializeCustomPostition(customPositionEntries[i]);
            g_State.m_CustomPositionEntries.InsertLast(@entry);
        }
    }
}

Json::Value serializeTableSettings()
{
    auto tableSettingsObj = Json::Object();

    auto columns = Json::Array();
    for (uint i = 0; i < g_AllTableColumns.Length; ++i)
    {
        columns.Add(serializeColumnSettings(@g_AllTableColumns[i]));
    }
    tableSettingsObj["columns"] = columns;

    return tableSettingsObj;
}

void deserializeTableSettings(const Json::Value&in tableSettingsObj)
{
    auto columnSettingsObj = tableSettingsObj["columns"];

    for (uint i = 0; i < columnSettingsObj.Length; ++i)
    {
        auto @columnSettings = @g_AllTableColumns[i];
        deserializeColumnSettings(columnSettings, columnSettingsObj[i]);
    }
}

Json::Value serializeColumnSettings(const TableColumn@ column)
{
    auto columnSettingsObj = Json::Object();
    columnSettingsObj["type"] = column.GetType();
    columnSettingsObj["show"] = column.m_Show;
    columnSettingsObj[IO_KEY::POSITION] = column.m_Pos;

    if (column.GetType() == TableColumnType::TimeDeltaColumn) {
        const TimeDeltaColumn @timeDeltaColumn = cast<TimeDeltaColumn>(column);
        if (timeDeltaColumn.m_ComparisonTarget !is null)
        {
            auto @target = @timeDeltaColumn.m_ComparisonTarget;
            columnSettingsObj["target"] = target.GetName();
            if (timeDeltaColumn.m_ComparisonTarget.GetType() == ComparisonTargetType::CustomTime)
            {
                auto @customTarget = cast<CustomTimeComparisonTarget>(target);
                columnSettingsObj["targetEntryId"] = customTarget.m_CustomEntryId;
            }
            else if (timeDeltaColumn.m_ComparisonTarget.GetType() == ComparisonTargetType::CustomPosition)
            {
                auto @customTarget = cast<CustomPositionComparisonTarget>(target);
                columnSettingsObj["targetEntryId"] = customTarget.m_CustomEntryId;
            }
        }
    }

    return columnSettingsObj;
}

void deserializeColumnSettings(TableColumn@ column, const Json::Value&in columnSettingsObj)
{
    column.m_Show = columnSettingsObj["show"];
    column.m_Pos = columnSettingsObj[IO_KEY::POSITION];

    if (column.GetType() == TableColumnType::TimeDeltaColumn) {
        TimeDeltaColumn @timeDeltaColumn = cast<TimeDeltaColumn>(column);
        const string target = columnSettingsObj["target"];
        auto @comparisonTarget = @GetComparisonTarget(target);
        if (comparisonTarget !is null)
        {
            @timeDeltaColumn.m_ComparisonTarget = @comparisonTarget;
    
            if (comparisonTarget.GetType() == ComparisonTargetType::CustomTime)
            {
                auto @customTarget = cast<CustomTimeComparisonTarget>(comparisonTarget);
                customTarget.m_CustomEntryId = columnSettingsObj["targetEntryId"];
            }
            else if (comparisonTarget.GetType() == ComparisonTargetType::CustomPosition)
            {
                auto @customTarget = cast<CustomPositionComparisonTarget>(comparisonTarget);
                customTarget.m_CustomEntryId = columnSettingsObj["targetEntryId"];
            }
        }
    }
}

string buildFileDir()
{
    return IO::FromStorageFolder("/leaderboards");
}

string buildFilePath(const string&in mapId)
{
    return IO::FromStorageFolder("/leaderboards/" + mapId + ".json");
}


namespace IO_KEY {
const string CHECKPOINTS = "cps";
const string ID = "id";
const string LAPS = "l";
const string NUMBER_RESPAWNS = "nr";
const string PLAYER = "p";
const string POSITION = "pos";
const string RANK = "r";
const string SCORE_NUMBER = "scn";
const string SESSION_NUMBER = "sen";
const string SPEED = "s";
const string TIME = "t";
const string TIME_FROM_START = "tfs";
const string TIME_FROM_PREVIOUS = "tfp";
const string TIME_FROM_PREVIOUS_NO_RESPAWN = "tfpnr";
const string TIME_IN_SESSION = "tis";
const string TIME_IN_TOTAL = "tit";
const string TIME_NO_RESPAWN = "tnr";
const string TIMESTAMP = "ts";
const string WAS_PERSONAL_BEST = "wpb";
const string WAS_SESSION_BEST = "wsb";
}


}

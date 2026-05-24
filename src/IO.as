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
        leaderboard["festestRun"] = serializeLeaderboardEntry(state.m_Leaderboard.m_FastestRun);
    }
    if (state.m_Leaderboard.m_FastestCopiumRun !is null)
    {
        leaderboard["festestCopiumRun"] = serializeLeaderboardEntry(state.m_Leaderboard.m_FastestCopiumRun);
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

    auto customEntries = Json::Array();
    for (uint i = 0; i < state.m_CustomEntries.Length; i++)
    {
        const auto @entry = @state.m_CustomEntries[i];
        auto entryObj = serializeLeaderboardEntry(entry);
        customEntries.Add(entryObj);
    }
    root["customEntries"] = customEntries;

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

    if (leaderboard.HasKey("festestRun"))
    {
        @state.m_Leaderboard.m_FastestRun = @deserializeLeaderboardEntry(leaderboard["festestRun"]);
    }
    if (leaderboard.HasKey("festestCopiumRun"))
    {
        @state.m_Leaderboard.m_FastestCopiumRun = @deserializeLeaderboardEntry(leaderboard["festestCopiumRun"]);
    }
    if (leaderboard.HasKey("bestCheckpointsRun"))
    {
        @state.m_Leaderboard.m_BestCheckpointsRun = @deserializeLeaderboardEntry(leaderboard["bestCheckpointsRun"]);
    }
    if (leaderboard.HasKey("bestLapsRun"))
    {
        @state.m_Leaderboard.m_BestLapsRun = @deserializeLeaderboardEntry(leaderboard["bestLapsRun"]);
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

    auto customEntries = root["customEntries"];
    for (uint i = 0; i < customEntries.Length; i++)
    {
        auto @entry = @deserializeLeaderboardEntry(customEntries[i]);
        state.m_CustomEntries.InsertLast(@entry);
    }
}

Json::Value serializeLeaderboardEntry(const LeaderboardEntry&in entry)
{
    auto entryObj = Json::Object();
    entryObj["id"] = entry.m_Id;
    entryObj["scoreNumber"] = entry.m_ScoreNumber;
    entryObj["sessionNumber"] = entry.m_SessionNumber;
    entryObj["type"] = entry.m_Type;
    entryObj["player"] = entry.m_PlayerName;
    entryObj["rank"] = entry.m_Rank;
    entryObj["time"] = entry.m_Time;
    entryObj["timeNoRespawn"] = entry.m_TimeNoRespawn;
    entryObj["numberRespawns"] = entry.m_NumberRespawns;
    entryObj["timestamp"] = entry.m_TimeStamp;
    entryObj["timeInTotal"] = entry.m_TimeInTotal;
    entryObj["timeInSession"] = entry.m_TimeInSession;
    entryObj["wasPersonalBest"] = entry.m_WasPersonalBest;
    entryObj["wasSessionBest"] = entry.m_WasSessionBest;

    auto checkpoints = Json::Array();
    for (uint i = 0; i < entry.m_Checkpoints.Length; i++)    {
        auto cpDataObj = serializeCheckpointData(entry.m_Checkpoints[i]);
        checkpoints.Add(cpDataObj);
    }
    entryObj["checkpoints"] = checkpoints;

    auto laps = Json::Array();
    for (uint i = 0; i < entry.m_Laps.Length; ++i)
    {
        auto lapDataObj = serializeLapData(entry.m_Laps[i]);
        laps.Add(lapDataObj);
    }
    entryObj["laps"] = laps;

    return entryObj;
}

LeaderboardEntry @deserializeLeaderboardEntry(const Json::Value&in entryObj)
{
    auto @entry = LeaderboardEntry();
    entry.m_Id = entryObj["id"];
    entry.m_ScoreNumber = entryObj["scoreNumber"];
    entry.m_SessionNumber = entryObj["sessionNumber"];
    int typeValue = entryObj["type"];
    entry.m_Type = LeaderboardEntryType(typeValue);
    entry.m_PlayerName = entryObj["player"];
    entry.m_Rank = entryObj["rank"];
    entry.m_Time = entryObj["time"];
    entry.m_TimeNoRespawn = entryObj["timeNoRespawn"];
    entry.m_NumberRespawns = entryObj["numberRespawns"];
    entry.m_TimeStamp = entryObj["timestamp"];
    entry.m_TimeInTotal = entryObj["timeInTotal"];
    entry.m_TimeInSession = entryObj["timeInSession"];
    entry.m_WasPersonalBest = entryObj["wasPersonalBest"];
    entry.m_WasSessionBest = entryObj["wasSessionBest"];

    for (uint i = 0; i < entryObj["checkpoints"].Length; i++)
    {
        auto cpDataObj = entryObj["checkpoints"][i];
        auto @cpData = @deserializeCheckpointData(cpDataObj);
        entry.m_Checkpoints.InsertLast(@cpData);
    }

    for (uint i = 0; i < entryObj["laps"].Length; ++i)
    {
        auto lapDataObj = entryObj["laps"][i];
        auto @lapData = @deserializeLapData(lapDataObj);
        entry.m_Laps.InsertLast(@lapData);
    }

    return @entry;
}

Json::Value serializeCheckpointData(const CheckpointData&in cpData)
{
    auto cpDataObj = Json::Object();
    cpDataObj["timeFromStart"] = cpData.m_TimeFromStart;
    cpDataObj["timeFromPrevious"] = cpData.m_TimeFromPrevious;
    cpDataObj["timeFromPreviousNoRespawn"] = cpData.m_TimeFromPreviousNoRespawn;
    cpDataObj["speed"] = cpData.m_Speed;
    cpDataObj["numberRespawns"] = cpData.m_NumberRespawns;
    return cpDataObj;
}

CheckpointData @deserializeCheckpointData(const Json::Value&in cpDataObj)
{
    auto @cpData = CheckpointData();
    cpData.m_TimeFromStart = cpDataObj["timeFromStart"];
    cpData.m_TimeFromPrevious = cpDataObj["timeFromPrevious"];
    cpData.m_TimeFromPreviousNoRespawn = cpDataObj["timeFromPreviousNoRespawn"];
    cpData.m_Speed = cpDataObj["speed"];
    cpData.m_NumberRespawns = cpDataObj["numberRespawns"];
    return @cpData;
}

Json::Value serializeLapData(const LapData&in lapData)
{
    auto lapDataObj = Json::Object();
    lapDataObj["timeFromStart"] = lapData.m_TimeFromStart;
    lapDataObj["timeFromPrevious"] = lapData.m_TimeFromPrevious;
    lapDataObj["timeFromPreviousNoRespawn"] = lapData.m_TimeFromPreviousNoRespawn;
    lapDataObj["numberRespawns"] = lapData.m_NumberRespawns;
    return lapDataObj;
}

LapData @deserializeLapData(const Json::Value&in lapDataObj)
{
    auto @lapData = LapData();
    lapData.m_TimeFromStart = lapDataObj["timeFromStart"];
    lapData.m_TimeFromPrevious = lapDataObj["timeFromPrevious"];
    lapData.m_TimeFromPreviousNoRespawn = lapDataObj["timeFromPreviousNoRespawn"];
    lapData.m_NumberRespawns = lapDataObj["numberRespawns"];
    return @lapData;
}

Json::Value serializeSettings()
{
    auto settingsObj = Json::Object();
    settingsObj["tableSettings"] = serializeTableSettings();
    return settingsObj;
}

void deserializeSettings(const Json::Value&in settingsObj)
{
    deserializeTableSettings(settingsObj["tableSettings"]);
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
    columnSettingsObj["pos"] = column.m_Pos;

    if (column.GetType() == TableColumnType::TimeDeltaColumn) {
        const TimeDeltaColumn @timeDeltaColumn = cast<TimeDeltaColumn>(column);
        if (timeDeltaColumn.m_ComparisonTarget !is null)
        {
            auto @target = @timeDeltaColumn.m_ComparisonTarget;
            columnSettingsObj["target"] = target.GetName();
            if (timeDeltaColumn.m_ComparisonTarget.GetType() == ComparisonTargetType::CustomEntry)
            {
                auto @customTarget = cast<CustomEntryComparisonTarget>(target);
                columnSettingsObj["targetEntryId"] = customTarget.m_CustomEntryId;
            }
        }
    }

    return columnSettingsObj;
}

void deserializeColumnSettings(TableColumn@ column, const Json::Value&in columnSettingsObj)
{
    column.m_Show = columnSettingsObj["show"];
    column.m_Pos = columnSettingsObj["pos"];

    if (column.GetType() == TableColumnType::TimeDeltaColumn) {
        TimeDeltaColumn @timeDeltaColumn = cast<TimeDeltaColumn>(column);
        const string target = columnSettingsObj["target"];
        auto @comparisonTarget = @GetComparisonTarget(target);
        @timeDeltaColumn.m_ComparisonTarget = @comparisonTarget;

        if (comparisonTarget.GetType() == ComparisonTargetType::CustomEntry)
        {
            auto @customTarget = cast<CustomEntryComparisonTarget>(comparisonTarget);
            customTarget.m_CustomEntryId = columnSettingsObj["targetEntryId"];
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

}

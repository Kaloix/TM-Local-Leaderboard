namespace LocalLeaderboard
{

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

    if (state.m_Leaderboard.m_TempNewestRun !is null)
    {
        leaderboard["tempNewestRun"] = serializeLeaderboardEntry(state.m_Leaderboard.m_TempNewestRun);
    }

    leaderboard["totalNumberFinishes"] = state.m_Leaderboard.m_TotalNumberFinishes;
    leaderboard["playerBestId"] = state.m_Leaderboard.m_PlayerBestId;
    leaderboard["playerBestTime"] = state.m_Leaderboard.m_PlayerBestTime;
    leaderboard["playerNewestId"] = state.m_Leaderboard.m_PlayerNewestId;
    leaderboard["playerNewestTime"] = state.m_Leaderboard.m_PlayerNewestTime;

    root["leaderboard"] = leaderboard;

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

    for (uint i = 0; i < entries.Length; i++)
    {
        auto entry = deserializeLeaderboardEntry(entries[i]);
        state.m_Leaderboard.AddEntry(entry);
    }

    if (leaderboard.HasKey("tempNewestRun"))
    {
        @state.m_Leaderboard.m_TempNewestRun = @deserializeLeaderboardEntry(leaderboard["tempNewestRun"]);
    }

    state.m_Leaderboard.m_TotalNumberFinishes = leaderboard["totalNumberFinishes"];
    state.m_Leaderboard.m_PlayerBestId = leaderboard["playerBestId"];
    state.m_Leaderboard.m_PlayerBestTime = leaderboard["playerBestTime"];
    state.m_Leaderboard.m_PlayerNewestId = leaderboard["playerNewestId"];
    state.m_Leaderboard.m_PlayerNewestTime = leaderboard["playerNewestTime"];
}

Json::Value serializeLeaderboardEntry(const LeaderboardEntry&in entry)
{
    auto entryObj = Json::Object();
    entryObj["scoreNumber"] = entry.m_ScoreNumber;
    entryObj["player"] = entry.m_PlayerName;
    entryObj["rank"] = entry.m_Rank;
    entryObj["time"] = entry.m_Time;
    entryObj["timeNoRespawn"] = entry.m_TimeNoRespawn;
    entryObj["numberRespawns"] = entry.m_NumberRespawns;
    entryObj["timestamp"] = entry.m_TimeStamp;
    return entryObj;
}

LeaderboardEntry deserializeLeaderboardEntry(const Json::Value&in entryObj)
{
    auto entry = LeaderboardEntry();
    entry.m_ScoreNumber = entryObj["scoreNumber"];
    entry.m_PlayerName = entryObj["player"];
    entry.m_Rank = entryObj["rank"];
    entry.m_Time = entryObj["time"];
    entry.m_TimeNoRespawn = entryObj["timeNoRespawn"];
    entry.m_NumberRespawns = entryObj["numberRespawns"];
    entry.m_TimeStamp = entryObj["timestamp"];
    return entry;
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

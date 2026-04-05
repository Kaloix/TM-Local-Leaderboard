
void Main()
{
    LocalLeaderboard::Init();
}

void OnEnabled()
{
    LocalLeaderboard::Init();
}

void OnDisabled()
{
    LocalLeaderboard::Shutdown();
}

void OnDestroyed()
{
    LocalLeaderboard::Shutdown();
}

void Update(float dt)
{
    LocalLeaderboard::Update(dt);
}

void OnSettingsChanged()
{
    LocalLeaderboard::InitRender();
    LocalLeaderboard::InitRows();
}

namespace LocalLeaderboard
{

State g_State = State();

void Init()
{
    InitRender();
    LogDebug("Local Leaderboard plugin initializing.");
}

void Shutdown()
{
    LogDebug("Local Leaderboard plugin shutting down.");
}

void Update(float dt)
{
    CGameCtnApp @app = GetApp();
    auto @map = @app.RootMap;
    const auto @raceData = @MLFeed::GetRaceData_V4();
    const auto @player = @raceData.GetPlayer_V4(MLFeed::LocalPlayersName);

    if (map is null || player is null)
    {
        // Wait for player being loaded
        if (g_State.m_CurrentMap != "")
            OnMapUnload();
        return;
    }

    auto currentMap = GetMapId();

    // Events for map loading and unloading
    if (g_State.m_CurrentMap == "")
    {
        if (currentMap != "")
        {
            LogDebug("Map loaded: " + currentMap);
            OnMapLoad();
        }
    }
    else
    {
        if (currentMap == "")
        {
            LogDebug("Map unloaded: " + g_State.m_CurrentMap);
            OnMapUnload();
        }
        else if (currentMap != g_State.m_CurrentMap)
        {
            LogDebug("Map changed from " + g_State.m_CurrentMap + " to " + currentMap);
            OnMapUnload();
            OnMapLoad();
        }
    }

    // Events for reaching checkpoints and finish
    const auto currentCp = player.CpCount;
    if (player.IsSpawned && currentCp != int(g_State.m_CurrentCheckpoints.Length))
    {
        if (currentCp == 0)
            OnRespawn();
        else
            OnReachingCheckpoint(currentCp);
    }

    // Events for player finishing
    if (g_State.m_IsPlayerFinishHandled && !player.IsFinished)
    {
        g_State.m_IsPlayerFinishHandled = false;
    }
    else if (!g_State.m_IsPlayerFinishHandled && player.IsFinished)
    {
        OnPlayerFinish();
        g_State.m_IsPlayerFinishHandled = true;
    }
}

void OnMapLoad()
{
    CGameCtnApp @app = GetApp();
    auto @map = @app.RootMap;

    g_State.m_CurrentMap = map.IdName;
    g_State.m_CurrentMapName = map.MapName;
    g_State.m_CurrentMapAuthor = map.AuthorNickName;

    InitializeMedals();
    InitializeComparisonTarget();

    LoadLeaderboard(g_State);

    addPreviousPb();

    g_State.m_Leaderboard.m_TotalNumberSessions++;

    addMedals();
    setMedals();
    InitRows();
}

void OnMapUnload()
{
    SaveLeaderboard(g_State);
    g_State = State();
}

void OnRespawn()
{
    g_State.m_CurrentCheckpoints.RemoveRange(0, g_State.m_CurrentCheckpoints.Length);
}

void OnReachingCheckpoint(int checkpoint)
{
    const auto @raceData = @MLFeed::GetRaceData_V4();
    const auto @player = @raceData.GetPlayer_V4(MLFeed::LocalPlayersName);

    auto time = player.cpTimes[checkpoint] - player.cpTimes[checkpoint - 1];

    CheckpointData @cpData = CheckpointData();
    g_State.m_CurrentCheckpoints.InsertLast(cpData);

    cpData.m_Speed = GetPlayerSpeed();
    cpData.m_TimeFromStart = player.cpTimes[checkpoint];
    cpData.m_TimeFromPrevious = time;
    cpData.m_TimeFromPreviousNoRespawn = time - player.TimeLostToRespawnByCp[checkpoint - 1];
    cpData.m_NumberRespawns = player.NbRespawnsByCp[checkpoint - 1];
}

void OnPlayerFinish()
{
    const auto @raceData = @MLFeed::GetRaceData_V4();
    const auto @player = @raceData.GetPlayer_V4(MLFeed::LocalPlayersName);

    if (player is null)
    {
        return;
    }

    g_State.m_Leaderboard.m_TotalNumberFinishes++;
    addNewRecord(player);
}

void addNewRecord(const MLFeed::PlayerCpInfo_V4 @player)
{
    g_State.m_Leaderboard.addNewestRun(player);
    InitRows();
    SaveLeaderboard(g_State);
}

void addPreviousPb()
{
    if (!settingDataAddPb || g_State.m_Leaderboard.m_Entries.Length > 0)
    {
        return;
    }

    const auto @raceData = @MLFeed::GetRaceData_V4();
    const auto @player = @raceData.GetPlayer_V4(MLFeed::LocalPlayersName);

    if (player.BestTime <= 0)
    {
        return;
    }

    g_State.m_Leaderboard.m_TotalNumberFinishes = 1;
    g_State.m_Leaderboard.m_TotalNumberSessions = 1;

    auto entry = LeaderboardEntry();
    entry.m_PlayerName = player.Name;
    entry.m_Time = player.BestTime;
    entry.m_ScoreNumber = 1;
    entry.m_SessionNumber = 1;
    g_State.m_Leaderboard.AddNewEntry(entry);
}

void addMedals()
{
    for (uint i = 0; i < g_Medals.Length; ++i)
    {
        Medal @medal = @g_Medals[i];
        auto medalEntry = LeaderboardEntry();
        medalEntry.m_Type = LeaderboardEntryType::Medal;
        @medalEntry.m_Medal = @medal;
        g_State.m_MedalEntries.InsertLast(medalEntry);
    }
}

void setMedals()
{
    for (uint i = 0; i < g_State.m_Leaderboard.m_Entries.Length; i++)
        setMedal(g_State.m_Leaderboard.m_Entries[i]);
    if (g_State.m_Leaderboard.m_NewestRun !is null)
        setMedal(g_State.m_Leaderboard.m_NewestRun);
    if (g_State.m_Leaderboard.m_FastestCopiumRun !is null)
        setMedal(g_State.m_Leaderboard.m_FastestCopiumRun);
    if (g_State.m_Leaderboard.m_BestCheckpointsRun !is null)
        setMedal(g_State.m_Leaderboard.m_BestCheckpointsRun);
    for (uint i = 0; i < g_State.m_CustomEntries.Length; i++)
        setMedal(g_State.m_CustomEntries[i]);
}

void setMedal(LeaderboardEntry&inout entry)
{
    for (uint i = 0; i < g_Medals.Length; i++)
    {
        const auto @medal = @g_Medals[i];
        if (entry.GetDisplayTime() <= medal.GetTime())
        {
            @entry.m_Medal = @medal;
            return;
        }
    }
    @entry.m_Medal = null;
}

class State
{
    /**
     * ID of the currently loaded map.
     * Empty string if no map is loaded or if the map doesn't have an ID (e.g. custom maps in Trackmania 2020).
     */
    string m_CurrentMap = "";
    string m_CurrentMapName = "";
    string m_CurrentMapAuthor = "";

    bool m_IsPlayerFinishHandled = true;
    array<CheckpointData @> m_CurrentCheckpoints;

    uint64 m_SessionStartTime = Time::get_Now();

    Leaderboard m_Leaderboard = Leaderboard();
    array<LeaderboardEntry @> m_MedalEntries;
    array<LeaderboardEntry @> m_CustomEntries;

    uint64 GetSessionTime() const
    {
        return Time::get_Now() - m_SessionStartTime;
    }

    void ResetData()
    {
        if (m_CurrentMap == "")
        {
            LogWarning("No map loaded, cannot reset leaderboard.");
            return;
        }

        LogInfo("Resetting leaderboard for map " + Text::StripFormatCodes(m_CurrentMapName));

        m_SessionStartTime = Time::get_Now();
        m_Leaderboard = Leaderboard();
        addPreviousPb();
        setMedals();
        InitRows();
        SaveLeaderboard(this);
    }

    void AddCustomEntry()
    {
        LeaderboardEntry newEntry;
        newEntry.m_Type = LeaderboardEntryType::CustomScore;
        newEntry.m_Time = 0;
        newEntry.m_PlayerName = "Custom Entry";
        setMedal(newEntry);
        m_CustomEntries.InsertLast(newEntry);

        InitRows();
        SaveLeaderboard(this);
    }

    void UpdateCustomEntryName(uint index, const string&in newName)
    {
        if (index >= m_CustomEntries.Length)
        {
            LogWarning("Custom entry index out of bounds: " + index);
            return;
        }

        m_CustomEntries[index].m_PlayerName = newName;

        SaveLeaderboard(this);
    }

    void UpdateCustomEntryTime(uint index, int newTime)
    {
        if (index >= m_CustomEntries.Length)
        {
            LogWarning("Custom entry index out of bounds: " + index);
            return;
        }

        m_CustomEntries[index].m_Time = newTime;
        setMedal(m_CustomEntries[index]);

        InitRows();
        SaveLeaderboard(this);
    }

    void RemoveCustomEntry(uint index)
    {
        if (index >= m_CustomEntries.Length)
        {
            LogWarning("Custom entry index out of bounds: " + index);
            return;
        }

        m_CustomEntries.RemoveAt(index);

        InitRows();
        SaveLeaderboard(this);
    }
}

}

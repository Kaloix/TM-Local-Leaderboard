
void Main()
{
    LocalRecords::Init();
}

void OnEnabled()
{
    LocalRecords::Init();
}

void OnDisabled()
{
    LocalRecords::Shutdown();
}

void OnDestroyed()
{
    LocalRecords::Shutdown();
}

void Update(float dt)
{
    LocalRecords::Update(dt);
}

void OnSettingsChanged()
{
    LocalRecords::OnSettingsChanged();
}

namespace LocalRecords
{

int MAX_INT = 2147483647;

State g_State = State();

void Init()
{
    InitNadeoApi();
    InitHooks();

    InitializeMedals();
    InitializeComparisonTarget();
    initializeTableColumns();

    loadSettings();
    InitRender();
    LogDebug("Local Records plugin initializing.");

    if (!Permissions::ViewRecords())
    {
        UI::ShowNotification(Icons::ExclamationTriangle + "Local Records", "Not allowed to view records, Global records are disabled.", vec4(1.0, 0.6, 0.0, 1.0));
    }

}

void Shutdown()
{
    UnloadHooks();
    LogDebug("Local Records plugin shutting down.");
}

void OnSettingsChanged()
{
    saveSettings();
    InitRender();
    InitRows();
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

    // Update leaderboard time
    g_State.m_Leaderboard.updateTime();

    // Events for starting a new run
    const auto startTime = player.StartTime;
    if (startTime != g_State.m_CurrentStartTime)
    {
        g_State.m_CurrentStartTime = startTime;
        g_State.m_LastStartTime = Time::get_Now() - player.CurrentRaceTimeRaw;
        g_State.m_LastCpReached = Time::get_Now() - player.CurrentRaceTimeRaw;
        g_State.m_LastRespawn = Time::get_Now() - player.CurrentRaceTimeRaw;
        OnStart();
    }

    // Events for respawning
    const auto respawnTime = player.LastRespawnRaceTime;
    if (respawnTime != g_State.m_CurrentRespawnTime)
    {
        g_State.m_CurrentRespawnTime = respawnTime;
        g_State.m_LastRespawn = g_State.m_LastCpReached + player.TimeLostToRespawnByCp[player.CpCount];
    }

    // Events for reaching checkpoints, starting is not handled here
    const auto currentCp = player.CpCount;
    if (player.IsSpawned && currentCp != int(g_State.m_CurrentCheckpoints.Length) && currentCp != 0)
    {
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
    const auto @raceData = @MLFeed::GetRaceData_V4();

    g_State.m_CurrentMap = map.IdName;
    g_State.m_CurrentMapName = map.MapName;
    g_State.m_CurrentMapAuthor = map.AuthorNickName;
    g_State.m_CurrentMapCpCount = raceData.CpCount;
    g_State.m_CurrentMapLapCount = raceData.LapCount;

    LoadLeaderboard(g_State);

    addPreviousPb();
    InitPersonalBestAsync();

    g_State.m_Leaderboard.m_TotalNumberSessions++;

    addMedals();
    setMedals();

    InitRows();

    GetNumberGlobalPositions();
    GetAtCpTimes();
    InitLiveDataAsync();
}

void OnMapUnload()
{
    SaveLeaderboard(g_State);
    g_State = State();
}

void OnStart()
{
    g_State.m_CurrentCheckpoints.RemoveRange(0, g_State.m_CurrentCheckpoints.Length);
    g_State.m_CurrentLaps.RemoveRange(0, g_State.m_CurrentLaps.Length);

    const LeaderboardEntry @comparisonTarget = @(cast<TimeDeltaColumn>(GetTableColumnByType(TableColumnType::TimeDeltaColumn))).m_ComparisonTarget.GetComparisonTargetEntry();
    g_State.m_CurrentRunComparisonCheckpoints = comparisonTarget !is null ? comparisonTarget.m_Checkpoints : array<CheckpointData@>();
}

void OnReachingCheckpoint(int checkpoint)
{
    const auto @raceData = @MLFeed::GetRaceData_V4();
    const auto @player = @raceData.GetPlayer_V4(MLFeed::LocalPlayersName);

    g_State.m_LastCpReached = Time::get_Now(); 
    g_State.m_LastRespawn = g_State.m_LastCpReached;

    // Add CP
    auto time = player.cpTimes[checkpoint] - player.cpTimes[checkpoint - 1];

    CheckpointData @cpData = CheckpointData();
    g_State.m_CurrentCheckpoints.InsertLast(cpData);

    cpData.m_Speed = GetPlayerSpeed();
    cpData.m_TimeFromStart = player.cpTimes[checkpoint];
    cpData.m_TimeFromPrevious = time;
    cpData.m_TimeFromPreviousNoRespawn = time - player.TimeLostToRespawnByCp[checkpoint - 1];
    cpData.m_NumberRespawns = player.NbRespawnsByCp[checkpoint - 1];

    AddLap(checkpoint, cpData, g_State.m_CurrentCheckpoints, g_State.m_CurrentLaps);
}

void AddLap(const int checkpointIndex, const CheckpointData&in currentCp, const array<CheckpointData@>&in checkpoints, array<LapData@>&inout laps)
{
    if (checkpointIndex % (g_State.m_CurrentMapCpCount + 1) == 0)
    {
        LapData @lapData = LapData();
        lapData.m_TimeFromStart = currentCp.m_TimeFromStart;

        for (uint i = (g_State.m_CurrentMapCpCount + 1) * laps.Length; i < checkpoints.Length; ++i)
        {
            lapData.m_TimeFromPrevious += checkpoints[i].m_TimeFromPrevious;
            lapData.m_TimeFromPreviousNoRespawn += checkpoints[i].m_TimeFromPreviousNoRespawn;
            lapData.m_NumberRespawns += checkpoints[i].m_NumberRespawns;
        }

        laps.InsertLast(lapData);
    }
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
    g_State.m_Leaderboard.m_TotalNumberSessionFinishes++;
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

        if (medal.GetTime() <= 0) {
            LogDebug("No time for medal " + medal.GetName());
            continue;
        }

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
    for (uint i = 0; i < g_State.m_CustomTimeEntries.Length; i++)
        setMedal(g_State.m_CustomTimeEntries[i]);
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

void GetNumberGlobalPositions()
{
#if DEPENDENCY_MAPINFO
    LogDebug("Using Map Info for determining number of players");
    g_State.m_NumberGlobalPositions = MapInfo::GetCurrentMapInfo().NbPlayers;
#else
    LogDebug("No plugin for determining number of players");
#endif
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
    uint m_CurrentMapCpCount = 0;
    uint m_CurrentMapLapCount = 0;

    int m_NumberGlobalPositions = -1;

    bool m_IsPlayerFinishHandled = true;
    array<CheckpointData @> m_CurrentCheckpoints;
    array<LapData @> m_CurrentLaps;
    uint64 m_CurrentStartTime = 0;
    uint64 m_CurrentRespawnTime = 0;
    uint64 m_LastStartTime = 0;
    uint64 m_LastCpReached = 0;
    uint64 m_LastRespawn = 0;

    // Cache the comparison checkpoints for the current run to prevent overwriting after the run is finished and the leaderboard is updated
    array<CheckpointData @> m_CurrentRunComparisonCheckpoints;

    uint64 m_SessionStartTime = Time::get_Now();

    Leaderboard m_Leaderboard = Leaderboard();
    array<LeaderboardEntry @> m_MedalEntries;
    array<LeaderboardEntry @> m_CustomTimeEntries;
    array<LeaderboardEntry @> m_CustomPositionEntries;

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

    LeaderboardEntry@ GetMedalEntry(MedalType medal)
    {
        for (uint i = 0; i < m_MedalEntries.Length; ++i)
        {
            if (m_MedalEntries[i].m_Medal.GetType() == medal)
                return m_MedalEntries[i];
        }
        return null;
    }

    void AddCustomTimeEntry()
    {
        LeaderboardEntry newEntry;
        newEntry.m_Type = LeaderboardEntryType::CustomTime;
        newEntry.m_PlayerName = "Custom Time " + (m_CustomTimeEntries.Length + 1);
        m_CustomTimeEntries.InsertLast(newEntry);

        InitRows();
        SaveLeaderboard(this);
    }

    LeaderboardEntry@ GetCustomTime(const int64 id)
    {
        for (uint i = 0; i < m_CustomTimeEntries.Length; ++i)
        {
            LeaderboardEntry@ entry = @m_CustomTimeEntries[i];
            if (entry.m_Id == id)
            {
                return entry;
            }
        }
        return null;
    }

    void UpdateCustomTimeEntryName(uint index, const string&in newName)
    {
        if (index >= m_CustomTimeEntries.Length)
        {
            LogWarning("Custom time entry index out of bounds: " + index);
            return;
        }

        m_CustomTimeEntries[index].m_PlayerName = newName;

        SaveLeaderboard(this);
    }

    void UpdateCustomTimeEntryTime(uint index, int newTime)
    {
        if (index >= m_CustomTimeEntries.Length)
        {
            LogWarning("Custom time entry index out of bounds: " + index);
            return;
        }

        m_CustomTimeEntries[index].m_Time = newTime;
        setMedal(m_CustomTimeEntries[index]);

        InitRows();
        SaveLeaderboard(this);

        InitPositionForEntryAsync(@m_CustomTimeEntries[index]);
    }

    void RemoveCustomTimeEntry(uint index)
    {
        if (index >= m_CustomTimeEntries.Length)
        {
            LogWarning("Custom time entry index out of bounds: " + index);
            return;
        }

        m_CustomTimeEntries.RemoveAt(index);

        InitRows();
        SaveLeaderboard(this);
    }

    void AddCustomPositionEntry()
    {
        LeaderboardEntry newEntry;
        newEntry.m_Type = LeaderboardEntryType::CustomPosition;
        newEntry.m_PlayerName = "Custom Pos " + (m_CustomPositionEntries.Length + 1);
        newEntry.m_GlobalPosition = 1;

        m_CustomPositionEntries.InsertLast(newEntry);

        saveSettings();

        InitTimeForEntryAsync(@newEntry);
    }

    LeaderboardEntry@ GetCustomPosition(const int64 id)
    {
        for (uint i = 0; i < m_CustomPositionEntries.Length; ++i)
        {
            LeaderboardEntry@ entry = @m_CustomPositionEntries[i];
            if (entry.m_Id == id)
            {
                return entry;
            }
        }
        return null;
    }

    void UpdateCustomPositionEntryName(uint index, const string&in newName)
    {
        if (index >= m_CustomPositionEntries.Length)
        {
            LogWarning("Custom position entry index out of bounds: " + index);
            return;
        }

        m_CustomPositionEntries[index].m_PlayerName = newName;

        saveSettings();
    }

    void UpdateCustomPositionEntryPosition(uint index, int newPosition)
    {
        if (index >= m_CustomPositionEntries.Length)
        {
            LogWarning("Custom position entry index out of bounds: " + index);
            return;
        }

        m_CustomPositionEntries[index].m_GlobalPosition = newPosition;

        saveSettings();

        InitTimeForEntryAsync(@m_CustomPositionEntries[index]);
    }

    void RemoveCustomPositionEntry(uint index)
    {
        if (index >= m_CustomPositionEntries.Length)
        {
            LogWarning("Custom position entry index out of bounds: " + index);
            return;
        }

        m_CustomPositionEntries.RemoveAt(index);

        InitRows();
        saveSettings();
    }

}

}

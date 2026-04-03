
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
}

/**
 * Gets the current map's unique identifier. Returns an empty string if no map is loaded.
 */
string GetMapId()
{
    CGameCtnApp @app = GetApp();
    if (app.RootMap is null)
    {
        return "";
    }

    return app.RootMap.IdName;
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
}

class Leaderboard
{
    array<LeaderboardEntry @> m_Entries;
    LeaderboardEntry @m_NewestRun = null;
    LeaderboardEntry @m_FastestRun = null;
    LeaderboardEntry @m_SessionFastestRun = null;

    LeaderboardEntry @m_NewestCopiumRun = null;
    LeaderboardEntry @m_FastestCopiumRun = null;
    LeaderboardEntry @m_SessionFastestCopiumRun = null;

    LeaderboardEntry @m_BestCheckpointsRun = null;
    LeaderboardEntry @m_SessionBestCheckpointsRun = null;

    uint m_TotalNumberFinishes = 0;
    uint m_TotalNumberSessions = 0;

    uint64 m_TotalTime = 0;
    uint64 m_LastUpdated = Time::get_Now();

    LeaderboardEntry @getLastPlayerEntry()
    {
        return @m_Entries[m_Entries.Length];
    }

    LeaderboardEntry @createNewEntry(const MLFeed::PlayerCpInfo_V4 @player) const
    {
        auto @entry = LeaderboardEntry();
        entry.m_PlayerName = player.Name;
        entry.m_Time = player.FinishTime;
        entry.m_TimeNoRespawn = (player.FinishTime - player.TimeLostToRespawns);
        entry.m_NumberRespawns = player.RespawnTimes.Length;
        entry.m_TimeStamp = Time::get_Stamp();

        entry.m_ScoreNumber = m_TotalNumberFinishes;
        entry.m_SessionNumber = m_TotalNumberSessions;

        entry.m_TimeInTotal = m_TotalTime;
        entry.m_TimeInSession = g_State.GetSessionTime();

        auto @cpTimes = @player.CpTimes;
        for (uint i = 1; i < cpTimes.Length; i++)
        {
            auto time = player.cpTimes[i] - player.cpTimes[i - 1];
            CheckpointData @cpData = CheckpointData();
            cpData.m_TimeFromStart = player.cpTimes[i];
            cpData.m_TimeFromPrevious = time;
            cpData.m_TimeFromPreviousNoRespawn = time - player.TimeLostToRespawnByCp[i - 1];
            cpData.m_NumberRespawns = player.NbRespawnsByCp[i - 1];
            entry.m_Checkpoints.InsertLast(@cpData);
        }

        setMedal(entry);

        return @entry;
    }

    void addNewestRun(const MLFeed::PlayerCpInfo_V4 @player)
    {
        updateTime();

        @m_NewestRun = @createNewEntry(player);
        if (m_NewestRun.m_NumberRespawns > 0)
        {
            @m_NewestCopiumRun = LeaderboardEntry(m_NewestRun);
            m_NewestCopiumRun.m_Type = LeaderboardEntryType::ScoreCopium;
            setMedal(m_NewestCopiumRun);
        }
        else
        {
            @m_NewestCopiumRun = null;
        }

        if (g_State.m_Leaderboard.m_Entries.Length < settingDataRecordLimit)
        {
            AddNewEntry(@m_NewestRun);
        }
        else
        {
            if (player.FinishTime < m_Entries[m_Entries.Length - 1].m_Time)
            {
                RemoveLastPlayerEntry();
                AddNewEntry(@m_NewestRun);
            }
            else
            {
                m_NewestRun.m_Rank = m_Entries.Length + 1;
            }
        }

        updateBestCheckpointsRun(m_NewestRun);
    }

    void AddNewEntry(LeaderboardEntry @entry)
    {
        AddEntry(@entry);

        if (m_FastestRun is null || entry.m_Time < m_FastestRun.m_Time)
        {
            entry.m_WasPersonalBest = true;
            @m_FastestRun = @entry;

            if (m_FastestCopiumRun !is null && m_FastestRun.m_Time <= m_FastestCopiumRun.m_TimeNoRespawn)
            {
                @m_FastestCopiumRun = null;
            }
        }
        if (m_SessionFastestRun is null || entry.m_Time < m_SessionFastestRun.m_Time)
        {
            if (m_SessionFastestRun !is null)
                m_SessionFastestRun.m_WasSessionBest = false;
            entry.m_WasSessionBest = true;
            @m_SessionFastestRun = @entry;

            if (m_SessionFastestCopiumRun !is null && m_SessionFastestRun.m_Time <= m_SessionFastestCopiumRun.m_TimeNoRespawn)
            {
                @m_SessionFastestCopiumRun = null;
            }
        }

        if (entry.m_NumberRespawns > 0 && entry.m_TimeNoRespawn < m_FastestRun.m_Time && (m_FastestCopiumRun is null || entry.m_TimeNoRespawn < m_FastestCopiumRun.m_TimeNoRespawn))
        {
            @m_FastestCopiumRun = LeaderboardEntry(entry);
            m_FastestCopiumRun.m_Type = LeaderboardEntryType::ScoreCopium;
            setMedal(m_FastestCopiumRun);
        }
        if (entry.m_NumberRespawns > 0 && entry.m_TimeNoRespawn < m_SessionFastestRun.m_Time && (m_SessionFastestCopiumRun is null || entry.m_TimeNoRespawn < m_SessionFastestCopiumRun.m_TimeNoRespawn))
        {
            @m_SessionFastestCopiumRun = LeaderboardEntry(entry);
            m_SessionFastestCopiumRun.m_Type = LeaderboardEntryType::ScoreCopium;
            setMedal(m_SessionFastestCopiumRun);
        }
    }

    void AddEntry(LeaderboardEntry @entry)
    {
        uint rank = 1;
        uint i = 0;
        bool inserted = false;
        for (; i < m_Entries.Length; i++)
        {
            if (entry.m_Time < m_Entries[i].m_Time)
            {
                entry.m_Rank = rank;
                m_Entries.InsertAt(i, entry);
                inserted = true;
                break;
            }
            rank++;
        }

        if (!inserted)
        {
            entry.m_Rank = rank;
            m_Entries.InsertLast(entry);
        }
        else
        {
            i++;
            for (; i < m_Entries.Length; i++)
            {
                m_Entries[i].m_Rank++;
            }
        }
    }

    void RemoveLastPlayerEntry()
    {
        m_Entries.RemoveLast();
    }

    void updateTime()
    {
        const auto updateTime = Time::get_Now();
        const auto timeSinceLastUpdate = updateTime - m_LastUpdated;
        m_LastUpdated = updateTime;

        m_TotalTime += timeSinceLastUpdate;
    }

    void updateBestCheckpointsRun(const LeaderboardEntry&in entry)
    {
        if (m_BestCheckpointsRun is null)
            @m_BestCheckpointsRun = LeaderboardEntry();
        updateCheckpointsRun(m_BestCheckpointsRun, entry);

        if (m_SessionBestCheckpointsRun is null)
            @m_SessionBestCheckpointsRun = LeaderboardEntry();
        updateCheckpointsRun(m_SessionBestCheckpointsRun, entry);
    }

    private void updateCheckpointsRun(LeaderboardEntry &inout checkpointsRun, const LeaderboardEntry&in entry) const
    {
        bool hasNewBestCheckpoint = false;

        if (checkpointsRun.m_Checkpoints.Length == 0)
        {
            checkpointsRun.m_PlayerName = entry.m_PlayerName;
            checkpointsRun.m_Type = LeaderboardEntryType::ScoreBestCheckpoints;

            for (uint i = 0; i < entry.m_Checkpoints.Length; i++)
            {
                CheckpointData @cpData = CheckpointData();
                cpData.m_TimeFromPrevious = entry.m_Checkpoints[i].m_TimeFromPrevious;
                cpData.m_TimeFromPreviousNoRespawn = entry.m_Checkpoints[i].m_TimeFromPreviousNoRespawn;
                cpData.m_NumberRespawns = entry.m_Checkpoints[i].m_NumberRespawns;
                checkpointsRun.m_Checkpoints.InsertLast(@cpData);
            }

            hasNewBestCheckpoint = true;
        }
        else
        {
            for (uint i = 0; i < entry.m_Checkpoints.Length; i++)
            {
                if (entry.m_Checkpoints[i].m_TimeFromPreviousNoRespawn < checkpointsRun.m_Checkpoints[i].m_TimeFromPreviousNoRespawn)
                {
                    checkpointsRun.m_Checkpoints[i].m_TimeFromPrevious = entry.m_Checkpoints[i].m_TimeFromPrevious;
                    checkpointsRun.m_Checkpoints[i].m_TimeFromPreviousNoRespawn = entry.m_Checkpoints[i].m_TimeFromPreviousNoRespawn;
                    checkpointsRun.m_Checkpoints[i].m_NumberRespawns = entry.m_Checkpoints[i].m_NumberRespawns;
                    hasNewBestCheckpoint = true;
                }
            }
        }

        if (hasNewBestCheckpoint)
        {
            checkpointsRun.m_TimeStamp = entry.m_TimeStamp;
            checkpointsRun.m_ScoreNumber = entry.m_ScoreNumber;
            checkpointsRun.m_SessionNumber = entry.m_SessionNumber;

            checkpointsRun.m_Time = 0;
            for (uint i = 0; i < checkpointsRun.m_Checkpoints.Length; i++)
            {
                checkpointsRun.m_Time += checkpointsRun.m_Checkpoints[i].m_TimeFromPreviousNoRespawn;
            }

            setMedal(checkpointsRun);
        }
    }
}

class LeaderboardEntry
{
    uint m_ScoreNumber = 0;
    uint m_SessionNumber = 0;
    LeaderboardEntryType m_Type = LeaderboardEntryType::Score;

    uint64 m_TimeInSession = 0;
    uint64 m_TimeInTotal = 0;

    string m_PlayerName = "";

    /**
     * The highest medal achieved with this run.
     * Can be null if the run was too slow for any medal.
     */
    const Medal @m_Medal = null;

    uint m_Rank = 0;

    int64 m_TimeStamp = 0;
    int m_Time = 0;
    int m_TimeNoRespawn = 0;
    uint m_NumberRespawns = 0;

    array<CheckpointData @> m_Checkpoints;

    bool m_WasPersonalBest = false;
    bool m_WasSessionBest = false;

    string GetDisplayRank() const
    {
        switch (m_Type)
        {
            case LeaderboardEntryType::Medal:
                return "";
            case LeaderboardEntryType::Score:
                return "" + m_Rank;
            case LeaderboardEntryType::ScoreBestCheckpoints:
            case LeaderboardEntryType::ScoreCopium:
                return "-";
            default:
                return "";
        }
    }

    string GetDisplayIcon() const
    {
        switch (m_Type)
        {
            case LeaderboardEntryType::Medal:
                return Icons::Circle;
            case LeaderboardEntryType::Score:
                return Icons::CircleO;
            case LeaderboardEntryType::ScoreBestCheckpoints:
                return Icons::AngleDoubleUp;
            case LeaderboardEntryType::ScoreCopium:
                return Icons::ArrowCircleOUp;
            default:
                return "";
        }
    }

    int GetDisplayTime() const
    {
        switch (m_Type)
        {
            case LeaderboardEntryType::Medal:
                return m_Medal.GetTime();
            case LeaderboardEntryType::Score:
            case LeaderboardEntryType::ScoreBestCheckpoints:
                return m_Time;
            case LeaderboardEntryType::ScoreCopium:
                return m_TimeNoRespawn;
            default:
                return 0;
        }
    }

    string GetDisplayName() const
    {
        switch (m_Type)
        {
            case LeaderboardEntryType::Medal:
                return m_Medal.GetName();
            case LeaderboardEntryType::Score:
                return m_PlayerName;
            case LeaderboardEntryType::ScoreBestCheckpoints:
                return m_PlayerName + " (Best Checkpoints)";
            case LeaderboardEntryType::ScoreCopium:
                return m_PlayerName + " (Copium)";
            default:
                return "";
        }
    }
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

    uint64 m_SessionStartTime = Time::get_Now();

    Leaderboard m_Leaderboard = Leaderboard();
    array<LeaderboardEntry @> m_MedalEntries;

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
}

class CheckpointData
{
    int m_TimeFromStart = 0;
    int m_TimeFromPrevious = 0;
    int m_TimeFromPreviousNoRespawn = 0;
    int m_NumberRespawns = 0;
}

enum LeaderboardEntryType
{
    Medal,
    Score,
    ScoreBestCheckpoints,
    ScoreCopium,
}

}

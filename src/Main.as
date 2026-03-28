
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
    addMedals();

    // Set medals of already existing entries
    for (uint i = 0; i < g_State.m_Leaderboard.m_Entries.Length; i++)
    {
        setMedal(g_State.m_Leaderboard.m_Entries[i]);
    }
    if (g_State.m_Leaderboard.m_NewestRun !is null)
        setMedal(g_State.m_Leaderboard.m_NewestRun);
    if (g_State.m_Leaderboard.m_FastestCopiumRun !is null)
        setMedal(g_State.m_Leaderboard.m_FastestCopiumRun);

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

    auto entry = LeaderboardEntry();
    entry.m_PlayerName = player.Name;
    entry.m_Time = player.BestTime;
    entry.m_ScoreNumber = 1;
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

    LeaderboardEntry @m_FastestCopiumRun = null;

    uint m_TotalNumberFinishes = 0;

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
        setMedal(entry);

        return @entry;
    }

    void addNewestRun(const MLFeed::PlayerCpInfo_V4 @player)
    {
        @m_NewestRun = @createNewEntry(player);

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
    }

    void AddNewEntry(LeaderboardEntry @entry)
    {
        AddEntry(@entry);

        if (m_FastestRun is null ||  entry.m_Time < m_FastestRun.m_Time)
        {
            @m_FastestRun = @entry;

            if (m_FastestCopiumRun !is null && m_FastestRun.m_Time <= m_FastestCopiumRun.m_Time)
            {
                @m_FastestCopiumRun = null;
            }
        }
        if (entry.m_NumberRespawns > 0 && entry.m_TimeNoRespawn < m_FastestRun.m_Time && (m_FastestCopiumRun is null || entry.m_TimeNoRespawn < m_FastestCopiumRun.m_TimeNoRespawn))
        {
            @m_FastestCopiumRun = LeaderboardEntry(entry);
            m_FastestCopiumRun.m_Type = LeaderboardEntryType::ScoreCopium;
            setMedal(m_FastestCopiumRun);
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
                LogInfo("" + m_Entries[i].m_Rank);
                m_Entries[i].m_Rank++;
            }
        }
    }

    void RemoveLastPlayerEntry()
    {
        m_Entries.RemoveLast();
    }
}

class LeaderboardEntry
{
    uint m_ScoreNumber = 0;
    LeaderboardEntryType m_Type = LeaderboardEntryType::Score;

    string m_PlayerName = "";

    const Medal@ m_Medal =  null;

    uint m_Rank = 0;

    int64 m_TimeStamp = 0;
    int m_Time = 0;
    int m_TimeNoRespawn = 0;
    uint m_NumberRespawns = 0;

    string GetDisplayRank() const
    {
        switch (m_Type)
        {
            case LeaderboardEntryType::Medal: return "";
            case LeaderboardEntryType::Score: return "" + m_Rank;
            case LeaderboardEntryType::ScoreCopium: return "-";
            default: return "";
        }
    }

    string GetDisplayIcon() const {
        switch (m_Type)
        {
            case LeaderboardEntryType::Medal: return Icons::Circle;
            case LeaderboardEntryType::Score: return Icons::CircleO;
            case LeaderboardEntryType::ScoreCopium: return Icons::ArrowCircleOUp;
            default: return "";
        }
    }

    int GetDisplayTime() const {
        switch (m_Type)
        {
            case LeaderboardEntryType::Medal: return m_Medal.GetTime();
            case LeaderboardEntryType::Score: m_Time;
            case LeaderboardEntryType::ScoreCopium: return m_TimeNoRespawn;
            default: return 0;
        }
    }

    string GetDisplayName() const {
        return m_Type == LeaderboardEntryType::Medal ? m_Medal.GetName() : m_PlayerName;
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

    Leaderboard m_Leaderboard = Leaderboard();
    array<LeaderboardEntry @> m_MedalEntries;
}

enum LeaderboardEntryType
{
    Medal,
    Score,
    ScoreCopium,
}

}


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
    const auto @raceData = @MLFeed::GetRaceData_V4();
    const auto @player = @raceData.GetPlayer_V4(MLFeed::LocalPlayersName);

    if (player is null)
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

    LoadLeaderboard(g_State);

    addPreviousPb();
    addMedals(map);

    // Set medals of already existing entries
    for (uint i = 0; i < g_State.m_Leaderboard.m_Entries.Length; i++)
    {
        setMedal(g_State.m_Leaderboard.m_Entries[i]);
    }
    if (g_State.m_Leaderboard.m_NewestRun !is null)
    {
        setMedal(g_State.m_Leaderboard.m_NewestRun);
    }

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

    if (player.BestTime == 0)
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

void addMedals(CGameCtnChallenge&inout map)
{
#if DEPENDENCY_CHAMPIONMEDALS
    auto championTime = ChampionMedals::GetCMTime();
    if (championTime > 0)
    {
        auto medalChampion = LeaderboardEntry();
        medalChampion.m_Type = LeaderboardEntryType::Medal;
        medalChampion.m_Medal = "Champion";
        medalChampion.m_PlayerName = "Champion";
        medalChampion.m_IconColor = vec3(0xf8 / 255.0f, 0x4a / 255.0f, 0x6e / 255.0f);
        medalChampion.m_Time = ChampionMedals::GetCMTime();
        g_State.m_MedalEntries.InsertLast(medalChampion);
        // g_State.m_Leaderboard.AddEntry(medalChampion);
    }
#endif
#if DEPENDENCY_WARRIORMEDALS
    auto warriorTime = WarriorMedals::GetWMTime();
    if (warriorTime > 0)
    {
        auto medalWarrior = LeaderboardEntry();
        medalWarrior.m_Type = LeaderboardEntryType::Medal;
        medalWarrior.m_Medal = "Warrior";
        medalWarrior.m_PlayerName = "Warrior";
        medalWarrior.m_IconColor = WarriorMedals::GetColorWarriorVec();
        medalWarrior.m_Time = WarriorMedals::GetWMTime();
        g_State.m_MedalEntries.InsertLast(medalWarrior);
    }
#endif

    auto medalAt = LeaderboardEntry();
    medalAt.m_Type = LeaderboardEntryType::Medal;
    medalAt.m_Medal = "Author";
    medalAt.m_PlayerName = "AT";
    medalAt.m_IconColor = vec3(0, 0x77 / 255.0f, 0x11 / 255.0f);
    medalAt.m_Time = map.MapInfo.TMObjective_AuthorTime;
    g_State.m_MedalEntries.InsertLast(medalAt);

    auto medalGold = LeaderboardEntry();
    medalGold.m_Type = LeaderboardEntryType::Medal;
    medalGold.m_Medal = "Gold";
    medalGold.m_PlayerName = "Gold";
    medalGold.m_IconColor = vec3(0xDD / 255.0f, 0xBB / 255.0f, 0x44 / 255.0f);
    medalGold.m_Time = map.MapInfo.TMObjective_GoldTime;
    g_State.m_MedalEntries.InsertLast(medalGold);

    auto medalSilver = LeaderboardEntry();
    medalSilver.m_Type = LeaderboardEntryType::Medal;
    medalSilver.m_Medal = "Silver";
    medalSilver.m_PlayerName = "Silver";
    medalSilver.m_IconColor = vec3(0x88 / 255.0f, 0x99 / 255.0f, 0x99 / 255.0f);
    medalSilver.m_Time = map.MapInfo.TMObjective_SilverTime;
    g_State.m_MedalEntries.InsertLast(medalSilver);

    auto medalBronze = LeaderboardEntry();
    medalBronze.m_Type = LeaderboardEntryType::Medal;
    medalBronze.m_Medal = "Bronze";
    medalBronze.m_PlayerName = "Bronze";
    medalBronze.m_IconColor = vec3(0x99 / 255.0f, 0x66 / 255.0f, 0x44 / 255.0f);
    medalBronze.m_Time = map.MapInfo.TMObjective_BronzeTime;
    g_State.m_MedalEntries.InsertLast(medalBronze);
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
    for (uint i = 0; i < g_State.m_MedalEntries.Length; i++)
    {
        const auto @medalEntry = @g_State.m_MedalEntries[i];
        if (entry.m_Time <= medalEntry.m_Time)
        {
            entry.m_Medal = medalEntry.m_Medal;
            entry.m_IconColor = medalEntry.m_IconColor;
            return;
        }
    }
}

class Leaderboard
{
    array<LeaderboardEntry @> m_Entries;
    LeaderboardEntry @m_NewestRun = null;

    uint m_TotalNumberFinishes = 0;

    uint m_PlayerBestId = 0;
    int m_PlayerBestTime = -1;

    LeaderboardEntry @getLastPlayerEntry()
    {
        return @m_Entries[m_Entries.Length];
    }

    LeaderboardEntry @createNewEntry(const MLFeed::PlayerCpInfo_V4 @player)
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
        AddEntry(entry);

        if (entry.m_Time < m_PlayerBestTime || m_PlayerBestTime == -1)
        {
            m_PlayerBestId = entry.m_ScoreNumber;
            m_PlayerBestTime = entry.m_Time;
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
    string m_Medal = "";

    uint m_Rank = 0;

    vec3 m_IconColor = vec3(1, 1, 1);

    int64 m_TimeStamp = 0;
    int m_Time = 0;
    int m_TimeNoRespawn = 0;
    uint m_NumberRespawns = 0;
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
}

}

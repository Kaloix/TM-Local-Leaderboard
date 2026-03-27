
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

    auto raceData = MLFeed::GetRaceData_V4();
    auto player = raceData.GetPlayer_V4(MLFeed::LocalPlayersName);
    if (player !is null)
    {
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

    g_State.m_Leaderboard.RemoveTemporaryLast();
    g_State.m_Leaderboard.m_TotalNumberFinishes++;

    if (g_State.m_Leaderboard.m_NumberPlayerScores < settingDataRecordLimit)
    {
        addNewRecord(player, false);
    }
    else
    {
        const LeaderboardEntry @lastEntry = @g_State.m_Leaderboard.getLastPlayerEntry();
        if (lastEntry !is null && player.FinishTime < lastEntry.m_Time)
        {
            g_State.m_Leaderboard.RemoveLastPlayerEntry();
            addNewRecord(player, false);
        }
        else
        {
            addNewRecord(player, true);
        }
    }
}

void addNewRecord(const MLFeed::PlayerCpInfo_V4 @player, bool temporary)
{
    auto entry = LeaderboardEntry();
    entry.m_PlayerName = player.Name;
    entry.m_Time = player.FinishTime;
    entry.m_TimeStamp = Time::get_Stamp();

    g_State.m_Leaderboard.AddNewEntry(entry, temporary);

    SaveLeaderboard(g_State);
}

void addPreviousPb()
{
    if (!settingDataAddPb || g_State.m_Leaderboard.m_NumberPlayerScores > 0)
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
    g_State.m_Leaderboard.AddNewEntry(entry, false);
}

void addMedals(CGameCtnChallenge&inout map)
{
    auto medalAt = LeaderboardEntry();
    medalAt.m_Type = LeaderboardEntryType::Medal;
    medalAt.m_Medal = "Author";
    medalAt.m_PlayerName = "AT";
    medalAt.m_IconColor = vec3(0, 0x77 / 255.0f, 0x11 / 255.0f);
    medalAt.m_Time = map.MapInfo.TMObjective_AuthorTime;
    g_State.m_Leaderboard.AddEntry(medalAt);

    auto medalGold = LeaderboardEntry();
    medalGold.m_Type = LeaderboardEntryType::Medal;
    medalGold.m_Medal = "Gold";
    medalGold.m_PlayerName = "Gold";
    medalGold.m_IconColor = vec3(0xDD / 255.0f, 0xBB / 255.0f, 0x44 / 255.0f);
    medalGold.m_Time = map.MapInfo.TMObjective_GoldTime;
    g_State.m_Leaderboard.AddEntry(medalGold);

    auto medalSilver = LeaderboardEntry();
    medalSilver.m_Type = LeaderboardEntryType::Medal;
    medalSilver.m_Medal = "Silver";
    medalSilver.m_PlayerName = "Silver";
    medalSilver.m_IconColor = vec3(0x88 / 255.0f, 0x99 / 255.0f, 0x99 / 255.0f);
    medalSilver.m_Time = map.MapInfo.TMObjective_SilverTime;
    g_State.m_Leaderboard.AddEntry(medalSilver);

    auto medalBronze = LeaderboardEntry();
    medalBronze.m_Type = LeaderboardEntryType::Medal;
    medalBronze.m_Medal = "Bronze";
    medalBronze.m_PlayerName = "Bronze";
    medalBronze.m_IconColor = vec3(0x99 / 255.0f, 0x66 / 255.0f, 0x44 / 255.0f);
    medalBronze.m_Time = map.MapInfo.TMObjective_BronzeTime;
    g_State.m_Leaderboard.AddEntry(medalBronze);

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
        g_State.m_Leaderboard.AddEntry(medalChampion);
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
        g_State.m_Leaderboard.AddEntry(medalWarrior);
    }
#endif

    // Set medals of already existing entries
    for (uint i = 0; i < g_State.m_Leaderboard.m_Entries.Length; i++)
    {
        auto @entry = @g_State.m_Leaderboard.m_Entries[i];
        if (entry.m_Type == LeaderboardEntryType::Medal)
        {
            continue;
        }

        setMedal(g_State.m_Leaderboard, entry);
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

void setMedal(const Leaderboard&in leaderboard, LeaderboardEntry&inout entry)
{
    for (uint i = 0; i < leaderboard.m_Entries.Length; i++)
    {
        const auto @medalEntry = @leaderboard.m_Entries[i];
        if (medalEntry.m_Type != LeaderboardEntryType::Medal)
            continue;

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

    uint m_TotalNumberFinishes = 0;
    uint m_NumberPlayerScores = 0;

    uint m_PlayerBestId = 0;
    int m_PlayerBestTime = -1;

    uint m_PlayerNewestId = 0;
    int m_PlayerNewestTime = -1;
    bool m_IsPlayerNewestTemporary = false;

    LeaderboardEntry @getLastPlayerEntry()
    {
        const auto lastPlayerEntry = GetLastPlayerEntryIndex();
        if (lastPlayerEntry < 0)
        {
            return null;
        }
        return @m_Entries[lastPlayerEntry];
    }

    void AddNewEntry(LeaderboardEntry entry, bool temporary)
    {
        entry.m_ScoreNumber = m_TotalNumberFinishes;
        setMedal(this, entry);

        AddEntry(entry);
        m_NumberPlayerScores++;

        m_PlayerNewestId = entry.m_ScoreNumber;
        m_PlayerNewestTime = entry.m_Time;
        m_IsPlayerNewestTemporary = temporary;

        if (entry.m_Time < m_PlayerBestTime || m_PlayerBestTime == -1)
        {
            m_PlayerBestId = entry.m_ScoreNumber;
            m_PlayerBestTime = entry.m_Time;
        }
    }

    void AddEntry(LeaderboardEntry entry)
    {
        for (uint i = 0; i < m_Entries.Length; i++)
        {
            if (entry.m_Time < m_Entries[i].m_Time)
            {
                m_Entries.InsertAt(i, entry);
                return;
            }
        }

        m_Entries.InsertLast(entry);
    }

    void RemoveLastPlayerEntry()
    {
        const auto lastPlayerEntry = GetLastPlayerEntryIndex();
        if (lastPlayerEntry >= 0)
        {
            m_Entries.RemoveAt(lastPlayerEntry);
            m_NumberPlayerScores--;
        }
    }

    void RemovePlayerEntry(uint scoreNumber)
    {
        const auto index = GetPlayerEntryIndex(scoreNumber);
        if (index >= 0)
        {
            m_Entries.RemoveAt(index);
        }
    }

    void RemoveTemporaryLast()
    {
        if (!m_IsPlayerNewestTemporary || m_PlayerNewestId <= 0)
        {
            return;
        }
        RemovePlayerEntry(m_PlayerNewestId);
        m_PlayerNewestId = 0;
        m_PlayerNewestTime = -1;
    }

    int GetPlayerEntryIndex(uint scoreNumber)
    {
        for (int i = m_Entries.Length - 1; i >= 0; i--)
        {
            if (m_Entries[i].m_ScoreNumber == scoreNumber)
            {
                return i;
            }
        }
        return -1;
    }

    int GetLastPlayerEntryIndex()
    {
        for (int i = m_Entries.Length - 1; i >= 0; i--)
        {
            if (m_Entries[i].m_Type == LeaderboardEntryType::Score)
            {
                return i;
            }
        }
        return -1;
    }
}

class LeaderboardEntry
{
    uint m_ScoreNumber = 0;
    LeaderboardEntryType m_Type = LeaderboardEntryType::Score;

    string m_PlayerName = "";
    string m_Medal = "";

    vec3 m_IconColor = vec3(1, 1, 1);

    int64 m_TimeStamp = 0;
    int m_Time = 0;
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
}

enum LeaderboardEntryType
{
    Medal,
    Score,
}

}

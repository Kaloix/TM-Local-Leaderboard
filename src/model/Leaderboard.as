namespace LocalLeaderboard
{

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

        entry.m_Checkpoints = g_State.m_CurrentCheckpoints;

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
                cpData.m_Speed = entry.m_Checkpoints[i].m_Speed;
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
                    checkpointsRun.m_Checkpoints[i].m_Speed = entry.m_Checkpoints[i].m_Speed;
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
            case LeaderboardEntryType::CustomScore:
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
            case LeaderboardEntryType::CustomScore:
                return Icons::ClockO;
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
            case LeaderboardEntryType::CustomScore:
                return m_Time;
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
            case LeaderboardEntryType::CustomScore:
                return m_PlayerName;
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

class CheckpointData
{
    int m_TimeFromStart = 0;
    int m_TimeFromPrevious = 0;
    int m_TimeFromPreviousNoRespawn = 0;
    int m_Speed = 0;
    int m_NumberRespawns = 0;
}

enum LeaderboardEntryType
{
    Medal,
    CustomScore,
    Score,
    ScoreBestCheckpoints,
    ScoreCopium,
}

}

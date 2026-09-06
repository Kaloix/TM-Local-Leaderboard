namespace LocalRecords
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

    LeaderboardEntry @m_BestLapsRun = null;
    LeaderboardEntry @m_SessionBestLapsRun = null;

    uint m_TotalNumberFinishes = 0;
    uint m_TotalNumberSessions = 0;
    uint m_TotalNumberSessionFinishes = 0;

    uint64 m_TotalTime = 0;
    uint64 m_LastUpdated = Time::get_Now();

    array<array<array<int> @> @> m_SortedCheckpoints;
    array<LeaderboardEntry @> m_ForRemoval;

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

        // Deep copy checkpoint and lap data so the stored run stays immutable when the current run updates.
        for (uint i = 0; i < g_State.m_CurrentCheckpoints.Length; ++i)
        {
            CheckpointData @cpData = CheckpointData();
            cpData.m_TimeFromStart = g_State.m_CurrentCheckpoints[i].m_TimeFromStart;
            cpData.m_TimeFromPrevious = g_State.m_CurrentCheckpoints[i].m_TimeFromPrevious;
            cpData.m_TimeFromPreviousNoRespawn = g_State.m_CurrentCheckpoints[i].m_TimeFromPreviousNoRespawn;
            cpData.m_Speed = g_State.m_CurrentCheckpoints[i].m_Speed;
            cpData.m_NumberRespawns = g_State.m_CurrentCheckpoints[i].m_NumberRespawns;
            entry.m_Checkpoints.InsertLast(@cpData);
        }

        for (uint i = 0; i < g_State.m_CurrentLaps.Length; ++i)
        {
            LapData @lapData = LapData();
            lapData.m_TimeFromStart = g_State.m_CurrentLaps[i].m_TimeFromStart;
            lapData.m_TimeFromPrevious = g_State.m_CurrentLaps[i].m_TimeFromPrevious;
            lapData.m_TimeFromPreviousNoRespawn = g_State.m_CurrentLaps[i].m_TimeFromPreviousNoRespawn;
            lapData.m_NumberRespawns = g_State.m_CurrentLaps[i].m_NumberRespawns;
            entry.m_Laps.InsertLast(@lapData);
        }

        setMedal(entry);

        return @entry;
    }

    void addNewestRun(const MLFeed::PlayerCpInfo_V4 @player)
    {
        @m_NewestRun = @createNewEntry(player);
        if (m_NewestRun.m_NumberRespawns > 0)
        {
            @m_NewestCopiumRun = LeaderboardEntry(m_NewestRun);
            m_NewestCopiumRun.m_Type = LeaderboardEntryType::ScoreCopium;
            m_NewestCopiumRun.m_Rank = 0;
            setMedal(m_NewestCopiumRun);
            InitPositionForEntryAsync(@m_NewestCopiumRun);
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
        updateBestLapsRun(m_NewestRun);
    }

    void AddNewEntry(LeaderboardEntry @entry)
    {
        AddEntry(@entry);

        if (m_FastestRun is null || entry.m_Time < m_FastestRun.m_Time)
            SetFastestRun(@entry);
        if (m_SessionFastestRun is null || entry.m_Time < m_SessionFastestRun.m_Time)
            SetSessionFastestRun(@entry);

        if (entry.m_NumberRespawns > 0 && m_FastestRun !is null && entry.m_TimeNoRespawn < m_FastestRun.m_Time && (m_FastestCopiumRun is null || entry.m_TimeNoRespawn < m_FastestCopiumRun.m_TimeNoRespawn))
            SetFastestCopiumRun(@entry);
        if (entry.m_NumberRespawns > 0 && m_SessionFastestRun !is null && entry.m_TimeNoRespawn < m_SessionFastestRun.m_Time && (m_SessionFastestCopiumRun is null || entry.m_TimeNoRespawn < m_SessionFastestCopiumRun.m_TimeNoRespawn))
            SetSessionFastestCopiumRun(@entry);

        AddSortedCheckpoint(entry);
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

    void MarkForRemoval(LeaderboardEntry @entry)
    {
        if (entry is null)
            return;

        m_ForRemoval.InsertLast(@entry);
    }

    void Clean()
    {
        if (m_ForRemoval.Length == 0)
            return;

        for (uint i = 0; i < m_ForRemoval.Length; i++)
        {
            RemoveEntry(m_ForRemoval[i]);
        }
        m_ForRemoval.RemoveRange(0, m_ForRemoval.Length);
        InitRows();
        SaveLeaderboard(g_State);
    }

    void RemoveEntry(LeaderboardEntry @entry)
    {
        if (entry is null)
            return;

        if (entry.m_Type == LeaderboardEntryType::CustomPosition)
        {
            g_State.RemoveCustomPositionEntryById(entry.m_Id);
            return;
        }
        if (entry.m_Type == LeaderboardEntryType::CustomTime)
        {
            g_State.RemoveCustomTimeEntryById(entry.m_Id);
            return;
        }

        // Update best runs, these are separate entries not contained in the m_Entries array.
        if (m_BestCheckpointsRun is entry)
        {
            @m_BestCheckpointsRun = null;
            return;
        }
        if (m_SessionBestCheckpointsRun is entry)
        {
            @m_SessionBestCheckpointsRun = null;
            return;
        }
        if (m_BestLapsRun is entry)
        {
            @m_BestLapsRun = null;
            return;
        }
        if (m_SessionBestLapsRun is entry)
        {
            @m_SessionBestLapsRun = null;
            return;
        }

        // Remove the entry from the leaderboard
        for (uint i = 0; i < m_Entries.Length; i++)
        {
            if (m_Entries[i].m_Id == entry.m_Id)
            {
                m_Entries.RemoveAt(i);
                break;
            }
        }

        // Update newest run
        if (m_NewestRun is entry)
            @m_NewestRun = null;
        

        // Update PB
        if (m_FastestRun is entry)
        {
            @m_FastestRun = null;
            if (m_Entries.Length > 0)
                SetFastestRun(@m_Entries[0]);
        }

        // Update session PB
        if (m_SessionFastestRun is entry)
        {
            @m_SessionFastestRun = null;
            for (uint i = 0; i < m_Entries.Length; i++)
            {
                if (m_Entries[i].m_SessionNumber == entry.m_SessionNumber)
                {
                    SetSessionFastestRun(@m_Entries[i]);
                    break;
                }
            }
        }

        // Update newest copium
        if (m_NewestCopiumRun is entry)
            @m_NewestCopiumRun = null;

        // Update copium
        if (m_FastestCopiumRun is entry)
        {
            @m_FastestCopiumRun = null;
            for (uint i = 0; i < m_Entries.Length; i++)
            {
                if (m_Entries[i].m_NumberRespawns > 0 && (m_FastestCopiumRun is null || m_Entries[i].m_TimeNoRespawn < m_FastestCopiumRun.m_TimeNoRespawn))
                    SetFastestCopiumRun(@m_Entries[i]);
            }
        }

        // Update session copium
        if (m_SessionFastestCopiumRun is entry)
        {
            @m_SessionFastestCopiumRun = null;
            for (uint i = 0; i < m_Entries.Length; i++)
            {
                if (m_Entries[i].m_SessionNumber == entry.m_SessionNumber && m_Entries[i].m_NumberRespawns > 0 && (m_SessionFastestCopiumRun is null || m_Entries[i].m_TimeNoRespawn < m_SessionFastestCopiumRun.m_TimeNoRespawn))
                    SetSessionFastestCopiumRun(@m_Entries[i]);
            }
        }

    }

    void RemoveLastPlayerEntry()
    {
        m_Entries.RemoveLast();
    }
    
    void SetFastestRun(LeaderboardEntry @entry)
    {
        entry.m_WasPersonalBest = true;
        InitPositionForEntryAsync(@entry);
        @m_FastestRun = @entry;

        if (m_FastestCopiumRun !is null && m_FastestRun.m_Time <= m_FastestCopiumRun.m_TimeNoRespawn)
            @m_FastestCopiumRun = null;
    }

    void SetSessionFastestRun(LeaderboardEntry @entry)
    {
        if (m_SessionFastestRun !is null)
            m_SessionFastestRun.m_WasSessionBest = false;

        entry.m_WasSessionBest = true;
        @m_SessionFastestRun = @entry;

        if (m_SessionFastestCopiumRun !is null && m_SessionFastestRun.m_Time <= m_SessionFastestCopiumRun.m_TimeNoRespawn)
            @m_SessionFastestCopiumRun = null;
    }

    void SetFastestCopiumRun(LeaderboardEntry @entry)
    {
        if (m_NewestCopiumRun !is entry)
        {
            @m_FastestCopiumRun = LeaderboardEntry(entry);
            m_FastestCopiumRun.m_Type = LeaderboardEntryType::ScoreCopium;
            m_FastestCopiumRun.m_Rank = 0;
            setMedal(m_FastestCopiumRun);
            InitPositionForEntryAsync(@m_FastestCopiumRun);
        }
        else
        {
            @m_NewestCopiumRun = @entry;
        }
    }

    void SetSessionFastestCopiumRun(LeaderboardEntry @entry)
    {
        if (m_NewestCopiumRun !is entry)
        {
            @m_SessionFastestCopiumRun = LeaderboardEntry(entry);
            m_SessionFastestCopiumRun.m_Type = LeaderboardEntryType::ScoreCopium;
            m_SessionFastestCopiumRun.m_Rank = 0;
            setMedal(m_SessionFastestCopiumRun);
            InitPositionForEntryAsync(@m_SessionFastestCopiumRun);
        }
        else
        {
            @m_NewestCopiumRun = @entry;
        }
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
                checkpointsRun.m_Checkpoints[i].m_TimeFromStart = checkpointsRun.m_Time;
            }

            setMedal(checkpointsRun);

            InitPositionForEntryAsync(@checkpointsRun);
        }
    }

    private void updateBestLapsRun(const LeaderboardEntry&in entry)
    {
        if (m_BestLapsRun is null)
            @m_BestLapsRun = LeaderboardEntry();
        updateLapsRun(m_BestLapsRun, entry);

        if (m_SessionBestLapsRun is null)
            @m_SessionBestLapsRun = LeaderboardEntry();
        updateLapsRun(m_SessionBestLapsRun, entry);
    }

    private void updateLapsRun(LeaderboardEntry &inout lapsRun, const LeaderboardEntry&in entry) const
    {
        bool hasNewBestLap = false;

        if (lapsRun.m_Laps.Length == 0)
        {
            lapsRun.m_PlayerName = entry.m_PlayerName;
            lapsRun.m_Type = LeaderboardEntryType::ScoreBestLaps;

            for (uint i = 0; i < entry.m_Laps.Length; i++)
            {
                LapData @lapData = LapData();
                lapData.m_TimeFromPrevious = entry.m_Laps[i].m_TimeFromPrevious;
                lapData.m_TimeFromPreviousNoRespawn = entry.m_Laps[i].m_TimeFromPreviousNoRespawn;
                lapData.m_NumberRespawns = entry.m_Laps[i].m_NumberRespawns;
                lapsRun.m_Laps.InsertLast(@lapData);
            }

            hasNewBestLap = true;
        } else {
            for (uint i = 0; i < entry.m_Laps.Length; i++)
            {
                if (entry.m_Laps[i].m_TimeFromPrevious < lapsRun.m_Laps[i].m_TimeFromPrevious)
                {
                    lapsRun.m_Laps[i].m_TimeFromPrevious = entry.m_Laps[i].m_TimeFromPrevious;
                    lapsRun.m_Laps[i].m_TimeFromPreviousNoRespawn = entry.m_Laps[i].m_TimeFromPreviousNoRespawn;
                    lapsRun.m_Laps[i].m_NumberRespawns = entry.m_Laps[i].m_NumberRespawns;
                    hasNewBestLap = true;
                }
            }
        }

        if (hasNewBestLap)
        {
            lapsRun.m_TimeStamp = entry.m_TimeStamp;
            lapsRun.m_ScoreNumber = entry.m_ScoreNumber;
            lapsRun.m_SessionNumber = entry.m_SessionNumber;

            lapsRun.m_Time = 0;
            for (uint i = 0; i < lapsRun.m_Laps.Length; i++)
            {
                lapsRun.m_Time += lapsRun.m_Laps[i].m_TimeFromPrevious;
                lapsRun.m_Laps[i].m_TimeFromStart = lapsRun.m_Time;
            }

            setMedal(lapsRun);

            InitPositionForEntryAsync(@lapsRun);
        }
    }

    void InitSortedCheckpoints()
    {
        m_SortedCheckpoints.RemoveRange(0, m_SortedCheckpoints.Length);
        for (uint i = 0; i < 6; ++i)
        {
            m_SortedCheckpoints.InsertLast(array<array<int> @>());
            CheckpointPositionComparison comparisonType = CheckpointPositionComparison(i);
            InitSortedCheckpointTimes(comparisonType);
        }
    }

    void InitSortedCheckpointTimes(const CheckpointPositionComparison comparisonType)
    {
        array<array<int> @> @a = @m_SortedCheckpoints[uint(comparisonType)];
        a.RemoveRange(0, a.Length);

        for (uint i = 0; i <= g_State.m_CurrentMapCpCount; i++)
        {
            a.InsertLast(array<int>());
        }

        for (uint j = 0; j < m_Entries.Length; j++)
        {
            AddSortedCheckpointTime(m_Entries[j].m_Checkpoints, comparisonType);
        }
    }

    void AddSortedCheckpoint(const LeaderboardEntry&in entry)
    {
        for (uint i = 0; i < 6; ++i)
        {
            m_SortedCheckpoints.InsertLast(array<array<int> @>());
            CheckpointPositionComparison comparisonType = CheckpointPositionComparison(i);
            AddSortedCheckpointTime(entry.m_Checkpoints, comparisonType);
        }
    }

    void AddSortedCheckpointTime(const array<CheckpointData@>&in entry, const CheckpointPositionComparison comparisonType)
    {
        for (uint checkpointIndex = 0; checkpointIndex < entry.Length; checkpointIndex++)
        {
            const int target = GetSortedCheckpointComparison(entry[checkpointIndex], comparisonType);
            array<int> @a = @m_SortedCheckpoints[uint(comparisonType)][checkpointIndex];

            for (uint j = 0; j < a.Length; j++)
            {
                if (target < a[j])
                {
                    a.InsertAt(j, target);
                    return;
                }
            }
            a.InsertLast(target);
        }
    }

    uint GetSortedCheckpointRank(uint checkpointIndex, const CheckpointData&in checkpointData, const CheckpointPositionComparison comparisonType) const
    {
        array<array<int> @> @a = m_SortedCheckpoints[uint(comparisonType)];

        if (checkpointIndex >= a.Length)
            return 0;

        const auto @checkpointTimes = @a[checkpointIndex];

        if (comparisonType == CheckpointPositionComparison::Speed)
        {
            // Greater is better for speed, so we need to reverse the comparison.
            for (uint i = 0; i < checkpointTimes.Length; i++)
            {
                const int target = GetSortedCheckpointComparison(checkpointData, comparisonType);
                if (target >= checkpointTimes[checkpointTimes.Length - 1 - i])
                    return i;
            }
        }
        else
        {
            // Lower is better for all other comparisons.
            for (uint i = 0; i < checkpointTimes.Length; i++)
            {
                const int target = GetSortedCheckpointComparison(checkpointData, comparisonType);
                if (target <= checkpointTimes[i])
                    return i;
            }
        }

        return checkpointTimes.Length;

    }

    int GetSortedCheckpointComparison(const CheckpointData&in checkpointData, const CheckpointPositionComparison comparisonType) const
    {
        if (checkpointData is null)
            return 0;

        switch (comparisonType)
        {
            case CheckpointPositionComparison::TimeFromStart:
                return checkpointData.m_TimeFromStart;
            case CheckpointPositionComparison::TimeFromPrevious:
                return checkpointData.m_TimeFromPrevious;
            case CheckpointPositionComparison::TimeFromPreviousNoRespawn:
                return checkpointData.m_TimeFromPreviousNoRespawn;
            case CheckpointPositionComparison::Speed:
                return checkpointData.m_Speed;
            case CheckpointPositionComparison::NumberRespawns:
                return checkpointData.m_NumberRespawns;
            default:
                return 0;
        }
        
    }

}

class LeaderboardEntry
{
    int64 m_Id = Time::get_Stamp();

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

    /**
     * The local rank.
     */
    uint m_Rank = 0;

    /**
     * The global rank for custom positions.
     */
    uint m_GlobalPosition = 0;

    int64 m_TimeStamp = 0;
    int m_Time = 0;
    int m_TimeNoRespawn = 0;
    uint m_NumberRespawns = 0;

    array<CheckpointData @> m_Checkpoints;
    array<LapData @> m_Laps;

    bool m_WasPersonalBest = false;
    bool m_WasSessionBest = false;
    bool m_IsStarred = false;

    array<RegionPositionData @> m_RegionPositions;
    array<RegionTimeData @> m_RegionTimes;

    string GetDisplayRank() const
    {
        switch (m_Type)
        {
            case LeaderboardEntryType::CustomPosition:
            case LeaderboardEntryType::CustomTime:
            case LeaderboardEntryType::Medal:
                return "";
            case LeaderboardEntryType::Score:
                return "" + m_Rank;
            case LeaderboardEntryType::ScoreBestCheckpoints:
            case LeaderboardEntryType::ScoreBestLaps:
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
            case LeaderboardEntryType::CustomPosition:
                return Icons::Kenney::PodiumAlt;
            case LeaderboardEntryType::CustomTime:
                return Icons::ClockO;
            case LeaderboardEntryType::Medal:
                return Icons::Circle;
            case LeaderboardEntryType::Score:
                return Icons::User;
            case LeaderboardEntryType::ScoreBestCheckpoints:
            case LeaderboardEntryType::ScoreBestLaps:
                return Icons::AngleDoubleUp;
            case LeaderboardEntryType::ScoreCopium:
                return Icons::ArrowCircleUp;
            default:
                return "";
        }
    }

    int GetDisplayTime() const
    {
        switch (m_Type)
        {
            case LeaderboardEntryType::CustomPosition:
                return GetLatestGlobalTime();
            case LeaderboardEntryType::CustomTime:
                return m_Time;
            case LeaderboardEntryType::Medal:
                return m_Medal is null ? 0 : m_Medal.GetTime();
            case LeaderboardEntryType::Score:
            case LeaderboardEntryType::ScoreBestCheckpoints:
            case LeaderboardEntryType::ScoreBestLaps:
                return m_Time;
            case LeaderboardEntryType::ScoreCopium:
                return m_TimeNoRespawn;
            default:
                return 0;
        }
    }

    string GetPlayerDisplayName() const
    {
        switch (m_Type)
        {
            case LeaderboardEntryType::CustomPosition:
            case LeaderboardEntryType::CustomTime:
                return m_PlayerName;
            case LeaderboardEntryType::Medal:
                return m_Medal is null ? "Unknown Medal" : m_Medal.GetName();
            case LeaderboardEntryType::Score:
                return m_PlayerName;
            case LeaderboardEntryType::ScoreBestCheckpoints:
                return m_PlayerName + " (Best Checkpoints)";
            case LeaderboardEntryType::ScoreBestLaps:
                return m_PlayerName + " (Best Laps)";
            case LeaderboardEntryType::ScoreCopium:
                return m_PlayerName + " (Copium)";
            default:
                return "";
        }
    }

    string GetDisplayName() const
    {
        switch (m_Type)
        {
            case LeaderboardEntryType::CustomPosition:
            case LeaderboardEntryType::CustomTime:
                return m_PlayerName;
            case LeaderboardEntryType::Medal:
                return m_Medal is null ? "Unknown Medal" : m_Medal.GetName() + " Medal";
            case LeaderboardEntryType::Score:
            {
                if (g_State.m_Leaderboard.m_FastestRun is this)
                    return "PB";
                return "Run #" + m_ScoreNumber;
            }
            case LeaderboardEntryType::ScoreBestCheckpoints:
                return "Best Checkpoints";
            case LeaderboardEntryType::ScoreBestLaps:
                return "Best Laps";
            case LeaderboardEntryType::ScoreCopium:
                return "Copium";
            default:
                return "";
        }
    }

    bool IsCurrentSession() const
    {
        return m_SessionNumber == g_State.m_Leaderboard.m_TotalNumberSessions;
    }

    uint GetLatestGlobalPosition() const
    {
        // Custom positions have the global position set
        if (m_GlobalPosition > 0)
            return m_GlobalPosition;

        // Take the latest value from the history
        const auto zoneName = GetCurrentZoneName();
        auto @regionPositionData = GetRegionPositionData(zoneName);
        if (regionPositionData !is null && regionPositionData.m_RegionPositions.Length > 0)
        {
            auto @lastEntry = regionPositionData.m_RegionPositions[regionPositionData.m_RegionPositions.Length - 1];
            return lastEntry.m_GlobalPosition;
        }

        return 0;
    }

    array<GlobalPositionData @> GetGlobalPositionHistory() const
    {
        const auto @region = @GetCurrentZone();
        auto @regionPositionData = GetRegionPositionData(region);
        if (regionPositionData !is null)
            return regionPositionData.m_RegionPositions;

        return array<GlobalPositionData @>();
    }

    void AddGlobalPositionData(const Json::Value &in globalPositionData)
    {
        if (globalPositionData.Length == 0)
            return;

        // Update the history
        const array<string> @keys = globalPositionData.GetKeys();
        for (uint i = 0; i < keys.Length; ++i)
        {
            const string region = keys[i];
            const uint position = globalPositionData[region];;

            GlobalPositionData @existingEntry = null;
            RegionPositionData @regionPositionData = GetRegionPositionData(region);

            if (regionPositionData !is null) {
                if (regionPositionData.m_RegionPositions.Length > 0)
                {
                    auto @lastEntry = regionPositionData.m_RegionPositions[regionPositionData.m_RegionPositions.Length - 1];

                    if (lastEntry.m_GlobalPosition == position && lastEntry.m_GlobalPositionTotalPlayers == g_State.m_NumberGlobalPositions)
                    {
                        continue;
                    }

                    if (lastEntry.m_IsCurrentSession)
                    {
                        @existingEntry = @lastEntry;
                    }
                }
            }

            if (existingEntry is null)
            {

                if (regionPositionData is null)
                {
                    @regionPositionData = RegionPositionData();
                    regionPositionData.m_Region = region;
                    m_RegionPositions.InsertLast(@regionPositionData);
                }

                // Add a new entry to the history
                @existingEntry = GlobalPositionData();
                existingEntry.m_IsCurrentSession = true;
                regionPositionData.m_RegionPositions.InsertLast(@existingEntry);
            }

            existingEntry.m_GlobalPosition = position;
            existingEntry.m_GlobalPositionTotalPlayers = g_State.m_NumberGlobalPositions;
            existingEntry.m_GlobalPositionPercentile = g_State.m_NumberGlobalPositions > 0 ? float(position) / float(g_State.m_NumberGlobalPositions) : 0.0f;
            existingEntry.m_TimeStamp = Time::get_Stamp();
        }
    }

    RegionPositionData @GetRegionPositionData(const Zone @zone) const
    {
        if (zone is null)
            return null;
        return GetRegionPositionData(zone.m_Name);
    }

    RegionPositionData @GetRegionPositionData(const string &in region) const
    {
        for (uint i = 0; i < m_RegionPositions.Length; ++i)
        {
            if (m_RegionPositions[i].m_Region == region)
                return m_RegionPositions[i];
        }
        return null;
    }

    uint GetLatestGlobalTime() const
    {
        auto @latestGlobalTimeData = @GetLatestGlobalTimeData();
        if (latestGlobalTimeData is null)
            return 0;

        return latestGlobalTimeData.m_Time;
    }

    /**
     * Returns the latest global time data for the current zone, or null if no data is available.
     */
    GlobalTimeData @GetLatestGlobalTimeData() const
    {
        const auto zoneName = GetCurrentZoneName();
        auto @regionPositionData = GetRegionTimeData(zoneName);

        if (regionPositionData is null || regionPositionData.m_RegionTimes.Length == 0)
            return null;

        return @regionPositionData.m_RegionTimes[regionPositionData.m_RegionTimes.Length - 1];
    }

    void AddGlobalTimeData(GlobalTimeData@ newData, const string &in zoneId)
    {
        // Update the history
        const auto zoneName = GetZoneName(zoneId);
        auto @regionPositionData = GetRegionTimeData(zoneName);
        if (regionPositionData is null)
        {
            @regionPositionData = RegionTimeData();
            regionPositionData.m_Region = zoneName;
            m_RegionTimes.InsertLast(@regionPositionData);
        }

        GlobalTimeData @existingEntry = null;
        if (regionPositionData.m_RegionTimes.Length > 0)
        {
            auto @lastEntry = regionPositionData.m_RegionTimes[regionPositionData.m_RegionTimes.Length - 1];
            if (lastEntry.m_PlayerId == newData.m_PlayerId && lastEntry.m_Time == newData.m_Time && lastEntry.m_TimeStamp == newData.m_TimeStamp)
            {
                return;
            }

            if (lastEntry.m_IsCurrentSession)
            {
                @existingEntry = @lastEntry;
            }
        }

        if (existingEntry is null)
        {
            // Add a new entry to the history
            @existingEntry = @newData;
            existingEntry.m_IsCurrentSession = true;
            regionPositionData.m_RegionTimes.InsertLast(@existingEntry);
        } else {
            existingEntry.m_PlayerId = newData.m_PlayerId;
            existingEntry.m_Time = newData.m_Time;
            existingEntry.m_TimeStamp = newData.m_TimeStamp;
        }
    }

    RegionTimeData @GetRegionTimeData(const string &in region) const
    {
        for (uint i = 0; i < m_RegionTimes.Length; ++i)
        {
            if (m_RegionTimes[i].m_Region == region)
                return m_RegionTimes[i];
        }
        return null;
    }

}

class CheckpointData
{
    int m_TimeFromStart = 0;
    int m_TimeFromStartNoRespawn = 0;
    int m_TimeFromPrevious = 0;
    int m_TimeFromPreviousNoRespawn = 0;
    int m_Speed = 0;
    int m_NumberRespawns = 0;
}

class LapData
{
    int m_TimeFromStart = 0;
    int m_TimeFromPrevious = 0;
    int m_TimeFromPreviousNoRespawn = 0;
    int m_NumberRespawns = 0;
}

enum LeaderboardEntryType
{
    Medal,
    CustomPosition,
    CustomTime,
    Score,
    ScoreBestCheckpoints,
    ScoreBestLaps,
    ScoreCopium,
}

class RegionPositionData
{
    string m_Region = "";
    array<GlobalPositionData @> m_RegionPositions;
}

class GlobalPositionData
{
    /**
     * Position in the region's leaderboard at the time this position was recorded.
     */
    uint m_GlobalPosition = 0;
    /**
     * The total number of players in the global leaderboard at the time this position was recorded.
     * Always refers to the worldwide leaderboard, not the regional leaderboard.
     */
    uint m_GlobalPositionTotalPlayers = 0;
    float m_GlobalPositionPercentile = 0.0f;

    /**
     * The timestamp of when this global position was recorded.
     */
    int64 m_TimeStamp = 0;

    /**
     * Whether this global position was recorded during the current session.
     */
    bool m_IsCurrentSession = false;
}

class RegionTimeData
{
    string m_Region = "";
    array<GlobalTimeData @> m_RegionTimes;
}


class GlobalTimeData
{
    int64 m_TimeStamp = 0;
    int m_Time = 0;
    string m_PlayerId = "";
    string m_PlayerName = "";

    bool m_IsCurrentSession = false;
}

enum CheckpointPositionComparison
{
    TimeFromStart,
    TimeFromStartNoRespawn,
    TimeFromPrevious,
    TimeFromPreviousNoRespawn,
    Speed,
    NumberRespawns,
}

}

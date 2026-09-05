namespace LocalRecords::Statistics
{

void Init()
{
    if (!settingStatisticsShow)
        return;
    Enable();
}

void Shutdown()
{
    Disable();
}

void StatisticsOnSettingsChanged()
{
    if (g_Statistics !is null)
        g_Statistics.Update();

    if (settingStatisticsShow)
    {
        g_StatisticsRenderer.Init();
        Enable();
    }
    else
    {
        Disable();
    }
}

void Update()
{
    if (g_Statistics !is null)
        g_Statistics.Update();
}

void Render()
{
    if (settingStatisticsHideWithUi && !UI::IsGameUIVisible())
    {
        return; // Don't render if the game UI is not visible
    }

    if (g_Statistics !is null)
        g_Statistics.Render();
}

Statistics@ g_Statistics = null;
StatisticsRenderer@ g_StatisticsRenderer = StatisticsRenderer();

void Enable()
{
    if (g_Statistics is null)
        @g_Statistics = Statistics();
}

void Disable()
{
    if (g_Statistics !is null)
        @g_Statistics = null;
}


class Statistics
{
    private int m_AverageTime = 0;
    private int m_SessionAverageTime = 0;
    private int m_IntervalAverageTime = 0;

    Statistics()
    {
        Update();
        LogDebug("Statistics initialized.");
    }

    int GetAverageTime() const
    {
        return m_AverageTime;
    }

    int GetSessionAverageTime() const
    {
        return m_SessionAverageTime;
    }

    int GetIntervalAverageTime() const
    {
        return m_IntervalAverageTime;
    }

    void Update()
    {
        UpdateAverageTime();
    }

    void Render()
    {
        g_StatisticsRenderer.Render(this);
    }

    private void UpdateAverageTime()
    {
        // Reset averages
        m_AverageTime = 0;
        m_SessionAverageTime = 0;
        m_IntervalAverageTime = 0;

        // Prepare array for interval average
        const auto count = g_State.m_Leaderboard.m_Entries.Length;
        const auto sessionCount = g_State.m_Leaderboard.m_TotalNumberSessionFinishes;

        array<const LeaderboardEntry@> intervalTimes;
        intervalTimes.Resize(Math::Min(count, settingsStatisticsAverageInterval));

        // Calculate averages
        for (uint i = 0; i < count; ++i)
        {
            // Update overall average
            const auto @entry = g_State.m_Leaderboard.m_Entries[i];
            m_AverageTime += entry.m_Time;

            // Update interval average
            if (entry.IsCurrentSession())
                m_SessionAverageTime += entry.m_Time;

            // Insert into intervalTimes array in sorted order
            InsertIntervalEntry(@entry, intervalTimes);
        }

        if (count > 0)
            m_AverageTime /= count;

        if (sessionCount > 0)
            m_SessionAverageTime /= sessionCount;

        if (intervalTimes.Length > 0)
        {
            for (uint i = 0; i < intervalTimes.Length; ++i)
            {
                if (intervalTimes[i] !is null)
                    m_IntervalAverageTime += intervalTimes[i].m_Time;
            }
            m_IntervalAverageTime /= intervalTimes.Length;
        }
    }

    /**
     * Inserts a leaderboard entry into the intervalTimes array in sorted order.
     * This is used to calculate the average of the last N runs.
     * @param entry The leaderboard entry to insert.
     * @param intervalTimes The array of leaderboard entries to insert into.
     */
    private void InsertIntervalEntry(const LeaderboardEntry @entry, array<const LeaderboardEntry@> &inout intervalTimes)
    {
        // Insert the entry into the intervalTimes array in sorted order
        for (uint i = 0; i < intervalTimes.Length; ++i)
        {
            if (intervalTimes[i] is null || entry.m_Time < intervalTimes[i].m_Time)
            {
                // Shift elements to the right
                for (uint j = intervalTimes.Length - 1; j > i; --j)
                {
                    @intervalTimes[j] = @intervalTimes[j - 1];
                }
                @intervalTimes[i] = @entry;
                return;
            }
        }
    }

}


}

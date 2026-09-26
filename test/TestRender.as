namespace LocalRecords::Tests
{

class MockMedal : Medal
{
    int m_Time = 0;

    MedalType GetType() const override
    {
        return MedalType::Author;
    }
    string GetName() const override
    {
        return "Mock";
    }
    vec3 GetIconColor() const override
    {
        return vec3(1, 1, 1);
    }
    int GetTime() const override
    {
        return m_Time;
    }
    bool IsVisible() const override
    {
        return false;
    }
}

[Test]
void TestSorting(Tests::Context@ ctx)
{
    // Backup settings
    const auto backup = settingLeaderboardSortDirection;

    //Prepare leaderboard
    array<LeaderboardEntry @> testEntries;
    auto @entry1 = LeaderboardEntry();
    testEntries.InsertLast(@entry1);
    entry1.m_PlayerName = "Rank2";
    entry1.m_Type = LeaderboardEntryType::Score;
    entry1.m_Time = 3;
    entry1.m_Rank = 2;

    auto @entry2 = LeaderboardEntry();
    testEntries.InsertLast(@entry2);
    entry2.m_PlayerName = "Rank1";
    entry2.m_Type = LeaderboardEntryType::Score;
    entry2.m_Time = entry1.m_Time;
    entry2.m_Rank = entry1.m_Rank - 1;

    auto @medal = MockMedal();
    medal.m_Time = entry1.m_Time;
    auto @entry3 = LeaderboardEntry();
    testEntries.InsertLast(@entry3);
    entry3.m_PlayerName = "Medal";
    entry3.m_Type = LeaderboardEntryType::Medal;
    entry3.m_Time = entry1.m_Time;
    @entry3.m_Medal = @medal;

    auto @entry4 = LeaderboardEntry();
    testEntries.InsertLast(@entry4);
    entry4.m_PlayerName = "CustomPos";
    entry4.m_Type = LeaderboardEntryType::CustomPosition;
    entry4.m_Time = entry1.m_Time;

    auto @entry5 = LeaderboardEntry();
    testEntries.InsertLast(@entry5);
    entry5.m_PlayerName = "Rank3";
    entry5.m_Type = LeaderboardEntryType::Score;
    entry5.m_Time = entry1.m_Time + 1;
    entry5.m_Rank = entry1.m_Rank + 1;

    // Test ascending
    settingLeaderboardSortDirection = LeaderboardSortDirection::Ascending;
    testEntries.Sort(timeSort);
    ctx.AssertSame(testEntries[0].m_PlayerName, entry4.m_PlayerName);
    ctx.AssertSame(testEntries[1].m_PlayerName, entry2.m_PlayerName);
    ctx.AssertSame(testEntries[2].m_PlayerName, entry1.m_PlayerName);
    ctx.AssertSame(testEntries[3].m_PlayerName, entry3.m_PlayerName);
    ctx.AssertSame(testEntries[4].m_PlayerName, entry5.m_PlayerName);

    // Test descending
    settingLeaderboardSortDirection = LeaderboardSortDirection::Descending;
    testEntries.Sort(timeSort);
    ctx.AssertSame(testEntries[0].m_PlayerName, entry5.m_PlayerName);
    ctx.AssertSame(testEntries[1].m_PlayerName, entry3.m_PlayerName);
    ctx.AssertSame(testEntries[2].m_PlayerName, entry1.m_PlayerName);
    ctx.AssertSame(testEntries[3].m_PlayerName, entry2.m_PlayerName);
    ctx.AssertSame(testEntries[4].m_PlayerName, entry4.m_PlayerName);

    // Restore settings
    settingLeaderboardSortDirection = backup;
}

}

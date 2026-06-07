void Render()
{
    if (!settingDisplayLeaderboard)
    {
        return; // Don't render the leaderboard if the setting is disabled
    }

    LocalLeaderboard::Render();
}

enum LeaderboardSortType
{
    Time,
    Chronological,
}

enum LeaderboardSortDirection
{
    Ascending,
    Descending,
}

namespace LocalLeaderboard
{
int windowFlags = 0;

array<LeaderboardEntry @> g_TableRows;
array<TableColumn @> g_TableColumns;

void InitRender()
{
    // Clear existing columns
    g_TableColumns.RemoveRange(0, g_TableColumns.Length);

    // Add all columns that are active
    for (uint i = 0; i < g_AllTableColumns.Length; ++i)
    {
        if (g_AllTableColumns[i].shouldDisplay())
        {
            g_TableColumns.InsertLast(@g_AllTableColumns[i]);
        }
    }

    // Order columns
    g_TableColumns.Sort(columnSort);

    // Setup window flags
    windowFlags = UI::GetDefaultWindowFlags() | UI::WindowFlags::AlwaysAutoResize;
    if (!settingDisplayLeaderboardTitleBar)
        windowFlags |= UI::WindowFlags::NoTitleBar;
}

void InitRows()
{
    if (g_State.m_CurrentMap == "")
        return;

    // Add rows to display
    g_TableRows.RemoveRange(0, g_TableRows.Length);

    // Sum of best checkpoints overall and of the current session
    if (settingDisplayLeaderboardBestCheckpointsRun && g_State.m_Leaderboard.m_BestCheckpointsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_BestCheckpointsRun.m_Time)
        g_TableRows.InsertLast(g_State.m_Leaderboard.m_BestCheckpointsRun);
    if (settingDisplayLeaderboardSessionBestCheckpointsRun && g_State.m_Leaderboard.m_SessionBestCheckpointsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_SessionBestCheckpointsRun.m_Time)
        g_TableRows.InsertLast(g_State.m_Leaderboard.m_SessionBestCheckpointsRun);

    // Sum of best laps overall and of the current session
    if (settingDisplayLeaderboardBestLapsRun && g_State.m_Leaderboard.m_BestLapsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_BestLapsRun.m_Time)
        g_TableRows.InsertLast(g_State.m_Leaderboard.m_BestLapsRun);
    if (settingDisplayLeaderboardSessionBestLapsRun && g_State.m_Leaderboard.m_SessionBestLapsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_SessionBestLapsRun.m_Time)
        g_TableRows.InsertLast(g_State.m_Leaderboard.m_SessionBestLapsRun);

    bool addedNewestCopium = false;
    bool addedFastestCopium = false;
    if (settingDisplayLeaderboardCopiumNewest && g_State.m_Leaderboard.m_NewestCopiumRun !is null)
    {
        g_TableRows.InsertLast(g_State.m_Leaderboard.m_NewestCopiumRun);
        addedNewestCopium = true;
    }
    if (settingDisplayLeaderboardCopiumFastest && g_State.m_Leaderboard.m_FastestCopiumRun !is null && (!addedNewestCopium || g_State.m_Leaderboard.m_FastestCopiumRun.m_ScoreNumber != g_State.m_Leaderboard.m_NewestCopiumRun.m_ScoreNumber))
    {
        g_TableRows.InsertLast(g_State.m_Leaderboard.m_FastestCopiumRun);
        addedFastestCopium = true;
    }
    if (settingDisplayLeaderboardCopiumSessionFastest && g_State.m_Leaderboard.m_SessionFastestCopiumRun !is null && (!addedNewestCopium || g_State.m_Leaderboard.m_SessionFastestCopiumRun.m_ScoreNumber != g_State.m_Leaderboard.m_NewestCopiumRun.m_ScoreNumber) && (!addedFastestCopium || g_State.m_Leaderboard.m_SessionFastestCopiumRun.m_ScoreNumber != g_State.m_Leaderboard.m_FastestCopiumRun.m_ScoreNumber))
        g_TableRows.InsertLast(g_State.m_Leaderboard.m_SessionFastestCopiumRun);

    if (g_State.m_Leaderboard.m_NewestRun !is null)
        g_TableRows.InsertLast(@g_State.m_Leaderboard.m_NewestRun);
    for (uint i = 0; i < g_State.m_Leaderboard.m_Entries.Length; i++)
    {
        if (settingFilterPersonalBests && !g_State.m_Leaderboard.m_Entries[i].m_WasPersonalBest)
            continue;
        if (settingFilterSessionBests && !g_State.m_Leaderboard.m_Entries[i].m_WasSessionBest)
            continue;
        if (settingFilterSessionCurrent && g_State.m_Leaderboard.m_Entries[i].m_SessionNumber != g_State.m_Leaderboard.m_TotalNumberSessions)
            continue;

        if (@g_State.m_Leaderboard.m_NewestRun is @g_State.m_Leaderboard.m_Entries[i])
            continue;
        g_TableRows.InsertLast(@g_State.m_Leaderboard.m_Entries[i]);
    }

    // Add medal entries
    for (uint i = 0; i < g_State.m_MedalEntries.Length; i++)
    {
        auto @entry = @g_State.m_MedalEntries[i];
        if (entry.m_Medal.IsVisible())
            g_TableRows.InsertLast(entry);
    }

    // Add custom entries
    if (settingDisplayLeaderboardCustomTimes)
    {
        for (uint i = 0; i < g_State.m_CustomTimeEntries.Length; i++)
        {
            g_TableRows.InsertLast(@g_State.m_CustomTimeEntries[i]);
        }
    }
    if (settingDisplayLeaderboardCustomPositions)
    {
        for (uint i = 0; i < g_State.m_CustomPositionEntries.Length; i++)
        {
            g_TableRows.InsertLast(@g_State.m_CustomPositionEntries[i]);
        }
    }

    // Sort rows
    switch (settingLeaderboardSortType)
    {
        case LeaderboardSortType::Time:
            g_TableRows.Sort(timeSort);
            break;
        case LeaderboardSortType::Chronological:
            g_TableRows.Sort(chronologicalSort);
            break;
    }
}

bool timeSort(const LeaderboardEntry @ const&in a, const LeaderboardEntry @ const&in b)
{

    switch (settingLeaderboardSortDirection)
    {
        case LeaderboardSortDirection::Ascending:
            return a.GetDisplayTime() < b.GetDisplayTime();
        case LeaderboardSortDirection::Descending:
            return a.GetDisplayTime() > b.GetDisplayTime();
        default:
            return false;
    }
}

bool chronologicalSort(const LeaderboardEntry @ const&in a, const LeaderboardEntry @ const&in b)
{
    switch (settingLeaderboardSortDirection)
    {
        case LeaderboardSortDirection::Ascending:
            return a.m_TimeStamp < b.m_TimeStamp;
        case LeaderboardSortDirection::Descending:
            return a.m_TimeStamp > b.m_TimeStamp;
        default:
            return false;
    }
}

bool columnSort(const TableColumn@ const&in a, const TableColumn@ const&in b)
{
    return a.m_Pos < b.m_Pos;
}

void Render()
{
    if (g_State.m_CurrentMap == "")
    {
        return; // Don't render if no map is loaded
    }

    bool open = true;
    UI::Begin("Local Leaderboard", open, windowFlags);

    if (settingDisplayLeaderboardMapName)
    {
        const auto mapName = Text::OpenplanetFormatCodes(g_State.m_CurrentMapName);
        UI::Text(mapName);
    }

    if (settingDisplayLeaderboardMapAuthor)
    {
        const auto mapAuthor = Text::OpenplanetFormatCodes(g_State.m_CurrentMapAuthor);
        UI::TextDisabled("By " + mapAuthor);
    }

    UI::BeginTable("LeaderboardTable", g_TableColumns.Length, UI::TableFlags::SizingFixedFit);

    // Setup columns
    for (uint i = 0; i < g_TableColumns.Length; i++)
    {
        g_TableColumns[i].setup(i);
    }

    // Table header
    if (settingDisplayLeaderboardHeader)
    {
        UI::TableHeadersRow();
    }

    // Table body
    auto context = TableRenderContext();
    for (uint i = 0; i < g_TableRows.Length; i++)
    {
        PrepareRenderContext(context, i);

        UI::TableNextRow();

        bool isRowHovered = false;
        for (uint col = 0; col < g_TableColumns.Length; col++)
        {
            UI::TableNextColumn();
            g_TableColumns[col].renderBody(context);

            isRowHovered = isRowHovered || UI::IsItemHovered();
        }

        if (settingDisplayLeaderboardTooltips && isRowHovered)
        {
            UI::BeginTooltip();
            UI::BeginTable("Tooltip" + i, 2);

            for (uint c = 0; c < g_AllTableColumns.Length; c++)
            {
                UI::TableNextRow();
                UI::TableNextColumn();
                g_AllTableColumns[c].renderHeader();
                UI::TableNextColumn();
                g_AllTableColumns[c].renderBody(context);
            }

            UI::EndTable();

            if (context.m_CurrentEntry.m_Checkpoints.Length > 1)
                RenderCheckpoints(context);
            if (context.m_CurrentEntry.m_Laps.Length > 1)
                RenderLaps(context);

            UI::EndTooltip();
        }
    }

    UI::EndTable();

    UI::End();
}

class TableRenderContext
{
    uint64 m_CurrentTime = Time::get_Stamp();

    uint m_CurrentRow = 0;
    LeaderboardEntry @m_CurrentEntry = null;

    bool m_IsPlayerNewest = false;
    bool m_IsPlayerBest = false;
    bool m_IsPlayerSessionBest = false;
    bool m_IsPlayerNewestCopium = false;
    bool m_IsPlayerBestCopium = false;
    bool m_IsPlayerSessionBestCopium = false;
    bool m_IsPlayerBestCheckpoints = false;
    bool m_IsPlayerSessionBestCheckpoints = false;
    bool m_IsPlayerBestLaps = false;
    bool m_IsPlayerSessionBestLaps = false;
}

void PrepareRenderContext(TableRenderContext&inout context, uint i)
{
    context.m_CurrentRow = i;
    @context.m_CurrentEntry = @g_TableRows[i];
    context.m_IsPlayerNewest = context.m_CurrentEntry is g_State.m_Leaderboard.m_NewestRun;
    context.m_IsPlayerBest = context.m_CurrentEntry is g_State.m_Leaderboard.m_FastestRun;
    context.m_IsPlayerSessionBest = context.m_CurrentEntry is g_State.m_Leaderboard.m_SessionFastestRun;
    context.m_IsPlayerNewestCopium = context.m_CurrentEntry is g_State.m_Leaderboard.m_NewestCopiumRun;
    context.m_IsPlayerBestCopium = context.m_CurrentEntry is g_State.m_Leaderboard.m_FastestCopiumRun;
    context.m_IsPlayerSessionBestCopium = context.m_CurrentEntry is g_State.m_Leaderboard.m_SessionFastestCopiumRun;
    context.m_IsPlayerBestCheckpoints = context.m_CurrentEntry is g_State.m_Leaderboard.m_BestCheckpointsRun;
    context.m_IsPlayerSessionBestCheckpoints = context.m_CurrentEntry is g_State.m_Leaderboard.m_SessionBestCheckpointsRun;
    context.m_IsPlayerBestCheckpoints = context.m_CurrentEntry is g_State.m_Leaderboard.m_BestLapsRun;
    context.m_IsPlayerSessionBestCheckpoints = context.m_CurrentEntry is g_State.m_Leaderboard.m_SessionBestLapsRun;
}

void RenderCheckpoints(const TableRenderContext&in context)
{
    UI::BeginTable("CheckpointTimes" + context.m_CurrentRow, 8, UI::TableFlags::SizingFixedFit);

    UI::TableSetupColumn("Cp", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Time Acc", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Time NR", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Speed", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn(Icons::Refresh, UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Delta Best", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Delta PB", UI::TableColumnFlags::WidthFixed);

    UI::TableHeadersRow();

    for (uint i = 0; i < context.m_CurrentEntry.m_Checkpoints.Length; i++)
    {
        UI::TableNextRow();

        const auto @raceData = @MLFeed::GetRaceData_V4();
        if (raceData.LapCount > 1 && i % (raceData.CPCount + 1) == 0)
        {
            UI::TableSetColumnIndex(1);
            UI::Text("Lap " + (i / (raceData.CpCount + 1) + 1));
            UI::TableNextRow();
        }

        auto @cpData = @context.m_CurrentEntry.m_Checkpoints[i];

        LeaderboardEntry @bestCheckpointsRun = g_State.m_Leaderboard.m_BestCheckpointsRun;
        LeaderboardEntry @pb = g_State.m_Leaderboard.m_FastestRun;

        bool pushedColor = false;
        if (bestCheckpointsRun !is null && bestCheckpointsRun.m_Checkpoints[i].m_TimeFromPreviousNoRespawn == cpData.m_TimeFromPreviousNoRespawn)
        {
            UI::PushStyleColor(UI::Col::Text, vec4(0xDD / 255.0f, 0xBB / 255.0f, 0x44 / 255.0f, 1));
            pushedColor = true;
        }

        UI::TableNextColumn();
        string cpName = i == context.m_CurrentEntry.m_Checkpoints.Length - 1 ? "Fin" : "" + (i + 1);
        UI::Text(cpName);

        UI::TableNextColumn();
        UI::Text(Time::Format(cpData.m_TimeFromStart));

        UI::TableNextColumn();
        UI::Text(Time::Format(cpData.m_TimeFromPrevious));

        UI::TableNextColumn();
        UI::Text(Time::Format(cpData.m_TimeFromPreviousNoRespawn));

        UI::TableNextColumn();
        UI::Text("" + cpData.m_Speed);

        UI::TableNextColumn();
        UI::Text("" + cpData.m_NumberRespawns);

        UI::TableNextColumn();
        if (bestCheckpointsRun !is null)
        {
            int delta = cpData.m_TimeFromPreviousNoRespawn - bestCheckpointsRun.m_Checkpoints[i].m_TimeFromPreviousNoRespawn;
            renderDelta(delta);
            UI::SameLine();
            UI::Text("(");
            UI::SameLine(0.0f, 0.0f);
            renderDeltaSpeed(cpData.m_Speed - bestCheckpointsRun.m_Checkpoints[i].m_Speed);
            UI::SameLine(0.0f, 0.0f);
            UI::Text(")");
        }
        else
        {
            UI::Text("");
        }

        UI::TableNextColumn();
        if (pb !is null && pb.m_Checkpoints.Length > i)
        {
            int delta = cpData.m_TimeFromPreviousNoRespawn - pb.m_Checkpoints[i].m_TimeFromPreviousNoRespawn;
            renderDelta(delta);
            UI::SameLine();
            UI::Text(" (");
            UI::SameLine(0.0f, 0.0f);
            renderDeltaSpeed(cpData.m_Speed - pb.m_Checkpoints[i].m_Speed);
            UI::SameLine(0.0f, 0.0f);
            UI::Text(")");
        }
        else
        {
            UI::Text("");
        }

        if (pushedColor)
        {
            UI::PopStyleColor();
        }
    }

    UI::EndTable();
}

void RenderLaps(const TableRenderContext&in context)
{
    UI::BeginTable("LapTimes" + context.m_CurrentRow, 8, UI::TableFlags::SizingFixedFit);

    UI::TableSetupColumn("Lap", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Time Acc", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Time NR", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn(Icons::Refresh, UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Delta Best", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Delta PB", UI::TableColumnFlags::WidthFixed);

    UI::TableHeadersRow();

    for (uint i = 0; i < context.m_CurrentEntry.m_Laps.Length; i++)
    {
        UI::TableNextRow();

        auto @lapData = @context.m_CurrentEntry.m_Laps[i];

        LeaderboardEntry @bestLapsRun = g_State.m_Leaderboard.m_BestLapsRun;
        LeaderboardEntry @pb = g_State.m_Leaderboard.m_FastestRun;

        bool pushedColor = false;

        if (bestLapsRun !is null && bestLapsRun.m_Laps[i].m_TimeFromPrevious == lapData.m_TimeFromPrevious)
        {
            UI::PushStyleColor(UI::Col::Text, vec4(0xDD / 255.0f, 0xBB / 255.0f, 0x44 / 255.0f, 1));
            pushedColor = true;
        }

        UI::TableNextColumn();
        UI::Text("" + (i + 1));

        UI::TableNextColumn();
        UI::Text(Time::Format(lapData.m_TimeFromStart));

        UI::TableNextColumn();
        UI::Text(Time::Format(lapData.m_TimeFromPrevious));

        UI::TableNextColumn();
        UI::Text(Time::Format(lapData.m_TimeFromPreviousNoRespawn));

        UI::TableNextColumn();
        UI::Text("" + lapData.m_NumberRespawns);

        UI::TableNextColumn();
        if (bestLapsRun !is null)
        {
            int delta = lapData.m_TimeFromPrevious - bestLapsRun.m_Laps[i].m_TimeFromPrevious;
            renderDelta(delta);
        }
        else
        {
            UI::Text("");
        }

        UI::TableNextColumn();
        if (pb !is null && pb.m_Laps.Length > i)
        {
            int delta = lapData.m_TimeFromPrevious - pb.m_Laps[i].m_TimeFromPrevious;
            renderDelta(delta);
        }
        else
        {
            UI::Text("");
        }

        if (pushedColor)
        {
            UI::PopStyleColor();
        }
    }


    UI::EndTable();
}

void renderText(const TableRenderContext&in context, const string&in text)
{
    if (text.Length == 0)
    {
        UI::Text("");
        return;
    }

    bool pushedColor = true;

    if (context.m_IsPlayerNewest)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeLast, 1));
    }
    else if (context.m_IsPlayerNewestCopium)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeLast, 1) * 0.8f);
    }
    else if (context.m_IsPlayerBest)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeBest * 1.4f, 1));
    }
    else if (context.m_IsPlayerBestCopium)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeBest * 0.9f, 1));
    }
    else if (context.m_IsPlayerSessionBest)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeSessionBest * 1.4f, 1));
    }
    else if (context.m_IsPlayerSessionBestCopium)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeSessionBest * 0.9f, 1));
    }
    else if (context.m_IsPlayerBestCheckpoints)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeBest * 0.7f, 1));
    }
    else if (context.m_IsPlayerSessionBestCheckpoints)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeSessionBest * 0.7f, 1));
    }
    else if (context.m_IsPlayerBestLaps)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeBest * 0.7f, 1));
    }
    else if (context.m_IsPlayerSessionBestLaps)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeSessionBest * 0.7f, 1));
    }
    else
    {
        pushedColor = false;
    }

    UI::Text(text);

    if (pushedColor)
    {
        UI::PopStyleColor();
    }
}

void renderDelta(int delta)
{
    auto deltaColor = delta < 0 ? vec4(settingColorDeltaBetter, 1) : (delta > 0 ? vec4(settingColorDeltaWorse, 1) : vec4(settingColorDeltaEqual, 1));
    string deltaStr = (delta > 0 ? "+" : (delta < 0 ? "" : "±")) + Time::Format(delta);

    UI::PushStyleColor(UI::Col::Text, deltaColor);
    UI::Text(deltaStr);
    UI::PopStyleColor();
}

void renderDeltaSpeed(int delta)
{
    auto deltaColor = delta < 0 ? vec4(settingColorDeltaBetter, 1) : (delta > 0 ? vec4(settingColorDeltaWorse, 1) : vec4(settingColorDeltaEqual, 1));
    string deltaStr = (delta > 0 ? "+" : (delta < 0 ? "" : "±")) + delta;

    UI::PushStyleColor(UI::Col::Text, deltaColor);
    UI::Text(deltaStr);
    UI::PopStyleColor();
}

}

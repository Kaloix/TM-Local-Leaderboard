void Render()
{
    if (settingDisplayLeaderboardWindow)
    {
        // Don't render the leaderboard if the setting is disabled
        LocalRecords::Render();
        LocalRecords::RenderDetailsWindow();
    }
    
    if (settingShowCurrentRun)
    {
        LocalRecords::CurrentRun::renderCurrentRun();
    }

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

namespace LocalRecords
{
int windowFlags = 0;
int g_DetailsWindowFlags = 0;

array<LeaderboardEntry @> g_TableRows;
array<TableColumn @> g_TableColumns;
array<TableColumn @> g_DetailColumns;

LeaderboardEntry @g_DetailsWindowEntry = null;

void InitRender()
{
    CurrentRun::InitRender();

    // Clear existing columns
    g_TableColumns.RemoveRange(0, g_TableColumns.Length);
    g_DetailColumns.RemoveRange(0, g_DetailColumns.Length);

    // Add all columns that are active
    for (uint i = 0; i < g_AllTableColumns.Length; ++i)
    {
        if (g_AllTableColumns[i].shouldDisplay())
        {
            g_TableColumns.InsertLast(@g_AllTableColumns[i]);
        }
        g_DetailColumns.InsertLast(@g_AllTableColumns[i]);
    }

    // Order columns
    g_TableColumns.Sort(columnSort);
    g_DetailColumns.Sort(columnSort);

    // Setup window flags
    windowFlags = UI::GetDefaultWindowFlags() | UI::WindowFlags::AlwaysAutoResize;
    if (!settingDisplayLeaderboardTitleBar)
        windowFlags |= UI::WindowFlags::NoTitleBar;
    g_DetailsWindowFlags = UI::GetDefaultWindowFlags() | UI::WindowFlags::AlwaysAutoResize;
}

void InitRows()
{
    if (g_State.m_CurrentMap == "")
        return;

    // Add rows to display
    g_TableRows.RemoveRange(0, g_TableRows.Length);

    if (g_State.m_Leaderboard.m_FastestRun !is null)
    {
        // Sum of best checkpoints overall and of the current session
        if (settingDisplayLeaderboardBestCheckpointsRun && g_State.m_Leaderboard.m_BestCheckpointsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_BestCheckpointsRun.m_Time)
            g_TableRows.InsertLast(g_State.m_Leaderboard.m_BestCheckpointsRun);
        if (settingDisplayLeaderboardSessionBestCheckpointsRun && g_State.m_Leaderboard.m_SessionBestCheckpointsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_SessionBestCheckpointsRun.m_Time
            && (g_State.m_Leaderboard.m_BestCheckpointsRun is null || g_State.m_Leaderboard.m_SessionBestCheckpointsRun.m_Time > g_State.m_Leaderboard.m_BestCheckpointsRun.m_Time))
            g_TableRows.InsertLast(g_State.m_Leaderboard.m_SessionBestCheckpointsRun);

        // Sum of best laps overall and of the current session
        if (settingDisplayLeaderboardBestLapsRun && g_State.m_Leaderboard.m_BestLapsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_BestLapsRun.m_Time)
            g_TableRows.InsertLast(g_State.m_Leaderboard.m_BestLapsRun);
        if (settingDisplayLeaderboardSessionBestLapsRun && g_State.m_Leaderboard.m_SessionBestLapsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_SessionBestLapsRun.m_Time)
            g_TableRows.InsertLast(g_State.m_Leaderboard.m_SessionBestLapsRun);
    }

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
        // Always add starred runs
        if (settingDisplayLeaderboardStarred && g_State.m_Leaderboard.m_Entries[i].m_IsStarred)
        {
            g_TableRows.InsertLast(@g_State.m_Leaderboard.m_Entries[i]);
            continue;
        }

        if (settingFilterPersonalBests && !g_State.m_Leaderboard.m_Entries[i].m_WasPersonalBest)
            continue;
        if (settingFilterSessionBests && !g_State.m_Leaderboard.m_Entries[i].m_WasSessionBest)
            continue;
        if (settingFilterSessionCurrent && g_State.m_Leaderboard.m_Entries[i].m_SessionNumber != g_State.m_Leaderboard.m_TotalNumberSessions)
            continue;

        if (@g_State.m_Leaderboard.m_NewestRun is @g_State.m_Leaderboard.m_Entries[i])
            continue;
        if (g_State.m_Leaderboard.m_Entries[i].m_Rank > settingDisplayLeaderboardNumberRanks)
            continue;
        g_TableRows.InsertLast(@g_State.m_Leaderboard.m_Entries[i]);
    }

    // Add medal entries
    array<LeaderboardEntry @> beatenMedals;
    array<LeaderboardEntry @> unbeatenMedals;
    int pbTime = g_State.m_Leaderboard.m_FastestRun !is null ? g_State.m_Leaderboard.m_FastestRun.m_Time : MAX_INT;
    for (uint i = 0; i < g_State.m_MedalEntries.Length; i++)
    {
        auto @entry = @g_State.m_MedalEntries[i];
        if (entry.m_Medal.IsVisible())
        {
            if (entry.m_Medal.GetTime() >= pbTime)
                beatenMedals.InsertLast(entry);
            else
                unbeatenMedals.InsertLast(entry);
        }
    }
    if (beatenMedals.Length > 0)
    {
        beatenMedals.Sort(timeSortDesc);
        for (uint i = 0; i < settingNumberBeatenMedals && i < beatenMedals.Length; i++)
        {
            g_TableRows.InsertLast(beatenMedals[i]);
        }
    }
    if (unbeatenMedals.Length > 0)
    {
        unbeatenMedals.Sort(timeSortAsc);
        for (uint i = 0; i < settingNumberUnbeatenMedals && i < unbeatenMedals.Length; i++)
        {
            g_TableRows.InsertLast(unbeatenMedals[i]);
        }
    }

    // Add custom entries
    if (settingDisplayLeaderboardCustomTimes)
    {
        for (uint i = 0; i < g_State.m_CustomTimeEntries.Length; i++)
        {
            if (g_State.m_CustomTimeEntries[i].m_Time > 0)
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
            return timeSortDesc(a, b);
        case LeaderboardSortDirection::Descending:
            return timeSortAsc(a, b);
        default:
            return false;
    }
}

bool timeSortAsc(const LeaderboardEntry @ const&in a, const LeaderboardEntry @ const&in b)
{
    return a.GetDisplayTime() > b.GetDisplayTime();
}

bool timeSortDesc(const LeaderboardEntry @ const&in a, const LeaderboardEntry @ const&in b)
{
    return a.GetDisplayTime() < b.GetDisplayTime();
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

    UI::PushFontSize(settingLeaderboardFontSize);
    UI::SetNextWindowBgAlpha(settingLeaderboardBackgroundTransparency);
    UI::SetNextWindowSizeConstraints(-1, 0, -1, settingDisplayLeaderboardMaxSize);

    bool open = true;
    UI::Begin("Local Records", open, windowFlags);

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

    if (settingDisplayLeaderboardStatistics)
    {
        UI::Text(Icons::ClockO + " " + Time::Format(g_State.GetSessionTime(), false) + " / " + Time::Format(g_State.m_Leaderboard.m_TotalTime, false));

        if (UI::IsItemHovered())
        {
            UI::BeginTooltip();
            UI::Text("Time in session / Time in total");
            UI::EndTooltip();
        }

        UI::SameLine();
        UI::Text(Icons::Flag + " " + formatPosition(g_State.m_Leaderboard.m_TotalNumberSessionFinishes, "0") + " / " + formatPosition(g_State.m_Leaderboard.m_TotalNumberFinishes, "0") + " / " + formatPosition(g_State.m_NumberGlobalPositions, "0"));

        if (UI::IsItemHovered())
        {
            UI::BeginTooltip();
            UI::Text("Session Finishes / Total Finishes / Global Positions");
            UI::EndTooltip();
        }
    }

    if (settingDisplayLeaderboard)
    {
        if (g_TableColumns.Length == 0)
        {
            UI::Text("No columns configured to display.");
            UI::End();
            return;
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
            UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
            UI::TableHeadersRow();
            UI::PopStyleColor();
        }

        // Table body
        auto context = TableRenderContext();
        for (uint i = 0; i < g_TableRows.Length; i++)
        {
            PrepareRenderContext(context, i);

            UI::TableNextRow();

            bool isRowHovered = false;
            bool isRowClicked = false;
            for (uint col = 0; col < g_TableColumns.Length; col++)
            {
                UI::TableNextColumn();
                g_TableColumns[col].renderBody(context);

                isRowHovered = isRowHovered || UI::IsItemHovered();
                isRowClicked = isRowClicked || UI::IsItemClicked();
            }

            if (isRowClicked)
            {
                @g_DetailsWindowEntry = @context.m_CurrentEntry;
            }

            if (settingDisplayLeaderboardTooltips && isRowHovered && g_DetailsWindowEntry !is context.m_CurrentEntry)
            {
                UI::BeginTooltip();
                RenderDetail(context);
                UI::EndTooltip();
            }
        }

        UI::EndTable();

        if (context.m_ShouldUpdateRows)
            InitRows();
        g_State.m_Leaderboard.Clean();
    }

    UI::End();

    UI::PopFontSize();
}

void RenderDetail(TableRenderContext&inout context)
{
    // Actions
    UI::BeginDisabled(context.m_CurrentEntry.m_Type == LeaderboardEntryType::Medal);
    if (UI::Button(Icons::Trash))
        g_State.m_Leaderboard.MarkForRemoval(@context.m_CurrentEntry);
    UI::EndDisabled();

    UI::SameLine();

    UI::BeginDisabled(context.m_CurrentEntry.m_Type != LeaderboardEntryType::Score);
    if (context.m_CurrentEntry.m_IsStarred) {
        if (UI::Button(Icons::Star))
        {
            context.m_CurrentEntry.m_IsStarred = false;
            context.m_ShouldUpdateRows = true;
        }
    }
    else {
        if (UI::Button(Icons::StarO))
        {
            context.m_CurrentEntry.m_IsStarred = true;
            context.m_ShouldUpdateRows = true;
        }
    }
    UI::EndDisabled();

    // Table
    UI::BeginTable("DetailTable" + context.m_CurrentRow, 2, UI::TableFlags::SizingFixedFit);

    UI::TableSetupColumn("#Property", UI::TableColumnFlags::WidthFixed, 200.0f);
    UI::TableSetupColumn("#Value", UI::TableColumnFlags::WidthStretch);

    for (uint c = 0; c < g_DetailColumns.Length; c++)
    {
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text(g_DetailColumns[c].GetName());
        UI::TableNextColumn();
        g_DetailColumns[c].renderBody(context);
    }

    UI::EndTable();

    UI::Separator();
    UI::Text("Checkpoints");
    if (context.m_CurrentEntry.m_Checkpoints.Length > 1)
        RenderCheckpoints(context);
    else
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.66f, 0.66f, 0.66f, 1.0f));
        UI::Text("No checkpoints available.");
        UI::PopStyleColor();
    }

    UI::Separator();
    UI::Text("Laps");
    if (context.m_CurrentEntry.m_Laps.Length > 1)
        RenderLaps(context);
    else
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.66f, 0.66f, 0.66f, 1.0f));
        UI::Text("No laps available.");
        UI::PopStyleColor();
    }

    UI::Separator();
    UI::Text("Global Position History");
    if (context.m_CurrentEntry.m_GlobalPositionHistory.Length > 0)
        RenderGlobalPositionHistory(context);
    else
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.66f, 0.66f, 0.66f, 1.0f));
        UI::Text("No history available.");
        UI::PopStyleColor();
    }
}

void RenderDetailsWindow()
{
    if (g_DetailsWindowEntry is null)
        return;

    UI::PushFontSize(settingLeaderboardFontSize);
    UI::SetNextWindowBgAlpha(settingLeaderboardBackgroundTransparency);
    UI::SetNextWindowSizeConstraints(-1, 0, -1, settingDisplayLeaderboardMaxSize);

    const auto mousePos = UI::GetMousePos();
    UI::SetNextWindowPos(mousePos.x, mousePos.y, UI::Cond::Once);

    bool open = true;
    UI::Begin("LocalRecords Details - " + g_DetailsWindowEntry.GetDisplayName(), open, g_DetailsWindowFlags);

    auto context = TableRenderContext();
    PrepareRenderContext(context, @g_DetailsWindowEntry);
    RenderDetail(context);

    UI::End();

    UI::PopFontSize();

    if (!open)
    {
        @g_DetailsWindowEntry = null;
    }
}

class TableRenderContext
{
    uint64 m_CurrentTime = Time::get_Stamp();

    uint m_CurrentRow = 0;
    LeaderboardEntry @m_CurrentEntry = null;

    // Flags for the current entry
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

    // Flags for modification that are applied after the render loop to avoid modifying the array while iterating over it
    bool m_ShouldUpdateRows = false;

}

void PrepareRenderContext(TableRenderContext&inout context, uint i)
{
    PrepareRenderContext(context, @g_TableRows[i]);
    context.m_CurrentRow = i;
}

void PrepareRenderContext(TableRenderContext&inout context, LeaderboardEntry@ const&in entry)
{
    context.m_CurrentRow = 0;
    @context.m_CurrentEntry = @entry;
    context.m_IsPlayerNewest = context.m_CurrentEntry is g_State.m_Leaderboard.m_NewestRun;
    context.m_IsPlayerBest = context.m_CurrentEntry is g_State.m_Leaderboard.m_FastestRun;
    context.m_IsPlayerSessionBest = context.m_CurrentEntry is g_State.m_Leaderboard.m_SessionFastestRun;
    context.m_IsPlayerNewestCopium = context.m_CurrentEntry is g_State.m_Leaderboard.m_NewestCopiumRun;
    context.m_IsPlayerBestCopium = context.m_CurrentEntry is g_State.m_Leaderboard.m_FastestCopiumRun;
    context.m_IsPlayerSessionBestCopium = context.m_CurrentEntry is g_State.m_Leaderboard.m_SessionFastestCopiumRun;
    context.m_IsPlayerBestCheckpoints = context.m_CurrentEntry is g_State.m_Leaderboard.m_BestCheckpointsRun;
    context.m_IsPlayerSessionBestCheckpoints = context.m_CurrentEntry is g_State.m_Leaderboard.m_SessionBestCheckpointsRun;
    context.m_IsPlayerBestLaps = context.m_CurrentEntry is g_State.m_Leaderboard.m_BestLapsRun;
    context.m_IsPlayerSessionBestLaps = context.m_CurrentEntry is g_State.m_Leaderboard.m_SessionBestLapsRun;
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

    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
    UI::TableHeadersRow();
    UI::PopStyleColor();

    for (uint i = 0; i < context.m_CurrentEntry.m_Checkpoints.Length; i++)
    {
        UI::TableNextRow();

        if (g_State.m_CurrentMapLapCount > 1 && i % (g_State.m_CurrentMapCpCount + 1) == 0)
        {
            UI::TableSetColumnIndex(1);
            UI::Text("Lap " + (i / (g_State.m_CurrentMapCpCount + 1) + 1));
            UI::TableNextRow();
        }

        auto @cpData = @context.m_CurrentEntry.m_Checkpoints[i];

        LeaderboardEntry @bestCheckpointsRun = g_State.m_Leaderboard.m_BestCheckpointsRun;
        LeaderboardEntry @pb = g_State.m_Leaderboard.m_FastestRun;

        bool pushedColor = false;
        if (bestCheckpointsRun !is null && bestCheckpointsRun.m_Checkpoints.Length > i && bestCheckpointsRun.m_Checkpoints[i].m_TimeFromPreviousNoRespawn == cpData.m_TimeFromPreviousNoRespawn)
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
        if (bestCheckpointsRun !is null && bestCheckpointsRun.m_Checkpoints.Length > i)
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

    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
    UI::TableHeadersRow();
    UI::PopStyleColor();

    for (uint i = 0; i < context.m_CurrentEntry.m_Laps.Length; i++)
    {
        UI::TableNextRow();

        auto @lapData = @context.m_CurrentEntry.m_Laps[i];

        LeaderboardEntry @bestLapsRun = g_State.m_Leaderboard.m_BestLapsRun;
        LeaderboardEntry @pb = g_State.m_Leaderboard.m_FastestRun;

        bool pushedColor = false;

        if (bestLapsRun !is null && bestLapsRun.m_Laps.Length > i && bestLapsRun.m_Laps[i].m_TimeFromPrevious == lapData.m_TimeFromPrevious)
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
        if (bestLapsRun !is null && bestLapsRun.m_Laps.Length > i)
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

void RenderGlobalPositionHistory(const TableRenderContext&in context)
{
    UI::BeginTable("GlobalPositionHistory" + context.m_CurrentRow, 4, UI::TableFlags::SizingFixedFit);

    UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Position", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Total Players", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Percentile", UI::TableColumnFlags::WidthFixed);

    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
    UI::TableHeadersRow();
    UI::PopStyleColor();

    for (uint i = 0; i < context.m_CurrentEntry.m_GlobalPositionHistory.Length; i++)
    {
        auto @data = @context.m_CurrentEntry.m_GlobalPositionHistory[i];

        UI::TableNextRow();

        UI::TableNextColumn();
        UI::Text(formatTimestamp(data.m_TimeStamp));

        UI::TableNextColumn();
        UI::Text(formatPosition(data.m_GlobalPosition));

        UI::TableNextColumn();
        UI::Text(formatPosition(data.m_GlobalPositionTotalPlayers));

        UI::TableNextColumn();
        UI::Text(formatPercentile(float(data.m_GlobalPosition) / float(g_State.m_NumberGlobalPositions)));
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
    auto deltaColor = delta < 0 ? vec4(settingColorDeltaWorse, 1) : (delta > 0 ? vec4(settingColorDeltaBetter, 1) : vec4(settingColorDeltaEqual, 1));
    string deltaStr = (delta > 0 ? "+" : (delta < 0 ? "" : "±")) + delta;

    UI::PushStyleColor(UI::Col::Text, deltaColor);
    UI::Text(deltaStr);
    UI::PopStyleColor();
}

void renderDeltaRespawns(int delta)
{
    auto deltaColor = delta < 0 ? vec4(settingColorDeltaBetter, 1) : (delta > 0 ? vec4(settingColorDeltaWorse, 1) : vec4(settingColorDeltaEqual, 1));
    string deltaStr = (delta > 0 ? "+" : (delta < 0 ? "" : "±")) + delta;

    UI::PushStyleColor(UI::Col::Text, deltaColor);
    UI::Text(deltaStr);
    UI::PopStyleColor();
}

string formatPosition(const uint position, const string&in defaultValue = "")
{
    if (position == 0)
        return defaultValue;
    if (position >= 100000)
        return "<" + (position / 1000) + "k";
    else
        return "" + position;
}

string formatPercentile(const float percentile, const string&in defaultValue = "")
{
    if (percentile <= 0.0f)
        return defaultValue;
    else
        return Math::Round(percentile * 100.0f, 2) + "%";
}

string formatTimestamp(const int64 timestamp)
{
    if (timestamp == 0)
    {
        return "";
    }

    auto time = Time::Parse(timestamp);
    return time.Year + "-" + Text::Format("%02d", time.Month) + "-" + Text::Format("%02d", time.Day) + " " + Text::Format("%02d", time.Hour) + ":" + Text::Format("%02d", time.Minute) + ":" + Text::Format("%02d", time.Second);
}

}

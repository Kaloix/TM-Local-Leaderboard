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

    if (settingStatisticsShow)
    {
        LocalRecords::Statistics::Render();
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

array<TableColumn @> g_TableColumns;
array<TableColumn @> g_DetailColumns;

LeaderboardRenderData @g_LeaderboardRenderData = null;
uint g_OpenDetails = 0;
bool g_IsDetailsOpen = false;

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
    if (!g_TableColumns.IsEmpty())
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
    array<LeaderboardEntry @> tableRows;
    auto @context = InitRowsContext();

    if (g_State.m_Leaderboard.m_FastestRun !is null)
    {
        // Sum of best checkpoints overall and of the current session
        if (settingDisplayLeaderboardBestCheckpointsRun && g_State.m_Leaderboard.m_BestCheckpointsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_BestCheckpointsRun.m_Time)
            tableRows.InsertLast(g_State.m_Leaderboard.m_BestCheckpointsRun);
        if (settingDisplayLeaderboardSessionBestCheckpointsRun && g_State.m_Leaderboard.m_SessionBestCheckpointsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_SessionBestCheckpointsRun.m_Time
            && (g_State.m_Leaderboard.m_BestCheckpointsRun is null || g_State.m_Leaderboard.m_SessionBestCheckpointsRun.m_Time > g_State.m_Leaderboard.m_BestCheckpointsRun.m_Time))
            tableRows.InsertLast(g_State.m_Leaderboard.m_SessionBestCheckpointsRun);

        // Sum of best laps overall and of the current session
        if (settingDisplayLeaderboardBestLapsRun && g_State.m_Leaderboard.m_BestLapsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_BestLapsRun.m_Time)
            tableRows.InsertLast(g_State.m_Leaderboard.m_BestLapsRun);
        if (settingDisplayLeaderboardSessionBestLapsRun && g_State.m_Leaderboard.m_SessionBestLapsRun !is null && g_State.m_Leaderboard.m_FastestRun.m_Time > g_State.m_Leaderboard.m_SessionBestLapsRun.m_Time)
            tableRows.InsertLast(g_State.m_Leaderboard.m_SessionBestLapsRun);
    }

    bool addedNewestCopium = false;
    bool addedFastestCopium = false;
    if (settingDisplayLeaderboardCopiumNewest && g_State.m_Leaderboard.m_NewestCopiumRun !is null)
    {
        tableRows.InsertLast(g_State.m_Leaderboard.m_NewestCopiumRun);
        addedNewestCopium = true;
    }
    if (settingDisplayLeaderboardCopiumFastest && g_State.m_Leaderboard.m_FastestCopiumRun !is null && (!addedNewestCopium || g_State.m_Leaderboard.m_FastestCopiumRun.m_ScoreNumber != g_State.m_Leaderboard.m_NewestCopiumRun.m_ScoreNumber))
    {
        tableRows.InsertLast(g_State.m_Leaderboard.m_FastestCopiumRun);
        addedFastestCopium = true;
    }
    if (settingDisplayLeaderboardCopiumSessionFastest && g_State.m_Leaderboard.m_SessionFastestCopiumRun !is null && (!addedNewestCopium || g_State.m_Leaderboard.m_SessionFastestCopiumRun.m_ScoreNumber != g_State.m_Leaderboard.m_NewestCopiumRun.m_ScoreNumber) && (!addedFastestCopium || g_State.m_Leaderboard.m_SessionFastestCopiumRun.m_ScoreNumber != g_State.m_Leaderboard.m_FastestCopiumRun.m_ScoreNumber))
        tableRows.InsertLast(g_State.m_Leaderboard.m_SessionFastestCopiumRun);

    // Always add the player's personal best and session best if the settings are enabled
    if (settingDisplayLeaderboardPersonalBest)
        context.AddRecord(tableRows, @g_State.m_Leaderboard.m_FastestRun);
    if (settingDisplayLeaderboardSessionBest)
        context.AddRecord(tableRows, @g_State.m_Leaderboard.m_SessionFastestRun);

    // Always add the player's latest run if the setting is enabled
    if (settingDisplayLeaderboardLatest)
        context.AddRecord(tableRows, @g_State.m_Leaderboard.m_NewestRun);

    for (uint i = 0; i < g_State.m_Leaderboard.m_Entries.Length; i++)
    {
        auto @entry = @g_State.m_Leaderboard.m_Entries[i];

        // Always add starred runs
        if (settingDisplayLeaderboardStarred && entry.m_IsStarred)
        {
            context.AddRecord(tableRows, @entry);
            continue;
        }

        // Filter by previous personal bests and session bests
        if (settingFilterPersonalBests && !entry.m_WasPersonalBest)
            continue;
        if (settingFilterSessionBests && !entry.m_WasSessionBest)
            continue;

        // Filter by the current session
        if (settingFilterSessionCurrent && !entry.IsCurrentSession())
            continue;

        // Filter the number of ranks displayed for each player
        if (entry.m_Rank > settingDisplayLeaderboardNumberRanks)
            continue;
        context.AddRecord(tableRows, @entry);
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
            tableRows.InsertLast(beatenMedals[i]);
        }
    }
    if (unbeatenMedals.Length > 0)
    {
        unbeatenMedals.Sort(timeSortAsc);
        for (uint i = 0; i < settingNumberUnbeatenMedals && i < unbeatenMedals.Length; i++)
        {
            tableRows.InsertLast(unbeatenMedals[i]);
        }
    }

    // Add custom entries
    if (settingDisplayLeaderboardCustomTimes)
    {
        for (uint i = 0; i < g_State.m_CustomTimeEntries.Length; i++)
        {
            if (g_State.m_CustomTimeEntries[i].m_Time > 0)
                tableRows.InsertLast(@g_State.m_CustomTimeEntries[i]);
        }
    }
    if (settingDisplayLeaderboardCustomPositions)
    {
        for (uint i = 0; i < g_CustomPositionEntries.Length; i++)
        {
            tableRows.InsertLast(@g_CustomPositionEntries[i]);
        }
    }

    // Sort rows
    switch (settingLeaderboardSortType)
    {
        case LeaderboardSortType::Time:
            tableRows.Sort(timeSort);
            break;
        case LeaderboardSortType::Chronological:
            tableRows.Sort(chronologicalSort);
            break;
    }

    // Convert to render data
    LeaderboardRenderData @renderData = LeaderboardRenderData();
    @g_LeaderboardRenderData = @renderData;

    // Prepare the header
    renderData.m_HeaderRow.Resize(g_AllTableColumns.Length);
    for (uint c = 0; c < g_AllTableColumns.Length; ++c)
    {
        const TableColumn @column = @g_AllTableColumns[c];
        string headerValue = column.GetHeaderValue();
        renderData.m_HeaderRow[c] = headerValue;
    }

    // Prepare the body data
    renderData.m_Rows.Resize(tableRows.Length);
    for (uint i = 0; i < tableRows.Length; ++i)
    {
        LeaderboardEntry @entry = @tableRows[i];

        LeaderboardRenderRow @renderRow = LeaderboardRenderRow();
        @renderData.m_Rows[i] = @renderRow;

        @renderRow.m_Entry = @entry;
        renderRow.m_CurrentRow = i;

        renderRow.m_IsPlayerNewest = entry is g_State.m_Leaderboard.m_NewestRun;
        renderRow.m_IsPlayerBest = entry is g_State.m_Leaderboard.m_FastestRun;
        renderRow.m_IsPlayerSessionBest = entry is g_State.m_Leaderboard.m_SessionFastestRun;
        renderRow.m_IsPlayerNewestCopium = entry is g_State.m_Leaderboard.m_NewestCopiumRun;
        renderRow.m_IsPlayerBestCopium = entry is g_State.m_Leaderboard.m_FastestCopiumRun;
        renderRow.m_IsPlayerSessionBestCopium = entry is g_State.m_Leaderboard.m_SessionFastestCopiumRun;
        renderRow.m_IsPlayerBestCheckpoints = entry is g_State.m_Leaderboard.m_BestCheckpointsRun;
        renderRow.m_IsPlayerSessionBestCheckpoints = entry is g_State.m_Leaderboard.m_SessionBestCheckpointsRun;
        renderRow.m_IsPlayerBestLaps = entry is g_State.m_Leaderboard.m_BestLapsRun;
        renderRow.m_IsPlayerSessionBestLaps = entry is g_State.m_Leaderboard.m_SessionBestLapsRun;


        if (entry.m_Type == LeaderboardEntryType::Score)
            renderRow.m_ValidComparisonTarget = renderRow.m_IsPlayerBest || renderRow.m_IsPlayerNewest || renderRow.m_IsPlayerSessionBest;
        else
            renderRow.m_ValidComparisonTarget = true;
        auto @timeDeltaColumn =  cast<TimeDeltaColumn>(g_AllTableColumns[TableColumnType::TimeDeltaColumn]);
        if (entry is timeDeltaColumn.m_ComparisonTarget.GetComparisonTargetEntry())
            renderRow.m_IsComparisonTarget = true;

        // Prepare the data for all table columns regardless of visibility for details and faster column changes
        renderRow.m_Cells.Resize(g_AllTableColumns.Length);
        for (uint c = 0; c < g_AllTableColumns.Length; ++c)
        {
            TableColumn @column = @g_AllTableColumns[c];

            LeaderboardRenderCell @renderCell = LeaderboardRenderCell();
            @renderRow.m_Cells[c] = @renderCell;

            column.PrepareBodyCell(renderRow, renderCell);
        }
    }

}

bool timeSort(const LeaderboardEntry @ const&in a, const LeaderboardEntry @ const&in b)
{
    // Sort by time if unequal
    if (a.GetDisplayTime() != b.GetDisplayTime())
    {
        return sortNumbers(a.GetDisplayTime(), b.GetDisplayTime());
    }

    // Sort by rank if both are scores
    if (a.m_Type == LeaderboardEntryType::Score && b.m_Type == LeaderboardEntryType::Score)
    {
        return sortNumbers(a.m_Rank, b.m_Rank);
    }

    // Sort by type
    return sortNumbers(GetTypePriority(a.m_Type), GetTypePriority(b.m_Type));
}

bool timeSortAsc(const LeaderboardEntry @ const&in a, const LeaderboardEntry @ const&in b)
{
    return a.GetDisplayTime() > b.GetDisplayTime();
}

bool timeSortDesc(const LeaderboardEntry @ const&in a, const LeaderboardEntry @ const&in b)
{
    return a.GetDisplayTime() < b.GetDisplayTime();
}

int GetTypePriority(const LeaderboardEntryType type)
{
    switch (type)
    {
        // Custom entries are global positions and can only be beaten by being faster
        case LeaderboardEntryType::CustomPosition:
            return 0;
        case LeaderboardEntryType::CustomTime:
            return 1;
        // Player scores should be above all other entries
        case LeaderboardEntryType::Score:
            return 2;
        // The order of these one do not really matter
        case LeaderboardEntryType::ScoreBestCheckpoints:
            return 3;
        case LeaderboardEntryType::ScoreBestLaps:
            return 4;
        case LeaderboardEntryType::ScoreCopium:
            return 5;
        // Medals can be beaten by tying them
        case LeaderboardEntryType::Medal:
            return 6;
        default:
            return 7;
    }
}

bool sortNumbers(const int a, const int b)
{
    switch (settingLeaderboardSortDirection)
    {
        case LeaderboardSortDirection::Ascending:
            return a < b;
        case LeaderboardSortDirection::Descending:
            return a > b;
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

    if (settingDisplayLeaderboardWindowHideWithUi && !UI::IsGameUIVisible())
    {
        return; // Don't render if the game UI is not visible
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

    if (settingDisplayLeaderboardActions)
    {
        if (UI::Button(Icons::Refresh))
        {
            InitLiveDataAsync();
        }

        UI::SameLine();

        const auto sortIcon = settingLeaderboardSortDirection == LeaderboardSortDirection::Ascending ? Icons::SortAsc : Icons::SortDesc;
        if (UI::Button(sortIcon))
        {
            settingLeaderboardSortDirection = settingLeaderboardSortDirection == LeaderboardSortDirection::Ascending ? LeaderboardSortDirection::Descending : LeaderboardSortDirection::Ascending;
            InitRows();
        }

        UI::SameLine();

        const auto sortTypeIcon = settingLeaderboardSortType == LeaderboardSortType::Time ? Icons::ClockO : Icons::Calendar;
        if (UI::Button(sortTypeIcon))
        {
            settingLeaderboardSortType = settingLeaderboardSortType == LeaderboardSortType::Time ? LeaderboardSortType::Chronological : LeaderboardSortType::Time;
            InitRows();
        }
    }

    if (settingDisplayLeaderboardZoneSelection && g_Zones.Length > 0)
    {
        if (UI::Button(Icons::ChevronLeft))
            SetZone((g_CurrentZoneIndex + 1) % g_Zones.Length);
        UI::SameLine();
        if(UI::Button(Icons::ChevronRight))
            SetZone(g_CurrentZoneIndex == 0 ? g_Zones.Length - 1 : g_CurrentZoneIndex - 1);
        UI::SameLine();
        UI::Text(GetCurrentZoneName());
    }


    if (settingDisplayLeaderboard)
        RenderLeaderboardTable();

    UI::End();

    UI::PopFontSize();

    if (!open)
        settingDisplayLeaderboardWindow = false;
}

void RenderLeaderboardTable()
{
    if (g_TableColumns.Length == 0)
    {
        UI::Text("No columns configured to display.");
        return;
    }

    UI::BeginTable("LeaderboardTable", g_TableColumns.Length, UI::TableFlags::SizingFixedFit);

    // Setup columns
    for (uint i = 0; i < g_TableColumns.Length; i++)
    {
        const int columnIndex = g_TableColumns[i].GetType();
        const string headerValue = g_LeaderboardRenderData.m_HeaderRow[columnIndex];
        UI::TableSetupColumn(headerValue, UI::TableColumnFlags::WidthFixed);
    }

    // Table header
    if (settingDisplayLeaderboardHeader)
    {
        UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
        UI::TableHeadersRow();
        UI::PopStyleColor();
    }

    // Table body
    bool shouldUpdateRows = false;
    for (uint i = 0; i < g_LeaderboardRenderData.m_Rows.Length; i++)
    {
        const LeaderboardRenderRow @renderRow = @g_LeaderboardRenderData.m_Rows[i];

        UI::TableNextRow();

        bool isRowHovered = false;
        bool isRowClicked = false;
        for (uint col = 0; col < g_TableColumns.Length; col++)
        {
            const TableColumn @column = g_TableColumns[col];

            const int columnIndex = column.GetType();
            const LeaderboardRenderCell @renderCell = @renderRow.m_Cells[columnIndex];

            UI::TableNextColumn();
            column.RenderBodyCell(renderRow, renderCell);

            if (column.EnableMouseInteraction())
            {
                isRowHovered = isRowHovered || UI::IsItemHovered();
                isRowClicked = isRowClicked || UI::IsItemClicked();
            }
        }

        if (isRowClicked)
        {
            g_OpenDetails = i;
            g_IsDetailsOpen = true;
        }

        if (settingDisplayLeaderboardTooltips && isRowHovered && (!g_IsDetailsOpen || i != g_OpenDetails))
        {
            UI::BeginTooltip();
            // shouldUpdateRows cannot be triggered from tooltip
            RenderDetail(renderRow, shouldUpdateRows);
            UI::EndTooltip();
        }
    }

    UI::EndTable();

    g_State.m_Leaderboard.Clean();
}

void RenderDetail(const LeaderboardRenderRow &in renderRow, bool &out shouldUpdateRows)
{
    // Actions
    UI::BeginDisabled(renderRow.m_Entry.m_Type == LeaderboardEntryType::Medal);
    if (UI::Button(Icons::Trash + "##" + renderRow.m_CurrentRow))
    {
        g_State.m_Leaderboard.MarkForRemoval(@renderRow.m_Entry);
        g_IsDetailsOpen = false;
    }
    UI::EndDisabled();

    UI::SameLine();

    UI::BeginDisabled(renderRow.m_Entry.m_Type != LeaderboardEntryType::Score);
    if (renderRow.m_Entry.m_IsStarred) {
        if (UI::Button(Icons::Star + "##" + renderRow.m_CurrentRow))
        {
            renderRow.m_Entry.m_IsStarred = false;
            shouldUpdateRows = true;
        }
    }
    else {
        if (UI::Button(Icons::StarO + "##" + renderRow.m_CurrentRow))
        {
            renderRow.m_Entry.m_IsStarred = true;
            shouldUpdateRows = true;
        }
    }
    UI::EndDisabled();

    UI::SameLine();

    UI::BeginDisabled(!renderRow.m_ValidComparisonTarget || renderRow.m_IsComparisonTarget);
    if (UI::Button(Icons::ClockO + "##" + renderRow.m_CurrentRow))
    {
        SetAsComparisonTarget(renderRow);
        shouldUpdateRows = true;
    }
    if(UI::IsItemHovered(UI::HoveredFlags::ForTooltip))
    {
        UI::BeginTooltip();
        UI::Text("Select as comparison target");
        UI::EndTooltip();
    }

    UI::EndDisabled();

    // Table
    UI::BeginTable("DetailTable" + renderRow.m_CurrentRow, 2, UI::TableFlags::SizingFixedFit);

    UI::TableSetupColumn("#Property", UI::TableColumnFlags::WidthFixed, 200.0f);
    UI::TableSetupColumn("#Value", UI::TableColumnFlags::WidthStretch);

    for (uint c = 0; c < g_DetailColumns.Length; c++)
    {
        const TableColumn @column = @g_DetailColumns[c];

        UI::TableNextRow();

        UI::TableNextColumn();
        UI::Text(column.GetName());

        UI::TableNextColumn();
        const uint columnIndex = uint(column.GetType());
        const LeaderboardRenderCell @renderCell = renderRow.m_Cells[columnIndex];
        g_DetailColumns[c].RenderBodyCell(renderRow, renderCell);
    }

    UI::EndTable();

    UI::Separator();
    UI::Text("Checkpoints");
    if (renderRow.m_Entry.m_Checkpoints.Length > 1)
        RenderCheckpoints(renderRow);
    else
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.66f, 0.66f, 0.66f, 1.0f));
        UI::Text("No checkpoints available.");
        UI::PopStyleColor();
    }

    UI::Separator();
    UI::Text("Laps");
    if (renderRow.m_Entry.m_Laps.Length > 1)
        RenderLaps(renderRow);
    else
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.66f, 0.66f, 0.66f, 1.0f));
        UI::Text("No laps available.");
        UI::PopStyleColor();
    }

    UI::Separator();
    UI::Text("Global Position History");
    if (renderRow.m_Entry.GetGlobalPositionHistory().Length > 0)
        RenderGlobalPositionHistory(renderRow);
    else
    {
        UI::PushStyleColor(UI::Col::Text, vec4(0.66f, 0.66f, 0.66f, 1.0f));
        UI::Text("No history available.");
        UI::PopStyleColor();
    }
}

void RenderDetailsWindow()
{
    if (!g_IsDetailsOpen)
        return;

    UI::PushFontSize(settingLeaderboardFontSize);
    UI::SetNextWindowBgAlpha(settingLeaderboardBackgroundTransparency);
    UI::SetNextWindowSizeConstraints(-1, 0, -1, settingDisplayLeaderboardMaxSize);

    bool open = true;
    UI::Begin("LocalRecords Details", open, g_DetailsWindowFlags);

    const LeaderboardRenderRow @renderRow = @g_LeaderboardRenderData.m_Rows[g_OpenDetails];
    bool shouldUpdateRows = false;
    RenderDetail(renderRow, shouldUpdateRows);

    UI::End();

    UI::PopFontSize();

    if (!open)
    {
        g_IsDetailsOpen = false;
    }

    if (shouldUpdateRows)
        InitRows();
}

class LeaderboardRenderData
{
    array<string> m_HeaderRow;
    array<LeaderboardRenderRow @> m_Rows;
}

class LeaderboardRenderRow
{
    uint m_CurrentRow = 0;

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

    bool m_ValidComparisonTarget = false;
    bool m_IsComparisonTarget = false;

    LeaderboardEntry @m_Entry;

    array<LeaderboardRenderCell @> m_Cells;
}

class LeaderboardRenderCell
{
    string m_Value = "";
    vec4 m_FontColor = vec4(1, 1, 1, 1);
}

class InitRowsContext
{
    bool m_AddedFastestRun = false;
    bool m_AddedSessionFastestRun = false;
    bool m_AddedNewestRun = false;

    void AddRecord(array<LeaderboardEntry @> &inout tableRows, LeaderboardEntry@ entry)
    {
        if (entry is null)
            return;

        if (entry is g_State.m_Leaderboard.m_FastestRun)
        {
            if (m_AddedFastestRun)
                return;
            m_AddedFastestRun = true;
        }
        if (entry is g_State.m_Leaderboard.m_SessionFastestRun)
        {
            if (m_AddedSessionFastestRun)
                return;
            m_AddedSessionFastestRun = true;
        }
        if (entry is g_State.m_Leaderboard.m_NewestRun)
        {
            if (m_AddedNewestRun)
                return;
            m_AddedNewestRun = true;
        }

        tableRows.InsertLast(@entry);
    }

}

void RenderCheckpoints(const LeaderboardRenderRow&in renderRow)
{
    UI::BeginTable("CheckpointTimes" + renderRow.m_CurrentRow, 8, UI::TableFlags::SizingFixedFit);

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

    for (uint i = 0; i < renderRow.m_Entry.m_Checkpoints.Length; i++)
    {
        UI::TableNextRow();

        if (g_State.m_CurrentMapLapCount > 1 && i % (g_State.m_CurrentMapCpCount + 1) == 0)
        {
            UI::TableSetColumnIndex(1);
            UI::Text("Lap " + (i / (g_State.m_CurrentMapCpCount + 1) + 1));
            UI::TableNextRow();
        }

        auto @cpData = @renderRow.m_Entry.m_Checkpoints[i];

        LeaderboardEntry @bestCheckpointsRun = g_State.m_Leaderboard.m_BestCheckpointsRun;
        LeaderboardEntry @pb = g_State.m_Leaderboard.m_FastestRun;

        bool pushedColor = false;
        if (bestCheckpointsRun !is null && bestCheckpointsRun.m_Checkpoints.Length > i && bestCheckpointsRun.m_Checkpoints[i].m_TimeFromPreviousNoRespawn == cpData.m_TimeFromPreviousNoRespawn)
        {
            UI::PushStyleColor(UI::Col::Text, vec4(0xDD / 255.0f, 0xBB / 255.0f, 0x44 / 255.0f, 1));
            pushedColor = true;
        }

        UI::TableNextColumn();
        string cpName = i == renderRow.m_Entry.m_Checkpoints.Length - 1 ? "Fin" : "" + (i + 1);
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

void RenderLaps(const LeaderboardRenderRow &in renderRow)
{
    UI::BeginTable("LapTimes" + renderRow.m_CurrentRow, 8, UI::TableFlags::SizingFixedFit);

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

    for (uint i = 0; i < renderRow.m_Entry.m_Laps.Length; i++)
    {
        UI::TableNextRow();

        auto @lapData = @renderRow.m_Entry.m_Laps[i];

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

void RenderGlobalPositionHistory(const LeaderboardRenderRow &in renderRow)
{
    UI::BeginTable("GlobalPositionHistory" + renderRow.m_CurrentRow, 4, UI::TableFlags::SizingFixedFit);

    UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Position", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Total Players", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Percentile", UI::TableColumnFlags::WidthFixed);

    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
    UI::TableHeadersRow();
    UI::PopStyleColor();

    const auto globalPositionHistory = renderRow.m_Entry.GetGlobalPositionHistory();
    for (uint i = 0; i < globalPositionHistory.Length; i++)
    {
        auto @data = @globalPositionHistory[i];

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

vec4 GetRowColor(const LeaderboardRenderRow &in renderRow)
{
    if (renderRow.m_IsPlayerNewest)
    {
        return vec4(settingColorTimeLast, 1);
    }
    else if (renderRow.m_IsPlayerNewestCopium)
    {
        return vec4(settingColorTimeLast, 1) * 0.8f;
    }
    else if (renderRow.m_IsPlayerBest)
    {
        return vec4(settingColorTimeBest * 1.4f, 1);
    }
    else if (renderRow.m_IsPlayerBestCopium)
    {
        return vec4(settingColorTimeBest * 0.9f, 1);
    }
    else if (renderRow.m_IsPlayerSessionBest)
    {
        return vec4(settingColorTimeSessionBest * 1.4f, 1);
    }
    else if (renderRow.m_IsPlayerSessionBestCopium)
    {
        return vec4(settingColorTimeSessionBest * 0.9f, 1);
    }
    else if (renderRow.m_IsPlayerBestCheckpoints)
    {
        return vec4(settingColorTimeBest * 0.7f, 1);
    }
    else if (renderRow.m_IsPlayerSessionBestCheckpoints)
    {
        return vec4(settingColorTimeSessionBest * 0.7f, 1);
    }
    else if (renderRow.m_IsPlayerBestLaps)
    {
        return vec4(settingColorTimeBest * 0.7f, 1);
    }
    else if (renderRow.m_IsPlayerSessionBestLaps)
    {
        return vec4(settingColorTimeSessionBest * 0.7f, 1);
    }
    else
    {
        return vec4(1, 1, 1, 1);
    }
}

vec4 GetDeltaColor(int delta)
{
    return delta < 0 ? vec4(settingColorDeltaBetter, 1) : (delta > 0 ? vec4(settingColorDeltaWorse, 1) : vec4(settingColorDeltaEqual, 1));
}

string GetDeltaString(int delta)
{
    return (delta > 0 ? "+" : (delta < 0 ? "" : "±")) + Time::Format(delta);
}

void renderDelta(int delta)
{
    auto deltaColor = GetDeltaColor(delta);
    string deltaStr = GetDeltaString(delta); 

    UI::PushStyleColor(UI::Col::Text, deltaColor);
    UI::Text(deltaStr);
    UI::PopStyleColor();
}

vec4 GetDeltaSpeedColor(int delta)
{
    return delta < 0 ? vec4(settingColorDeltaWorse, 1) : (delta > 0 ? vec4(settingColorDeltaBetter, 1) : vec4(settingColorDeltaEqual, 1));
}

string GetDeltaSpeedString(int delta)
{
    return (delta > 0 ? "+" : (delta < 0 ? "" : "±")) + delta;
}

void renderDeltaSpeed(int delta)
{
    auto deltaColor = GetDeltaSpeedColor(delta);
    string deltaStr = GetDeltaSpeedString(delta);

    UI::PushStyleColor(UI::Col::Text, deltaColor);
    UI::Text(deltaStr);
    UI::PopStyleColor();
}

void renderDeltaRespawns(int delta)
{
    auto deltaColor = GetDeltaColor(delta);
    string deltaStr = GetDeltaSpeedString(delta);

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

void SetAsComparisonTarget(const LeaderboardRenderRow &in row)
{
    auto @entry = row.m_Entry;
    auto @timeDeltaColumn =  cast<TimeDeltaColumn>(g_AllTableColumns[TableColumnType::TimeDeltaColumn]);

    switch(entry.m_Type)
    {
        case LeaderboardEntryType::CustomPosition:
        {
            auto @ct = cast<CustomPositionComparisonTarget>(@g_ComparisonTargets[ComparisonTargetType::CustomPosition]);
            ct.m_CustomEntryId = entry.m_Id;
            @timeDeltaColumn.m_ComparisonTarget = @ct;
            break;
        }
        case LeaderboardEntryType::CustomTime:
        {
            auto @ct = cast<CustomTimeComparisonTarget>(@g_ComparisonTargets[ComparisonTargetType::CustomTime]);
            ct.m_CustomEntryId = entry.m_Id;
            @timeDeltaColumn.m_ComparisonTarget = @ct;
            break;
        }
        case LeaderboardEntryType::Medal:
        {
            switch (entry.m_Medal.GetType())
            {
#if DEPENDENCY_CHAMPIONMEDALS
                case MedalType::Champion:
                {
                    @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::ChampionMedal];
                    break;
                }
#endif
#if DEPENDENCY_WARRIORMEDALS
                case MedalType::Warrior:
                {
                    @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::WarriorMedal];
                    break;
                }
#endif
                case MedalType::Author:
                {
                    @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::AuthorMedal];
                    break;
                }
                case MedalType::Gold:
                {
                    @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::GoldMedal];
                    break;
                }
                case MedalType::Silver:
                {
                    @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::SilverMedal];
                    break;
                }
                case MedalType::Bronze:
                {
                    @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::BronzeMedal];
                    break;
                }
            }
            break;
        }
        case LeaderboardEntryType::Score:
        {
            if (row.m_IsPlayerBest)
                @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::FastestRun];
            else if (row.m_IsPlayerSessionBest)
                @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::SessionFastestRun];
            else if (row.m_IsPlayerNewest)
                @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::NewestRun];
            break;
        }
        case LeaderboardEntryType::ScoreBestCheckpoints:
        {
            @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::BestCheckpoints];
            break;
        }
        case LeaderboardEntryType::ScoreBestLaps:
        {
            if (row.m_IsPlayerBestLaps)
                @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::BestLaps];
            else if (row.m_IsPlayerSessionBestLaps)
                @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::SessionBestLaps];
            break;
        }
        case LeaderboardEntryType::ScoreCopium:
        {
            if (row.m_IsPlayerBestCopium)
                @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::FastestCopium];
            else if (row.m_IsPlayerNewestCopium)
                @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::NewestCopium];
            else if (row.m_IsPlayerSessionBestCopium)
                @timeDeltaColumn.m_ComparisonTarget = @g_ComparisonTargets[ComparisonTargetType::SessionFastestCopium];
            break;
        }

    }

    saveSettings();
}

}

namespace LocalRecords
{

namespace CurrentRun
{

int windowFlags = 0;
uint g_FocusedColumn = 0;

CurrentRunRenderData @g_CurrentRunRenderData = null;

void InitRender()
{
    // Setup window flags
    windowFlags = UI::GetDefaultWindowFlags() | UI::WindowFlags::AlwaysAutoResize;
    if (!settingCurrentRunDisplayTitleBar)
        windowFlags |= UI::WindowFlags::NoTitleBar;
}

void OnStart()
{
    if (settingCurrentRunKeepLastUntilFirstCp)
        return;
    PrepareCurrentRun();
}

void OnUpdate()
{
    if (g_CurrentRunRenderData is null)
        return;

    if (settingCurrentRunKeepLastUntilFirstCp)
    {
        // Keep the data of the last run before reaching first CP
        const uint cp = g_State.m_CurrentCheckpoints.Length;
        if (cp == 0)
            return;
        else if (cp == 1)
            PrepareCurrentRun();
    }

    UpdateCurrentCp(g_CurrentRunRenderData);
}

void Shutdown()
{
    @g_CurrentRunRenderData = null;
}

void CurrentRunOnSettingsChanged()
{
    if (settingShowCurrentRun && g_CurrentRunRenderData is null)
        PrepareCurrentRun();
    if (!settingShowCurrentRun && g_CurrentRunRenderData !is null)
        Shutdown();
}

void PrepareCurrentRun()
{
    @g_CurrentRunRenderData = CurrentRunRenderData();

    PrepareCurrentRunHeader(g_CurrentRunRenderData);
    PrepareCurrentRunRows(g_CurrentRunRenderData);
}

void PrepareCurrentRunHeader(CurrentRunRenderData &inout renderData)
{
    if (settingCurrentRunShowCp)
        renderData.m_HeaderRow.InsertLast("CP");
    if (settingCurrentRunShowPosition)
        renderData.m_HeaderRow.InsertLast(Icons::Trophy);

    for (uint col = 0; col < g_AllCurrentRunColumns.Length; ++col)
    {
        const auto @column = @g_AllCurrentRunColumns[col];
        string icon = column.GetHeaderValue();

        if (column.m_ShowValue)
        {
            renderData.m_HeaderRow.InsertLast(icon);
            icon = "";
        }
        if (column.m_ShowDelta)
        {
            renderData.m_HeaderRow.InsertLast(icon);
            icon = "";
        }
        if (column.m_ShowPos)
            renderData.m_HeaderRow.InsertLast(icon);
    }
}

void PrepareCurrentRunRows(CurrentRunRenderData &inout renderData)
{
    renderData.m_Rows.Resize(g_State.GetCurrentMapTotalCpCount());

    for (uint cp = 0; cp < g_State.GetCurrentMapTotalCpCount(); ++cp)
    {
        auto @row = CurrentRunRenderRow();
        @renderData.m_Rows[cp] = @row;

        row.m_Cells.Resize(renderData.m_HeaderRow.Length);

        uint cellIndex = 0;
        CurrentRunRenderCell @cell = null;

        if (settingCurrentRunShowCp)
        {
            @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
            cell.m_Value = cp == g_State.GetCurrentMapTotalCpCount() - 1 ? "Fin" : "" + (cp + 1);
        }

        const auto @comparisonCheckpointData = (g_State.m_CurrentRunComparisonCheckpoints.Length > cp) ? @g_State.m_CurrentRunComparisonCheckpoints[cp] : null;

        if (cp < g_State.m_CurrentCheckpoints.Length)
        {
            const auto @checkpointData = @g_State.m_CurrentCheckpoints[cp];

            if (settingCurrentRunShowPosition)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = "" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, settingCurrentRunCheckpointPosition) + 1);
            }

            for (uint col = 0; col < g_AllCurrentRunColumns.Length; ++col)
            {
                const auto @column = @g_AllCurrentRunColumns[col];

                if (column.m_ShowValue)
                {
                    @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                    column.PrepareValue(checkpointData, cell);
                }
                if (column.m_ShowDelta)
                {
                    @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                    if (comparisonCheckpointData !is null)
                        column.PrepareDelta(checkpointData, comparisonCheckpointData, cell);
                }
                if (column.m_ShowPos)
                {
                    @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                    cell.m_Value = "(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, column.GetComparison()) + 1) + ")";
                }
            }
        }
        else
        {
            while(cellIndex < renderData.m_HeaderRow.Length)
            {
                InitCell(row.m_Cells, cellIndex, cellIndex);
            }
        }
    }
}

void UpdateCurrentCp(CurrentRunRenderData &inout renderData)
{
    const uint cp = g_State.m_CurrentCheckpoints.Length;

    // Reached the finish
    if (cp >= renderData.m_Rows.Length || !settingCurrentRunShowCurrentCp)
        return;

    CurrentRunRenderRow @row = @renderData.m_Rows[cp];
    const auto @comparisonCheckpointData = (g_State.m_CurrentRunComparisonCheckpoints.Length > cp) ? @g_State.m_CurrentRunComparisonCheckpoints[cp] : null;
    const auto @raceData = @MLFeed::GetRaceData_V4();
    const auto @player = @raceData.GetPlayer_V4(MLFeed::LocalPlayersName);

    uint cellIndex = 0;
    CurrentRunRenderCell @cell = null;

    if (settingCurrentRunShowCp)
    {
        @cell = @GetCell(row.m_Cells, cellIndex, cellIndex);
        cell.m_Value = cp == g_State.GetCurrentMapTotalCpCount() - 1 ? "Fin" : "" + (cp + 1);
    }

    if (settingCurrentRunShowPosition)
        cellIndex += 1;

    const auto now = Time::get_Now();
    const auto speed = GetPlayerSpeed();
    for (uint col = 0; col < g_AllCurrentRunColumns.Length; ++col)
    {
        const auto @column = @g_AllCurrentRunColumns[col];

        if (column.m_ShowValue)
        {
            @cell = @GetCell(row.m_Cells, cellIndex, cellIndex);
            column.PrepareValueCurrent(cp, now, speed, player, cell);
        }
        if (column.m_ShowDelta)
        {
            @cell = @GetCell(row.m_Cells, cellIndex, cellIndex);
            if (comparisonCheckpointData !is null)
                column.PrepareDeltaCurrent(cp, now, speed, player, comparisonCheckpointData, cell);
        }
        if (column.m_ShowPos)
            cellIndex += 1;
    }
}

CurrentRunRenderCell@ InitCell(array<CurrentRunRenderCell @> &inout cells, const int cellIndexIn, int &out cellIndexOut)
{
    auto @cell = CurrentRunRenderCell();
    @cells[cellIndexIn] = @cell;
    cellIndexOut = cellIndexIn + 1;
    return @cell;
}

CurrentRunRenderCell@ GetCell(array<CurrentRunRenderCell @> &inout cells, const int cellIndexIn, int &out cellIndexOut)
{
    cellIndexOut = cellIndexIn + 1;
    return @cells[cellIndexIn];
}

void renderCurrentRun()
{
    if (g_State.m_CurrentMap == "")
    {
        return; // Don't render if no map is loaded
    }

    if (settingCurrentRunHideWithUi && !UI::IsGameUIVisible())
    {
        return; // Don't render if the game UI is not visible
    }

    UI::PushFontSize(settingCurrentRunFontSize);
    UI::SetNextWindowBgAlpha(settingCurrentRunBackgroundTransparency);
    UI::SetNextWindowSizeConstraints(-1, 0, -1, settingCurrentRunMaxSize);

    bool open = true;
    UI::Begin("LocalRecords current run", open, windowFlags);

    renderCurrentRunInfo();

    UI::End();

    UI::PopFontSize();
}

void renderCurrentRunInfo()
{
    if (g_CurrentRunRenderData.m_HeaderRow.Length == 0)
        return;

    UI::BeginTable("CurrentRunInfo", g_CurrentRunRenderData.m_HeaderRow.Length, UI::TableFlags::SizingFixedFit);

    for (uint i = 0; i < g_CurrentRunRenderData.m_HeaderRow.Length; ++i)
        UI::TableSetupColumn("" + i, UI::TableColumnFlags::WidthFixed);

    // Table header
    if (settingCurrentRunShowHeader)
    {
        UI::TableNextRow();
        for (uint i = 0; i < g_CurrentRunRenderData.m_HeaderRow.Length; ++i)
        {
            UI::TableNextColumn();
            UI::Text(g_CurrentRunRenderData.m_HeaderRow[i]);
        }
    }

    // Table body
    RenderCpsForLap();

    UI::EndTable();
}

void RenderCpsForLap()
{
    for (uint cp = 0; cp < g_CurrentRunRenderData.m_Rows.Length; ++cp)
    {
        if (g_State.m_CurrentMapLapCount > 1 && cp % (g_State.m_CurrentMapCpCount + 1) == 0)
        {
            UI::TableNextRow();
            UI::TableNextColumn();
            UI::Text("Lap " + (int(cp / g_State.m_CurrentMapCpCount) + 1));
        }

        UI::TableNextRow();
        const auto @row = @g_CurrentRunRenderData.m_Rows[cp];

        if (cp == g_State.m_CurrentCheckpoints.Length && g_FocusedColumn != cp)
        {
            g_FocusedColumn = cp;
            UI::SetScrollHereY();
        }

        for (uint i = 0; i < row.m_Cells.Length; ++i)
        {
            UI::TableNextColumn();
            const auto @renderCell = @row.m_Cells[i];

            UI::PushStyleColor(UI::Col::Text, renderCell.m_FontColor);
            UI::Text(renderCell.m_Value);
            UI::PopStyleColor();
        }

    }
}

class CurrentRunRenderData
{
    array<string> m_HeaderRow;
    array<CurrentRunRenderRow @> m_Rows;
}

class CurrentRunRenderRow
{
    uint m_CurrentLap = 0;
    array<CurrentRunRenderCell @> m_Cells;
}

class CurrentRunRenderCell
{
    string m_Value = "";
    vec4 m_FontColor = vec4(1, 1, 1, 1);
}


}

}

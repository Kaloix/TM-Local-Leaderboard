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

void OnUpdate()
{
    if (g_CurrentRunRenderData is null)
        return;
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

    // Time from start
    string icon = Icons::ClockO;
    if (settingCurrentRunShowTime)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##AccValue");
        icon = "";
    }
    if (settingCurrentRunShowTimeDelta)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##AccDelta");
        icon = "";
    }
    if (settingCurrentRunShowTimePosition)
        renderData.m_HeaderRow.InsertLast(icon + "##AccPosition");

    // Speed
    icon = Icons::Tachometer;
    if (settingCurrentRunShowSpeed)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##SpeedValue");
        icon = "";
    }
    if (settingCurrentRunShowSpeedDelta)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##SpeedDelta");
        icon = "";
    }
    if (settingCurrentRunShowSpeedPosition)
        renderData.m_HeaderRow.InsertLast(icon + "##SpeedPosition");

    // Time from previous
    icon = Icons::FlagCheckered;
    if (settingCurrentRunShowCpTime)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##CpTimePosition");
        icon = "";
    }
    if (settingCurrentRunShowCpTimeDelta)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##CpTimeDelta");
        icon = "";
    }
    if (settingCurrentRunShowCpTimePosition)
        renderData.m_HeaderRow.InsertLast(icon + "##CpTimePosition");

    // Time from previous no respawn
    icon = Icons::Forward;
    if (settingCurrentRunShowCpTimeNr)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##CpTimeNrValue");
        icon = "";
    }
    if (settingCurrentRunShowCpTimeNrDelta)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##CpTimeNrDelta");
        icon = "";
    }
    if (settingCurrentRunShowCpTimeNrPosition)
        renderData.m_HeaderRow.InsertLast(icon + "##CpTimeNrPosition");
    
    // Time from start no respawn
    icon = Icons::FastForward;
    if (settingCurrentRunShowTimeNr)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##AccNrValue");
        icon = "";
    }
    if (settingCurrentRunShowTimeNrDelta)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##AccNrDelta");
        icon = "";
    }
    if (settingCurrentRunShowTimeNrPosition)
        renderData.m_HeaderRow.InsertLast(icon + "##AccNrPosition");

    // Number of respawns
    icon = Icons::Refresh;
    if (settingCurrentRunShowNumberRespawns)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##NumberRespawnsValue");
        icon = "";
    }
    if (settingCurrentRunShowNumberRespawnsDelta)
    {
        renderData.m_HeaderRow.InsertLast(icon + "##NumberRespawnsDelta");
        icon = "";
    }
    if (settingCurrentRunShowNumberRespawnsPosition)
        renderData.m_HeaderRow.InsertLast(icon + "##NumberRespawnsPosition");
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
                cell.m_Value = "" + g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, settingCurrentRunCheckpointPosition) + 1;
            }

            // Time from start
            if (settingCurrentRunShowTime)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = Time::Format(checkpointData.m_TimeFromStart);
            }
            if (settingCurrentRunShowTimeDelta)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                if (comparisonCheckpointData !is null)
                {
                    const int delta = checkpointData.m_TimeFromStart - comparisonCheckpointData.m_TimeFromStart;
                    cell.m_Value = GetDeltaString(delta);
                    cell.m_FontColor = GetDeltaColor(delta);
                }
            }
            if (settingCurrentRunShowTimePosition)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = "(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::TimeFromStart) + 1) + ")";
            }

            // Speed
            if (settingCurrentRunShowSpeed)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = "" + checkpointData.m_Speed;
            }
            if (settingCurrentRunShowSpeedDelta)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                if (comparisonCheckpointData !is null)
                {
                    const int delta = checkpointData.m_Speed - comparisonCheckpointData.m_Speed;
                    cell.m_Value = GetDeltaSpeedString(delta);
                    cell.m_FontColor = GetDeltaSpeedColor(delta);
                }
            }
            if (settingCurrentRunShowSpeedPosition)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = "(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::Speed) + 1) + ")";
            }

            // Time from previous
            if (settingCurrentRunShowCpTime)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = Time::Format(checkpointData.m_TimeFromPrevious);
            }
            if (settingCurrentRunShowCpTimeDelta)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                if (comparisonCheckpointData !is null)
                {
                    int delta = checkpointData.m_TimeFromPrevious - comparisonCheckpointData.m_TimeFromPrevious;
                    cell.m_Value = GetDeltaString(delta);
                    cell.m_FontColor = GetDeltaColor(delta);
                }
            }
            if (settingCurrentRunShowCpTimePosition)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = "(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::TimeFromPrevious) + 1) + ")";
            }

            // Time from previous no respawn
            if (settingCurrentRunShowCpTimeNr)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = Time::Format(checkpointData.m_TimeFromPreviousNoRespawn);
            }
            if (settingCurrentRunShowCpTimeNrDelta)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                if (comparisonCheckpointData !is null)
                {
                    int delta = checkpointData.m_TimeFromPreviousNoRespawn - comparisonCheckpointData.m_TimeFromPreviousNoRespawn;
                    cell.m_Value = GetDeltaString(delta);
                    cell.m_FontColor = GetDeltaColor(delta);
                }
            }
            if (settingCurrentRunShowCpTimeNrPosition)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = "(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::TimeFromPreviousNoRespawn) + 1) + ")";
            }

            // Time from start no respawn
            if (settingCurrentRunShowTimeNr)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = Time::Format(checkpointData.m_TimeFromStartNoRespawn);
            }
            if (settingCurrentRunShowTimeNrDelta)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                if (comparisonCheckpointData !is null)
                {
                    int delta = checkpointData.m_TimeFromStartNoRespawn - comparisonCheckpointData.m_TimeFromStartNoRespawn;
                    cell.m_Value = GetDeltaString(delta);
                    cell.m_FontColor = GetDeltaColor(delta);
                }
            }
            if (settingCurrentRunShowTimeNrPosition)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = "(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::TimeFromStartNoRespawn) + 1) + ")";
            }

            // Number of respawns
            if (settingCurrentRunShowNumberRespawns)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = "" + checkpointData.m_NumberRespawns;
            }
            if (settingCurrentRunShowNumberRespawnsDelta)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                if (comparisonCheckpointData !is null)
                {
                    int delta = checkpointData.m_NumberRespawns - comparisonCheckpointData.m_NumberRespawns;
                    cell.m_Value = GetDeltaSpeedString(delta);
                    cell.m_FontColor = GetDeltaColor(delta);
                }
            }
            if (settingCurrentRunShowNumberRespawnsPosition)
            {
                @cell = InitCell(row.m_Cells, cellIndex, cellIndex);
                cell.m_Value = "(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::NumberRespawns) + 1) + ")";
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
    if (cp >= renderData.m_Rows.Length)
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

    int timeAcc = Time::get_Now() - g_State.m_LastStartTime;
    int time = Time::get_Now() - g_State.m_LastRespawn;
            
    // Time from start
    if (settingCurrentRunShowTime)
    {
        @cell = @GetCell(row.m_Cells, cellIndex, cellIndex);
        cell.m_Value = Time::Format(timeAcc);
    }
    if (settingCurrentRunShowTimeDelta)
    {
        @cell = @GetCell(row.m_Cells, cellIndex, cellIndex);
        if (comparisonCheckpointData !is null)
        {
            int delta = timeAcc - comparisonCheckpointData.m_TimeFromStart;
            cell.m_Value = GetDeltaString(delta);
            cell.m_FontColor = GetDeltaColor(delta);
        }
    }
    if (settingCurrentRunShowTimePosition)
        cellIndex += 1;

    // Speed
    const auto speed = GetPlayerSpeed();
    if (settingCurrentRunShowSpeed)
    {
        @cell = @GetCell(row.m_Cells, cellIndex, cellIndex);
        cell.m_Value = "" + speed;
    }
    if (settingCurrentRunShowSpeedDelta)
    {
        @cell = @GetCell(row.m_Cells, cellIndex, cellIndex);
        if (comparisonCheckpointData !is null)
        {
            int delta = speed - comparisonCheckpointData.m_Speed;
            cell.m_Value = GetDeltaSpeedString(delta);
            cell.m_FontColor = GetDeltaSpeedColor(delta);
        }
    }
    if (settingCurrentRunShowSpeedPosition)
        cellIndex += 1;

    // Time from previous
    if (settingCurrentRunShowCpTime)
        cellIndex += 1;
    if (settingCurrentRunShowCpTimeDelta)
        cellIndex += 1;
    if (settingCurrentRunShowCpTimePosition)
        cellIndex += 1;

    // Time from previous no respawn
    if (settingCurrentRunShowCpTimeNr)
    {
        @cell = @GetCell(row.m_Cells, cellIndex, cellIndex);
        cell.m_Value = Time::Format(time);
    }
    if (settingCurrentRunShowCpTimeNrDelta)
    {
        @cell = @GetCell(row.m_Cells, cellIndex, cellIndex);
        if (comparisonCheckpointData !is null)
        {
            int delta = time - comparisonCheckpointData.m_TimeFromPrevious;
            cell.m_Value = GetDeltaString(delta);
            cell.m_FontColor = GetDeltaColor(delta);
        }
    }
    if (settingCurrentRunShowCpTimeNrPosition)
        cellIndex += 1;

    // Time from start no respawn
    if (settingCurrentRunShowTimeNr)
        cellIndex += 1;
    if (settingCurrentRunShowTimeNrDelta)
        cellIndex += 1;
    if (settingCurrentRunShowTimeNrPosition)
        cellIndex += 1;

    // Number of respawns
    if (settingCurrentRunShowNumberRespawns)
    {
        @cell = @GetCell(row.m_Cells, cellIndex, cellIndex);
        if (player.NbRespawnsByCp.Length > cp)
            cell.m_Value = "" + player.NbRespawnsByCp[cp];
    }
    if (settingCurrentRunShowNumberRespawnsDelta)
    {
        @cell = @GetCell(row.m_Cells, cellIndex, cellIndex);
        if (player.NbRespawnsByCp.Length > cp && comparisonCheckpointData !is null)
        {
            int delta = player.NbRespawnsByCp[cp] - comparisonCheckpointData.m_NumberRespawns;
            cell.m_Value = GetDeltaSpeedString(delta);
            cell.m_FontColor = GetDeltaColor(delta);
        }
    }
    if (settingCurrentRunShowNumberRespawnsPosition)
        cellIndex += 1;
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
    {
        UI::TableSetupColumn(g_CurrentRunRenderData.m_HeaderRow[i], UI::TableColumnFlags::WidthFixed);
    }

    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
    UI::TableHeadersRow();
    UI::PopStyleColor();

    RenderCpsForLap(0);

    UI::EndTable();
}

void RenderCpsForLap(const uint lap)
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


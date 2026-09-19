namespace LocalRecords
{

namespace CurrentRun
{

int windowFlags = 0;
uint g_NumberColumns = 0;
uint g_FocusedColumn = 0;

void InitRender()
{
    // Setup window flags
    windowFlags = UI::GetDefaultWindowFlags() | UI::WindowFlags::AlwaysAutoResize;
    if (!settingCurrentRunDisplayTitleBar)
        windowFlags |= UI::WindowFlags::NoTitleBar;
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
    // Has to be done here and not after settings changed, otherwise a crash can occur
    g_NumberColumns = 0;
    if (settingCurrentRunShowCp)
        g_NumberColumns += 1;
    if (settingCurrentRunShowPosition)
        g_NumberColumns += 1;
    if (settingCurrentRunShowTime)
        g_NumberColumns += 1;
    if (settingCurrentRunShowTimeDelta)
        g_NumberColumns += 1;
    if (settingCurrentRunShowTimePosition)
        g_NumberColumns += 1;
    if (settingCurrentRunShowTimeNr)
        g_NumberColumns += 1;
    if (settingCurrentRunShowTimeNrDelta)
        g_NumberColumns += 1;
    if (settingCurrentRunShowTimeNrPosition)
        g_NumberColumns += 1;
    if (settingCurrentRunShowSpeed)
        g_NumberColumns += 1;
    if (settingCurrentRunShowSpeedDelta)
        g_NumberColumns += 1;
    if (settingCurrentRunShowSpeedPosition)
        g_NumberColumns += 1;
    if (settingCurrentRunShowCpTime)
        g_NumberColumns += 1;
    if (settingCurrentRunShowCpTimeDelta)
        g_NumberColumns += 1;
    if (settingCurrentRunShowCpTimePosition)
        g_NumberColumns += 1;
    if (settingCurrentRunShowCpTimeNr)
        g_NumberColumns += 1;
    if (settingCurrentRunShowCpTimeNrDelta)
        g_NumberColumns += 1;
    if (settingCurrentRunShowCpTimeNrPosition)
        g_NumberColumns += 1;
    if (settingCurrentRunShowNumberRespawns)
        g_NumberColumns += 1;
    if (settingCurrentRunShowNumberRespawnsDelta)
        g_NumberColumns += 1;
    if (settingCurrentRunShowNumberRespawnsPosition)
        g_NumberColumns += 1;

    UI::BeginTable("CurrentRunInfo", g_NumberColumns, UI::TableFlags::SizingFixedFit);

    if (settingCurrentRunShowCp)
        UI::TableSetupColumn("CP", UI::TableColumnFlags::WidthFixed);
    if (settingCurrentRunShowPosition)
        UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed);

    // Time from start
    string icon = Icons::ClockO;
    if (settingCurrentRunShowTime)
    {
        UI::TableSetupColumn(icon + "##AccValue", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowTimeDelta)
    {
        UI::TableSetupColumn(icon + "##AccDelta", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowTimePosition)
        UI::TableSetupColumn(icon + "##AccPosition", UI::TableColumnFlags::WidthFixed);

    // Speed
    icon = Icons::Tachometer;
    if (settingCurrentRunShowSpeed)
    {
        UI::TableSetupColumn(icon + "##SpeedValue", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowSpeedDelta)
    {
        UI::TableSetupColumn(icon + "##SpeedDelta", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowSpeedPosition)
        UI::TableSetupColumn(icon + "##SpeedPosition", UI::TableColumnFlags::WidthFixed);

    // Time from previous
    icon = Icons::FlagCheckered;
    if (settingCurrentRunShowCpTime)
    {
        UI::TableSetupColumn(icon + "##CpTimeValue", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowCpTimeDelta)
    {
        UI::TableSetupColumn(icon + "##CpTimeDelta", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowCpTimePosition)
        UI::TableSetupColumn(icon + "##CpTimePosition", UI::TableColumnFlags::WidthFixed);

    // Time from previous no respawn
    icon = Icons::Forward;
    if (settingCurrentRunShowCpTimeNr)
    {
        UI::TableSetupColumn(icon + "##CpTimeNrValue", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowCpTimeNrDelta)
    {
        UI::TableSetupColumn(icon + "##CpTimeNrDelta", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowCpTimeNrPosition)
        UI::TableSetupColumn(icon + "##CpTimeNrPosition", UI::TableColumnFlags::WidthFixed);

    
    // Time from start no respawn
    icon = Icons::FastForward;
    if (settingCurrentRunShowTimeNr)
    {
        UI::TableSetupColumn(icon + "##AccNrValue", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowTimeNrDelta)
    {
        UI::TableSetupColumn(icon + "##AccNrDelta", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowTimeNrPosition)
        UI::TableSetupColumn(icon + "##AccNrPosition", UI::TableColumnFlags::WidthFixed);

    // Number of respawns
    icon = Icons::Refresh;
    if (settingCurrentRunShowNumberRespawns)
    {
        UI::TableSetupColumn(icon + "##NumberRespawnsValue", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowNumberRespawnsDelta)
    {
        UI::TableSetupColumn(icon + "##NumberRespawnsDelta", UI::TableColumnFlags::WidthFixed);
        icon = "";
    }
    if (settingCurrentRunShowNumberRespawnsPosition)
        UI::TableSetupColumn(icon + "##NumberRespawnsPosition", UI::TableColumnFlags::WidthFixed);

    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
    UI::TableHeadersRow();
    UI::PopStyleColor();

    const auto @raceData = @MLFeed::GetRaceData_V4();
    const auto @player = @raceData.GetPlayer_V4(MLFeed::LocalPlayersName);

    for (uint lapIndex = 0; lapIndex < g_State.m_CurrentMapLapCount; ++lapIndex)
    {
        if (g_State.m_CurrentMapLapCount > 1)
        {
            UI::TableNextRow();
            UI::TableNextColumn();
            UI::Text("Lap " + (lapIndex + 1));
        }
        RenderCpsForLap(lapIndex, player);
    }

    UI::EndTable();
}

void RenderCpsForLap(const uint lap, const MLFeed::PlayerCpInfo_V4 &in player)
{
    uint cp = lap * (g_State.m_CurrentMapCpCount + 1);
    for (; cp < (lap + 1) * (g_State.m_CurrentMapCpCount + 1); ++cp)
    {
        UI::TableNextRow();

        if (settingCurrentRunShowCp)
        {
            UI::TableNextColumn();
            string cpName = cp == ((g_State.m_CurrentMapCpCount + 1) * g_State.m_CurrentMapLapCount) - 1 ? "Fin" : "" + (cp + 1);
            UI::Text(cpName);
        }

        const auto @comparisonCheckpointData = (g_State.m_CurrentRunComparisonCheckpoints.Length > cp) ? @g_State.m_CurrentRunComparisonCheckpoints[cp] : null;

        if (cp < g_State.m_CurrentCheckpoints.Length)
        {
            const auto @checkpointData = @g_State.m_CurrentCheckpoints[cp];

            if (settingCurrentRunShowPosition)
            {
                UI::TableNextColumn();
                UI::Text("" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, settingCurrentRunCheckpointPosition) + 1));
            }

            // Time from start
            if (settingCurrentRunShowTime)
            {
                UI::TableNextColumn();
                UI::Text(Time::Format(checkpointData.m_TimeFromStart));
            }
            if (settingCurrentRunShowTimeDelta)
            {
                UI::TableNextColumn();
                if (comparisonCheckpointData !is null)
                {
                    int delta = checkpointData.m_TimeFromStart - comparisonCheckpointData.m_TimeFromStart;
                    renderDelta(delta);
                }
            }
            if (settingCurrentRunShowTimePosition)
            {
                UI::TableNextColumn();
                UI::Text("(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::TimeFromStart) + 1) + ")");
            }

            // Speed
            if (settingCurrentRunShowSpeed)
            {
                UI::TableNextColumn();
                UI::Text("" + checkpointData.m_Speed);
            }
            if (settingCurrentRunShowSpeedDelta)
            {
                UI::TableNextColumn();
                if (comparisonCheckpointData !is null)
                {
                    int delta = checkpointData.m_Speed - comparisonCheckpointData.m_Speed;
                    renderDeltaSpeed(delta);
                }
            }
            if (settingCurrentRunShowSpeedPosition)
            {
                UI::TableNextColumn();
                UI::Text("(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::Speed) + 1) + ")");
            }

            // Time from previous
            if (settingCurrentRunShowCpTime)
            {
                UI::TableNextColumn();
                UI::Text(Time::Format(checkpointData.m_TimeFromPrevious));
            }
            if (settingCurrentRunShowCpTimeDelta)
            {
                UI::TableNextColumn();
                if (comparisonCheckpointData !is null)
                {
                    int delta = checkpointData.m_TimeFromPrevious - comparisonCheckpointData.m_TimeFromPrevious;
                    renderDelta(delta);
                }
            }
            if (settingCurrentRunShowCpTimePosition)
            {
                UI::TableNextColumn();
                UI::Text("(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::TimeFromPrevious) + 1) + ")");
            }

            // Time from previous no respawn
            if (settingCurrentRunShowCpTimeNr)
            {
                UI::TableNextColumn();
                UI::Text(Time::Format(checkpointData.m_TimeFromPreviousNoRespawn));
            }
            if (settingCurrentRunShowCpTimeNrDelta)
            {
                UI::TableNextColumn();
                if (comparisonCheckpointData !is null)
                {
                    int delta = checkpointData.m_TimeFromPreviousNoRespawn - comparisonCheckpointData.m_TimeFromPreviousNoRespawn;
                    renderDelta(delta);
                }
            }
            if (settingCurrentRunShowCpTimeNrPosition)
            {
                UI::TableNextColumn();
                UI::Text("(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::TimeFromPreviousNoRespawn) + 1) + ")");
            }

            // Time from start no respawn
            if (settingCurrentRunShowTimeNr)
            {
                UI::TableNextColumn();
                UI::Text(Time::Format(checkpointData.m_TimeFromStartNoRespawn));
            }
            if (settingCurrentRunShowTimeNrDelta)
            {
                UI::TableNextColumn();
                if (comparisonCheckpointData !is null)
                {
                    int delta = checkpointData.m_TimeFromStartNoRespawn - comparisonCheckpointData.m_TimeFromStartNoRespawn;
                    renderDelta(delta);
                }
            }
            if (settingCurrentRunShowTimeNrPosition)
            {
                UI::TableNextColumn();
                UI::Text("(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::TimeFromStartNoRespawn) + 1) + ")");
            }

            // Number of respawns
            if (settingCurrentRunShowNumberRespawns)
            {
                UI::TableNextColumn();
                UI::Text("" + checkpointData.m_NumberRespawns);
            }
            if (settingCurrentRunShowNumberRespawnsDelta)
            {
                UI::TableNextColumn();
                if (comparisonCheckpointData !is null)
                {
                    int delta = checkpointData.m_NumberRespawns - comparisonCheckpointData.m_NumberRespawns;
                    renderDeltaRespawns(delta);
                }
            }
            if (settingCurrentRunShowNumberRespawnsPosition)
            {
                UI::TableNextColumn();
                UI::Text("(" + (g_State.m_Leaderboard.GetSortedCheckpointRank(cp, checkpointData, CheckpointPositionComparison::NumberRespawns) + 1) + ")");
            }
        }
        else if (cp == g_State.m_CurrentCheckpoints.Length)
        {
            if (g_FocusedColumn != cp)
            {
                g_FocusedColumn = cp;
                UI::SetScrollHereY();
            }

            if (settingCurrentRunShowPosition)
                UI::TableNextColumn();

            int timeAcc = Time::get_Now() - g_State.m_LastStartTime;
            int time = Time::get_Now() - g_State.m_LastRespawn;
            
            // Time from start
            if (settingCurrentRunShowTime)
            {
                UI::TableNextColumn();
                UI::Text(Time::Format(timeAcc));
            }
            if (settingCurrentRunShowTimeDelta)
            {
                UI::TableNextColumn();

                if (comparisonCheckpointData !is null)
                {
                    int delta = timeAcc - comparisonCheckpointData.m_TimeFromStart;
                    renderDelta(delta);
                }
            }
            if (settingCurrentRunShowTimePosition)
                UI::TableNextColumn();

            // Speed
            const auto speed = GetPlayerSpeed();
            if (settingCurrentRunShowSpeed)
            {
                UI::TableNextColumn();
                UI::Text("" + speed);
            }
            if (settingCurrentRunShowSpeedDelta)
            {
                UI::TableNextColumn();
                if (comparisonCheckpointData !is null)
                {
                    int delta = speed - comparisonCheckpointData.m_Speed;
                    renderDeltaSpeed(delta);
                }
            }
            if (settingCurrentRunShowSpeedPosition)
                UI::TableNextColumn();

            // Time from previous
            if (settingCurrentRunShowCpTime)
                UI::TableNextColumn();
            if (settingCurrentRunShowCpTimeDelta)
                UI::TableNextColumn();
            if (settingCurrentRunShowCpTimePosition)
                UI::TableNextColumn();

            // Time from previous no respawn
            if (settingCurrentRunShowCpTimeNr)
            {
                UI::TableNextColumn();
                UI::Text(Time::Format(time));
            }
            if (settingCurrentRunShowCpTimeNrDelta)
            {
                UI::TableNextColumn();
                if (comparisonCheckpointData !is null)
                {
                    int delta = time - comparisonCheckpointData.m_TimeFromPrevious;
                    renderDelta(delta);
                }
            }
            if (settingCurrentRunShowCpTimeNrPosition)
                UI::TableNextColumn();

            // Time from start no respawn
            if (settingCurrentRunShowTimeNr)
                UI::TableNextColumn();
            if (settingCurrentRunShowTimeNrDelta)
                UI::TableNextColumn();
            if (settingCurrentRunShowTimeNrPosition)
                UI::TableNextColumn();

            // Number of respawns
            if (settingCurrentRunShowNumberRespawns)
            {
                UI::TableNextColumn();
                if (player.NbRespawnsByCp.Length > cp)
                    UI::Text("" + player.NbRespawnsByCp[cp]);
            }
            if (settingCurrentRunShowNumberRespawnsDelta)
            {
                UI::TableNextColumn();
                if (player.NbRespawnsByCp.Length > cp && comparisonCheckpointData !is null)
                {
                    int delta = player.NbRespawnsByCp[cp] - comparisonCheckpointData.m_NumberRespawns;
                    renderDeltaRespawns(delta);
                }
            }
            if (settingCurrentRunShowNumberRespawnsPosition)
                UI::TableNextColumn();

        }

    }
}


}

}


namespace LocalRecords
{

namespace CurrentRun
{

int windowFlags = 0;

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

    UI::PushFontSize(settingCurrentRunFontSize);
    UI::SetNextWindowBgAlpha(settingCurrentRunBackgroundTransparency);
    UI::SetNextWindowSizeConstraints(-1, 0, -1, settingDisplayLeaderboardMaxSize);

    bool open = true;
    UI::Begin("LocalRecords current run", open, windowFlags);

    renderCurrentRunInfo();

    UI::End();

    UI::PopFontSize();
}

void renderCurrentRunInfo()
{
    UI::BeginTable("CurrentRunInfo", 11, UI::TableFlags::SizingFixedFit);

    UI::TableSetupColumn("CP", UI::TableColumnFlags::WidthFixed); // 0
    UI::TableSetupColumn(Icons::ClockO, UI::TableColumnFlags::WidthFixed); // 1
    UI::TableSetupColumn("##ACC Delta", UI::TableColumnFlags::WidthFixed); // 2
    UI::TableSetupColumn(Icons::Tachometer, UI::TableColumnFlags::WidthFixed); // 3
    UI::TableSetupColumn("##Speed Delta", UI::TableColumnFlags::WidthFixed); // 4

    UI::TableSetupColumn(Icons::Forward, UI::TableColumnFlags::WidthFixed); // 5
    UI::TableSetupColumn("##NR Delta", UI::TableColumnFlags::WidthFixed); // 6
    UI::TableSetupColumn(Icons::FastForward, UI::TableColumnFlags::WidthFixed); // 7
    UI::TableSetupColumn("##Acc NR Delta", UI::TableColumnFlags::WidthFixed); // 8

    UI::TableSetupColumn(Icons::Refresh, UI::TableColumnFlags::WidthFixed); // 9
    UI::TableSetupColumn("##Number Respawns", UI::TableColumnFlags::WidthFixed); // 10

    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
    UI::TableHeadersRow();
    UI::PopStyleColor();

    const auto @raceData = @MLFeed::GetRaceData_V4();
    const auto @player = @raceData.GetPlayer_V4(MLFeed::LocalPlayersName);

    int timeNr = 0;
    int comparisonTimeNr = 0;

    // CPs
    for (uint i = 0; i <= g_State.m_CurrentMapCpCount; ++i)
    {
        UI::TableNextRow();

        UI::TableSetColumnIndex(0);
        string cpName = i == g_State.m_CurrentMapCpCount ? "Fin" : "" + (i + 1);
        UI::Text(cpName);

        const auto @comparisonCheckpointData = (g_State.m_CurrentRunComparisonCheckpoints.Length > i) ? @g_State.m_CurrentRunComparisonCheckpoints[i] : null;

        if (i < g_State.m_CurrentCheckpoints.Length)
        {
            const auto @checkpointData = @g_State.m_CurrentCheckpoints[i];

            UI::TableSetColumnIndex(1);
            UI::Text(Time::Format(checkpointData.m_TimeFromStart));

            if (comparisonCheckpointData !is null)
            {
                UI::TableSetColumnIndex(2);
                int delta = checkpointData.m_TimeFromStart - comparisonCheckpointData.m_TimeFromStart;
                renderDelta(delta);
            }

            UI::TableSetColumnIndex(3);
            UI::Text("" + checkpointData.m_Speed);

            if (comparisonCheckpointData !is null)
            {
                UI::TableSetColumnIndex(4);
                renderDeltaSpeed(checkpointData.m_Speed - comparisonCheckpointData.m_Speed);
            }

            UI::TableSetColumnIndex(5);
            UI::Text(Time::Format(checkpointData.m_TimeFromPreviousNoRespawn));

            if (comparisonCheckpointData !is null)
            {
                UI::TableSetColumnIndex(6);
                int delta = checkpointData.m_TimeFromPreviousNoRespawn - comparisonCheckpointData.m_TimeFromPreviousNoRespawn;
                renderDelta(delta);
            }

            timeNr += checkpointData.m_TimeFromPreviousNoRespawn;

            UI::TableSetColumnIndex(7);
            UI::Text(Time::Format(timeNr));

            if (comparisonCheckpointData !is null)
            {
                UI::TableSetColumnIndex(8);
                comparisonTimeNr += comparisonCheckpointData.m_TimeFromPreviousNoRespawn;
                int delta = timeNr - comparisonTimeNr;
                renderDelta(delta);
            }

            UI::TableSetColumnIndex(9);
            UI::Text("" + checkpointData.m_NumberRespawns);

            if (comparisonCheckpointData !is null)
            {
                UI::TableSetColumnIndex(10);
                int delta = checkpointData.m_NumberRespawns - comparisonCheckpointData.m_NumberRespawns;
                renderDeltaRespawns(delta);
            }

        }
        else if (i == g_State.m_CurrentCheckpoints.Length)
        {
            UI::TableSetColumnIndex(1);
            int timeAcc = Time::get_Now() - g_State.m_LastStartTime;
            UI::Text(Time::Format(timeAcc));
            
            if (comparisonCheckpointData !is null)
            {
                UI::TableSetColumnIndex(2);
                int delta = timeAcc - comparisonCheckpointData.m_TimeFromStart;
                renderDelta(delta);
            }

            UI::TableSetColumnIndex(5);
            int time = Time::get_Now() - g_State.m_LastRespawn;
            UI::Text(Time::Format(time));

            if (comparisonCheckpointData !is null)
            {
                UI::TableSetColumnIndex(6);
                int delta = time - comparisonCheckpointData.m_TimeFromPrevious;
                renderDelta(delta);
            }

            if (player.NbRespawnsByCp.Length > i)
            {
                UI::TableSetColumnIndex(9);
                UI::Text("" + player.NbRespawnsByCp[i]);

                if (comparisonCheckpointData !is null)
                {
                    UI::TableSetColumnIndex(10);
                    int delta = player.NbRespawnsByCp[i] - comparisonCheckpointData.m_NumberRespawns;
                    renderDeltaRespawns(delta);
                }
            }

        }

    }

    UI::EndTable();
}


}

}


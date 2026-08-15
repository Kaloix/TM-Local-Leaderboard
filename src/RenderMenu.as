void RenderMenu()
{
    if (UI::BeginMenu(Icons::ListUl + " Local Records"))
    {
        if (UI::MenuItem(Icons::Trash + " Reset Records", "", false, LocalRecords::g_State.m_CurrentMap != ""))
        {
            LocalRecords::g_State.ResetData();
        }

        if (UI::BeginMenu(Icons::ClockO + " Edit Custom Times"))
        {
            LocalRecords::RenderCustomTimeEntries();
            UI::EndMenu();
        }

        if (UI::BeginMenu(Icons::ClockO + " Edit Custom Positions"))
        {
            LocalRecords::RenderCustomPositionEntries();
            UI::EndMenu();
        }

        if (UI::BeginMenu(Icons::ClockO + " Edit Table Columns"))
        {
            LocalRecords::RenderTableColumnsMenu();
            UI::EndMenu();
        }

        UI::EndMenu();
    }
}

namespace LocalRecords
{

void RenderCustomTimeEntries()
{
    if (UI::Button("Add"))
    {
        g_State.AddCustomTimeEntry();
    }

    UI::BeginTable("CustomTimeEntriesTable", 4, UI::TableFlags::SizingFixedFit);

    UI::TableSetupColumn("##Actions", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("##CPs", UI::TableColumnFlags::WidthFixed);

    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
    UI::TableHeadersRow();
    UI::PopStyleColor();

    for (uint i = 0; i < g_State.m_CustomTimeEntries.Length ; i++)
    {
        UI::TableNextRow();
        auto @entry = g_State.m_CustomTimeEntries[i];

        UI::TableNextColumn();
        if (UI::Button(Icons::Trash + "##" + i))
        {
            g_State.RemoveCustomTimeEntry(i);
            // Break because the array length has been modified
            break;
        }

        UI::TableNextColumn();
        bool nameChanged = false;
        UI::SetNextItemWidth(200);
        auto newName = UI::InputText("##PlayerName" + i, g_State.m_CustomTimeEntries[i].m_PlayerName, nameChanged);
        if (nameChanged)
        {
            g_State.UpdateCustomTimeEntryName(i, newName);
        }

        UI::TableNextColumn();

        int currentMinutes = entry.m_Time / 60000;
        int currentSeconds = (entry.m_Time / 1000) % 60;
        int currentMilliseconds = entry.m_Time % 1000;

        UI::Text("Time: " + Time::Format(entry.m_Time));

        UI::SameLine();
        UI::Text("m:");
        UI::SameLine();
        UI::SetNextItemWidth(100);
        auto newTimeMinutes = Math::Max(0, UI::InputInt("##TimeMinutes" + i, currentMinutes));

        UI::SameLine();
        UI::Text("s:");
        UI::SameLine();
        UI::SetNextItemWidth(100);
        auto newTimeSeconds = Math::Max(-1, UI::InputInt("##TimeSeconds" + i, currentSeconds)) % 60;
        if (newTimeSeconds == -1) {
            newTimeSeconds = 59;
        }

        UI::SameLine();
        UI::Text("ms:");
        UI::SameLine();
        UI::SetNextItemWidth(100);
        auto newTimeMilliseconds = Math::Max(-1, UI::InputInt("##TimeMilliseconds" + i, currentMilliseconds)) % 1000;
        if (newTimeMilliseconds == -1) {
            newTimeMilliseconds = 999;
        }

        if (newTimeMinutes != currentMinutes || newTimeSeconds != currentSeconds || newTimeMilliseconds != currentMilliseconds)
        {
            auto newTime =  newTimeMinutes * 60000 + newTimeSeconds * 1000 + newTimeMilliseconds;
            g_State.UpdateCustomTimeEntryTime(i, newTime);
        }

        UI::TableNextColumn();
        if (UI::BeginMenu(Icons::List + "##CheckpointTimes" + i))
        {
            LocalRecords::RenderCustomCheckpointTimes(@entry);
            UI::EndMenu();
        }
    }

    UI::EndTable();
}

void RenderCustomCheckpointTimes(LeaderboardEntry@ entry)
{
    UI::BeginTable("CustomTimeEntriesTable", 3, UI::TableFlags::SizingFixedFit);

    UI::TableSetupColumn("CP", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed);
    UI::TableHeadersRow();

    for (uint i = 0; i < g_State.m_CurrentMapCpCount; ++i)
    {
        UI::TableNextRow();

        auto @cpData = entry.m_Checkpoints[i];

        UI::TableNextColumn();
        string cpName = i == g_State.m_CurrentMapCpCount ? "Fin" : "" + (i + 1);
        UI::Text(cpName);

        UI::TableNextColumn();

        int currentMinutes = cpData.m_TimeFromStart / 60000;
        int currentSeconds = (cpData.m_TimeFromStart / 1000) % 60;
        int currentMilliseconds = cpData.m_TimeFromStart % 1000;

        UI::Text("Time: " + Time::Format(cpData.m_TimeFromStart));

        UI::SameLine();
        UI::Text("m:");
        UI::SameLine();
        UI::SetNextItemWidth(100);
        auto newTimeMinutes = Math::Max(0, UI::InputInt("##TimeMinutes" + i, currentMinutes));

        UI::SameLine();
        UI::Text("s:");
        UI::SameLine();
        UI::SetNextItemWidth(100);
        auto newTimeSeconds = Math::Max(-1, UI::InputInt("##TimeSeconds" + i, currentSeconds)) % 60;
        if (newTimeSeconds == -1) {
            newTimeSeconds = 59;
        }

        UI::SameLine();
        UI::Text("ms:");
        UI::SameLine();
        UI::SetNextItemWidth(100);
        auto newTimeMilliseconds = Math::Max(-1, UI::InputInt("##TimeMilliseconds" + i, currentMilliseconds)) % 1000;
        if (newTimeMilliseconds == -1) {
            newTimeMilliseconds = 999;
        }

        if (newTimeMinutes != currentMinutes || newTimeSeconds != currentSeconds || newTimeMilliseconds != currentMilliseconds)
        {
            auto newTime =  newTimeMinutes * 60000 + newTimeSeconds * 1000 + newTimeMilliseconds;
            cpData.m_TimeFromStart = newTime;
            cpData.m_TimeFromStartNoRespawn = newTime;
            cpData.m_TimeFromPrevious = i == 0 ? cpData.m_TimeFromStart : cpData.m_TimeFromStart - entry.m_Checkpoints[i - 1].m_TimeFromStart;
            cpData.m_TimeFromPreviousNoRespawn = cpData.m_TimeFromPrevious;
        }
    }

    UI::EndTable();
}

void RenderCustomPositionEntries()
{
    if (UI::Button("Add"))
    {
        g_State.AddCustomPositionEntry();
    }


    UI::BeginTable("CustomPositionEntriesTable", 3);

    UI::TableSetupColumn("##Actions", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Pos", UI::TableColumnFlags::WidthFixed);

    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
    UI::TableHeadersRow();
    UI::PopStyleColor();

    for (uint i = 0; i < g_State.m_CustomPositionEntries.Length ; i++)
    {
        UI::TableNextRow();
        auto @entry = g_State.m_CustomPositionEntries[i];

        UI::TableNextColumn();
        if (UI::Button(Icons::Trash + "##" + i))
        {
            g_State.RemoveCustomPositionEntry(i);
            // Break because the array length has been modified
            break;
        }

        UI::TableNextColumn();
        bool nameChanged = false;
        UI::SetNextItemWidth(200);
        auto newName = UI::InputText("##PlayerName" + i, entry.m_PlayerName, nameChanged);
        if (nameChanged)
        {
            g_State.UpdateCustomPositionEntryName(i, newName);
        }

        UI::TableNextColumn();

        int currentPosition = entry.m_GlobalPosition;
        auto newPosition = Math::Max(1, UI::InputInt("##Position" + i, currentPosition));

        if (newPosition != currentPosition)
        {
            g_State.UpdateCustomPositionEntryPosition(i, newPosition);
        }
    }

    UI::EndTable();
}

void RenderTableColumnsMenu()
{

    UI::BeginTable("CustomEntriesTable", 3, UI::TableFlags::SizingFixedFit);

    UI::TableSetupColumn("##Actions", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("##Other", UI::TableColumnFlags::WidthFixed);

    UI::PushStyleColor(UI::Col::HeaderHovered, vec4(0.0f, 0.0f, 0.0f, 0.0f));
    UI::TableHeadersRow();
    UI::PopStyleColor();

    for (uint i = 0; i < g_AllTableColumns.Length; ++i)
    {
        UI::TableNextRow();

        auto @column = @GetTableColumn(i);

        UI::TableNextColumn();
        const auto newShow = UI::Checkbox("##Show" + i, column.m_Show);
        if (column.m_Show != newShow) {
            column.m_Show = newShow;
            OnSettingsChanged();
        }

        UI::SameLine();
        UI::BeginDisabled(i == 0);
        if (UI::Button(Icons::ArrowUp + "##" + i))
        {
            SetColumnPosition(@column, column.m_Pos - 1);
            OnSettingsChanged();

            UI::EndDisabled();
            break;
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(i == g_AllTableColumns.Length - 1);
        if (UI::Button(Icons::ArrowDown + "##" + i) )
        {
            SetColumnPosition(@column, column.m_Pos - 1);

            OnSettingsChanged();

            UI::EndDisabled();
            break;
        }
        UI::EndDisabled();

        UI::TableNextColumn();
        UI::Text(column.GetName());

        UI::TableNextColumn();
        if (column.GetType() == TableColumnType::TimeDeltaColumn) {
            auto @timeDeltaColumn = cast<TimeDeltaColumn>(column);

            UI::PushItemWidth(250.0f);
            if (UI::BeginCombo("##Target" + i, timeDeltaColumn.m_ComparisonTarget.GetName()))
            {
                for (uint j = 0; j < g_ComparisonTargets.Length; ++j)
                {
                    auto @comparisonTarget = @g_ComparisonTargets[j];
                    auto isEntrySelected = timeDeltaColumn.m_ComparisonTarget.GetType() == comparisonTarget.GetType();

                    if (comparisonTarget.GetType() == ComparisonTargetType::CustomTime)
                    {
                        auto @customEntryTarget = cast<CustomTimeComparisonTarget>(comparisonTarget);
                        for (uint k = 0; k < g_State.m_CustomTimeEntries.Length; ++k)
                        {
                            auto @customEntry = @g_State.m_CustomTimeEntries[k];
                            if (UI::Selectable("Custom Time: " + customEntry.m_PlayerName, isEntrySelected && customEntryTarget.m_CustomEntryId == customEntry.m_Id))
                            {
                                customEntryTarget.m_CustomEntryId = customEntry.m_Id;
                                @timeDeltaColumn.m_ComparisonTarget = customEntryTarget;
                                OnSettingsChanged();
                            }
                        }
                    }
                    else if (comparisonTarget.GetType() == ComparisonTargetType::CustomPosition)
                    {
                        auto @customEntryTarget = cast<CustomPositionComparisonTarget>(comparisonTarget);
                        for (uint k = 0; k < g_State.m_CustomPositionEntries.Length; ++k)
                        {
                            auto @customEntry = @g_State.m_CustomPositionEntries[k];
                            if (UI::Selectable("Custom Position: " + customEntry.m_GlobalPosition, isEntrySelected && customEntryTarget.m_CustomEntryId == customEntry.m_Id))
                            {
                                customEntryTarget.m_CustomEntryId = customEntry.m_Id;
                                @timeDeltaColumn.m_ComparisonTarget = customEntryTarget;
                                OnSettingsChanged();
                            }
                        }
                    }
                    else
                    {
                        if (UI::Selectable(comparisonTarget.GetName(), isEntrySelected))
                        {
                            @timeDeltaColumn.m_ComparisonTarget = @comparisonTarget;
                            OnSettingsChanged();
                        }
                    }
                }

                UI::EndCombo();
            }
            UI::PopItemWidth();
        }
    }


    UI::EndTable();
}

}

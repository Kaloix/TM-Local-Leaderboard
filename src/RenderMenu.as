void RenderMenu()
{
    if (UI::BeginMenu(Icons::ListUl + " Local Leaderboard"))
    {
        if (UI::MenuItem(Icons::Trash + " Reset Leaderboard", "", false, LocalLeaderboard::g_State.m_CurrentMap != ""))
        {
            LocalLeaderboard::g_State.ResetData();
        }

        if (UI::BeginMenu(Icons::ClockO + " Edit Custom Entries"))
        {
            LocalLeaderboard::RenderCustomEntries();
            UI::EndMenu();
        }

        if (UI::BeginMenu(Icons::ClockO + " Edit Table Columns"))
        {
            LocalLeaderboard::RenderTableColumnsMenu();
            UI::EndMenu();
        }

        UI::EndMenu();
    }
}

namespace LocalLeaderboard
{

void RenderCustomEntries()
{
    if (UI::Button("Add Custom Entry"))
    {
        g_State.AddCustomEntry();
    }


    UI::BeginTable("CustomEntriesTable", 3);

    UI::TableSetupColumn("##Actions", UI::TableColumnFlags::WidthFixed, 30);
    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 200);
    UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 500);

    UI::TableHeadersRow();

    for (uint i = 0; i < g_State.m_CustomEntries.Length ; i++)
    {
        UI::TableNextRow();
        auto @entry = g_State.m_CustomEntries[i];

        UI::TableNextColumn();
        if (UI::Button(Icons::Trash + "##" + i))
        {
            g_State.RemoveCustomEntry(i);
            // Break because the array length has been modified
            break;
        }

        UI::TableNextColumn();
        bool nameChanged = false;
        UI::SetNextItemWidth(200);
        auto newName = UI::InputText("##PlayerName" + i, g_State.m_CustomEntries[i].m_PlayerName, nameChanged);
        if (nameChanged)
        {
            g_State.UpdateCustomEntryName(i, newName);
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

        if ( newTimeMinutes != currentMinutes || newTimeSeconds != currentSeconds || newTimeMilliseconds != currentMilliseconds)
        {
            auto newTime =  newTimeMinutes * 60000 + newTimeSeconds * 1000 + newTimeMilliseconds;
            g_State.UpdateCustomEntryTime(i, newTime);
        }
    }

    UI::EndTable();
}

void RenderTableColumnsMenu()
{

    UI::BeginTable("CustomEntriesTable", 3);

    UI::TableSetupColumn("##Actions", UI::TableColumnFlags::WidthFixed, 200);
    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 200);
    UI::TableSetupColumn("##Other", UI::TableColumnFlags::WidthFixed, 300);

    UI::TableHeadersRow();

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
            GetTableColumn(i - 1).m_Pos += 1;
            column.m_Pos -= 1;
            OnSettingsChanged();

            UI::EndDisabled();
            break;
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(i == g_AllTableColumns.Length - 1);
        if (UI::Button(Icons::ArrowDown + "##" + i) )
        {
            GetTableColumn(i + 1).m_Pos -= 1;
            column.m_Pos += 1;

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

                    if (comparisonTarget.GetType() == ComparisonTargetType::CustomEntry)
                    {
                        auto @customEntryTarget = cast<CustomEntryComparisonTarget>(comparisonTarget);
                        for (uint k = 0; k < g_State.m_CustomEntries.Length; ++k)
                        {
                            auto @customEntry = @g_State.m_CustomEntries[k];
                            if (UI::Selectable("Custom Entry: " + customEntry.m_PlayerName, isEntrySelected && customEntryTarget.m_CustomEntryId == customEntry.m_Id))
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

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

    array<ColumnSettings @> @columnSettings = @g_Settings.m_TableSettings.m_Columns;

    UI::BeginCombo();
    for (uint i = 0; i < g_AllTableColumns.Length; ++i)
    {
        auto @column = g_AllTableColumns[i];
        if (UI::Selectable(column.renderHeader()))
        {
            g_Settings.m_TableSettings.m_Columns.InsertLast(ColumnSettings(column.GetType()));
            saveSettings(g_Settings);
        }
    }
    UI::EndCombo();


    UI::BeginTable("CustomEntriesTable", 3);

    UI::TableSetupColumn("##Actions", UI::TableColumnFlags::WidthFixed, 30);
    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 200);

    UI::TableHeadersRow();

    UI::TableNextRow();
    for (uint i = 0; i < g_TableColumns.Length; ++i)
    {
        auto @column = g_TableColumns[i];

        UI::TableNextColumn();
        if (UI::Button(Icons::Trash + "##" + i))
        {
            columnSettings.RemoveAt(i);
            OnSettingsChanged();
            break;
        }

        if (UI::Button(Icons::ArrowUp + "##" + i) && i > 0)
        {
            auto @tmp = columnSettings[i];
            @columnSettings[i] = @columnSettings[i - 1];
            @columnSettings[i - 1] = @tmp;
            OnSettingsChanged();
            break;
        }

        if (UI::Button(Icons::ArrowDown + "##" + i) && i < g_TableColumns.Length - 1)
        {
            auto @tmp = columnSettings[i];
            @columnSettings[i] = @columnSettings[i + 1];
            @columnSettings[i + 1] = @tmp;
            OnSettingsChanged();
            break;
        }

        UI::TableNextColumn();
        column.renderHeader();
    }


    UI::EndTable();
}

}

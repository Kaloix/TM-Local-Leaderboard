namespace LocalRecords::Statistics
{

class StatisticsRenderer
{

    StatisticsRenderer()
    {
        Init();
    }

    int m_WindowFlags = UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize;

    void Init()
    {
        m_WindowFlags = UI::GetDefaultWindowFlags() | UI::WindowFlags::AlwaysAutoResize;
        if (!settingStatisticsDisplayTitleBar)
            m_WindowFlags |= UI::WindowFlags::NoTitleBar;
    }

    void Render(const Statistics &in statistics)
    {
        RenderWindow(statistics);
    }

    void RenderWindow(const Statistics &in statistics)
    {
        UI::PushFontSize(settingStatisticFontSize);
        UI::SetNextWindowBgAlpha(settingStatisticsBackgroundTransparency);

        bool open = true;
        if(UI::Begin("Local Records Statistics", open, m_WindowFlags))
        {
            RenderTable(statistics);
        }
        UI::End();

        UI::PopFontSize();

        if (!open)
        {
            // Window was closed by the user
            settingStatisticsShow = false;
            Disable();
        }

    }

    void RenderTable(const Statistics &in statistics)
    {
        UI::BeginTable("StatisticsTable", 2, UI::TableFlags::SizingFixedFit);

        UI::TableSetupColumn("#Property", UI::TableColumnFlags::WidthFixed);
        UI::TableSetupColumn("#Value", UI::TableColumnFlags::WidthStretch);

        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text("Average:");
        UI::TableNextColumn();
        UI::Text(Time::Format(statistics.GetAverageTime()));

        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text("Session Average:");
        UI::TableNextColumn();
        UI::Text(Time::Format(statistics.GetSessionAverageTime()));

        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text("Interval Average:");
        UI::TableNextColumn();
        UI::Text(Time::Format(statistics.GetIntervalAverageTime()));

        UI::EndTable();
    }


}


}

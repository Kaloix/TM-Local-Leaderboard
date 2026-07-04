namespace LocalLeaderboard
{

array<TableColumn @> g_AllTableColumns = {
    MedalColumn(),
    RankColumn(),
    GlobalPositionColumn(),
    GlobalPercentageColumn(),
    PlayerColumn(),
    TimeColumn(),
    TimeDeltaColumn(),
    TimeNoRespawnColumn(),
    NumberRespawnsColumn(),
    ScoreNumberColumn(),
    SessionNumberColumn(),
    TimestampColumn(),
    TotalTimeColumn(),
    SessionTimeColumn(),
    TimeSinceColumn()
};

enum TableColumnType
{
    MedalColumn,
    RankColumn,
    GlobalPositionColumn,
    GlobalPercentageColumn,
    PlayerColumn,
    TimeColumn,
    TimeDeltaColumn,
    TimeNoRespawnColumn,
    NumberRespawnsColumn,
    ScoreNumberColumn,
    SessionNumberColumn,
    TimestampColumn,
    TotalTimeColumn,
    SessionTimeColumn,
    TimeSinceColumn,
}

void initializeTableColumns()
{
    // Set comparison target for the delta column
    @(cast<TimeDeltaColumn>(GetTableColumnByType(TableColumnType::TimeDeltaColumn))).m_ComparisonTarget = @GetComparisonTarget(ComparisonTargetType::FastestRun);

    // Set position
    for (uint i = 0; i < g_AllTableColumns.Length; ++i)
    {
        g_AllTableColumns[i].m_Pos = i;
    }
}

TableColumn@ GetTableColumn(const int pos)
{
    for (uint i = 0; i < g_AllTableColumns.Length; ++i)
    {
        if (g_AllTableColumns[i].m_Pos == pos)
        {
            return @g_AllTableColumns[i];
        }
    }

    LogWarning("No column at position: " + pos);
    return null;
}

TableColumn@ GetTableColumnByType(const TableColumnType type)
{
    for (uint i = 0; i < g_AllTableColumns.Length; ++i)
    {
        if (g_AllTableColumns[i].GetType() == type)
        {
            return @g_AllTableColumns[i];
        }
    }

    LogWarning("No column with type: " + type);
    return null;
}

class TableColumn
{
    bool m_Show = true;

    int m_Pos = 0;

    TableColumn()
    {
        m_Show = GetDefaultShow();
    }
    bool GetDefaultShow()
    {
        return true;
    }
    TableColumnType GetType() const
    {
        return TableColumnType::MedalColumn;
    }
    string GetName() const
    {
        return "";
    }
    string GetHeaderValue() const
    {
        return GetName();
    }
    string GetBodyValue(const TableRenderContext&in context) const
    {
        return "";
    }
    bool shouldDisplay() const
    {
        return m_Show;
    }
    void setup(const uint index) const
    {
        UI::TableSetupColumn(GetHeaderValue() + "##" + index, UI::TableColumnFlags::WidthFixed);
    }
    void renderHeader() const
    {
        UI::Text(GetHeaderValue());
    }
    void renderBody(TableRenderContext &inout context) const
    {
        renderText(context, GetBodyValue(context));
    }
}

class RankColumn : TableColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::RankColumn;
    }
    string GetName() const override
    {
        return "Rank";
    }
    string GetBodyValue(const TableRenderContext&in context) const override
    {
        return context.m_CurrentEntry.GetDisplayRank();
    }
}

class GlobalPositionColumn : TableColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::GlobalPositionColumn;
    }
    string GetName() const override
    {
        return "Pos";
    }
    string GetBodyValue(const TableRenderContext&in context) const override
    {
        if (context.m_CurrentEntry.m_GlobalPosition <= 0)
            return "";
        if (context.m_CurrentEntry.m_GlobalPosition >= 100000)
            return "<" + (context.m_CurrentEntry.m_GlobalPosition / 1000) + "k";
        else
            return "" + context.m_CurrentEntry.m_GlobalPosition;
    }
}

class GlobalPercentageColumn : TableColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::GlobalPercentageColumn;
    }
    string GetName() const override
    {
        return "%";
    }
    string GetBodyValue(const TableRenderContext&in context) const override
    {
        if (g_State.m_NumberGlobalPositions <= 0 || context.m_CurrentEntry.m_GlobalPosition <= 0)
            return "";
        else
            return Math::Round((float(context.m_CurrentEntry.m_GlobalPosition) / float(g_State.m_NumberGlobalPositions)) * 100.0f, 2) + "%";
    }
}

class MedalColumn : TableColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::MedalColumn;
    }
    string GetName() const override
    {
        return "Medal";
    }
    string GetHeaderValue() const override
    {
        return "";
    }
    string GetBodyValue(const TableRenderContext&in context) const override
    {
        return context.m_CurrentEntry.GetDisplayIcon();
    }
    void renderBody(TableRenderContext&inout context) const override
    {
        // Medal can be null if the record was too slow
        if (context.m_CurrentEntry.m_Medal !is null)
            UI::PushStyleColor(UI::Col::Text, vec4(context.m_CurrentEntry.m_Medal.GetIconColor(), 1));

        UI::Text(GetBodyValue(context));

        if (context.m_CurrentEntry.m_Medal !is null)
            UI::PopStyleColor();
    }
}

class TimeColumn : TableColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::TimeColumn;
    }
    string GetName() const override
    {
        return "Time";
    }
    string GetBodyValue(const TableRenderContext&in context) const override
    {
        const auto time = GetTime(context);
        if (time > 0)
            return Time::Format(GetTime(context), ShowFractions());
        else
            return "";
    }
    int64 GetTime(TableRenderContext&in context) const
    {
        return context.m_CurrentEntry.GetDisplayTime();
    }
    bool ShowFractions()
    {
        return true;
    }
}

class PlayerColumn : TableColumn
{
    bool GetDefaultShow() override
    {
        return false;
    }
    TableColumnType GetType() const override
    {
        return TableColumnType::PlayerColumn;
    }
    string GetName() const override
    {
        return "Player";
    }
    string GetBodyValue(const TableRenderContext&in context) const override
    {
        return context.m_CurrentEntry.GetDisplayName();
    }
}

class TimeDeltaColumn : TableColumn
{
    ComparisonTarget@ m_ComparisonTarget = null;

    TableColumnType GetType() const override
    {
        return TableColumnType::TimeDeltaColumn;
    }
    string GetName() const override
    {
        return "Delta";
    }
    string GetBodyValue(const TableRenderContext&in context) const override
    {
        bool showDelta = m_ComparisonTarget !is null && m_ComparisonTarget.IsAvailable() && context.m_CurrentEntry.GetDisplayTime() > 0;
        if (context.m_CurrentEntry.GetDisplayTime() <= 0 || !showDelta)
        {
            return "";
        }

        if (context.m_CurrentEntry is m_ComparisonTarget.GetComparisonTargetEntry())
        {
            return "";
        }
        else
        {
            return "" + (context.m_CurrentEntry.GetDisplayTime() - m_ComparisonTarget.GetTime());
        }
    }
    void renderBody(TableRenderContext&inout context) const override
    {
        bool showDelta = m_ComparisonTarget !is null && m_ComparisonTarget.IsAvailable() && context.m_CurrentEntry.GetDisplayTime() > 0;
        if (context.m_CurrentEntry.GetDisplayTime() <= 0 || !showDelta)
        {
            UI::Text("");
            return;
        }

        if (context.m_CurrentEntry is m_ComparisonTarget.GetComparisonTargetEntry())
        {
            UI::Text("");
        }
        else
        {
            renderDelta(context.m_CurrentEntry.GetDisplayTime() - m_ComparisonTarget.GetTime());
        }
    }
}

class TimeNoRespawnColumn : TableColumn
{
    bool GetDefaultShow() override
    {
        return false;
    }
    TableColumnType GetType() const override
    {
        return TableColumnType::TimeNoRespawnColumn;
    }
    string GetName() const override
    {
        return "Copium";
    }
    string GetBodyValue(const TableRenderContext&in context) const override {
        if (context.m_CurrentEntry.m_Type == LeaderboardEntryType::Score && context.m_CurrentEntry.m_NumberRespawns != 0)
            return Time::Format(context.m_CurrentEntry.m_TimeNoRespawn);
        else
            return "";
    }
}

class NumberRespawnsColumn : TableColumn
{
    bool GetDefaultShow() override
    {
        return false;
    }
    TableColumnType GetType() const override
    {
        return TableColumnType::NumberRespawnsColumn;
    }
    string GetName() const override
    {
        return "Respawns";
    }
    string GetHeaderValue() const override
    {
        return Icons::Refresh;
    }
    string GetBodyValue(const TableRenderContext&in context) const override
    {
        if (context.m_CurrentEntry.m_NumberRespawns != 0)
            return "" + context.m_CurrentEntry.m_NumberRespawns;
        else
            return "";
    }
}

class ScoreNumberColumn : TableColumn
{
    bool GetDefaultShow() override
    {
        return false;
    }
    TableColumnType GetType() const override
    {
        return TableColumnType::ScoreNumberColumn;
    }
    string GetName() const override
    {
        return "Score Number";
    }
    string GetHeaderValue() const override
    {
        return "No.";
    }
    string GetBodyValue(const TableRenderContext&in context) const override
    {
        if (context.m_CurrentEntry.m_ScoreNumber > 0)
            return  "" + context.m_CurrentEntry.m_ScoreNumber;
        else
            return "";
    }
}

class SessionNumberColumn : TableColumn
{
    bool GetDefaultShow() override
    {
        return false;
    }
    TableColumnType GetType() const override
    {
        return TableColumnType::SessionNumberColumn;
    }
    string GetName() const override
    {
        return "Session Number";
    }
    string GetHeaderValue() const override
    {
        return "S";
    }
    string GetBodyValue(const TableRenderContext&in context) const override
    {
        if (context.m_CurrentEntry.m_SessionNumber > 0)
            return "" + context.m_CurrentEntry.m_SessionNumber;
        else
            return "";
    }
}

class TimestampColumn : TableColumn
{
    bool GetDefaultShow() override
    {
        return false;
    }
    TableColumnType GetType() const override
    {
        return TableColumnType::TimestampColumn;
    }
    string GetName() const override
    {
        return "Timestamp";
    }
    string GetBodyValue(const TableRenderContext&in context) const override
    {
        if (context.m_CurrentEntry.m_TimeStamp == 0)
        {
            return "";
        }

        auto time = Time::Parse(context.m_CurrentEntry.m_TimeStamp);
        return time.Year + "-" + Text::Format("%02d", time.Month) + "-" + Text::Format("%02d", time.Day) + " " + Text::Format("%02d", time.Hour) + ":" + Text::Format("%02d", time.Minute) + ":" + Text::Format("%02d", time.Second);
    }
}

class TotalTimeColumn : TimeColumn
{
    bool GetDefaultShow() override
    {
        return false;
    }
    TableColumnType GetType() const override
    {
        return TableColumnType::TotalTimeColumn;
    }
    string GetName() const override
    {
        return "Total Time";
    }
    string GetHeaderValue() const override
    {
        return "Tot. T.";
    }
    int64 GetTime(TableRenderContext&in context) const override
    {
        return context.m_CurrentEntry.m_TimeInTotal;
    }
}

class SessionTimeColumn : TimeColumn
{
    bool GetDefaultShow() override
    {
        return false;
    }
    TableColumnType GetType() const override
    {
        return TableColumnType::SessionTimeColumn;
    }
    string GetName() const override
    {
        return "Session Time";
    }
    string GetHeaderValue() const override
    {
        return "Ses. T.";
    }
    int64 GetTime(TableRenderContext&in context) const override
    {
        return context.m_CurrentEntry.m_TimeInSession;
    }
}

class TimeSinceColumn : TimeColumn
{
    bool GetDefaultShow() override
    {
        return false;
    }
    TableColumnType GetType() const override
    {
        return TableColumnType::TimeSinceColumn;
    }
    string GetName() const override
    {
        return "Time Since Record";
    }
    string GetHeaderValue() const override
    {
        return "Since";
    }
    int64 GetTime(TableRenderContext&in context) const override
    {
        if (context.m_CurrentEntry.m_TimeStamp <= 0)
        {
            return 0;
        }

        return (context.m_CurrentTime - context.m_CurrentEntry.m_TimeStamp) * 1000;
    }
    bool ShowFractions() override
    {
        return false;
    }
}

}

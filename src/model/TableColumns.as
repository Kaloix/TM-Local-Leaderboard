namespace LocalLeaderboard
{

array<TableColumn @> g_AllTableColumns = {
    MedalColumn(),
    RankColumn(),
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
    TimeSinceColumn()};

enum TableColumnType
{
    MedalColumn,
    RankColumn,
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

class TableColumn
{
    TableColumnType GetType() const
    {
        return TableColumnType::MedalColumn;
    }
    string GetName() const
    {
        return "";
    }
    float GetWidth() const
    {
        0.0f;
    }
    void setup() const
    {
        UI::TableSetupColumn(GetName(), UI::TableColumnFlags::WidthFixed, GetWidth());
    }
    void renderHeader() const
    {
        UI::Text(GetName());
    }
    void renderBody(TableRenderContext &inout context) const
    {
        UI::Text("");
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
    float GetWidth() const override
    {
        30.0f;
    }
    void renderBody(TableRenderContext&inout context) const override
    {
        renderText(context, context.m_CurrentEntry.GetDisplayRank());
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
    float GetWidth() const override
    {
        20.0f;
    }
    void renderHeader() const override
    {
        ;
    }

    void renderBody(TableRenderContext&inout context) const override
    {
        // Medal can be null if the record was too slow
        if (context.m_CurrentEntry.m_Medal !is null)
            UI::PushStyleColor(UI::Col::Text, vec4(context.m_CurrentEntry.m_Medal.GetIconColor(), 1));

        UI::Text(context.m_CurrentEntry.GetDisplayIcon());

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
    float GetWidth() const override
    {
        60.0f;
    }
    void renderHeader()
    {
        UI::Text(getHeaderName());
    }

    void renderBody(TableRenderContext&inout context) const override
    {
        const auto time = GetTime(context);
        if (time > 0)
        {
            renderText(context, Time::Format(GetTime(context), ShowFractions()));
        }
        else
        {
            UI::Text("");
        }
    }

    string getHeaderName()
    {
        return "Time";
    }
    int64 GetTime(TableRenderContext&inout context)
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
    TableColumnType GetType() const override
    {
        return TableColumnType::PlayerColumn;
    }
    string GetName() const override
    {
        return "Player";
    }
    float GetWidth() const override
    {
        60.0f;
    }
    void renderBody(TableRenderContext&inout context) const override
    {
        renderText(context, context.m_CurrentEntry.GetDisplayName());
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
    float GetWidth() const override
    {
        return COLUMN_TIME_DELTA_WIDTH;
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
            renderText(context, Time::Format(context.m_CurrentEntry.GetDisplayTime()));
        }
        else
        {
            renderDelta(context.m_CurrentEntry.GetDisplayTime() - m_ComparisonTarget.GetTime());
        }
    }
}

class TimeNoRespawnColumn : TableColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::TimeNoRespawnColumn;
    }
    string GetName() const override
    {
        return "Copium";
    }
    float GetWidth() const override
    {
        50.0f;
    }
    void renderBody(TableRenderContext&inout context) const override
    {
        if (context.m_CurrentEntry.m_Type == LeaderboardEntryType::Score && context.m_CurrentEntry.m_NumberRespawns != 0)
            renderText(context, Time::Format(context.m_CurrentEntry.m_TimeNoRespawn));
        else
            UI::Text("");
    }
}

class NumberRespawnsColumn : TableColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::NumberRespawnsColumn;
    }
    string GetName() const override
    {
        return "Respawns";
    }
    float GetWidth() const override
    {
        COLUMN_NUMBER_RESPAWNS_WIDTH;
    }
    void renderHeader() const override
    {
        UI::Text(Icons::Refresh);
    }
    void renderBody(TableRenderContext&inout context) const override
    {
        if (context.m_CurrentEntry.m_NumberRespawns != 0)
            renderText(context, "" + context.m_CurrentEntry.m_NumberRespawns);
        else
            UI::Text("");
    }
}

class ScoreNumberColumn : TableColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::ScoreNumberColumn;
    }
    string GetName() const override
    {
        return "Score Number";
    }
    float GetWidth() const override
    {
        return 30.0f;
    }
    void renderHeader() const override
    {
        UI::Text("No.");
    }
    void renderBody(TableRenderContext&inout context) const override
    {
        if (context.m_CurrentEntry.m_ScoreNumber > 0)
            renderText(context, "" + context.m_CurrentEntry.m_ScoreNumber);
        else
            UI::Text("");
    }
}

class SessionNumberColumn : TableColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::SessionNumberColumn;
    }
    string GetName() const override
    {
        return "Session Number";
    }
    float GetWidth() const override
    {
        return 30.0f;
    }
    void renderHeader() const override
    {
        UI::Text("S");
    }
    void renderBody(TableRenderContext&inout context) const override
    {
        if (context.m_CurrentEntry.m_SessionNumber > 0)
            renderText(context, "" + context.m_CurrentEntry.m_SessionNumber);
        else
            UI::Text("");
    }
}

class TimestampColumn : TableColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::TimestampColumn;
    }
    string GetName() const override
    {
        return "Timestamp";
    }
    float GetWidth() const override
    {
        return 150.0f;
    }
    void renderBody(TableRenderContext&inout context) const override
    {
        if (context.m_CurrentEntry.m_TimeStamp == 0)
        {
            UI::Text("");
            return;
        }

        auto time = Time::Parse(context.m_CurrentEntry.m_TimeStamp);
        string timeStr = time.Year + "-" + Text::Format("%02d", time.Month) + "-" + Text::Format("%02d", time.Day) + " " + Text::Format("%02d", time.Hour) + ":" + Text::Format("%02d", time.Minute) + ":" + Text::Format("%02d", time.Second);
        renderText(context, timeStr);
    }
}

class TotalTimeColumn : TimeColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::TotalTimeColumn;
    }
    string GetName() const override
    {
        return "Total Time";
    }
    string getHeaderName() override
    {
        return "Tot. T.";
    }
    int64 GetTime(TableRenderContext&inout context) override
    {
        return context.m_CurrentEntry.m_TimeInTotal;
    }
}

class SessionTimeColumn : TimeColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::SessionTimeColumn;
    }
    string GetName() const override
    {
        return "Session Time";
    }
    string getHeaderName() override
    {
        return "Ses. T.";
    }
    int64 GetTime(TableRenderContext&inout context) override
    {
        return context.m_CurrentEntry.m_TimeInSession;
    }
}

class TimeSinceColumn : TimeColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::TimeSinceColumn;
    }
    string GetName() const override
    {
        return "Time Since Record";
    }
    string getHeaderName() override
    {
        return "Since";
    }
    int64 GetTime(TableRenderContext&inout context) override
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

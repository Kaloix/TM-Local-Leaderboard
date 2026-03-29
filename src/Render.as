void Render()
{
    if (!settingDisplayLeaderboard)
    {
        return; // Don't render the leaderboard if the setting is disabled
    }

    LocalLeaderboard::Render();
}

enum LeaderboardSortType
{
    Time,
    Chronological,
}

enum LeaderboardSortDirection
{
    Ascending,
    Descending,
}

namespace LocalLeaderboard
{
int windowFlags = 0;

array<LeaderboardEntry @> g_TableRows;
array<TableColumn @> g_TableColumns;
array<TableColumn @> g_AllTableColumns = {MedalColumn(), RankColumn(), PlayerColumn(), TimeColumn(), BestTimeDeltaColumn(), LastTimeDeltaColumn(), TimeNoRespawnColumn(), NumberRespawnsColumn(), ScoreNumberColumn(), SessionNumberColumn(), TimestampColumn(), TotalTimeColumn(), SessionTimeColumn(), TimeSinceColumn()};

void InitRender()
{
    // Clear existing columns
    g_TableColumns.RemoveRange(0, g_TableColumns.Length);

    for (uint i = 0; i < g_AllTableColumns.Length; i++)
    {
        if (g_AllTableColumns[i].shouldDisplay())
        {
            g_TableColumns.InsertLast(@g_AllTableColumns[i]);
        }
    }

    windowFlags = UI::GetDefaultWindowFlags();
    if (!settingDisplayLeaderboardTitleBar)
        windowFlags |= UI::WindowFlags::NoTitleBar;
}

void InitRows()
{
    g_TableRows.RemoveRange(0, g_TableRows.Length);

    bool addedNewestCopium = false;
    bool addedFastestCopium = false;
    if (settingDisplayLeaderboardCopiumNewest && g_State.m_Leaderboard.m_NewestCopiumRun !is null)
    {
        g_TableRows.InsertLast(g_State.m_Leaderboard.m_NewestCopiumRun);
        addedNewestCopium = true;
    }
    if (settingDisplayLeaderboardCopiumFastest && g_State.m_Leaderboard.m_FastestCopiumRun !is null && (!addedNewestCopium || g_State.m_Leaderboard.m_FastestCopiumRun.m_ScoreNumber != g_State.m_Leaderboard.m_NewestCopiumRun.m_ScoreNumber))
    {
        g_TableRows.InsertLast(g_State.m_Leaderboard.m_FastestCopiumRun);
        addedFastestCopium = true;
    }
    if (settingDisplayLeaderboardCopiumSessionFastest && g_State.m_Leaderboard.m_SessionFastestCopiumRun !is null && (!addedNewestCopium || g_State.m_Leaderboard.m_SessionFastestCopiumRun.m_ScoreNumber != g_State.m_Leaderboard.m_NewestCopiumRun.m_ScoreNumber) && (!addedFastestCopium || g_State.m_Leaderboard.m_SessionFastestCopiumRun.m_ScoreNumber != g_State.m_Leaderboard.m_FastestCopiumRun.m_ScoreNumber))
        g_TableRows.InsertLast(g_State.m_Leaderboard.m_SessionFastestCopiumRun);

    if (g_State.m_Leaderboard.m_NewestRun !is null)
        g_TableRows.InsertLast(@g_State.m_Leaderboard.m_NewestRun);
    for (uint i = 0; i < g_State.m_Leaderboard.m_Entries.Length; i++)
    {
        if (settingFilterPersonalBests && !g_State.m_Leaderboard.m_Entries[i].m_WasPersonalBest)
            continue;
        if (settingFilterSessionBests && !g_State.m_Leaderboard.m_Entries[i].m_WasSessionBest)
            continue;
        if (settingFilterSessionCurrent && g_State.m_Leaderboard.m_Entries[i].m_SessionNumber != g_State.m_Leaderboard.m_TotalNumberSessions)
            continue;

        if (@g_State.m_Leaderboard.m_NewestRun is @g_State.m_Leaderboard.m_Entries[i])
            continue;
        g_TableRows.InsertLast(@g_State.m_Leaderboard.m_Entries[i]);
    }

    for (uint i = 0; i < g_State.m_MedalEntries.Length; i++)
    {
        auto @entry = @g_State.m_MedalEntries[i];
        if (entry.m_Medal.IsVisible())
            g_TableRows.InsertLast(entry);
    }

    switch (settingLeaderboardSortType)
    {
        case LeaderboardSortType::Time:
            g_TableRows.Sort(timeSort);
            break;
        case LeaderboardSortType::Chronological:
            g_TableRows.Sort(chronologicalSort);
            break;
    }
}

bool timeSort(const LeaderboardEntry @ const&in a, const LeaderboardEntry @ const&in b)
{

    switch (settingLeaderboardSortDirection)
    {
        case LeaderboardSortDirection::Ascending:
            return a.GetDisplayTime() < b.GetDisplayTime();
        case LeaderboardSortDirection::Descending:
            return a.GetDisplayTime() > b.GetDisplayTime();
        default:
            return false;
    }
}

bool chronologicalSort(const LeaderboardEntry @ const&in a, const LeaderboardEntry @ const&in b)
{
    switch (settingLeaderboardSortDirection)
    {
        case LeaderboardSortDirection::Ascending:
            return a.m_TimeStamp < b.m_TimeStamp;
        case LeaderboardSortDirection::Descending:
            return a.m_TimeStamp > b.m_TimeStamp;
        default:
            return false;
    }
}

void Render()
{
    if (g_State.m_CurrentMap == "")
    {
        return; // Don't render if no map is loaded
    }

    // UI::Begin("Local Leaderboard", true, windowFlags);
    bool open = true;
    UI::Begin("Local Leaderboard", open, windowFlags);

    if (settingDisplayLeaderboardMapName)
    {
        const auto mapName = Text::OpenplanetFormatCodes(g_State.m_CurrentMapName);
        UI::Text(mapName);
    }

    if (settingDisplayLeaderboardMapAuthor)
    {
        const auto mapAuthor = Text::OpenplanetFormatCodes(g_State.m_CurrentMapAuthor);
        UI::TextDisabled("By " + mapAuthor);
    }

    UI::BeginTable("LeaderboardTable", g_TableColumns.Length);

    // Setup columns
    for (uint i = 0; i < g_TableColumns.Length; i++)
    {
        g_TableColumns[i].setup();
    }

    // Table header
    if (settingDisplayLeaderboardHeader)
    {
        UI::TableNextRow(UI::TableRowFlags::Headers);
        for (uint i = 0; i < g_TableColumns.Length; i++)
        {
            UI::TableNextColumn();
            g_TableColumns[i].renderHeader();
        }
    }

    // Table body
    auto context = TableRenderContext();
    for (uint i = 0; i < g_TableRows.Length; i++)
    {
        context.m_CurrentRow = i;
        @context.m_CurrentEntry = @g_TableRows[i];
        context.m_IsPlayerNewest = context.m_CurrentEntry is g_State.m_Leaderboard.m_NewestRun;
        context.m_IsPlayerBest = context.m_CurrentEntry is g_State.m_Leaderboard.m_FastestRun;
        context.m_IsPlayerSessionBest = context.m_CurrentEntry is g_State.m_Leaderboard.m_SessionFastestRun;
        context.m_IsPlayerNewestCopium = context.m_CurrentEntry is g_State.m_Leaderboard.m_NewestCopiumRun;
        context.m_IsPlayerBestCopium = context.m_CurrentEntry is g_State.m_Leaderboard.m_FastestCopiumRun;
        context.m_IsPlayerSessionBestCopium = context.m_CurrentEntry is g_State.m_Leaderboard.m_SessionFastestCopiumRun;

        UI::TableNextRow();

        bool isRowHovered = false;
        for (uint col = 0; col < g_TableColumns.Length; col++)
        {
            UI::TableNextColumn();
            g_TableColumns[col].renderBody(context);

            isRowHovered = isRowHovered || UI::IsItemHovered();
        }

        if (settingDisplayLeaderboardTooltips && isRowHovered)
        {
            UI::BeginTooltip();
            UI::BeginTable("Tooltip" + i, 2);

            for (uint c = 0; c < g_AllTableColumns.Length; c++)
            {
                UI::TableNextRow();
                UI::TableNextColumn();
                g_AllTableColumns[c].renderHeader();
                UI::TableNextColumn();
                g_AllTableColumns[c].renderBody(context);
            }

            UI::EndTable();
            UI::EndTooltip();
        }
    }

    UI::EndTable();

    UI::End();
}

class TableRenderContext
{
    uint64 m_CurrentTime = Time::get_Stamp();

    uint m_CurrentRow = 0;
    LeaderboardEntry @m_CurrentEntry = null;

    bool m_IsPlayerNewest = false;
    bool m_IsPlayerBest = false;
    bool m_IsPlayerSessionBest = false;
    bool m_IsPlayerNewestCopium = false;
    bool m_IsPlayerBestCopium = false;
    bool m_IsPlayerSessionBestCopium = false;
}

interface TableColumn
{
    bool shouldDisplay();
    void setup();
    void renderHeader();
    void renderBody(TableRenderContext &inout context);
}

class RankColumn : TableColumn
{
    bool shouldDisplay()
    {
        return settingDisplayLeaderboardRankColumn;
    }
    void setup()
    {
        UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 30);
    }

    void renderHeader()
    {
        UI::Text("Rank");
    }

    void renderBody(TableRenderContext&inout context)
    {
        renderText(context, context.m_CurrentEntry.GetDisplayRank());
    }
}

class MedalColumn : TableColumn
{
    bool shouldDisplay()
    {
        return settingDisplayLeaderboardMedalColumn;
    }
    void setup()
    {
        UI::TableSetupColumn("Medal", UI::TableColumnFlags::WidthFixed, 20);
    }

    void renderHeader()
    {
    }

    void renderBody(TableRenderContext&inout context)
    {

        UI::PushStyleColor(UI::Col::Text, vec4(context.m_CurrentEntry.m_Medal.GetIconColor(), 1));
        UI::Text(context.m_CurrentEntry.GetDisplayIcon());
        UI::PopStyleColor();
    }
}

class TimeColumn : TableColumn
{
    bool shouldDisplay()
    {
        return settingDisplayLeaderboardTimeColumn;
    }
    void setup()
    {
        UI::TableSetupColumn(getHeaderName(), UI::TableColumnFlags::WidthFixed, 60);
    }

    void renderHeader()
    {
        UI::Text(getHeaderName());
    }

    void renderBody(TableRenderContext&inout context)
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
    bool shouldDisplay()
    {
        return settingDisplayLeaderboardPlayerColumn;
    }
    void setup()
    {
        UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
    }

    void renderHeader()
    {
        UI::Text("Player");
    }

    void renderBody(TableRenderContext&inout context)
    {
        renderText(context, context.m_CurrentEntry.GetDisplayName());
    }
}

class TimeDeltaColumn : TableColumn
{
    bool shouldDisplay()
    {
        return true;
    }
    string getHeaderName()
    {
        return "";
    }
    bool isSelf(const TableRenderContext&in context)
    {
        return false;
    }
    bool isShowDelta(const TableRenderContext&in context)
    {
        return true;
    }
    int getDelta(const TableRenderContext&in context)
    {
        return 0;
    }

    void setup()
    {
        UI::TableSetupColumn(getHeaderName(), UI::TableColumnFlags::WidthFixed, 60);
    }

    void renderHeader()
    {
        UI::Text(getHeaderName());
    }

    void renderBody(TableRenderContext&inout context)
    {
        if (context.m_CurrentEntry.GetDisplayTime() <= 0 || !isShowDelta(context))
        {
            UI::Text("");
            return;
        }

        if (isSelf(context))
        {
            renderText(context, Time::Format(context.m_CurrentEntry.GetDisplayTime()));
        }
        else
        {
            const int delta = getDelta(context);
            auto deltaColor = delta < 0 ? vec4(settingColorDeltaBetter, 1) : (delta > 0 ? vec4(settingColorDeltaWorse, 1) : vec4(settingColorDeltaEqual, 1));
            string deltaStr = (delta > 0 ? "+" : "") + Time::Format(delta);

            UI::PushStyleColor(UI::Col::Text, deltaColor);
            UI::Text(deltaStr);
            UI::PopStyleColor();
        }
    }
}

class BestTimeDeltaColumn : TimeDeltaColumn
{
    bool shouldDisplay() override
    {
        return settingDisplayLeaderboardDeltaPBColumn;
    }
    string getHeaderName() override
    {
        return "Delta PB";
    }
    bool isSelf(const TableRenderContext&in context) override
    {
        return context.m_IsPlayerBest;
    }
    bool isShowDelta(const TableRenderContext&in context) override
    {
        return g_State.m_Leaderboard.m_FastestRun !is null;
    }
    int getDelta(const TableRenderContext&in context) override
    {
        return context.m_CurrentEntry.GetDisplayTime() - g_State.m_Leaderboard.m_FastestRun.GetDisplayTime();
    }
}

class LastTimeDeltaColumn : TimeDeltaColumn
{
    bool shouldDisplay() override
    {
        return settingDisplayLeaderboardDeltaLastColumn;
    }
    string getHeaderName() override
    {
        return "Delta Last";
    }
    bool isSelf(const TableRenderContext&in context) override
    {
        return context.m_IsPlayerNewest;
    }
    bool isShowDelta(const TableRenderContext&in context) override
    {
        return g_State.m_Leaderboard.m_NewestRun !is null;
    }
    int getDelta(const TableRenderContext&in context) override
    {
        return context.m_CurrentEntry.GetDisplayTime() - g_State.m_Leaderboard.m_NewestRun.GetDisplayTime();
    }
}

class TimeNoRespawnColumn : TableColumn
{
    bool shouldDisplay()
    {
        return settingDisplayLeaderboardCopiumColumn;
    }
    void setup()
    {
        UI::TableSetupColumn("Copium", UI::TableColumnFlags::WidthFixed, 50);
    }

    void renderHeader()
    {
        UI::Text("Copium");
    }

    void renderBody(TableRenderContext&inout context)
    {
        if (context.m_CurrentEntry.m_Type == LeaderboardEntryType::Score && context.m_CurrentEntry.m_NumberRespawns != 0)
            renderText(context, Time::Format(context.m_CurrentEntry.m_TimeNoRespawn));
        else
            UI::Text("");
    }
}

class NumberRespawnsColumn : TableColumn
{
    bool shouldDisplay()
    {
        return settingDisplayLeaderboardRespawnsColumn;
    }
    void setup()
    {
        UI::TableSetupColumn("Respawns", UI::TableColumnFlags::WidthFixed, 20);
    }

    void renderHeader()
    {
        UI::Text(Icons::Refresh);
    }

    void renderBody(TableRenderContext&inout context)
    {
        if (context.m_CurrentEntry.m_NumberRespawns != 0)
            renderText(context, "" + context.m_CurrentEntry.m_NumberRespawns);
        else
            UI::Text("");
    }
}

class ScoreNumberColumn : TableColumn
{
    bool shouldDisplay()
    {
        return settingDisplayLeaderboardScoreNumberColumn;
    }
    void setup()
    {
        UI::TableSetupColumn("ScoreNumber", UI::TableColumnFlags::WidthFixed, 30);
    }
    void renderHeader()
    {
        UI::Text("No.");
    }
    void renderBody(TableRenderContext&inout context)
    {
        if (context.m_CurrentEntry.m_ScoreNumber > 0)
            renderText(context, "" + context.m_CurrentEntry.m_ScoreNumber);
        else
            UI::Text("");
    }
}

class SessionNumberColumn : TableColumn
{
    bool shouldDisplay()
    {
        return settingDisplayLeaderboardSessionNumberColumn;
    }
    void setup()
    {
        UI::TableSetupColumn("SessionNumber", UI::TableColumnFlags::WidthFixed, 30);
    }
    void renderHeader()
    {
        UI::Text("S");
    }
    void renderBody(TableRenderContext&inout context)
    {
        if (context.m_CurrentEntry.m_SessionNumber > 0)
            renderText(context, "" + context.m_CurrentEntry.m_SessionNumber);
        else
            UI::Text("");
    }
}

class TimestampColumn : TableColumn
{
    bool shouldDisplay()
    {
        return settingDisplayLeaderboardTimestampColumn;
    }
    void setup()
    {
        UI::TableSetupColumn("Timestamp", UI::TableColumnFlags::WidthFixed, 150);
    }

    void renderHeader()
    {
        UI::Text("Timestamp");
    }

    void renderBody(TableRenderContext&inout context)
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
    bool shouldDisplay() override
    {
        return settingDisplayLeaderboardTotalTimeColumn;
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
    bool shouldDisplay() override
    {
        return settingDisplayLeaderboardSessionTimeColumn;
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
    bool shouldDisplay() override
    {
        return settingDisplayLeaderboardTimeSinceColumn;
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

void renderText(const TableRenderContext&in context, const string&in text)
{
    if (context.m_IsPlayerNewest)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeLast, 1));
    }
    else if (context.m_IsPlayerNewestCopium)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeLast, 1) * 0.8f);
    }
    else if (context.m_IsPlayerBest)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeBest * 1.4f, 1));
    }
    else if (context.m_IsPlayerBestCopium)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeBest * 0.9f, 1));
    }
    else if (context.m_IsPlayerSessionBest)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeSessionBest * 1.4f, 1));
    }
    else if (context.m_IsPlayerSessionBestCopium)
    {
        UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeSessionBest * 0.9f, 1));
    }
    UI::Text(text);
    if (context.m_IsPlayerNewest || context.m_IsPlayerNewestCopium || context.m_IsPlayerBest || context.m_IsPlayerBestCopium || context.m_IsPlayerSessionBest || context.m_IsPlayerSessionBestCopium)
    {
        UI::PopStyleColor();
    }
}

}

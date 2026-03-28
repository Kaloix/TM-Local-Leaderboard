void Render()
{
    if (!settingDisplayLeaderboard)
    {
        return; // Don't render the leaderboard if the setting is disabled
    }

    LocalLeaderboard::Render();
}

namespace LocalLeaderboard
{
int windowFlags = 0;

array<LeaderboardEntry @> g_TableRows;
array<TableColumn @> g_TableColumns;

void InitRender()
{
    // Clear existing columns
    g_TableColumns.RemoveRange(0, g_TableColumns.Length);

    if (settingDisplayLeaderboardMedalColumn)
        g_TableColumns.InsertLast(MedalColumn());
    if (settingDisplayLeaderboardRankColumn)
        g_TableColumns.InsertLast(RankColumn());
    if (settingDisplayLeaderboardPlayerColumn)
        g_TableColumns.InsertLast(PlayerColumn());
    if (settingDisplayLeaderboardTimeColumn)
        g_TableColumns.InsertLast(TimeColumn());
    if (settingDisplayLeaderboardDeltaPBColumn)
        g_TableColumns.InsertLast(BestTimeDeltaColumn());
    if (settingDisplayLeaderboardDeltaLastColumn)
        g_TableColumns.InsertLast(LastTimeDeltaColumn());
    if (settingDisplayLeaderboardCopiumColumn)
        g_TableColumns.InsertLast(TimeNoRespawnColumn());
    if (settingDisplayLeaderboardRespawnsColumn)
        g_TableColumns.InsertLast(NumberRespawnsColumn());
    if (settingDisplayLeaderboardScoreNumberColumn)
        g_TableColumns.InsertLast(ScoreNumberColumn());
    if (settingDisplayLeaderboardTimestampColumn)
        g_TableColumns.InsertLast(TimestampColumn());

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

    g_TableRows.Sort(timeSort);
}

bool timeSort(const LeaderboardEntry @ const&in a, const LeaderboardEntry @ const&in b)
{
    return a.GetDisplayTime() < b.GetDisplayTime();
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

        for (uint col = 0; col < g_TableColumns.Length; col++)
        {
            UI::TableNextColumn();
            g_TableColumns[col].renderBody(context);
        }
    }

    UI::EndTable();

    UI::End();
}

class TableRenderContext
{
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
    void setup();
    void renderHeader();
    void renderBody(TableRenderContext &inout context);
}

class RankColumn : TableColumn
{
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
    void setup()
    {
        UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 60);
    }

    void renderHeader()
    {
        UI::Text("Time");
    }

    void renderBody(TableRenderContext&inout context)
    {
        renderText(context, Time::Format(context.m_CurrentEntry.GetDisplayTime()));
    }
}

class PlayerColumn : TableColumn
{
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
    }
}

class NumberRespawnsColumn : TableColumn
{
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
        {
            renderText(context, "" + context.m_CurrentEntry.m_NumberRespawns);
        }
    }
}

class ScoreNumberColumn : TableColumn
{
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
        {
            renderText(context, "" + context.m_CurrentEntry.m_ScoreNumber);
        }
    }
}

class TimestampColumn : TableColumn
{
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
            return;
        }

        auto time = Time::Parse(context.m_CurrentEntry.m_TimeStamp);
        string timeStr = time.Year + "-" + Text::Format("%02d", time.Month) + "-" + Text::Format("%02d", time.Day) + " " + Text::Format("%02d", time.Hour) + ":" + Text::Format("%02d", time.Minute) + ":" + Text::Format("%02d", time.Second);
        renderText(context, timeStr);
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

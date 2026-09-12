namespace LocalRecords
{

array<TableColumn @> g_AllTableColumns = {
    // version 0.1.0
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
    TimeSinceColumn(),
    // version 0.2.0
    LocalPercentageColumn(),
    DisplayNameColumn(),
    ReplayColumn(),
};

enum TableColumnType
{
    // version 0.1.0
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
    // version 0.2.0
    LocalPercentageColumn,
    DisplayNameColumn,
    ReplayColumn,
}

string TableColumnTypeToString(const TableColumnType type)
{
    switch (type)
    {
        case TableColumnType::MedalColumn:           return "MedalColumn";
        case TableColumnType::RankColumn:            return "RankColumn";
        case TableColumnType::GlobalPositionColumn:  return "GlobalPositionColumn";
        case TableColumnType::GlobalPercentageColumn:return "GlobalPercentageColumn";
        case TableColumnType::PlayerColumn:          return "PlayerColumn";
        case TableColumnType::TimeColumn:            return "TimeColumn";
        case TableColumnType::TimeDeltaColumn:       return "TimeDeltaColumn";
        case TableColumnType::TimeNoRespawnColumn:   return "TimeNoRespawnColumn";
        case TableColumnType::NumberRespawnsColumn:  return "NumberRespawnsColumn";
        case TableColumnType::ScoreNumberColumn:     return "ScoreNumberColumn";
        case TableColumnType::SessionNumberColumn:   return "SessionNumberColumn";
        case TableColumnType::TimestampColumn:       return "TimestampColumn";
        case TableColumnType::TotalTimeColumn:       return "TotalTimeColumn";
        case TableColumnType::SessionTimeColumn:     return "SessionTimeColumn";
        case TableColumnType::TimeSinceColumn:       return "TimeSinceColumn";
        case TableColumnType::LocalPercentageColumn: return "LocalPercentageColumn";
        case TableColumnType::DisplayNameColumn:     return "DisplayNameColumn";
        case TableColumnType::ReplayColumn:          return "ReplayColumn";
    }
    return "";
}

TableColumnType StringToTableColumnType(const string&in value)
{
    if (value == "MedalColumn")            return TableColumnType::MedalColumn;
    if (value == "RankColumn")             return TableColumnType::RankColumn;
    if (value == "GlobalPositionColumn")   return TableColumnType::GlobalPositionColumn;
    if (value == "GlobalPercentageColumn") return TableColumnType::GlobalPercentageColumn;
    if (value == "PlayerColumn")           return TableColumnType::PlayerColumn;
    if (value == "TimeColumn")             return TableColumnType::TimeColumn;
    if (value == "TimeDeltaColumn")        return TableColumnType::TimeDeltaColumn;
    if (value == "TimeNoRespawnColumn")    return TableColumnType::TimeNoRespawnColumn;
    if (value == "NumberRespawnsColumn")   return TableColumnType::NumberRespawnsColumn;
    if (value == "ScoreNumberColumn")      return TableColumnType::ScoreNumberColumn;
    if (value == "SessionNumberColumn")    return TableColumnType::SessionNumberColumn;
    if (value == "TimestampColumn")        return TableColumnType::TimestampColumn;
    if (value == "TotalTimeColumn")        return TableColumnType::TotalTimeColumn;
    if (value == "SessionTimeColumn")      return TableColumnType::SessionTimeColumn;
    if (value == "TimeSinceColumn")        return TableColumnType::TimeSinceColumn;
    if (value == "LocalPercentageColumn")  return TableColumnType::LocalPercentageColumn;
    if (value == "DisplayNameColumn")      return TableColumnType::DisplayNameColumn;
    if (value == "ReplayColumn")           return TableColumnType::ReplayColumn;

    LogWarning("Unknown TableColumnType string: " + value);
    return TableColumnType::MedalColumn;
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

TableColumn@ GetTableColumn(const uint pos)
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

void SetColumnPosition(TableColumn@ column, const uint newPos)
{
    if (column is null)
        return;

    auto currentPos = column.m_Pos;
    if (currentPos == newPos)
        return;

    if (currentPos < newPos)
    {
        for (uint i = currentPos; i < g_AllTableColumns.Length && i < newPos; ++i)
            SwapColumnPositions(column, GetTableColumn(i + 1));
    }
    else
    {
        for (uint i = currentPos; i > 0 && i > newPos; --i)
            SwapColumnPositions(GetTableColumn(i - 1), column);
    }
}

void SwapColumnPositions(TableColumn@ columnFirst, TableColumn@ columnSecond)
{
    columnFirst.m_Pos += 1;
    columnSecond.m_Pos -= 1;
}

class TableColumn
{
    bool m_Show = true;

    uint m_Pos = 0;

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
    bool EnableMouseInteraction() const
    {
        return true;
    }
    string GetHeaderValue() const
    {
        return GetName() + "##" + int(GetType());
    }
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const
    {
        return "";
    }
    void PrepareBodyCell(const LeaderboardRenderRow &in renderRow, LeaderboardRenderCell &inout renderCell) const
    {
        renderCell.m_Value = GetBodyValue(renderRow);
        renderCell.m_FontColor = GetRowColor(renderRow);
    }
    void RenderBodyCell(const LeaderboardRenderRow &in renderRow, const LeaderboardRenderCell &in renderCell) const
    {
        UI::PushStyleColor(UI::Col::Text, renderCell.m_FontColor);
        UI::Text(renderCell.m_Value);
        UI::PopStyleColor();
    }
    bool shouldDisplay() const
    {
        return m_Show;
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
        return "Local Rank (#)";
    }
    string GetHeaderValue() const override
    {
        return Icons::Trophy;
    }
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override
    {
        return renderRow.m_Entry.GetDisplayRank();
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
        return "Global Position (#)";
    }
    string GetHeaderValue() const override
    {
        return Icons::Globe;
    }
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override
    {
        return formatPosition(renderRow.m_Entry.GetLatestGlobalPosition());
    }
}

class LocalPercentageColumn : TableColumn
{
    TableColumnType GetType() const override
    {
        return TableColumnType::LocalPercentageColumn;
    }
    string GetName() const override
    {
        return "Local Rank (%)";
    }
    string GetHeaderValue() const override
    {
        return Icons::Desktop + " %";
    }
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override
    {
        if (g_State.m_Leaderboard.m_TotalNumberFinishes <= 0 || renderRow.m_Entry.m_Rank <= 0)
            return "";
        else
            return formatPercentile(float(renderRow.m_Entry.m_Rank) / float(g_State.m_Leaderboard.m_TotalNumberFinishes));
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
        return "Global Position (%)";
    }
    string GetHeaderValue() const override
    {
        return Icons::Globe + " %";
    }
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override
    {
        if (g_State.m_NumberGlobalPositions == 0 || renderRow.m_Entry.GetLatestGlobalPosition() <= 0)
            return "";
        else
            return formatPercentile(float(renderRow.m_Entry.GetLatestGlobalPosition()) / float(g_State.m_NumberGlobalPositions));
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
    void PrepareBodyCell(const LeaderboardRenderRow &in renderRow, LeaderboardRenderCell &inout renderCell) const override
    {
        renderCell.m_Value = renderRow.m_Entry.GetDisplayIcon();
        if (renderRow.m_Entry.m_Medal !is null)
        {
            renderCell.m_FontColor = vec4(renderRow.m_Entry.m_Medal.GetIconColor(), 1);
        }
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
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override
    {
        const auto time = GetTime(renderRow);
        if (time > 0)
            return Time::Format(time, ShowFractions());
        else if (time < 0)
            return Icons::EyeSlash;
        else
            return "";
    }
    int64 GetTime(const LeaderboardRenderRow&in renderRow) const
    {
        return renderRow.m_Entry.GetDisplayTime();
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
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override
    {
        return renderRow.m_Entry.GetPlayerDisplayName();
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
    void PrepareBodyCell(const LeaderboardRenderRow &in renderRow, LeaderboardRenderCell &inout renderCell) const override
    {
        bool showDelta = m_ComparisonTarget !is null && m_ComparisonTarget.IsAvailable() && renderRow.m_Entry.GetDisplayTime() > 0;
        if (renderRow.m_Entry.GetDisplayTime() <= 0 || !showDelta)
        {
            return;
        }
        if (renderRow.m_Entry is m_ComparisonTarget.GetComparisonTargetEntry())
        {
            return;
        }

        const int delta = renderRow.m_Entry.GetDisplayTime() - m_ComparisonTarget.GetTime(); 
        renderCell.m_Value = GetDeltaString(delta);
        renderCell.m_FontColor = GetDeltaColor(delta);
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
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override {
        if (renderRow.m_Entry.m_Type == LeaderboardEntryType::Score && renderRow.m_Entry.m_NumberRespawns != 0)
            return Time::Format(renderRow.m_Entry.m_TimeNoRespawn);
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
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override
    {
        if (renderRow.m_Entry.m_NumberRespawns != 0)
            return "" + renderRow.m_Entry.m_NumberRespawns;
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
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override
    {
        if (renderRow.m_Entry.m_ScoreNumber > 0)
            return  "" + renderRow.m_Entry.m_ScoreNumber;
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
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override
    {
        if (renderRow.m_Entry.m_SessionNumber > 0)
            return "" + renderRow.m_Entry.m_SessionNumber;
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
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override
    {
        return formatTimestamp(renderRow.m_Entry.m_TimeStamp);
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
    int64 GetTime(const LeaderboardRenderRow&in renderRow) const override
    {
        return renderRow.m_Entry.m_TimeInTotal;
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
    int64 GetTime(const LeaderboardRenderRow&in renderRow) const override
    {
        return renderRow.m_Entry.m_TimeInSession;
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
    int64 GetTime(const LeaderboardRenderRow&in renderRow) const override
    {
        if (renderRow.m_Entry.m_TimeStamp <= 0)
        {
            return 0;
        }

        return (g_State.m_Leaderboard.m_TotalTime - renderRow.m_Entry.m_TimeInTotal);
    }
    bool ShowFractions() override
    {
        return false;
    }
}

class DisplayNameColumn : TableColumn
{
    bool GetDefaultShow() override
    {
        return false;
    }
    TableColumnType GetType() const override
    {
        return TableColumnType::DisplayNameColumn;
    }
    string GetName() const override
    {
        return "Display Name";
    }
    string GetBodyValue(const LeaderboardRenderRow&in renderRow) const override
    {
        return renderRow.m_Entry.GetDisplayName();
    }
}

class ReplayColumn : TableColumn
{
    bool GetDefaultShow() override
    {
        return false;
    }
    TableColumnType GetType() const override
    {
        return TableColumnType::ReplayColumn;
    }
    string GetName() const override
    {
        return "Replay";
    }
    bool EnableMouseInteraction() const override
    {
        return false;
    }
    void RenderBodyCell(const LeaderboardRenderRow &in renderRow, const LeaderboardRenderCell &in renderCell) const override
    {
        if (!Permissions::PlayRecords())
            return;

        if (renderRow.m_IsPlayerBest)
            PbReplay();
        else
        {
            const auto @timeData = @renderRow.m_Entry.GetLatestGlobalTimeData();
            if (timeData !is null)
                CustomPositionReplay(@timeData);
        }
    }

    void PbReplay()
    {
        Replay(g_State.m_PlayerWebServicesId);
    }

    void CustomPositionReplay(const GlobalTimeData@ globalTimeData)
    {
        if (globalTimeData is null || globalTimeData.m_PlayerId == "")
            return;
        Replay(globalTimeData.m_PlayerId);
    }

    void Replay(const string &in playerId)
    {
        // Determine if the player ghost is enabled
        const int ghostIndex = g_State.m_ActiveGhosts.Find(playerId);
        const bool ghostEnabled = ghostIndex != -1;

        // Ghost toggle
        const auto ghostIcon = ghostEnabled ? Icons::Eye : Icons::EyeSlash;
        UI::Text(ghostIcon);
        if (UI::IsItemClicked())
        {
            // The event is sent twice when using the leaderboard
            toggleHook.m_FirstCall = true;
            MLHook::Queue_SH_SendCustomEvent("TMGame_Record_ToggleGhost", {playerId});
        }

        UI::SameLine();

        // Replay Toggle
        const auto replayIcon = (g_State.m_ActiveReplay == playerId) ? Icons::Stop : Icons::Play;
        UI::Text(replayIcon);
        if (UI::IsItemClicked())
        {
            MLHook::Queue_SH_SendCustomEvent("TMGame_Record_SpectateGhost", {playerId});
        }
    }
}

}

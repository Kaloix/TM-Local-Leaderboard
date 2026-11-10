namespace LocalRecords::CurrentRun
{

array<CurrentRunColumn@> g_AllCurrentRunColumns = {
    CurrentRunTime(),
    CurrentRunTimeNr(),
    CurrentRunSpeed(),
    CurrentRunCpTime(),
    CurrentRunCpTimeNr(),
    CurrentRunNumberRespawns(),
};

CurrentRunColumn@ GetColumnById(const string &in id)
{
    for (uint i = 0; i < g_AllCurrentRunColumns.Length; ++i)
        if (g_AllCurrentRunColumns[i].GetId() == id)
            return @g_AllCurrentRunColumns[i];

    return null;
}

class CurrentRunColumn
{
    uint m_Pos = 0;

    bool m_ShowValue = true;
    bool m_ShowDelta = true;
    bool m_ShowPos = true;

    string GetId() const
    {
        LogWarning("Calling on base class!");
        return "<ID>";
    }

    string GetHeaderValue() const
    {
        LogWarning("Calling on base class!");
        return "<Missing>";
    }

    void PrepareValue(const CheckpointData &in checkpointData, CurrentRunRenderCell &inout cell) const
    {
        LogWarning("Calling on base class!");
    }

    void PrepareValueCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, CurrentRunRenderCell &inout cell) const
    {
        LogWarning("Calling on base class!");
    }

    void PrepareDelta(const CheckpointData &in checkpointData, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const
    {
        LogWarning("Calling on base class!");
    }

    void PrepareDeltaCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const
    {
        LogWarning("Calling on base class!");
    }

    CheckpointPositionComparison GetComparison() const
    {
        LogWarning("Calling on base class!");
        return CheckpointPositionComparison::TimeFromStart;
    }
}

class CurrentRunTime : CurrentRunColumn
{
    string GetId() const override
    {
        return "Time";
    }

    string GetHeaderValue() const override
    {
        return Icons::ClockO;
    }

    void PrepareValue(const CheckpointData &in checkpointData, CurrentRunRenderCell &inout cell) const override
    {
        cell.m_Value = Time::Format(checkpointData.m_TimeFromStart);
    }

    void PrepareValueCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, CurrentRunRenderCell &inout cell) const override
    {
        cell.m_Value = Time::Format(now - g_State.m_LastStartTime);
    }

    void PrepareDelta(const CheckpointData &in checkpointData, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        const int delta = checkpointData.m_TimeFromStart - comparisonCheckpointData.m_TimeFromStart;
        cell.m_Value = GetDeltaString(delta);
        cell.m_FontColor = GetDeltaColor(delta);
    }

    void PrepareDeltaCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        int delta = (now - g_State.m_LastStartTime) - comparisonCheckpointData.m_TimeFromStart;
        cell.m_Value = GetDeltaString(delta);
        cell.m_FontColor = GetDeltaColor(delta);
    }

    CheckpointPositionComparison GetComparison() const override
    {
        return CheckpointPositionComparison::TimeFromStart;
    }
}

class CurrentRunTimeNr : CurrentRunColumn
{
    string GetId() const override
    {
        return "TimeNoRespawn";
    }

    string GetHeaderValue() const override
    {
        return Icons::FastForward;
    }

    void PrepareValue(const CheckpointData &in checkpointData, CurrentRunRenderCell &inout cell) const override
    {
        cell.m_Value = Time::Format(checkpointData.m_TimeFromStartNoRespawn);
    }

    void PrepareValueCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, CurrentRunRenderCell &inout cell) const override
    {
        return;
    }

    void PrepareDelta(const CheckpointData &in checkpointData, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        int delta = checkpointData.m_TimeFromStartNoRespawn - comparisonCheckpointData.m_TimeFromStartNoRespawn;
        cell.m_Value = GetDeltaString(delta);
        cell.m_FontColor = GetDeltaColor(delta);
    }

    void PrepareDeltaCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        return;
    }

    CheckpointPositionComparison GetComparison() const override
    {
        return CheckpointPositionComparison::TimeFromStartNoRespawn;
    }
}

class CurrentRunSpeed : CurrentRunColumn
{
    string GetId() const override
    {
        return "Speed";
    }

    string GetHeaderValue() const override
    {
        return Icons::Tachometer;;
    }

    void PrepareValue(const CheckpointData &in checkpointData, CurrentRunRenderCell &inout cell) const override
    {
        cell.m_Value = "" + checkpointData.m_Speed;
    }

    void PrepareValueCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, CurrentRunRenderCell &inout cell) const override
    {
        cell.m_Value = "" + speed;
    }

    void PrepareDelta(const CheckpointData &in checkpointData, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        const int delta = checkpointData.m_Speed - comparisonCheckpointData.m_Speed;
        cell.m_Value = GetDeltaSpeedString(delta);
        cell.m_FontColor = GetDeltaSpeedColor(delta);
    }

    void PrepareDeltaCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        int delta = speed - comparisonCheckpointData.m_Speed;
        cell.m_Value = GetDeltaSpeedString(delta);
        cell.m_FontColor = GetDeltaSpeedColor(delta);
    }

    CheckpointPositionComparison GetComparison() const override
    {
        return CheckpointPositionComparison::Speed;
    }
}

class CurrentRunCpTime : CurrentRunColumn
{
    string GetId() const override
    {
        return "CheckpointTime";
    }

    string GetHeaderValue() const override
    {
        return Icons::FlagCheckered;
    }

    void PrepareValue(const CheckpointData &in checkpointData, CurrentRunRenderCell &inout cell) const override
    {
        cell.m_Value = Time::Format(checkpointData.m_TimeFromPrevious);
    }

    void PrepareValueCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, CurrentRunRenderCell &inout cell) const override
    {
        return;
    }

    void PrepareDelta(const CheckpointData &in checkpointData, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        int delta = checkpointData.m_TimeFromPrevious - comparisonCheckpointData.m_TimeFromPrevious;
        cell.m_Value = GetDeltaString(delta);
        cell.m_FontColor = GetDeltaColor(delta);
    }

    void PrepareDeltaCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        return;
    }

    CheckpointPositionComparison GetComparison() const override
    {
        return CheckpointPositionComparison::TimeFromPrevious;
    }
}

class CurrentRunCpTimeNr : CurrentRunColumn
{
    string GetId() const override
    {
        return "CheckpointTimeNoRespawn";
    }

    string GetHeaderValue() const override
    {
        return Icons::Forward;
    }

    void PrepareValue(const CheckpointData &in checkpointData, CurrentRunRenderCell &inout cell) const override
    {
        cell.m_Value = Time::Format(checkpointData.m_TimeFromPreviousNoRespawn);
    }

    void PrepareValueCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, CurrentRunRenderCell &inout cell) const override
    {
        cell.m_Value = Time::Format(now - g_State.m_LastRespawn);
    }

    void PrepareDelta(const CheckpointData &in checkpointData, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        int delta = checkpointData.m_TimeFromPreviousNoRespawn - comparisonCheckpointData.m_TimeFromPreviousNoRespawn;
        cell.m_Value = GetDeltaString(delta);
        cell.m_FontColor = GetDeltaColor(delta);
    }

    void PrepareDeltaCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        int delta = (now - g_State.m_LastRespawn) - comparisonCheckpointData.m_TimeFromPrevious;
        cell.m_Value = GetDeltaString(delta);
        cell.m_FontColor = GetDeltaColor(delta);
    }

    CheckpointPositionComparison GetComparison() const override
    {
        return CheckpointPositionComparison::TimeFromPreviousNoRespawn;
    }
}

class CurrentRunNumberRespawns : CurrentRunColumn
{
    string GetId() const override
    {
        return "NumberRespawns";
    }

    string GetHeaderValue() const override
    {
        return Icons::Refresh;
    }

    void PrepareValue(const CheckpointData &in checkpointData, CurrentRunRenderCell &inout cell) const override
    {
        cell.m_Value = "" + checkpointData.m_NumberRespawns;
    }

    void PrepareValueCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, CurrentRunRenderCell &inout cell) const override
    {
        if (player.NbRespawnsByCp.Length <= currentCp)
            return;
        cell.m_Value = "" + player.NbRespawnsByCp[currentCp];
    }

    void PrepareDelta(const CheckpointData &in checkpointData, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        int delta = checkpointData.m_NumberRespawns - comparisonCheckpointData.m_NumberRespawns;
        cell.m_Value = GetDeltaSpeedString(delta);
        cell.m_FontColor = GetDeltaColor(delta);
    }

    void PrepareDeltaCurrent(const uint currentCp, const int now, const int speed, const MLFeed::PlayerCpInfo_V4@ player, const CheckpointData &in comparisonCheckpointData, CurrentRunRenderCell &inout cell) const override
    {
        if (player.NbRespawnsByCp.Length <= currentCp)
            return;
        int delta = player.NbRespawnsByCp[currentCp] - comparisonCheckpointData.m_NumberRespawns;
        cell.m_Value = GetDeltaSpeedString(delta);
        cell.m_FontColor = GetDeltaColor(delta);
    }

    CheckpointPositionComparison GetComparison() const override
    {
        return CheckpointPositionComparison::NumberRespawns;
    }
}

}


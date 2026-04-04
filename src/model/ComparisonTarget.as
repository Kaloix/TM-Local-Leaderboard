enum ComparisonTargetType
{
    // Best runs
    FastestRun,
    SessionFastestRun,

    // Newest runs
    NewestRun,

    // Copium runs
    FastestCopium,
    SessionFastestCopium,
    NewestCopium,

    // Checkpoints runs
    BestCheckpoints,
    SessionBestCheckpoints,

    // Medals
#if DEPENDENCY_CHAMPIONMEDALS
    ChampionMedal,
#endif
#if DEPENDENCY_WARRIORMEDALS
    WarriorMedal,
#endif
    AuthorMedal,
    GoldMedal,
    SilverMedal,
    BronzeMedal,
}

namespace LocalLeaderboard
{

array<ComparisonTarget@> g_ComparisonTargets;

void InitializeComparisonTarget()
{
    // Best runs
    g_ComparisonTargets.InsertLast(PersonalBestComparisonTarget());
    g_ComparisonTargets.InsertLast(SessionBestComparisonTarget());
    // Newest runs
    g_ComparisonTargets.InsertLast(NewestRunComparisonTarget());
    // Copium runs
    g_ComparisonTargets.InsertLast(FastestCopiumComparisonTarget());
    g_ComparisonTargets.InsertLast(SessionFastestCopiumComparisonTarget());
    g_ComparisonTargets.InsertLast(NewestCopiumComparisonTarget());
    // Checkpoints runs
    g_ComparisonTargets.InsertLast(BestCheckpointsComparisonTarget());
    g_ComparisonTargets.InsertLast(SessionBestCheckpointsComparisonTarget());
    // Medals
#if DEPENDENCY_CHAMPIONMEDALS
    g_ComparisonTargets.InsertLast(ChampionMedalComparisonTarget());
#endif
#if DEPENDENCY_WARRIORMEDALS
    g_ComparisonTargets.InsertLast(WarriorMedalComparisonTarget());
#endif
    g_ComparisonTargets.InsertLast(AuthorMedalComparisonTarget());
    g_ComparisonTargets.InsertLast(GoldMedalComparisonTarget());
    g_ComparisonTargets.InsertLast(SilverMedalComparisonTarget());
    g_ComparisonTargets.InsertLast(BronzeMedalComparisonTarget());
}

ComparisonTarget@ GetComparisonTarget(ComparisonTargetType type)
{
    for (uint i = 0; i < g_ComparisonTargets.Length; i++)
    {
        if (g_ComparisonTargets[i].GetType() == type)
            return @g_ComparisonTargets[i];
    }
    LogWarning("Comparison target not found for type: " + type);
    return null;
}

class ComparisonTarget
{
    ComparisonTargetType GetType() const
    {
        return ComparisonTargetType::FastestRun;
    }

    int GetTime() const
    {
        return GetComparisonTargetEntry().GetDisplayTime();
    }

    bool IsAvailable() const
    {
        auto @entry = GetComparisonTargetEntry();
        return entry !is null && entry.GetDisplayTime() > 0;
    }

    bool IsSelf(const LeaderboardEntry@ entry) const
    {
        return entry is GetComparisonTargetEntry();
    }

    LeaderboardEntry@ GetComparisonTargetEntry() const
    {
        LogWarning("Calling GetComparisonTargetEntry of base class!");
        return null;
    }
}

// =================
// --- Best runs ---
// =================

class PersonalBestComparisonTarget : ComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::FastestRun;
    }
    LeaderboardEntry@ GetComparisonTargetEntry() const override
    {
        return @g_State.m_Leaderboard.m_FastestRun;
    }
}

class SessionBestComparisonTarget : ComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::SessionFastestRun;
    }
    LeaderboardEntry@ GetComparisonTargetEntry() const override
    {
        return @g_State.m_Leaderboard.m_SessionFastestRun;
    }
}

// ================
// --- Last run ---
// ================

class NewestRunComparisonTarget : ComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::NewestRun;
    }
    LeaderboardEntry@ GetComparisonTargetEntry() const override
    {
        return @g_State.m_Leaderboard.m_NewestRun;
    }
}

// ===================
// --- Copium runs ---
// ===================

class FastestCopiumComparisonTarget : ComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::FastestCopium;
    }
    LeaderboardEntry@ GetComparisonTargetEntry() const override
    {
        return @g_State.m_Leaderboard.m_FastestCopiumRun;
    }
}

class SessionFastestCopiumComparisonTarget : ComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::SessionFastestCopium;
    }
    LeaderboardEntry@ GetComparisonTargetEntry() const override
    {
        return @g_State.m_Leaderboard.m_SessionFastestCopiumRun;
    }
}

class NewestCopiumComparisonTarget : ComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::NewestCopium;
    }
    LeaderboardEntry@ GetComparisonTargetEntry() const override
    {
        return @g_State.m_Leaderboard.m_NewestCopiumRun;
    }
}

// ========================
// --- Checkpoints runs ---
// ========================

class BestCheckpointsComparisonTarget : ComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::BestCheckpoints;
    }
    LeaderboardEntry@ GetComparisonTargetEntry() const override
    {
        return @g_State.m_Leaderboard.m_BestCheckpointsRun;
    }
}

class SessionBestCheckpointsComparisonTarget : ComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::SessionBestCheckpoints;
    }
    LeaderboardEntry@ GetComparisonTargetEntry() const override
    {
        return @g_State.m_Leaderboard.m_SessionBestCheckpointsRun;
    }
}

// ==============
// --- Medals ---
// ==============

class MedalComparisonTarget : ComparisonTarget
{
    MedalType GetMedalType() const
    {
        return MedalType::Author;
    }
    LeaderboardEntry@ GetComparisonTargetEntry() const override
    {
        return @g_State.m_MedalEntries[GetMedalType()];
    }
}

#if DEPENDENCY_CHAMPIONMEDALS
class ChampionMedalComparisonTarget : MedalComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::ChampionMedal;
    }
    MedalType GetMedalType() const override
    {
        return MedalType::Champion;
    }
}
#endif

#if DEPENDENCY_WARRIORMEDALS
class WarriorMedalComparisonTarget : MedalComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::WarriorMedal;
    }
    MedalType GetMedalType() const override
    {
        return MedalType::Warrior;
    }
}
#endif

class AuthorMedalComparisonTarget : MedalComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::AuthorMedal;
    }
    MedalType GetMedalType() const override
    {
        return MedalType::Author;
    }
}

class GoldMedalComparisonTarget : MedalComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::GoldMedal;
    }
    MedalType GetMedalType() const override
    {
        return MedalType::Gold;
    }
}

class SilverMedalComparisonTarget : MedalComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::SilverMedal;
    }
    MedalType GetMedalType() const override
    {
        return MedalType::Silver;
    }
}

class BronzeMedalComparisonTarget : MedalComparisonTarget
{
    ComparisonTargetType GetType() const override
    {
        return ComparisonTargetType::BronzeMedal;
    }
    MedalType GetMedalType() const override
    {
        return MedalType::Bronze;
    }
}

}

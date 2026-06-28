namespace LocalLeaderboard
{

#if DEPENDENCY_MLHOOK

// Stolen from https://github.com/jespervdz/tm-at-check/tree/main

void GetAtCpTimes()
{
    // Request ML via MLHook for the AT CP Times. Will write it to `CPTimesAT`
    MLHook::Queue_MessageManialinkPlayground("LocalLeaderboard", "Hook_LocalLeaderboard");
}

const string script = """
main() {
    declare metadata Integer[] Race_AuthorRaceWaypointTimes for Map;
    declare Text[][] MLHook_Inbound_LocalLeaderboard for ClientUI;
    while (True) {
        yield;
        foreach (Event in MLHook_Inbound_LocalLeaderboard) {
            if (Event[0] == "Hook_LocalLeaderboard")
                SendCustomEvent("MLHook_Event_LocalLeaderboard", [Race_AuthorRaceWaypointTimes.tojson()]);
        }
        MLHook_Inbound_LocalLeaderboard = [];
    }
}
""";

void InitHooks() {
    LogDebug("MLHook found. Setting up hooks...");
    MLHook::RequireVersionApi("0.5.2");
    MLHook::RegisterMLHook(ATWaypointTimesFeed, ATWaypointTimesFeed.type);
    MLHook::InjectManialinkToPlayground("Hook_LocalLeaderboard", script, true);
}

void UnloadHooks()
{
    MLHook::UnregisterMLHooksAndRemoveInjectedML();
}

_ATWaypointTimesFeed@ ATWaypointTimesFeed = _ATWaypointTimesFeed();

class _ATWaypointTimesFeed : MLHook::HookMLEventsByType
{
    _ATWaypointTimesFeed() { super("LocalLeaderboard"); }

    void OnEvent(MLHook::PendingEvent@ event) override {
        Json::Value parsed = Json::Parse(event.data[0]);
        int[] CPTimesAT = {};

        if (parsed.GetType() == Json::Type::Array) {
            CPTimesAT.Resize(parsed.Length);
            for (uint i = 0; i < parsed.Length; i++)
                CPTimesAT[i] = int(parsed[i]);
        } else {
            CPTimesAT.Resize(0);
        }

        LeaderboardEntry@ authorEntry = g_State.GetMedalEntry(MedalType::Author);
        authorEntry.m_Checkpoints.RemoveRange(0, authorEntry.m_Checkpoints.Length);

        for (uint i = 0; i < CPTimesAT.Length; ++i)
        {
            CheckpointData @cpData = CheckpointData();
            authorEntry.m_Checkpoints.InsertLast(cpData);

            cpData.m_TimeFromStart = CPTimesAT[i];
            cpData.m_TimeFromPrevious = i == 0 ? 0 : CPTimesAT[i] - CPTimesAT[i - 1];

            AddLap(i + 1, cpData, authorEntry.m_Checkpoints, authorEntry.m_Laps);
        }
    }
}

#else

void GetAtCpTimes()
{
    LogDebug("No MLHook for reading AT CP times");
}

void InitHooks() {
    LogDebug("No MLHook found");
}

void UnloadHooks()
{
}

#endif

}

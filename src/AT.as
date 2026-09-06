namespace LocalRecords
{

bool g_InitializedHooks = false;

void UpdateHookSettings()
{
    if (g_InitializedHooks)
    {
        UnloadHooks();
    }
    else if (!g_InitializedHooks)
    {
        InitHooks();
    }
}

#if DEPENDENCY_MLHOOK

// Stolen from https://github.com/jespervdz/tm-at-check/tree/main

void GetAtCpTimes()
{
    if (!settingReadATCpTimes)
        return;
    // Request ML via MLHook for the AT CP Times. Will write it to `CPTimesAT`
    MLHook::Queue_MessageManialinkPlayground("LocalRecords", "Hook_LocalRecords");
}

const string script = """
main() {
    declare metadata Integer[] Race_AuthorRaceWaypointTimes for Map;
    declare Text[][] MLHook_Inbound_LocalRecords for ClientUI;
    while (True) {
        yield;
        foreach (Event in MLHook_Inbound_LocalRecords) {
            if (Event[0] == "Hook_LocalRecords")
                SendCustomEvent("MLHook_Event_LocalRecords", [Race_AuthorRaceWaypointTimes.tojson()]);
        }
        MLHook_Inbound_LocalRecords = [];
    }
}
""";

void InitHooks() {
    if (!settingReadATCpTimes)
        return;

    LogDebug("MLHook found. Setting up hooks...");
    MLHook::RequireVersionApi("0.5.2");

    if (settingReadATCpTimes)
    {
        MLHook::RegisterMLHook(ATWaypointTimesFeed, ATWaypointTimesFeed.type);
        MLHook::InjectManialinkToPlayground("Hook_LocalRecords", script, true);
    }

    MLHook::RegisterMLHook(spectateHook, "TMGame_Record_SpectateGhost", true);
    MLHook::RegisterMLHook(spectateHook, "TMGame_Record_Spectate", true);
    MLHook::RegisterMLHook(toggleHook, "TMGame_Record_ToggleGhost", true);
    // TODO: handle toggle of ghost during replay
    // MLHook::RegisterMLHook(toggleHook, "TMGame_Record_TogglePB", true);

    g_InitializedHooks = true;
}

void UnloadHooks()
{
    if (!g_InitializedHooks)
        return;
    MLHook::UnregisterMLHooksAndRemoveInjectedML();
    g_InitializedHooks = false;
}

_ATWaypointTimesFeed@ ATWaypointTimesFeed = _ATWaypointTimesFeed();

class _ATWaypointTimesFeed : MLHook::HookMLEventsByType
{
    _ATWaypointTimesFeed() { super("LocalRecords"); }

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
            cpData.m_TimeFromPrevious = i == 0 ? CPTimesAT[0] : CPTimesAT[i] - CPTimesAT[i - 1];

            AddLap(i + 1, cpData, authorEntry.m_Checkpoints, authorEntry.m_Laps);
        }
    }
}

ToggleHook @toggleHook = ToggleHook();
SpectateHook @spectateHook = SpectateHook();

class ToggleHook : MLHook::HookMLEventsByType {
    ToggleHook() {
        super("TMGame_Record_ToggleGhost");
    }

    bool m_FirstCall = false;

    void OnEvent(MLHook::PendingEvent@ event) override {
        // Event is fired twice when using the normal leaderboard
        string id = event.data[0];
        LogDebug("Toggle Ghost:" + event.data[0]);
        if (!m_FirstCall)
        {
            m_FirstCall = true;
            return;
        }
        m_FirstCall = false;

        const int ghostIndex = g_State.m_ActiveGhosts.Find(id);
        if (ghostIndex == -1)
        {
            g_State.m_ActiveGhosts.InsertLast(id);
        }
        else
        {
            g_State.m_ActiveGhosts.RemoveAt(ghostIndex);
        }
    }
}

class SpectateHook : MLHook::HookMLEventsByType {
    SpectateHook() {
        super("TMGame_Record_Spectate");
    }

    void OnEvent(MLHook::PendingEvent@ event) override {
        LogDebug("TMGame_Record_Spectate: " + event.data[0]);
        g_State.m_ActiveReplay = event.data[0];
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

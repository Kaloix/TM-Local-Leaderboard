namespace LocalRecords
{

void InitNadeoApi()
{
    if (!settingUseNadeoApi)
    {
        LogDebug("Usage of Nadeo's API is disabled");
        return;
    }

    LogDebug("Authenticating to NadeoLiveServices...");
    NadeoServices::AddAudience("NadeoLiveServices");
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices"))
    {
        LogDebug("Waiting for Authentication to NadeoLiveServices...");
        yield();
    }
    LogDebug("Authenticated to NadeoLiveServices");
}


awaitable@ g_InitPb = null;
void InitPersonalBestAsync()
{
    if (g_State.m_Leaderboard.m_FastestRun is null)
        return;
    InitPositionForEntryAsync(@g_State.m_Leaderboard.m_FastestRun);
    // if (g_InitPb !is null && g_InitPb.IsRunning())
    //     return;
    // @g_InitPb = @startnew(InitPersonalBest);
}

void InitPersonalBest()
{
    if (g_State.m_Leaderboard.m_FastestRun is null)
        return;
    const int position = FetchPersonalBest();
    g_State.m_Leaderboard.m_FastestRun.AddGlobalPositionData(position);
}

awaitable@ g_InitLiveData = null;
void InitLiveDataAsync()
{
    if (g_InitLiveData !is null && g_InitLiveData.IsRunning())
        return;
    @g_InitLiveData = @startnew(InitLiveData);
}

awaitable@ g_InitPositionForEntryAsync = null;
array<LeaderboardEntry @> g_InitPositionForEntryAsyncQueue;
void InitPositionForEntryAsync(LeaderboardEntry@ entry)
{
    g_InitPositionForEntryAsyncQueue.InsertLast(@entry);
    if (g_InitPositionForEntryAsync !is null && g_InitPositionForEntryAsync.IsRunning())
        return;
    @g_InitPositionForEntryAsync = @startnew(InitPositionForEntryData);
}

void InitLiveData()
{
    // Medals
    for (uint i = 0; i < g_State.m_MedalEntries.Length; ++i) {
        InitPositionForEntry(@g_State.m_MedalEntries[i]);
    }

    // Custom times
    for (uint i = 0; i < g_State.m_CustomTimeEntries.Length; ++i) {
        InitPositionForEntry(@g_State.m_CustomTimeEntries[i]);
    }

    // Custom positions
    for (uint i = 0; i < g_State.m_CustomPositionEntries.Length; ++i) {
        InitTimeForEntry(@g_State.m_CustomPositionEntries[i]);
    }

    // Copium
    InitPositionForEntry(@g_State.m_Leaderboard.m_FastestCopiumRun);
    InitPositionForEntry(@g_State.m_Leaderboard.m_BestCheckpointsRun);
}

void InitPositionForEntryData()
{
    while (true)
    {
        if (g_InitPositionForEntryAsyncQueue.Length == 0)
            break;
        LeaderboardEntry@ entry = @g_InitPositionForEntryAsyncQueue[0];
        g_InitPositionForEntryAsyncQueue.RemoveAt(0);
        InitPositionForEntry(@entry);
    }
}

void InitPositionForEntry(LeaderboardEntry@ entry)
{
    if (entry is null)
        return;
    if (g_State.m_CurrentMap == "")
        return;

    array<int> times = {entry.GetDisplayTime()};
    const auto positions = FetchForTimes(times);
    entry.AddGlobalPositionData(positions[0]);
}

awaitable@ g_InitTimeForEntryAsync = null;
array<LeaderboardEntry @> g_InitTimeForEntryAsyncQueue;

void InitTimeForEntryAsync(LeaderboardEntry@ entry)
{
    if (entry is null)
        return;
    if (g_State.m_CurrentMap == "")
        return;

    g_InitTimeForEntryAsyncQueue.InsertLast(@entry);
    if (g_InitTimeForEntryAsync !is null && g_InitTimeForEntryAsync.IsRunning())
        return;

    @g_InitTimeForEntryAsync = @startnew(InitTimeForEntryData);
}

void InitTimeForEntryData()
{
    while (g_InitTimeForEntryAsyncQueue.Length > 0)
    {
        LeaderboardEntry@ entry = @g_InitTimeForEntryAsyncQueue[0];
        g_InitTimeForEntryAsyncQueue.RemoveAt(0);
        InitTimeForEntry(@entry);
    }
}

void InitTimeForEntry(LeaderboardEntry@ entry)
{
    if (entry is null)
        return;

    const auto results = FetchRecords(entry.m_GlobalPosition);
    entry.m_Time = results[0];
    entry.m_TimeStamp = results[1];

    setMedal(entry);
    InitRows();
}

Json::Value@ FetchFromNadeoApi(const string&in uri)
{
    auto @request = NadeoServices::Get("NadeoLiveServices", NadeoServices::BaseURLLive() + uri);
    return DoRequest(request);
}

Json::Value@ PostToNadeoApi(const string&in uri, const string&in body)
{
    auto @request = NadeoServices::Post("NadeoLiveServices", NadeoServices::BaseURLLive() + uri, body);
    return DoRequest(request);
}

uint64 g_LastRequest = 0;
uint64 g_RateLimit = 1000;
Json::Value@ DoRequest(Net::HttpRequest@ request)
{
    if (!settingUseNadeoApi)
    {
        return Json::Object();
    }
    if (!Permissions::ViewRecords())
    {
        LogDebug("Not allowed to view records, skipping request to " + request.Url);
        return Json::Object();
    }

    LogDebug("Doing request to " + request.Url);
    // Apply rate limit
    const auto now = Time::get_Now();
    const auto next = g_LastRequest + g_RateLimit;
    if (now < next)
    {
        LogDebug("Waiting for " + (next - now) + "ms because of rate limit");
        sleep(next - now);
    }
    g_LastRequest = now;

    request.Start();
    while (!request.Finished())
    {
        yield();
    }
    LogDebug("Received Answer: " + request.String());
    return request.Json();
}

array<int> FetchRecords(uint position)
{
    const auto @response = FetchFromNadeoApi("/api/token/leaderboard/group/Personal_Best/map/" + g_State.m_CurrentMap + "/top?length=" + 1 + "&onlyWorld=true&offset=" + (position - 1));

    if (!response.HasKey("tops"))
        return {0, 0};

    const auto tops = response["tops"];
    if (tops.Length < 1)
        return {0, 0};

    const auto top = tops[0]["top"];
    if (top.Length < 1)
        return {0, 0};

    return {top[0]["score"], top[0]["timestamp"]};
}

int FetchPersonalBest()
{
    const auto @response = FetchFromNadeoApi("/api/token/leaderboard/group/Personal_Best/map/"+ g_State.m_CurrentMap +"/surround/0/0?onlyWorld=true");

    if (!response.HasKey("tops"))
        return 0;
    
    const auto tops = response["tops"];
    if (tops.Length < 1)
        return 0;

    const auto top = tops[0]["top"];
    if (top.Length < 1)
        return 0;

    return top[0]["position"];
}

array<int> FetchForTimes(const array<int>&in time)
{
    const auto @raceData = @MLFeed::GetRaceData_V4();
    const auto @player = @raceData.GetPlayer_V4(MLFeed::LocalPlayersName);


    // Initialize positions
    array<int> positions;
    for (uint i = 0; i < time.Length; ++i)
        positions.InsertLast(0);

    // Prepare the body and uri
    auto maps = Json::Array();
    
    string params = "?";
    for (uint i = 0; i < time.Length; ++i)
    {
        // Skip times slower than PB because API does not return results for these
        if (time[i] <= 0)
            continue;
        if (player.BestTime > 0 && player.BestTime < time[i])
            continue;

        auto map = Json::Object();
        map["mapUid"] = g_State.m_CurrentMap;
        map["groupUid"] = "Personal_Best";
        maps.Add(map);

        if (params.Length > 1)
        {
            params += "&";
        }
        params += "scores[" + g_State.m_CurrentMap + "]=" + time[i];
    }

    if (maps.Length == 0)
        return positions;

    // Do the request
    auto body = Json::Object();
    body["maps"] = maps;

    const auto @results = PostToNadeoApi("/api/token/leaderboard/group/map" + params, Json::Write(body));

    if (results is null || results.GetType() != Json::Type::Array)
        return positions;

    for (uint i = 0; i < results.Length; ++i)
    {
        const auto response = results[i];

        int timeIndex = -1;
        for (uint t = 0; t < time.Length; ++t)
        {
            if (response["score"] == time[t])
            {
                timeIndex = t;
                break;
            }
        }

        if (timeIndex < 0)
            continue;

        if (!response.HasKey("zones"))
            continue;

        for (uint z = 0; z < response["zones"].Length; ++z)
        {
            const auto zone = response["zones"][z];
            if (zone["zoneName"] == "World")
            {
                positions[timeIndex] = zone["ranking"]["position"];
                break;
            }
        }
    }

    return positions;
}

}


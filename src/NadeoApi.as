namespace LocalLeaderboard
{

void InitNadeoApi()
{
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
    if (g_InitPb !is null && g_InitPb.IsRunning())
        return;
    @g_InitPb = @startnew(InitPersonalBest);
}

void InitPersonalBest()
{
    const int position = FetchPersonalBest();
    if (g_State.m_Leaderboard.m_FastestRun is null)
        return;
    g_State.m_Leaderboard.m_FastestRun.m_GlobalPosition = position;
}

Json::Value@ FetchFromNadeoApi(const string&in uri)
{
    auto request = NadeoServices::Get("NadeoLiveServices", NadeoServices::BaseURLLive() + uri);
    request.Start();
    while (!request.Finished())
    {
        yield();
    }
    LogDebug(request.String());
    return request.Json();
}

void FetchRecords()
{

}

int FetchPersonalBest()
{
    const auto response = FetchFromNadeoApi("/api/token/leaderboard/group/Personal_Best/map/"+ g_State.m_CurrentMap +"/surround/0/0?onlyWorld=true");

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

void FetchForTimes()
{

}

}


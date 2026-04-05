namespace LocalLeaderboard
{

/**
 * Gets the current map's unique identifier. Returns an empty string if no map is loaded.
 */
string GetMapId()
{
    CGameCtnApp @app = GetApp();
    if (app.RootMap is null)
    {
        return "";
    }

    return app.RootMap.IdName;
}

CSmPlayer @GetPlayer()
{
    auto @playground = GetPlayground();
    if (playground is null)
        return null;
    return cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
}

CSmArenaClient @GetPlayground()
{
    CGameCtnApp @app = GetApp();
    return cast<CSmArenaClient>(app.CurrentPlayground);
}

CSmScriptPlayer @GetPlayerScript()
{
    CSmPlayer @player = GetPlayer();
    if (player is null)
        return null;
    return cast<CSmScriptPlayer>(player.ScriptAPI);
}

int GetPlayerSpeed()
{
    CSmScriptPlayer @playerScript = GetPlayerScript();
    if (playerScript is null)
        return 0;
    int speed = playerScript.DisplaySpeed;
    if (speed == 0)
        speed = int(Math::Round(playerScript.Speed * 3.6f));
    return speed;
}

}

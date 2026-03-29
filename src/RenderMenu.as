void RenderMenu()
{
    if (UI::BeginMenu(Icons::ListUl + " Local Leaderboard"))
    {
        if (UI::MenuItem("Reset Leaderboard", "", false,  LocalLeaderboard::g_State.m_CurrentMap != ""))
        {
            LocalLeaderboard::g_State.ResetData();
        }

        UI::EndMenu();
    }
}

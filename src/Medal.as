namespace LocalLeaderboard
{

enum MedalType
{
#if DEPENDENCY_CHAMPIONMEDALS
    Champion,
#endif
#if DEPENDENCY_WARRIORMEDALS
    Warrior,
#endif
    Author,
    Gold,
    Silver,
    Bronze
}

array<Medal @> g_Medals;

void InitializeMedals()
{
    g_Medals.RemoveRange(0, g_Medals.Length);

#if DEPENDENCY_CHAMPIONMEDALS
    g_Medals.InsertLast(ChampionMedal());
#endif
#if DEPENDENCY_WARRIORMEDALS
    g_Medals.InsertLast(WarriorMedal());
#endif
    g_Medals.InsertLast(AuthorMedal());
    g_Medals.InsertLast(GoldMedal());
    g_Medals.InsertLast(SilverMedal());
    g_Medals.InsertLast(BronzeMedal());
}

interface Medal
{
    string GetName() const;
    vec3 GetIconColor() const;
    int GetTime() const;
    bool IsVisible() const;
}

#if DEPENDENCY_CHAMPIONMEDALS
class ChampionMedal : Medal
{
    string GetName() const override
    {
        return "Champion";
    }
    vec3 GetIconColor() const override
    {
        return vec3(0xf8 / 255.0f, 0x4a / 255.0f, 0x6e / 255.0f);
    }
    int GetTime() const override
    {
        return ChampionMedals::GetCMTime();
    }
    bool IsVisible() const override
    {
        return settingDisplayLeaderboardMedalChampion;
    }
}
#endif

#if DEPENDENCY_WARRIORMEDALS
class WarriorMedal : Medal
{
    string GetName() const override
    {
        return "Warrior";
    }
    vec3 GetIconColor() const override
    {
        return WarriorMedals::GetColorWarriorVec();
    }
    int GetTime() const override
    {
        return WarriorMedals::GetWMTime();
    }
    bool IsVisible() const override
    {
        return settingDisplayLeaderboardMedalWarrior;
    }
}
#endif

class AuthorMedal : Medal
{
    string GetName() const override
    {
        return "Author";
    }
    vec3 GetIconColor() const override
    {
        return vec3(0, 0x77 / 255.0f, 0x11 / 255.0f);
    }
    int GetTime() const override
    {
        auto @map = @GetApp().RootMap;
        return map is null ? 0 : map.MapInfo.TMObjective_AuthorTime;
    }
    bool IsVisible() const override
    {
        return settingDisplayLeaderboardMedalAuthor;
    }
}

class GoldMedal : Medal
{
    string GetName() const override
    {
        return "Gold";
    }
    vec3 GetIconColor() const override
    {
        return vec3(0xDD / 255.0f, 0xBB / 255.0f, 0x44 / 255.0f);
    }
    int GetTime() const override
    {
        auto @map = @GetApp().RootMap;
        return map is null ? 0 : map.MapInfo.TMObjective_GoldTime;
    }
    bool IsVisible() const override
    {
        return settingDisplayLeaderboardMedalGold;
    }
}

class SilverMedal : Medal
{
    string GetName() const override
    {
        return "Silver";
    }
    vec3 GetIconColor() const override
    {
        return vec3(0x88 / 255.0f, 0x99 / 255.0f, 0x99 / 255.0f);
    }
    int GetTime() const override
    {
        auto @map = @GetApp().RootMap;
        return map is null ? 0 : map.MapInfo.TMObjective_SilverTime;
    }
    bool IsVisible() const override
    {
        return settingDisplayLeaderboardMedalSilver;
    }
}

class BronzeMedal : Medal
{
    string GetName() const override
    {
        return "Bronze";
    }
    vec3 GetIconColor() const override
    {
        return vec3(0x99 / 255.0f, 0x66 / 255.0f, 0x44 / 255.0f);
    }
    int GetTime() const override
    {
        auto @map = @GetApp().RootMap;
        return map is null ? 0 : map.MapInfo.TMObjective_BronzeTime;
    }
    bool IsVisible() const override
    {
        return settingDisplayLeaderboardMedalBronze;
    }
}

}

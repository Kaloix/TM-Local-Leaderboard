namespace LocalRecords
{

array<Zone @> g_Zones;
uint g_CurrentZoneIndex = 0;

Zone@ GetCurrentZone()
{
    return g_CurrentZoneIndex >= g_Zones.Length ? null : g_Zones[g_CurrentZoneIndex];
}

string GetCurrentZoneName()
{
    auto @zone = GetCurrentZone();
    return zone is null ? "World" : zone.m_Name;
}

string GetZoneName(const string&in zoneId)
{
    for (uint i = 0; i < g_Zones.Length; ++i)
    {
        if (g_Zones[i].m_Id == zoneId)
            return g_Zones[i].m_Name;
    }
    return "";
}

string GetCurrentZoneId()
{
    auto @zone = GetCurrentZone();
    return zone is null ? "301e1b69-7e13-11e8-8060-e284abfd2bc4" : zone.m_Id;
}

void SetZone(const uint zoneIndex)
{
    g_CurrentZoneIndex = zoneIndex;

    if (g_State.m_CurrentMap == "")
        return;

    for (uint i = 0; i < g_State.m_CustomPositionEntries.Length; ++i)
    {
        InitTimeForEntryAsync(@g_State.m_CustomPositionEntries[i]);
    }
}


class Zone
{
    string m_Id;
    string m_Name;
}

}

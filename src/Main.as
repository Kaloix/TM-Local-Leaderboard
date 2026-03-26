
void Main()
{
	LocalLeaderboard::Init();
}

void OnEnabled()
{
	LocalLeaderboard::Init();
}

void OnDisabled()
{
	LocalLeaderboard::Shutdown();
}

void OnDestroyed()
{
	LocalLeaderboard::Shutdown();
}

void Update(float dt)
{
	LocalLeaderboard::Update(dt);
}

void OnSettingsChanged()
{
	LocalLeaderboard::InitRender();
}

namespace LocalLeaderboard
{

	State g_State = State();

	void Init()
	{
		InitRender();
		LogDebug("Local Leaderboard plugin initializing.");
	}

	void Shutdown()
	{
		LogDebug("Local Leaderboard plugin shutting down.");
	}

	void Update(float dt)
	{
		auto currentMap = GetMapId();

		// Events for map loading and unloading
		if (g_State.m_CurrentMap == "")
		{
			if (currentMap != "")
			{
				LogDebug("Map loaded: " + currentMap);
				OnMapLoad();
			}
		}
		else
		{
			if (currentMap == "")
			{
				LogDebug("Map unloaded: " + g_State.m_CurrentMap);
				OnMapUnload();
			}
			else if (currentMap != g_State.m_CurrentMap)
			{
				LogDebug("Map changed from " + g_State.m_CurrentMap + " to " + currentMap);
				OnMapUnload();
				OnMapLoad();
			}
		}

		auto raceData = MLFeed::GetRaceData_V4();
		auto player = raceData.GetPlayer_V4(MLFeed::LocalPlayersName);
		if (player !is null)
		{
			if (g_State.m_IsPlayerFinishHandled && !player.IsFinished)
			{
				g_State.m_IsPlayerFinishHandled = false;
			}
			else if (!g_State.m_IsPlayerFinishHandled && player.IsFinished)
			{
				OnPlayerFinish();
				g_State.m_IsPlayerFinishHandled = true;
			}
		}
	}

	void OnMapLoad()
	{
		CGameCtnApp @app = GetApp();
		auto map = app.RootMap;

		g_State.m_CurrentMap = map.IdName;
		g_State.m_CurrentMapName = map.MapName;
		g_State.m_CurrentMapAuthor = map.AuthorNickName;

		LoadLeaderboard(g_State);

		// Add medals
		auto medalAt = LeaderboardEntry();
		medalAt.m_Medal = "Author";
		medalAt.m_PlayerName = "AT";
		medalAt.m_IconColor = vec3(0, 0x77/255.0f, 0x11/255.0f);
		medalAt.m_Time = map.MapInfo.TMObjective_AuthorTime;
		g_State.m_Leaderboard.AddEntry(medalAt);

		auto medalGold = LeaderboardEntry();
		medalGold.m_Medal = "Gold";
		medalGold.m_PlayerName = "Gold";
		medalGold.m_IconColor = vec3(0xDD/255.0f, 0xBB/255.0f, 0x44/255.0f);
		medalGold.m_Time = map.MapInfo.TMObjective_GoldTime;
		g_State.m_Leaderboard.AddEntry(medalGold);

		auto medalSilver = LeaderboardEntry();
		medalSilver.m_Medal = "Silver";
		medalSilver.m_PlayerName = "Silver";
		medalSilver.m_IconColor = vec3(0x88/255.0f, 0x99/255.0f, 0x99/255.0f);
		medalSilver.m_Time = map.MapInfo.TMObjective_SilverTime;
		g_State.m_Leaderboard.AddEntry(medalSilver);

		auto medalBronze = LeaderboardEntry();
		medalBronze.m_Medal = "Bronze";
		medalBronze.m_PlayerName = "Bronze";
		medalBronze.m_IconColor = vec3(0x99/255.0f, 0x66/255.0f, 0x44/255.0f);
		medalBronze.m_Time = map.MapInfo.TMObjective_BronzeTime;
		g_State.m_Leaderboard.AddEntry(medalBronze);

#if DEPENDENCY_CHAMPIONMEDALS
		auto championTime = ChampionMedals::GetCMTime();
		if (championTime > 0)
		{
			auto medalChampion = LeaderboardEntry();
			medalChampion.m_Medal = "Champion";
			medalChampion.m_PlayerName = "Champion";
			medalChampion.m_IconColor = vec3(0xf8/255.0f, 0x4a/255.0f, 0x6e/255.0f);
			medalChampion.m_Time = ChampionMedals::GetCMTime();
			g_State.m_Leaderboard.AddEntry(medalChampion);
		}
#endif
#if DEPENDENCY_WARRIORMEDALS
		auto warriorTime = WarriorMedals::GetWMTime();
		if (warriorTime > 0)
		{
			auto medalWarrior = LeaderboardEntry();
			medalWarrior.m_Medal = "Warrior";
			medalWarrior.m_PlayerName = "Warrior";
			medalWarrior.m_IconColor = WarriorMedals::GetColorWarriorVec();
			medalWarrior.m_Time = WarriorMedals::GetWMTime();
			g_State.m_Leaderboard.AddEntry(medalWarrior);
		}
#endif
	}

	void OnMapUnload()
	{
		SaveLeaderboard(g_State);
		g_State = State();
	}

	void OnPlayerFinish()
	{
		auto raceData = MLFeed::GetRaceData_V4();
		auto player = raceData.GetPlayer_V4(MLFeed::LocalPlayersName);

		if (player is null)
		{
			return;
		}

		auto entry = LeaderboardEntry();
		entry.m_PlayerName = player.Name;
		entry.m_Time = player.FinishTime;
		entry.m_TimeStamp = Time::get_Stamp();

		g_State.m_Leaderboard.AddNewEntry(entry);

		SaveLeaderboard(g_State);
	}

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

	class Leaderboard
	{
		array<LeaderboardEntry @> m_Entries;

		string m_PlayerBestId = '';
		int m_PlayerBestTime = -1;

		string m_PlayerLastId = '';
		int m_PlayerLastTime = -1;

		void AddNewEntry(LeaderboardEntry entry)
		{
			AddEntry(entry);
			m_PlayerLastId = entry.m_Id;
			m_PlayerLastTime = entry.m_Time;

			if (entry.m_Time < m_PlayerBestTime || m_PlayerBestTime == -1)
			{
				m_PlayerBestId = entry.m_Id;
				m_PlayerBestTime = entry.m_Time;
			}
		}

		void AddEntry(LeaderboardEntry entry)
		{
			for (uint i = 0; i < m_Entries.Length; i++)
			{
				if (entry.m_Time < m_Entries[i].m_Time)
				{
					m_Entries.InsertAt(i, entry);
					return;
				}
			}

			m_Entries.InsertLast(entry);
		}
	}

	class LeaderboardEntry
	{
		string m_Id = Crypto::RandomBase64(12);

		string m_PlayerName = "";
		string m_Medal = "";

		vec3 m_IconColor = vec3(1, 1, 1);

		int64 m_TimeStamp = 0;
		int m_Time = 0;
	}

	class State
	{
		/**
		 * ID of the currently loaded map.
		 * Empty string if no map is loaded or if the map doesn't have an ID (e.g. custom maps in Trackmania 2020).
		 */
		string m_CurrentMap = "";
		string m_CurrentMapName = "";
		string m_CurrentMapAuthor = "";

		bool m_IsPlayerFinishHandled = true;

		Leaderboard m_Leaderboard = Leaderboard();
	}
}

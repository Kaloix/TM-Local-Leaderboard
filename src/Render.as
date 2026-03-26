void Render()
{
	if (!settingDisplayLeaderboard)
	{
		return; // Don't render the leaderboard if the setting is disabled
	}

	LocalLeaderboard::Render();
}

namespace LocalLeaderboard
{
	int numberOfColumns = 0;
	int windowFlags = 0;

	void InitRender()
	{
		numberOfColumns = 0;
		if (settingDisplayLeaderboardRankColumn)
			numberOfColumns++;
		if (settingDisplayLeaderboardPlayerColumn)
			numberOfColumns++;
		if (settingDisplayLeaderboardTimeColumn)
			numberOfColumns++;
		if (settingDisplayLeaderboardTimestampColumn)
			numberOfColumns++;

		windowFlags = UI::GetDefaultWindowFlags();
		if (!settingDisplayLeaderboardTitleBar)
			windowFlags |= UI::WindowFlags::NoTitleBar;
	}

	void Render()
	{
		if (g_State.m_CurrentMap == "")
		{
			return; // Don't render if no map is loaded
		}

		// UI::Begin("Local Leaderboard", true, windowFlags);
		bool open = true;
		UI::Begin("Local Leaderboard", open, windowFlags);

		if (g_State.m_CurrentMap == "")
		{
			UI::Text("No map loaded.");
			UI::End();
			return;
		}

		if (settingDisplayLeaderboardMapName)
		{
			const auto mapName = Text::OpenplanetFormatCodes(g_State.m_CurrentMapName);
			UI::Text(mapName);
		}

		if (settingDisplayLeaderboardMapAuthor)
		{
			const auto mapAuthor = Text::OpenplanetFormatCodes(g_State.m_CurrentMapAuthor);
			UI::TextDisabled("By " + mapAuthor);
		}

		UI::BeginTable("LeaderboardTable", numberOfColumns);

		// Setup columns
		if (settingDisplayLeaderboardRankColumn)
		{
			UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 30);
		}
		if (settingDisplayLeaderboardPlayerColumn)
		{
			UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
		}
		if (settingDisplayLeaderboardTimeColumn)
		{
			UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 60);
		}
		if (settingDisplayLeaderboardTimestampColumn)
		{
			UI::TableSetupColumn("Timestamp", UI::TableColumnFlags::WidthFixed, 150);
		}

		// Table header
		UI::TableNextRow();

		if (settingDisplayLeaderboardRankColumn)
		{
			UI::TableNextColumn();
			UI::Text("No.");
		}
		if (settingDisplayLeaderboardPlayerColumn)
		{
			UI::TableNextColumn();
			UI::Text("Player");
		}
		if (settingDisplayLeaderboardTimeColumn)
		{
			UI::TableNextColumn();
			UI::Text("Time");
		}
		if (settingDisplayLeaderboardTimestampColumn)
		{
			UI::TableNextColumn();
			UI::Text("Timestamp");
		}

		int position = 1;
		for (uint i = 0; i < g_State.m_Leaderboard.m_Entries.Length; i++)
		{
			const auto @entry = g_State.m_Leaderboard.m_Entries[i];

			UI::TableNextRow();

			string positionStr = "" + position;

			if (entry.m_Medal != "")
			{
				positionStr = "";

				if (entry.m_Medal == "Author" && !settingDisplayLeaderboardMedalAuthor)
				{
					continue; // Skip author medal if the setting is disabled
				}
				else if (entry.m_Medal == "Gold" && !settingDisplayLeaderboardMedalGold)
				{
					continue; // Skip gold medal if the setting is disabled
				}
				else if (entry.m_Medal == "Silver" && !settingDisplayLeaderboardMedalSilver)
				{
					continue; // Skip silver medal if the setting is disabled
				}
				else if (entry.m_Medal == "Bronze" && !settingDisplayLeaderboardMedalBronze)
				{
					continue; // Skip bronze medal if the setting is disabled
				}
				else if (entry.m_Medal == "Champion" && !settingDisplayLeaderboardMedalChampion)
				{
					continue; // Skip champion medal if the setting is disabled
				}
				else if (entry.m_Medal == "Warrior" && !settingDisplayLeaderboardMedalWarrior)
				{
					continue; // Skip warrior medal if the setting is disabled
				}
			}
			else
			{
				position++; // Increment position for non-medal entries
			}

			if (settingDisplayLeaderboardRankColumn)
			{
				UI::TableNextColumn();
				UI::PushStyleColor(UI::Col::Text, vec4(entry.m_IconColor, 1));

				if (entry.m_Medal != "")
				{
					UI::Text(Icons::Circle);
				}
				else
				{
					UI::Text(positionStr);
				}
				UI::PopStyleColor();
			}

			if (settingDisplayLeaderboardPlayerColumn)
			{
				UI::TableNextColumn();
				UI::Text(entry.m_PlayerName);
			}

			if (settingDisplayLeaderboardTimeColumn)
			{
				UI::TableNextColumn();
				UI::Text(Time::Format(entry.m_Time));
			}

			if (settingDisplayLeaderboardTimestampColumn)
			{
				UI::TableNextColumn();
				if (entry.m_TimeStamp == 0)
				{
					UI::Text("");
				}
				else
				{
					auto time = Time::Parse(entry.m_TimeStamp);
					UI::Text(time.Year + "-" + Text::Format("%02d", time.Month) + "-" + Text::Format("%02d", time.Day) + " " + Text::Format("%02d", time.Hour) + ":" + Text::Format("%02d", time.Minute) + ":" + Text::Format("%02d", time.Second));
				}
			}
		}

		UI::EndTable();

		UI::End();
	}
}

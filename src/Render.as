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
	int windowFlags = 0;

	array<TableColumn @> g_TableColumns;

	void InitRender()
	{
		// Clear existing columns
		g_TableColumns.RemoveRange(0, g_TableColumns.Length);

		if (settingDisplayLeaderboardMedalColumn)
			g_TableColumns.InsertLast(MedalColumn());
		if (settingDisplayLeaderboardRankColumn)
			g_TableColumns.InsertLast(RankColumn());
		if (settingDisplayLeaderboardPlayerColumn)
			g_TableColumns.InsertLast(PlayerColumn());
		if (settingDisplayLeaderboardTimeColumn)
			g_TableColumns.InsertLast(TimeColumn());
		if (settingDisplayLeaderboardDeltaPBColumn)
			g_TableColumns.InsertLast(BestTimeDeltaColumn());
		if (settingDisplayLeaderboardDeltaLastColumn)
			g_TableColumns.InsertLast(LastTimeDeltaColumn());
		if (settingDisplayLeaderboardScoreNumberColumn)
			g_TableColumns.InsertLast(ScoreNumberColumn());
		if (settingDisplayLeaderboardTimestampColumn)
			g_TableColumns.InsertLast(TimestampColumn());

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

		if (g_State.m_Leaderboard.m_Entries.Length == 0)
		{
			UI::End();
			return;
		}

		UI::BeginTable("LeaderboardTable", g_TableColumns.Length);

		// Setup columns
		for (uint i = 0; i < g_TableColumns.Length; i++)
		{
			g_TableColumns[i].setup();
		}

		// Table header
		if (settingDisplayLeaderboardHeader)
		{
			UI::TableNextRow(UI::TableRowFlags::Headers);
			for (uint i = 0; i < g_TableColumns.Length; i++)
			{
				UI::TableNextColumn();
				g_TableColumns[i].renderHeader();
			}
		}

		// Table body
		auto context = TableRenderContext();
		for (uint i = 0; i < g_State.m_Leaderboard.m_Entries.Length; i++)
		{
			@context.m_CurrentEntry = @g_State.m_Leaderboard.m_Entries[i];
			context.m_IsPlayerBest = context.m_CurrentEntry.m_ScoreNumber == g_State.m_Leaderboard.m_PlayerBestId;
			context.m_IsPlayerNewest = context.m_CurrentEntry.m_ScoreNumber == g_State.m_Leaderboard.m_PlayerNewestId;

			if (context.m_CurrentEntry.m_Type == LeaderboardEntryType::Medal)
			{
				if (context.m_CurrentEntry.m_Medal == "Author" && !settingDisplayLeaderboardMedalAuthor)
				{
					continue; // Skip author medal if the setting is disabled
				}
				else if (context.m_CurrentEntry.m_Medal == "Gold" && !settingDisplayLeaderboardMedalGold)
				{
					continue; // Skip gold medal if the setting is disabled
				}
				else if (context.m_CurrentEntry.m_Medal == "Silver" && !settingDisplayLeaderboardMedalSilver)
				{
					continue; // Skip silver medal if the setting is disabled
				}
				else if (context.m_CurrentEntry.m_Medal == "Bronze" && !settingDisplayLeaderboardMedalBronze)
				{
					continue; // Skip bronze medal if the setting is disabled
				}
				else if (context.m_CurrentEntry.m_Medal == "Champion" && !settingDisplayLeaderboardMedalChampion)
				{
					continue; // Skip champion medal if the setting is disabled
				}
				else if (context.m_CurrentEntry.m_Medal == "Warrior" && !settingDisplayLeaderboardMedalWarrior)
				{
					continue; // Skip warrior medal if the setting is disabled
				}
			}

			UI::TableNextRow();

			for (uint col = 0; col < g_TableColumns.Length; col++)
			{
				UI::TableNextColumn();
				g_TableColumns[col].renderBody(context);
			}
		}

		UI::EndTable();

		UI::End();
	}

	class TableRenderContext
	{
		uint m_CurrentRow = 0;
		uint m_CurrentPosition = 1;
		LeaderboardEntry @m_CurrentEntry = null;

		bool m_IsPlayerBest = false;
		bool m_IsPlayerNewest = false;
	}

	interface TableColumn
	{
		void setup();
		void renderHeader();
		void renderBody(TableRenderContext &inout context);
	}

	class RankColumn : TableColumn
	{
		void setup()
		{
			UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 30);
		}

		void renderHeader()
		{
			UI::Text("Rank");
		}

		void renderBody(TableRenderContext&inout context)
		{
			if (context.m_CurrentEntry.m_Type == LeaderboardEntryType::Medal)
			{
				return;
			}
			renderText(context, "" + context.m_CurrentPosition);
			context.m_CurrentPosition++;
		}
	}

	class MedalColumn : TableColumn
	{
		void setup()
		{
			UI::TableSetupColumn("Medal", UI::TableColumnFlags::WidthFixed, 20);
		}

		void renderHeader()
		{
		}

		void renderBody(TableRenderContext&inout context)
		{

			if (context.m_CurrentEntry.m_Type == LeaderboardEntryType::Medal)
			{
				UI::PushStyleColor(UI::Col::Text, vec4(context.m_CurrentEntry.m_IconColor, 1));
				UI::Text(Icons::Circle);
				UI::PopStyleColor();
			}
			else if (context.m_CurrentEntry.m_Type == LeaderboardEntryType::Score)
			{
				renderText(context, Icons::UserO);
			}
		}
	}

	class TimeColumn : TableColumn
	{
		void setup()
		{
			UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 60);
		}

		void renderHeader()
		{
			UI::Text("Time");
		}

		void renderBody(TableRenderContext&inout context)
		{
			renderText(context, Time::Format(context.m_CurrentEntry.m_Time));
		}
	}

	class PlayerColumn : TableColumn
	{
		void setup()
		{
			UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
		}

		void renderHeader()
		{
			UI::Text("Player");
		}

		void renderBody(TableRenderContext&inout context)
		{
			const auto name = context.m_CurrentEntry.m_Type == LeaderboardEntryType::Medal ? context.m_CurrentEntry.m_Medal : context.m_CurrentEntry.m_PlayerName;
			renderText(context, name);
		}
	}

	class TimeDeltaColumn : TableColumn
	{
		string getHeaderName()
		{
			return "";
		}
		bool isShowDelta(const TableRenderContext&in context)
		{
			return true;
		}
		int getDelta(const TableRenderContext&in context)
		{
			return 0;
		}

		void setup()
		{
			UI::TableSetupColumn(getHeaderName(), UI::TableColumnFlags::WidthFixed, 60);
		}

		void renderHeader()
		{
			UI::Text(getHeaderName());
		}

		void renderBody(TableRenderContext&inout context)
		{
			if (context.m_CurrentEntry.m_Time <= 0 || !isShowDelta(context))
			{
				return;
			}

			const int delta = getDelta(context);
			auto deltaColor = delta < 0 ? vec4(settingColorDeltaBetter, 1) : (delta > 0 ? vec4(settingColorDeltaWorse, 1) : vec4(settingColorDeltaEqual, 1));
			string deltaStr = (delta > 0 ? "+" : "") + Time::Format(delta);

			UI::PushStyleColor(UI::Col::Text, deltaColor);
			UI::Text(deltaStr);
			UI::PopStyleColor();
		}
	}

	class BestTimeDeltaColumn : TimeDeltaColumn
	{
		string getHeaderName() override
		{
			return "Delta PB";
		}
		bool isShowDelta(const TableRenderContext&in context) override
		{
			return !context.m_IsPlayerBest && g_State.m_Leaderboard.m_PlayerBestTime > 0;
		}
		int getDelta(const TableRenderContext&in context) override
		{
			return context.m_CurrentEntry.m_Time - g_State.m_Leaderboard.m_PlayerBestTime;
		}
	}

	class LastTimeDeltaColumn : TimeDeltaColumn
	{
		string getHeaderName() override
		{
			return "Delta Last";
		}
		bool isShowDelta(const TableRenderContext&in context) override
		{
			return !context.m_IsPlayerNewest && g_State.m_Leaderboard.m_PlayerNewestTime > 0;
		}
		int getDelta(const TableRenderContext&in context) override
		{
			return context.m_CurrentEntry.m_Time - g_State.m_Leaderboard.m_PlayerNewestTime;
		}
	}

	class ScoreNumberColumn : TableColumn
	{
		void setup()
		{
			UI::TableSetupColumn("ScoreNumber", UI::TableColumnFlags::WidthFixed, 30);
		}
		void renderHeader()
		{
			UI::Text("No.");
		}
		void renderBody(TableRenderContext&inout context)
		{
			if (context.m_CurrentEntry.m_Type == LeaderboardEntryType::Score)
			{
				renderText(context, "" + context.m_CurrentEntry.m_ScoreNumber);
			}
		}
	}

	class TimestampColumn : TableColumn
	{
		void setup()
		{
			UI::TableSetupColumn("Timestamp", UI::TableColumnFlags::WidthFixed, 150);
		}

		void renderHeader()
		{
			UI::Text("Timestamp");
		}

		void renderBody(TableRenderContext&inout context)
		{
			if (context.m_CurrentEntry.m_TimeStamp == 0)
			{
				return;
			}

			auto time = Time::Parse(context.m_CurrentEntry.m_TimeStamp);
			string timeStr = time.Year + "-" + Text::Format("%02d", time.Month) + "-" + Text::Format("%02d", time.Day) + " " + Text::Format("%02d", time.Hour) + ":" + Text::Format("%02d", time.Minute) + ":" + Text::Format("%02d", time.Second);
			renderText(context, timeStr);
		}
	}

	void renderText(const TableRenderContext&in context, const string&in text)
	{
		if (context.m_IsPlayerNewest)
		{
			UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeLast, 1));
		}
		else if (context.m_IsPlayerBest)
		{
			UI::PushStyleColor(UI::Col::Text, vec4(settingColorTimeBest, 1));
		}
		UI::Text(text);
		if (context.m_IsPlayerNewest || context.m_IsPlayerBest)
		{
			UI::PopStyleColor();
		}
	}
}

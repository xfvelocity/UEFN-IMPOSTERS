using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

StatType := enum{Kills, ImposterPlays, ImposterWins, CrewmatePlays, CrewmateWins, TasksCompleted}

player_stats_manager := class():
    InitPlayer(Player: player): void=
        if:
            # Check if the player already has saved stats, if not, initialise them
            not PlayerStatsMap[Player]
            set PlayerStatsMap[Player] = player_stats_table{}

    InitAllPlayers(Agents: []agent): void=
        for(Agent : Agents):
            if(Player := player[Agent]):
                InitPlayer(Player)

    # Returns the players stats
    GetPlayerStats(Agent: agent)<decides><transacts>: player_stats_table=
        var PlayerStats: player_stats_table = player_stats_table{}

        if:
            Player := player[Agent]
            PlayerStatsTable := PlayerStatsMap[Player]
            set PlayerStats = MakePlayerStatsTable(PlayerStatsTable)
        PlayerStats

    # Updates the players stats
    RecordPlayerStat(Agent: agent, Stat: StatType, Value: int): void=
        if:
            Player := player[Agent]
            PlayerStatsTable := PlayerStatsMap[Player]

            if(Stat = StatType.Kills):
                KillsStat := PlayerStatsTable.Kills

                set PlayerStatsMap[Player] = player_stats_table:
                    Kills := KillsStat + Value
                    MakePlayerStatsTable<constructor>(PlayerStatsTable)

            if(Stat = StatType.ImposterPlays):
                ImposterPlaysStat := PlayerStatsTable.ImposterPlays

                set PlayerStatsMap[Player] = player_stats_table:
                    ImposterPlays := ImposterPlaysStat + Value
                    MakePlayerStatsTable<constructor>(PlayerStatsTable)

            if(Stat = StatType.ImposterWins):
                ImposterWinsStat := PlayerStatsTable.ImposterWins

                set PlayerStatsMap[Player] = player_stats_table:
                    ImposterWins := ImposterWinsStat + Value
                    MakePlayerStatsTable<constructor>(PlayerStatsTable)

            if(Stat = StatType.CrewmateWins):
                CrewmateWinsStat := PlayerStatsTable.CrewmateWins

                set PlayerStatsMap[Player] = player_stats_table:
                    CrewmateWins := CrewmateWinsStat + Value
                    MakePlayerStatsTable<constructor>(PlayerStatsTable)

            if(Stat = StatType.CrewmatePlays):
                CrewmatePlaysStat := PlayerStatsTable.CrewmatePlays

                set PlayerStatsMap[Player] = player_stats_table:
                    CrewmatePlays := CrewmatePlaysStat + Value
                    MakePlayerStatsTable<constructor>(PlayerStatsTable)

            if(Stat = StatType.TasksCompleted):
                TasksCompletedStat := PlayerStatsTable.TasksCompleted

                set PlayerStatsMap[Player] = player_stats_table:
                    TasksCompleted := TasksCompletedStat + Value
                    MakePlayerStatsTable<constructor>(PlayerStatsTable)
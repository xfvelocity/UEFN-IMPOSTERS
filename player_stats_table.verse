using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }

player_stats_table := class<final><persistable>:
    Version: int = 0
    Kills: int = 0
    CrewmateWins: int = 0
    ImposterWins: int = 0
    ImposterPlays: int = 0
    CrewmatePlays: int = 0
    TasksCompleted: int = 0

MakePlayerStatsTable<constructor>(OldTable: player_stats_table)<transacts> := player_stats_table:
    Version := OldTable.Version
    Kills := OldTable.Kills
    CrewmateWins := OldTable.CrewmateWins
    CrewmatePlays := OldTable.CrewmatePlays
    ImposterWins := OldTable.ImposterWins
    ImposterPlays := OldTable.ImposterPlays
    TasksCompleted := OldTable.TasksCompleted

var PlayerStatsMap: weak_map(player, player_stats_table) = map{}

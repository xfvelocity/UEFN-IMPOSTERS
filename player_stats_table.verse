using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }

player_stats_table := class<final><persistable>:
    Version: float = 0.0
    Kills: float = 0.0
    CrewmateWins: float = 0.0
    ImposterWins: float = 0.0
    ImposterPlays: float = 0.0
    CrewmatePlays: float = 0.0
    TasksCompleted: float = 0.0

MakePlayerStatsTable<constructor>(OldTable: player_stats_table)<transacts> := player_stats_table:
    Version := OldTable.Version
    Kills := OldTable.Kills
    CrewmateWins := OldTable.CrewmateWins
    CrewmatePlays := OldTable.CrewmatePlays
    ImposterWins := OldTable.ImposterWins
    ImposterPlays := OldTable.ImposterPlays
    TasksCompleted := OldTable.TasksCompleted

var PlayerStatsMap: weak_map(player, player_stats_table) = map{}

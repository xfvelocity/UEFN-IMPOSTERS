
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Colors/NamedColors }


PlayerManagerTag := class(tag){}

tasks := class:
    var TasksCompleted: int = 0
    var TaskList: [Task]logic = map{}
    var CompletedTaskList: []Task = array{}
    
custom_player := class<concrete>:
    var FollowProps: follow_prop = follow_prop{}
    var ReportProps: report_prop = report_prop{}
    var Tasks: tasks = tasks{}
    var IsImposter: logic = false
    var IsDead: logic = false

player_manager_device := class(creative_device):
    var CustomPlayers: [player]custom_player = map{}
    var Players: []player = array{}

    var PlayersSet: event() = event(){}

    OnBegin<override>()<suspends>:void=
        set Players = GetPlayspace().GetPlayers()

        for(Player : Players):
            if(set CustomPlayers[Player] = custom_player{}){}

        Sleep(1.0)
        PlayersSet.Signal()

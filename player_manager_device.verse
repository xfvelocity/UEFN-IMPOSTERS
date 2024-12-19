using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Colors/NamedColors }
using { /UnrealEngine.com/Temporary/SpatialMath }

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
    @editable
    StartTimerDevice: timer_device = timer_device{}
    @editable 
    VotingTable: creative_prop = creative_prop{}
    @editable
    PlayerCounter: player_counter_device = player_counter_device{}
    @editable
    Button: button_device = button_device{}

    PlayerStatsManager: player_stats_manager = player_stats_manager{}
    var CustomPlayers: [player]custom_player = map{}
    var Players: []player = array{}
    var PlayerIndex: int = 1
    var PlayersSet: event() = event(){}
    var PlayersCount: int = 0
    var StatsUICanvas: [agent]canvas = map{}
    var GameHasStarted: logic = false

    OnBegin<override>()<suspends>: void=
        Button.InteractedWithEvent.Subscribe(ManualOverride)

        StartTimerDevice.PauseForAll()

        PlayerCounter.CountedEvent.Subscribe(PlayerJoined)
        StartTimerDevice.SuccessEvent.Subscribe(OnStartGame)

    ManualOverride(Agent: agent): void=
        StartTimerDevice.SetActiveDuration(3.0)
        StartTimerDevice.ResumeForAll()

    StatsUI(Agent: agent) :void=
        if(StatsUICanvas[Agent]):
        else:
            if:
                Player := player[Agent]
                PlayerUI := GetPlayerUI[Player]
                CurrentPlayerStats := PlayerStatsManager.GetPlayerStats[Agent]
            then:
                var Stats: [string]string = map{"Eliminations" => "{CurrentPlayerStats.Kills}", "Tasks Completed" => "{CurrentPlayerStats.TasksCompleted}", "Imposter Wins" => "{CurrentPlayerStats.ImposterWins}/{CurrentPlayerStats.ImposterPlays}", "Crewmate Wins" => "{CurrentPlayerStats.CrewmateWins}/{CurrentPlayerStats.CrewmatePlays}"}
                var BackgroundImage: texture_block = texture_block{DefaultImage := Images.OpaqueBackground}
                var TitleText: text_block = text_block{DefaultText := StringToMessage("Lifetime Stats:"), DefaultTextColor := White}

                var Slots: []canvas_slot = array{
                    canvas_slot:
                        Anchors :=  anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 0.0, Y := 0.0}}
                        Offsets := margin{Left := 15.0, Top := 15.0, Right := 550.0, Bottom := 380.0}
                        Alignment := vector2{X := 0.0, Y := 0.0}
                        ZOrder := 0
                        SizeToContent := false
                        Widget := BackgroundImage
                    canvas_slot:
                        Anchors :=  anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 0.0, Y := 0.0}}
                        Offsets := margin{Left := 35.0, Top := 35.0 , Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.0, Y := 0.0}
                        ZOrder := 1
                        SizeToContent := false
                        Widget := TitleText
                }
                    
                var TextBlockIndex: int = 0

                for(Key -> Stat : Stats):
                    var TextBlock : text_block = text_block{DefaultText := StringToMessage("{Key}: {Stat}"), DefaultTextColor := White}

                    set Slots += array{
                        canvas_slot:
                            Anchors :=  anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 0.0, Y := 0.0}}
                            Offsets := margin{Left := 35.0, Top := 90.0 + (TextBlockIndex * 40.0), Right := 0.0, Bottom := 0.0}
                            Alignment := vector2{X := 0.0, Y := 0.0}
                            ZOrder := 1
                            SizeToContent := false
                            Widget := TextBlock
                    }

                    set TextBlockIndex += 1

                if:
                    set StatsUICanvas[Agent] = canvas{ Slots := Slots }
                    SelectedCanvas := StatsUICanvas[Agent]
                then:
                    PlayerUI.AddWidget(SelectedCanvas)


    PlayerJoined(Agent: agent): void=
        set PlayersCount = GetPlayspace().GetPlayers().Length

        if(PlayersCount = 5):
            StartTimerDevice.StartForAll()
   
        if(PlayersCount = 10):
            StartTimerDevice.SetActiveDuration(5.0)

        StatsUI(Agent);

    PlayerLeft(Agent: agent): void=
        set PlayersCount = GetPlayspace().GetPlayers().Length

        if(PlayersCount < 5):
            StartTimerDevice.ResetForAll()

        for(CreativeObject : FindCreativeObjectsWithTag(GameManagerTag{})):
            if:
                GameManager := game_manager_device[CreativeObject]
                GameHasStarted = true
            then:
                GameManager.CheckIfImpostersWon()

    OnStartGame(MaybeAgent: ?agent): void=
        set Players = GetPlayspace().GetPlayers()

        PlayerStatsManager.InitAllPlayers(Players)

        for(Player : Players):
            if(set CustomPlayers[Player] = custom_player{}){}

            if:
                Character := Player.GetFortCharacter[]
                NewAgent := Character.GetAgent[]
                PlayerUI := GetPlayerUI[Player]

                Translation := VotingTable.GetTransform().Translation

                Character.TeleportTo[
                    vector3{X := Translation.X + (PlayerIndex * 200.0), Y := Translation.Y + (PlayerIndex * 200.0), Z := 0.0}, 
                    Character.GetTransform().Rotation
                ]
            then:
                set PlayerIndex += 1

                if(CurrentCanvas := StatsUICanvas[NewAgent]):
                    PlayerUI.RemoveWidget(CurrentCanvas)

        PlayersSet.Signal()
        set GameHasStarted = true

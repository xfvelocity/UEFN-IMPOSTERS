using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Colors/NamedColors }
using { /UnrealEngine.com/Temporary/SpatialMath }

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
    var PlayerClass: int = 0

player_count_stats := class:
    @editable
    PlayerCount1: analytics_device = analytics_device{}
    @editable
    PlayerCount2: analytics_device = analytics_device{}
    @editable
    PlayerCount3: analytics_device = analytics_device{}
    @editable
    PlayerCount4: analytics_device = analytics_device{}
    @editable
    PlayerCount5: analytics_device = analytics_device{}
    @editable
    PlayerCount6: analytics_device = analytics_device{}
    @editable
    PlayerCount7: analytics_device = analytics_device{}
    @editable
    PlayerCount8: analytics_device = analytics_device{}
    @editable
    PlayerCount9: analytics_device = analytics_device{}
    @editable
    PlayerCount10: analytics_device = analytics_device{}

player_manager_device := class(creative_device):
    @editable 
    VotingTable: creative_prop = creative_prop{}
    @editable
    PlayerCountStats: player_count_stats = player_count_stats{}
    @editable
    PlayerCounter: player_counter_device = player_counter_device{}
    @editable
    OverrideButton: button_device = button_device{}
    @editable
    Timer: timer_device = timer_device{}
    @editable
    Teleporter: teleporter_device = teleporter_device{}

    PlayerStatsManager: player_stats_manager = player_stats_manager{}
    var CustomPlayers: [player]custom_player = map{}
    var PlayersSet: event() = event(){}
    var StatsUICanvas: [agent]canvas = map{}
    var GameHasStarted: logic = false
    var PlayersCount: int = 0

    var PlayerCountText: [agent]text_block = map{}
    var PlayerCountCanvas: [agent]canvas = map{}

    OnBegin<override>()<suspends>: void=
        set PlayersCount = GetPlayspace().GetPlayers().Length

        Timer.SuccessEvent.Subscribe(OnStartGame)
        PlayerCounter.CountedEvent.Subscribe(PlayerJoined)
        PlayerCounter.RemovedEvent.Subscribe(PlayerLeft)
        OverrideButton.InteractedWithEvent.Subscribe(ManualOverride)

        for(Player : GetPlayspace().GetPlayers()):
            PlayerCountUI(Player);

    ManualOverride(Agent: agent): void=
        Timer.SetActiveDuration(5.0)
        Timer.Start();
        RemovePlayercountUI();

    PlayerJoined(Agent: agent): void=
        set PlayersCount = GetPlayspace().GetPlayers().Length

        for(Player : GetPlayspace().GetPlayers()):
            if:
                NewAgent := agent[Player]
                Text := PlayerCountText[NewAgent]
            then:
                Text.SetText(StringToMessage("Waiting for at least 5 players before starting ({PlayersCount}/10)"))
            
        if(PlayersCount = 5):
            Timer.Start();
            RemovePlayercountUI()
    
        if(PlayersCount = 10):
            Timer.SetActiveDuration(5.0)

    RemovePlayercountUI(): void=
        for(Player : GetPlayspace().GetPlayers()):
            if:
                Agent := agent[Player]
                PlayerUI := GetPlayerUI[Player]
                SelectedPlayerCountCanvas := PlayerCountCanvas[Agent]
            then:
                PlayerUI.RemoveWidget(SelectedPlayerCountCanvas);

    PlayerCountUI(Player: player) :void=
        if:
            PlayerUI := GetPlayerUI[Player]
            Agent := agent[Player]

            set PlayerCountText[Agent] = text_block{DefaultTextColor := White, DefaultJustification := text_justification.Center}
            Text := PlayerCountText[Agent]
        then:
            Text.SetText(StringToMessage("Waiting for at least 5 players before starting ({PlayersCount}/10)"))
            
            var Slots: []canvas_slot = array{
                canvas_slot:
                    Anchors :=  anchors{Minimum := vector2{X := 0.5, Y := 1.0}, Maximum := vector2{X := 0.5, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := -100.0 , Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.0}
                    ZOrder := 1
                    SizeToContent := false
                    Widget := Text
            }
                
            if:
                set PlayerCountCanvas[Agent] = canvas{ Slots := Slots }
                SelectedCanvas := PlayerCountCanvas[Agent]
            then:
                PlayerUI.AddWidget(SelectedCanvas)

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
                        Anchors :=  anchors{Minimum := vector2{X := 1.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 0.0}}
                        Offsets := margin{Left := -575.0, Top := 15.0, Right := 550.0, Bottom := 380.0}
                        Alignment := vector2{X := 0.0, Y := 0.0}
                        ZOrder := 0
                        SizeToContent := false
                        Widget := BackgroundImage
                    canvas_slot:
                        Anchors :=  anchors{Minimum := vector2{X := 1.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 0.0}}
                        Offsets := margin{Left := -555.0, Top := 35.0 , Right := 0.0, Bottom := 0.0}
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
                            Anchors :=  anchors{Minimum := vector2{X := 1.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 0.0}}
                            Offsets := margin{Left := -555.0, Top := 90.0 + (TextBlockIndex * 40.0), Right := 0.0, Bottom := 0.0}
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

    PlayerLeft(Agent: agent): void=
        if(PlayersCount < 5):
            Timer.SetActiveDuration(60.0)

        for(CreativeObject : FindCreativeObjectsWithTag(GameManagerTag{})):
            if:
                GameManager := game_manager_device[CreativeObject]
                GameHasStarted = true
            then:
                GameManager.CheckIfImpostersWon()

    OnStartGame(MaybeAgent: ?agent): void=
        spawn:
            StartGame()

    StartGame()<suspends>: void=
        Print("StartGame")
        var Players: []player = GetPlayspace().GetPlayers()
        var PlayerIndex: int = 1

        PlayerCount: int = Players.Length
        PlayerStatsManager.InitAllPlayers(Players)

        for(Player : Players):
            if(Agent := agent[Player]):
                if(set CustomPlayers[Player] = custom_player{}){}
                StatsUI(Agent)

                if(PlayerIndex = 1):
                    if(PlayerCount = 1):
                        PlayerCountStats.PlayerCount1.Submit(Agent)
                    else if(PlayerCount = 2):
                        PlayerCountStats.PlayerCount2.Submit(Agent)
                    else if(PlayerCount = 3):
                        PlayerCountStats.PlayerCount3.Submit(Agent)
                    else if(PlayerCount = 4):
                        PlayerCountStats.PlayerCount4.Submit(Agent)
                    else if(PlayerCount = 5):
                        PlayerCountStats.PlayerCount5.Submit(Agent)
                    else if(PlayerCount = 6):
                        PlayerCountStats.PlayerCount6.Submit(Agent)
                    else if(PlayerCount = 7):
                        PlayerCountStats.PlayerCount7.Submit(Agent)
                    else if(PlayerCount = 8):
                        PlayerCountStats.PlayerCount8.Submit(Agent)
                    else if(PlayerCount = 9):
                        PlayerCountStats.PlayerCount9.Submit(Agent)
                    else if(PlayerCount = 10):
                        PlayerCountStats.PlayerCount10.Submit(Agent)
                
                set PlayerIndex += 1

        Sleep(1.0)
        Print("PlayersSet.Signal before")
        PlayersSet.Signal()
        Print("PlayersSet.Signal after")
        set GameHasStarted = true

        for(Player : GetPlayspace().GetPlayers()):
            if:
                Agent := agent[Player]
                PlayerUI := GetPlayerUI[Player]
                SelectedCanvas := StatsUICanvas[Agent]
            then:
                Teleporter.Teleport(Agent)
                PlayerUI.RemoveWidget(SelectedCanvas)

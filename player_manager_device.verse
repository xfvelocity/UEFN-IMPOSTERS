using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Colors/NamedColors }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Game }
using { /Fortnite.com/FortPlayerUtilities }

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
    OverrideButton: button_device = button_device{}
    @editable
    Timer: timer_device = timer_device{}
    @editable
    Teleporters: []teleporter_device = array{}
    @editable
    PlayerCounter5: player_counter_device = player_counter_device{}
    @editable
    PlayerCounter10: player_counter_device = player_counter_device{}

    PlayerStatsManager: player_stats_manager = player_stats_manager{}
    var CustomPlayers: [player]custom_player = map{}
    var PlayersSet: event() = event(){}
    var StatsUICanvas: [agent]canvas = map{}
    var GameHasStarted: logic = false
    var PlayerCountCanvas: [agent]canvas = map{}

    OnBegin<override>()<suspends>: void=
        Timer.SuccessEvent.Subscribe(OnStartGame)
        OverrideButton.InteractedWithEvent.Subscribe(ManualOverride)

        PlayerCounter10.CountedEvent.Subscribe(PlayerJoined)
        PlayerCounter10.RemovedEvent.Subscribe(PlayerLeft)

        PlayerCounter5.CountSucceedsEvent.Subscribe(Players5Reached)
        PlayerCounter10.CountSucceedsEvent.Subscribe(Players10Reached)

    GameStartedUI(Agent: agent): void=
        if:
            Player := player[Agent]
            PlayerUI := GetPlayerUI[Player]
        then:
            Text :=  text_block{DefaultTextColor := White, DefaultJustification := text_justification.Center}
            Text.SetText(StringToMessage("Game has already started. You will join the next game."))
            
            var Slots: []canvas_slot = array{
                canvas_slot:
                    Anchors :=  anchors{Minimum := vector2{X := 0.5, Y := 1.0}, Maximum := vector2{X := 0.5, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := -100.0 , Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.0}
                    ZOrder := 1
                    SizeToContent := false
                    Widget := Text
            }
                
            PlayerUI.AddWidget(canvas{ Slots := Slots })

    ManualOverride(Agent: agent): void=
        Timer.SetActiveDuration(ValuePregameWaitingTime)
        Timer.Start();

        spawn:
            HandleRemovePlayercountUI()

    Players5Reached(): void=
        Timer.SetActiveDuration(ValuePregameWaitingTime)
        Timer.Start();

        spawn:
            HandleRemovePlayercountUI()

    Players10Reached(): void=
        Timer.SetActiveDuration(ValuePregameWaitingTime)
        Timer.Start();

        spawn:
            HandleRemovePlayercountUI()

    HandleRemovePlayercountUI()<suspends>: void=
        Sleep(1.0)
        RemovePlayercountUI();
    
    PlayerJoined(Agent: agent): void=

        if:
            GameHasStarted = true
        then:
            GameStartedUI(Agent)
        else if(Player := player[Agent]):
            StatsUI(Agent)
            PlayerCountUI(Player);

    RemovePlayercountUI(): void=
        for(Agent : GetPlayspace().GetParticipants()):
            if:
                Player := player[Agent]
                PlayerUI := GetPlayerUI[Player]
                SelectedPlayerCountCanvas := PlayerCountCanvas[Agent]
            then:
                PlayerUI.RemoveWidget(SelectedPlayerCountCanvas);

    PlayerCountUI(Player: player) :void=
        if:
            Agent := agent[Player]
            PlayerCountCanvas[Agent]
        then:
        else if:
            PlayerUI := GetPlayerUI[Player]
            Agent := agent[Player]
        then:
            Text :=  text_block{DefaultTextColor := White, DefaultJustification := text_justification.Center}
            Text.SetText(StringToMessage("Waiting for at least 5 players before starting"))
            
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
        Print("PlayerLeft")
        if(GameHasStarted = false):
        else:
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
        var Agents: []agent = GetPlayspace().GetParticipants()
        var PlayerIndex: int = 1

        PlayerCount: int = Agents.Length
        PlayerStatsManager.InitAllPlayers(Agents)

        Print("PlayerCount: {PlayerCount}")

        for(Agent : Agents):
            if:
                Player := player[Agent]
                set CustomPlayers[Player] = custom_player{}
            then:
                Print("Custom Players: {CustomPlayers.Length}")

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

        TeleportPlayersToStart();

    TeleportPlayersToStart(): void=
        var TeleportIndex: int = 0;
        var LoopingIndex: int = 0;

        for(Agent : GetPlayspace().GetParticipants()):
            if:
                Player := player[Agent]
                PlayerUI := GetPlayerUI[Player]
                SelectedCanvas := StatsUICanvas[Agent]
            then:
                PlayerUI.RemoveWidget(SelectedCanvas)

            if(Teleporter := Teleporters[TeleportIndex]):
                Teleporter.Teleport(Agent)
                set LoopingIndex += 1

            if(LoopingIndex = 2):
                set TeleportIndex += 1
                set LoopingIndex = 0

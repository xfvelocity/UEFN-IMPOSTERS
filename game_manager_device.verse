using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /Verse.org/Colors/NamedColors }

ValueEliminationCooldown: int = 22
ValueEmergencyButtonCooldown: int = 15
ValueVotingTime: int = 60

IsOdd(X: int)<decides><transacts>:void = (Mod[X, 2] <> 0)

GameManagerTag := class(tag):

emergency_button_tag := class(tag):

voting_device_tag := class(tag):

team_device_tag := class(tag):

EliminatePlayerHandler := class:
    Device: game_manager_device   
    EliminatedAgent: agent

    HandlerFunction(Agent: agent): void=
        Device.EliminatePlayer(EliminatedAgent, Agent)

report_prop := class<concrete>:
    @editable 
    ReportButton: button_device = button_device{}
    @editable 
    MoveableProp: creative_prop = creative_prop{}
    @editable
    EliminatedProp: creative_prop = creative_prop{}

follow_prop := class<concrete>:
    @editable 
    MoveableProp: creative_prop = creative_prop{}
    @editable
    EliminateButton: button_device = button_device{}

game_manager_device := class(creative_device):
    @editable 
    VotingTable: creative_prop = creative_prop{}
    @editable 
    EmergencyButton: button_device = button_device{}
    @editable
    AudioPlayer: audio_player_device = audio_player_device{}
    @editable
    FollowProps: []follow_prop = array{}
    @editable
    ReportProps: []report_prop = array{}
    @editable
    EndgameCamera: gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}
    @editable
    SequencerDevice: cinematic_sequence_device = cinematic_sequence_device{}
    @editable
    VictoryHudDevice: hud_message_device = hud_message_device{}
    @editable
    DefeatHudDevice: hud_message_device = hud_message_device{}
    @editable
    EndGameDevice: end_game_device = end_game_device{}
    @editable
    ImposterVictorySound: audio_player_device = audio_player_device{}
    @editable
    CremwateVictorySound: audio_player_device = audio_player_device{}

    var CustomPlayers: [player]custom_player = map{}
    var GameEnded: event() = event(){}
    var HasUsedEmergency: [agent]logic = map{}
    var EmergencyButtonCooldownComplete: logic = false
    var EmergencyButtonText: [agent]text_block = map{}
    var EmergencyButtonCanvas: [agent]canvas = map{}
    var EliminationCooldown: [agent]int = map{}
    var EliminationCooldownText: [agent]text_block = map{}

    PlayerStatsManager: player_stats_manager = player_stats_manager{}

    OnBegin<override>()<suspends>:void=
        for(CreativeObject : FindCreativeObjectsWithTag(PlayerManagerTag{})):
            if(PlayerManager := player_manager_device[CreativeObject]):
                PlayerManager.PlayersSet.Await()
                set CustomPlayers = PlayerManager.CustomPlayers

            spawn:
                AsyncCountdown()

        EmergencyButton.InteractedWithEvent.Subscribe(EmergencyButtonPressed)

        # Setup elimination watchers for players
        for (Player -> CustomPlayer : CustomPlayers):
            if:
                Character := Player.GetFortCharacter[]
                Agent := Character.GetAgent[]
                PlayerUI := GetPlayerUI[Player]

                set HasUsedEmergency[Agent] = false
            then:
                Character.EliminatedEvent().Subscribe(HandlePlayerElimination)

                if:
                    CustomPlayer.IsImposter = true
                    set EliminationCooldown[Agent] = ValueEliminationCooldown
                then:
                    TextBlock := text_block{DefaultJustification := text_justification.Center, DefaultTextColor := White}
                    Icon := texture_block{DefaultImage := Images.EliminationCooldownActive}
                    TextBlock.SetText(StringToMessage("{ValueEliminationCooldown}s"))

                    if(set EliminationCooldownText[Agent] = TextBlock):
        
                    var Canvas: canvas = canvas:
                        Slots := array{
                            canvas_slot:
                                Anchors :=  anchors{Minimum := vector2{X := 1.0, Y := 0.5}, Maximum := vector2{X := 1.0, Y := 0.5}}
                                Offsets := margin{Left := -80.0, Top := 180.0, Right := 50.0, Bottom := 50.0}
                                Alignment := vector2{X := 0.5, Y := 0.5}
                                ZOrder := 1
                                SizeToContent := false
                                Widget := Icon
                            canvas_slot:
                                Anchors :=  anchors{Minimum := vector2{X := 1.0, Y := 0.5}, Maximum := vector2{X := 1.0, Y := 0.5}}
                                Offsets := margin{Left := -80.0, Top := 210.0, Right := 0.0, Bottom := 0.0}
                                Alignment := vector2{X := 0.5, Y := 0.5}
                                ZOrder := 1
                                SizeToContent := false
                                Widget := TextBlock
                        }
    
                    PlayerUI.AddWidget(Canvas)

                    spawn:
                        EliminationCooldownTimer(Agent)

        SetupProps()
        HandleFollowProps()

    EliminationCooldownTimer(Agent: agent)<suspends>: void=
        if(Cooldown := EliminationCooldown[Agent]):
            var RemainingTime: int = Cooldown

            loop:
                # Wait for 1 second.
                Sleep(1.0)
                set RemainingTime = RemainingTime - 1 

                if(set EliminationCooldown[Agent] = RemainingTime):
                if(CooldownText := EliminationCooldownText[Agent]):
                    CooldownText.SetText(StringToMessage("{RemainingTime}s"))
    
                if(RemainingTime <= 0):
                    break; 

    EmergencyButtonPressed(Agent: agent): void=
        if:
            Player := player[Agent]
            PlayerUI := GetPlayerUI[Player]
        then:
            if(HasUsedEmergency[Agent] = false and EmergencyButtonCooldownComplete = true):
                if:
                    set HasUsedEmergency[Agent] = true
                    SelectedEmergencyButtonCanvas := EmergencyButtonCanvas[Agent]
                then:
                    PlayerUI.RemoveWidget(SelectedEmergencyButtonCanvas)

                Reported(Agent)
            else:
                if(SelectedEmergencyButtonCanvas := EmergencyButtonCanvas[Agent]):
                    PlayerUI.RemoveWidget(SelectedEmergencyButtonCanvas)

                TextBlock := text_block{DefaultJustification := text_justification.Center, DefaultTextColor := White}

                if(HasUsedEmergency[Agent] = true):
                    TextBlock.SetText(StringToMessage("You have already used the emergency button!"))
    
                if(set EmergencyButtonText[Agent] = TextBlock):
    
                var Canvas: canvas = canvas:
                    Slots := array{
                        canvas_slot:
                            Anchors :=  anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                            Offsets := margin{Left := 0.0, Top := 450.0, Right := 0.0, Bottom := 0.0}
                            Alignment := vector2{X := 0.5, Y := 0.5}
                            ZOrder := 1
                            SizeToContent := false
                            Widget := TextBlock
                    }

                if(set EmergencyButtonCanvas[Agent] = Canvas):    
                    PlayerUI.AddWidget(Canvas)

                spawn:
                    RemoveEmergencyButtonUI(PlayerUI, Canvas)


    RemoveEmergencyButtonUI(PlayerUI: player_ui, Canvas: canvas)<suspends>: void=
        Sleep(3.0)

        PlayerUI.RemoveWidget(Canvas)

    AsyncCountdown()<suspends>:void=
        var RemainingTime: int = ValueEmergencyButtonCooldown

        loop:
            for (Player : GetPlayspace().GetPlayers()):
                if:
                    Character := Player.GetFortCharacter[]
                    Agent := Character.GetAgent[]
                    SelectedEmergencyButtonText := EmergencyButtonText[Agent]
                then:
                    SelectedEmergencyButtonText.SetText(StringToMessage("Button is on cooldown: {RemainingTime}s"))

            Sleep(1.0)
            set RemainingTime = RemainingTime - 1

            if(RemainingTime <= 0):
                set EmergencyButtonCooldownComplete = true

                for (Player : GetPlayspace().GetPlayers()):
                    if:
                        Character := Player.GetFortCharacter[]
                        Agent := Character.GetAgent[]
                        PlayerUI := GetPlayerUI[Player]
    
                        SelectedEmergencyButtonCanvas := EmergencyButtonCanvas[Agent]
                    then:
                        PlayerUI.RemoveWidget(SelectedEmergencyButtonCanvas)

                break;

    SetupProps(): void=
        var PropsIndex: int = 0

        for (CreativeObject : Self.FindCreativeObjectsWithTag(team_device_tag{})):
            for (Player -> CustomPlayer : CustomPlayers):
                if:
                    CustomPlayer.IsImposter = false

                    FortCharacter := Player.GetFortCharacter[]
                    Agent := FortCharacter.GetAgent[]

                    FollowProp := FollowProps[PropsIndex]
                    set CustomPlayer.FollowProps = FollowProp

                    ReportProp := ReportProps[PropsIndex]
                    set CustomPlayer.ReportProps = ReportProp
                then:
                    # Report
                    CustomPlayer.ReportProps.ReportButton.InteractedWithEvent.Subscribe(Reported)

                    # Eliminate
                    CustomPlayer.FollowProps.EliminateButton.InteractedWithEvent.Subscribe(EliminatePlayerHandler{Device := Self, EliminatedAgent := Agent}.HandlerFunction)
            
                    set PropsIndex += 1 

    CheckIfImpostersWon(): void=
        var SurvivingCrewmates: int = 0
        var SurvivingImposters: int = 0

        for(CustomPlayer : CustomPlayers):
            if(CustomPlayer.IsDead = false):
                if(CustomPlayer.IsImposter = true):
                    set SurvivingImposters += 1
                else:
                    set SurvivingCrewmates += 1

        if:
            SurvivingImposters = 1
            SurvivingCrewmates = 1
        then:
            spawn:
                HandleEndGame(false)

        if:
            SurvivingImposters = 2
            SurvivingCrewmates = 2
        then:
            spawn:
                HandleEndGame(false)
        
        if:
            SurvivingImposters = 0
        then:
            spawn:
                HandleEndGame(true)

    EliminatePlayer(EliminatedAgent: agent, EliminatingAgent: agent): void=
        if(EliminationCooldown[EliminatingAgent] = 0):
            if:
                Player := player[EliminatedAgent]
                FortCharacter := Player.GetFortCharacter[]
            then:
                FortCharacter.Damage(100000.0)

                if:
                    CurrentPlayerStats := PlayerStatsManager.GetPlayerStats[EliminatingAgent]
                then:
                    PlayerStatsManager.RecordPlayerStat(EliminatingAgent, StatType.Kills, 1)

                if(set EliminationCooldown[EliminatingAgent] = ValueEliminationCooldown):
                    spawn:
                        EliminationCooldownTimer(EliminatingAgent)

    HandleFollowProps()<suspends>: void=
        loop:
            Sleep(0.0)

            for (Player -> CustomPlayer : CustomPlayers):
                if:
                    CustomPlayer.IsImposter = false
                    FortCharacter := Player.GetFortCharacter[]
                then:
                    if(CustomPlayer.FollowProps.MoveableProp.TeleportTo[
                        FortCharacter.GetTransform().Translation, 
                        FortCharacter.GetTransform().Rotation
                    ]):  

    HandlePlayerElimination(EliminationResult: elimination_result): void=
        FortCharacter := EliminationResult.EliminatedCharacter

        for(CreativeObject : FindCreativeObjectsWithTag(voting_device_tag{})):
            # Set eliminated player as dead
            if:
                VotingDevice := voting_device[CreativeObject]
                CurrentPlayer := VotingDevice.Players[FortCharacter.GetAgent[]]
                Agent := FortCharacter.GetAgent[]
            then:
                set CurrentPlayer.IsDead = true

                # Allow the report button to be activated
                EnableReport(Agent);
        
        if(Agent := FortCharacter.GetAgent[]):
            ResetImposterCooldown(Agent)

        CheckIfImpostersWon()

    ResetImposterCooldown(Agent: agent): void=
        for(CreativeObject : FindCreativeObjectsWithTag(team_device_tag{})):
            if:
                TeamDevice := team_device[CreativeObject]
                Player := player[Agent]

                CustomPlayer := CustomPlayers[Player]
                CustomPlayer.IsImposter = true
            then:
                TeamDevice.CanNotEliminateClassSelector.ChangeClass(Agent)

                spawn:
                    TeamDevice.SetCooldown(Agent)

    EnableReport(Agent: agent): void=        
        if:
            Player := player[Agent]
            FortCharacter := Player.GetFortCharacter[]

            CustomPlayer := CustomPlayers[Player]
        then:
            Translation := FortCharacter.GetTransform().Translation

            if(CustomPlayer.ReportProps.MoveableProp.TeleportTo[
                vector3{X := Translation.X, Y := Translation.Y, Z := 1548.0}, 
                FortCharacter.GetTransform().Rotation
            ]):  

            CustomPlayer.FollowProps.EliminateButton.Disable()

    HandleEndGame(CrewmateWin: logic)<suspends>: void=
        Sleep(1.0)

        var PlayerIndex: int = 1

        if(CrewmateWin = true):
            CremwateVictorySound.Play();
        else:
            ImposterVictorySound.Play();

        for (Player -> CustomPlayer : CustomPlayers):
            if:
                Character := Player.GetFortCharacter[]
                NewAgent := Character.GetAgent[]
            then:
                if(CustomPlayer.IsImposter = true):
                    if:
                        CrewmateWin = false    
                    then:
                        HandleEndGamePlayers(Player, PlayerIndex)

                        PlayerStatsManager.RecordPlayerStat(NewAgent, StatType.ImposterWins, 1)
                        Character.PutInStasis(stasis_args{})
                        VictoryHudDevice.Show(NewAgent)
                        set PlayerIndex += 1
                    else:
                        DefeatHudDevice.Show(NewAgent)
                else:
                    if:
                        CrewmateWin = true
                    then:
                        HandleEndGamePlayers(Player, PlayerIndex)
                        
                        PlayerStatsManager.RecordPlayerStat(NewAgent, StatType.CrewmateWins, 1)
                        Character.PutInStasis(stasis_args{})
                        VictoryHudDevice.Show(NewAgent)
                        set PlayerIndex += 1
                    else:
                        DefeatHudDevice.Show(NewAgent)

        GameEnded.Signal()
        SequencerDevice.Play()

        EndgameCamera.AddToAll()

        Sleep(7.5)

        for (Player -> CustomPlayer : CustomPlayers):
            if:
                Character := Player.GetFortCharacter[]
                Agent := Character.GetAgent[]
            then:
                EndGameDevice.Activate(Agent)
    
    HandleEndGamePlayers(Player: player, PlayerIndex: int): void=        
        if:
            Character := Player.GetFortCharacter[]
        then:
            var PlayerXOffset: float = 50.0 * PlayerIndex
            var TeleportPosition: vector3 = vector3{X := -7310.0, Y := -33960.0, Z := 1550.0} 

            if(IsOdd[PlayerIndex]):
                set TeleportPosition = vector3{X := TeleportPosition.X - PlayerXOffset, Y := TeleportPosition.Y, Z := TeleportPosition.Z}  
            else:
                set TeleportPosition = vector3{X := TeleportPosition.X + PlayerXOffset, Y := TeleportPosition.Y, Z := TeleportPosition.Z} 

            if(Character.TeleportTo[TeleportPosition, MakeRotation(TeleportPosition, 0.0)]):
                

    Reported(Agent: agent): void=
        AudioPlayer.Play()

        for(CreativeObject : FindCreativeObjectsWithTag(voting_device_tag{})):
            if:
                VotingDevice := voting_device[CreativeObject]
            then:
                var PlayerIndex: int = 1

                VotingDevice.AddUI(Agent)

                # Teleport the player to the meeting table when something is reported
                for (Player : GetPlayspace().GetPlayers()):
                    if:
                        Character := Player.GetFortCharacter[]
                        NewAgent := Character.GetAgent[]

                        VoteablePlayer := VotingDevice.Players[NewAgent]
                        Translation := VotingTable.GetTransform().Translation

                        Character.TeleportTo[
                            vector3{X := Translation.X + (PlayerIndex * 100.0), Y := Translation.Y + (PlayerIndex * 100.0), Z := Translation.Z}, 
                            Character.GetTransform().Rotation
                        ]
                    then:
                        set PlayerIndex += 1
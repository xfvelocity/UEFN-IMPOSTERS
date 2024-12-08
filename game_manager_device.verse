using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation/Tags }

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

    var CustomPlayers: [player]custom_player = map{}
    PlayerStatsManager: player_stats_manager = player_stats_manager{}
   
    OnBegin<override>()<suspends>:void=
        for(CreativeObject : FindCreativeObjectsWithTag(PlayerManagerTag{})):
            if(PlayerManager := player_manager_device[CreativeObject]):
                PlayerManager.PlayersSet.Await()
                set CustomPlayers = PlayerManager.CustomPlayers

        EmergencyButton.InteractedWithEvent.Subscribe(Reported)

        # Setup elimination watchers for players
        for (Player -> CustomPlayer : CustomPlayers):
            if (Character := Player.GetFortCharacter[]):
                Character.EliminatedEvent().Subscribe(HandlePlayerElimination)

        SetupProps()
        HandleFollowProps()

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

    EliminatePlayer(EliminatedAgent: agent, EliminatingAgent: agent): void=
        if:
            Player := player[EliminatedAgent]
            FortCharacter := Player.GetFortCharacter[]
        then:
            FortCharacter.Damage(100000.0)

            if:
                # Get players current stats
                CurrentPlayerStats := PlayerStatsManager.GetPlayerStats[EliminatingAgent]
            then:
                PlayerStatsManager.RecordPlayerStat(EliminatingAgent, StatType.Kills, 1)
                Print("{CurrentPlayerStats.Kills + 1}")

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
                vector3{X := Translation.X, Y := Translation.Y, Z := 0.0}, 
                FortCharacter.GetTransform().Rotation
            ]):  

            CustomPlayer.FollowProps.EliminateButton.Disable()

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
                            vector3{X := Translation.X + (PlayerIndex * 100.0), Y := Translation.Y + (PlayerIndex * 100.0), Z := 0.0}, 
                            Character.GetTransform().Rotation
                        ]
                    then:
                        set PlayerIndex += 1
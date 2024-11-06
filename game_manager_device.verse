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
    EliminatingAgent: agent

    HandlerFunction(Agent: agent): void=
        Device.EliminatePlayer(EliminatingAgent)

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
    PlayerFollowProps: []follow_prop = array{}
    @editable 
    ReportFollowProps: []report_prop = array{}
    @editable
    AudioPlayer: audio_player_device = audio_player_device{}
   
    var PlayerFollowPropsMap: [agent]follow_prop = map{}
    var ReportFollowPropsMap: [agent]report_prop = map{}

    OnBegin<override>()<suspends>:void=
        Players := GetPlayspace().GetPlayers();

        EmergencyButton.InteractedWithEvent.Subscribe(Reported)

        # Setup elimination watchers for players
        for (Player : Players):
            if (Character := Player.GetFortCharacter[]):
                Character.EliminatedEvent().Subscribe(HandlePlayerElimination)

        SetupFollowProps(Players)
        HandleFollowProps(Players)

    SetupFollowProps(Players: []player): void=
        for (CreativeObject : Self.FindCreativeObjectsWithTag(team_device_tag{})):
            for (Index -> Player : Players):
                if:
                    TeamDevice := team_device[CreativeObject]
                    TeamDevice.Imposters[Player]
                else:
                    if:
                        FortCharacter := Player.GetFortCharacter[]
                        Agent := FortCharacter.GetAgent[]

                        FollowProp := PlayerFollowProps[Index]
                        set PlayerFollowPropsMap[Agent] = FollowProp

                        ReportProp := ReportFollowProps[Index]
                        set ReportFollowPropsMap[Agent] = ReportProp
                    then:
                        # Report
                        ReportProp.ReportButton.InteractedWithEvent.Subscribe(Reported)

                        # Eliminate
                        FollowProp.EliminateButton.InteractedWithEvent.Subscribe(EliminatePlayerHandler{Device := Self, EliminatingAgent := Agent}.HandlerFunction)
            
    EliminatePlayer(Agent: agent): void=
        if:
            Player := player[Agent]
            FortCharacter := Player.GetFortCharacter[]
        then:
            FortCharacter.Damage(100000.0)
            Print("Eliminate")

    HandleFollowProps(Players: []player)<suspends>: void=
        loop:
            Sleep(0.0)

            for (Player : Players):
                if:
                    FortCharacter := Player.GetFortCharacter[]
                    Agent := FortCharacter.GetAgent[]

                    FollowProp := PlayerFollowPropsMap[Agent]
                then:
                    if(FollowProp.MoveableProp.TeleportTo[
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
                CurrentPlayer := player[Agent]

                Imposter := TeamDevice.Imposters[CurrentPlayer]
            then:
                TeamDevice.CanNotEliminateClassSelector.ChangeClass(Agent)

                spawn:
                    TeamDevice.SetCooldown(Agent)

    EnableReport(Agent: agent): void=        
        if:
            ReportProp := ReportFollowPropsMap[Agent]
            Player := player[Agent]
            FortCharacter := Player.GetFortCharacter[]

            FollowProp := PlayerFollowPropsMap[Agent]
        then:
            Translation := FortCharacter.GetTransform().Translation

            if(ReportProp.MoveableProp.TeleportTo[
                vector3{X := Translation.X, Y := Translation.Y, Z := 0.0}, 
                FortCharacter.GetTransform().Rotation
            ]):  

            FollowProp.EliminateButton.Disable()

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
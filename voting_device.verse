using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Colors/NamedColors }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation/Tags }#
using { /Verse.org/Colors }

StringToMessage<localizes>(String: string) : message ="{String}"

AgentToMessage<localizes>(Agent: agent, String: string) : message ="{Agent} {String}"

ButtonPressHandler := class:
    Device: voting_device   
    Agent: agent

    HandlerFunction(Message: widget_message): void=
        Device.HandleUserVote(Agent, Message)

results_message := class:
    var BackgroundImage: texture_block = texture_block{DefaultImage := Images.T_SimpleSpaceBackground}
    var Text: text_block = text_block{DefaultTextColor := White, DefaultJustification := text_justification.Center}
    var Canvas: canvas = canvas{}

voteable_player := class:
    var Buttons: [agent]button_quiet = map{}
    var VotedImages: [agent]texture_block = map{}
    var HasVoted: logic = false
    var IsDead: logic = false
    var Votes: int = 0
    var Canvas: canvas = canvas{}
    var TimerText: text_block = text_block{}
    var SkipButton: button_quiet = button_quiet{}
    var BackdropImage: texture_block = texture_block{DefaultImage := Images.T_TabletBackground}
    var MegaphoneImages: [agent]texture_block = map{}

voting_device := class(creative_device):
    @editable
    ImposterVotedAnalytic: analytics_device = analytics_device{}
    @editable
    CrewmateVotedAnalytic: analytics_device = analytics_device{}
    
    var CustomPlayers: [player]custom_player = map{}
    var Players: [agent]voteable_player = map{}
    var SkipVotes: int = 0
    var VotedUsersCount: int = 0
    var TimerDuration: int = ValueVotingTime

    OnBegin<override>()<suspends>:void=
        Print("VotingDevice OnBegin")
        for(CreativeObject : FindCreativeObjectsWithTag(PlayerManagerTag{})):
            if(PlayerManager := player_manager_device[CreativeObject]):
                PlayerManager.PlayersSet.Await()
                Print("VotingDevice After Await")
                set CustomPlayers = PlayerManager.CustomPlayers

        # Created empty player classes
        for (NewAgent : GetPlayspace().GetParticipants()):
            if(set Players[NewAgent] = voteable_player{}):

        Print("Voteable Players: {Players.Length}")

    HandleUserVote(VotedForAgent: agent, Message: widget_message): void=
        if:
            # Get the player thats being 
            VotedForPlayer := Players[VotedForAgent]

            # Get the current player from the players array and set them as voted
            Character := Message.Player.GetFortCharacter[]
            CurrentAgent := Character.GetAgent[]
            CurrentPlayer := Players[CurrentAgent] 

            CurrentPlayer.HasVoted = false
            CurrentPlayer.IsDead = false
        then:
            # If they've not already voted increase the count
            set VotedForPlayer.Votes += 1
            set CurrentPlayer.HasVoted = true
            set VotedUsersCount += 1

            # Loop through the players
            for(Key -> Value : Players):
                # Looped through the empty voted images
                for(VotedImagesKey -> VotedImagesValue : Value.VotedImages):
                     # If the player has voted, update the voted image
                    if:
                        VoteablePlayer := Players[VotedImagesKey]
                        VoteablePlayer.HasVoted = true
                    then:
                        VotedImagesValue.SetImage(InImage := Images.T_Voted)

            if(VotedUsersCount = Players.Length):
                spawn:
                    HandleVoteTotals()
                
    AddUI(Agent: agent): void=
        spawn:
            AsyncCountdown()

        for (NewAgent : GetPlayspace().GetParticipants()):
            if:
                Player := player[NewAgent]
                PlayerUI := GetPlayerUI[Player]

                VoteablePlayer := Players[NewAgent]
            then:
                InitializeTimerUI(VoteablePlayer)

                set VoteablePlayer.Canvas = CreateUI(NewAgent, Agent)
                
                PlayerUI.AddWidget(VoteablePlayer.Canvas, player_ui_slot{InputMode := ui_input_mode.All})

    HandleExit(Agent: agent): void=
        # Remove the UI from the player
        if:
            Player := player[Agent]
            PlayerUI := GetPlayerUI[Player]
            VoteablePlayer := Players[Agent]
        then:
            PlayerUI.RemoveWidget(VoteablePlayer.Canvas)

    InitializeTimerUI(VoteablePlayer: voteable_player):void=
        VoteablePlayer.TimerText.SetText(StringToMessage("Voting Time: {TimerDuration}s"))
        VoteablePlayer.TimerText.SetVisibility(widget_visibility.Visible)

    # Asynchronous function to handle the countdown.
    AsyncCountdown()<suspends>:void=
        var RemainingTime: int = TimerDuration

        loop:
            # Wait for 1 second.
            Sleep(1.0)
            set RemainingTime = RemainingTime - 1

            for (Agent : GetPlayspace().GetParticipants()):
                if(VoteablePlayer := Players[Agent]):
                    VoteablePlayer.TimerText.SetText(StringToMessage("Voting Time: {RemainingTime}s"))

            if(TimerDuration = 0):
                break;

            if(RemainingTime <= 0):
                HandleVoteTotals()
                    
                break;

    HandleVoteTotals()<suspends>: void=
        for(Key -> Value : Players):
            # Looped through the empty voted images
            for(ButtonKey -> ButtonValue : Value.Buttons):
                if(VoteablePlayer := Players[ButtonKey]):
                    ButtonValue.SetText(AgentToMessage(ButtonKey, "({VoteablePlayer.Votes})"))

                Value.SkipButton.SetText(StringToMessage("Skip ({SkipVotes})"))

                for(VotedImagesKey -> VotedImagesValue : Value.VotedImages):
                    VotedImagesValue.SetImage(InImage := Images.T_Blank)

        set TimerDuration = 0
        set VotedUsersCount = 0

        Sleep(3.0)

        SetResultsUI()

    SetResultsUI()<suspends>: void=
        var HighestVotes: int = 0
        var TiedVote: logic = false
        var MaybeHighestVotedPlayer: ?agent = false
        var VoteSkipped: logic = false

        var ResultsCanvasItems: [agent]results_message = map{}
        var ResultsText: message = StringToMessage("")

        for(VoteableAgent -> VoteablePlayer : Players):
            if(VoteablePlayer.Votes > HighestVotes):
                set HighestVotes = VoteablePlayer.Votes
                set MaybeHighestVotedPlayer = option{VoteableAgent}
                set TiedVote = false
            else if(VoteablePlayer.Votes = HighestVotes):
                set TiedVote = true

        if(SkipVotes > HighestVotes):
            set VoteSkipped = true
            set TiedVote = false
        else if(SkipVotes = HighestVotes):
            set TiedVote = true

        for(VoteableAgent -> VoteablePlayer : Players):
            if:
                set ResultsCanvasItems[VoteableAgent] = results_message{}
                CanvasItem := ResultsCanvasItems[VoteableAgent]
            then:
                if(TiedVote = true):
                    CanvasItem.Text.SetText(StringToMessage("No one was ejected! (Tied)"))
                else if(VoteSkipped = true):
                    CanvasItem.Text.SetText(StringToMessage("No one was ejected! (Skipped)"))
                else if(HighestVotedPlayer := MaybeHighestVotedPlayer?):
                    CanvasItem.Text.SetText(AgentToMessage(HighestVotedPlayer, " was ejected!"))

        for (VoteableAgent -> VoteablePlayer : Players):
            if:
                Player := player[VoteableAgent]
                CanvasItem := ResultsCanvasItems[VoteableAgent]
                PlayerUI := GetPlayerUI[Player]
            then:
                set CanvasItem.Canvas = canvas:
                    Slots := array{
                        canvas_slot:
                            Anchors :=  anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                            Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                            Alignment := vector2{X := 0.0, Y := 0.0}
                            ZOrder := 0
                            SizeToContent := false
                            Widget := CanvasItem.BackgroundImage
                        canvas_slot:
                            Anchors :=  anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                            Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                            Alignment := vector2{X := 0.5, Y := 0.5}
                            ZOrder := 1
                            SizeToContent := false
                            Widget := CanvasItem.Text
                    }

                PlayerUI.AddWidget(CanvasItem.Canvas, player_ui_slot{InputMode := ui_input_mode.All})
        
        for (Agent : GetPlayspace().GetParticipants()):
            HandleExit(Agent)

        if:
            TiedVote = false
            Agent := MaybeHighestVotedPlayer?
            FortChar := Agent.GetFortCharacter[]
        then:
            FortChar.Damage(100000.0)

            if(CustomPlayer := CustomPlayers[Agent]):
                if(CustomPlayer.IsImposter = true):
                    ImposterVotedAnalytic.Submit(Agent)
                else:
                    CrewmateVotedAnalytic.Submit(Agent)

        Sleep(3.0)

        for (VoteableAgent -> VoteablePlayer : Players):
            if:
                Player := player[VoteableAgent]
                CanvasItem := ResultsCanvasItems[VoteableAgent]
                PlayerUI := GetPlayerUI[Player]
            then:
                PlayerUI.RemoveWidget(CanvasItem.Canvas)

        set VotedUsersCount = 0;
        set SkipVotes = 0;
        set TimerDuration = ValueVotingTime;

        for(CreativeObject : FindCreativeObjectsWithTag(GameManagerTag{})):
            if(GameManager := game_manager_device[CreativeObject]):
                GameManager.EmergencyButtonTimer.Reset()
                GameManager.EmergencyButtonTimer.Start()
                GameManager.CheckIfImpostersWon()

                for(CooldownAgent -> CooldownInt : GameManager.EliminationCooldown):
                    if(set GameManager.EliminationCooldown[CooldownAgent] = ValueEliminationCooldown):
                        spawn:
                            GameManager.EliminationCooldownTimer(CooldownAgent)

    SetUserAsVoted(Message: widget_message): void=
        if:
            # Get the current player from the players array and set them as voted
            Character := Message.Player.GetFortCharacter[]
            CurrentAgent := Character.GetAgent[]
            CurrentPlayer := Players[CurrentAgent] 

            CurrentPlayer.HasVoted = false
        then:
            set CurrentPlayer.HasVoted = true
            set VotedUsersCount += 1

            # Loop through the playrs
            for(Agent -> VoteablePlayer : Players):
                # Looped through the empty voted images
                for(VotedImagesKey -> VotedImagesValue : VoteablePlayer.VotedImages):
                     # If the player has voted, update the voted image
                    if(VotedPlayer := Players[VotedImagesKey], VotedPlayer.HasVoted = true):
                        VotedImagesValue.SetImage(InImage := Images.T_Voted)

            if(VotedUsersCount = Players.Length):
                spawn:
                    HandleVoteTotals()


    HandleSkip(Message: widget_message): void=
        if:
            Character := Message.Player.GetFortCharacter[]
            CurrentAgent := Character.GetAgent[]
            CurrentPlayer := Players[CurrentAgent] 

            CurrentPlayer.HasVoted = false
        then:
            set SkipVotes += 1
            SetUserAsVoted(Message)

    CreateUI(Agent: agent, ReportedAgent: agent): canvas=
        var Slots: []canvas_slot = array{}
        var Buttons: [agent]button_quiet = map{}
        var VotedImages: [agent]texture_block = map{}
        var DeadImages: []texture_block = array{}
        var TimerText: text_block = text_block{}
        var SkipButton: button_quiet = button_quiet{}
        var BackdropImage: texture_block = texture_block{DefaultImage := Images.T_TabletBackground}
        # var MegaphoneImages: texture_block = texture_block{DefaultImage := Images.T_Megaphone}
        var MegaphoneImages: [agent]texture_block = map{}

        TimerText.SetText(StringToMessage("Voting Time: {TimerDuration}s"))
        SkipButton.SetText(StringToMessage("Skip"))
        SkipButton.OnClick().Subscribe(HandleSkip)

        for(VoteableAgent -> VoteablePlayer : Players):
            # Buttons
            Button: button_quiet = button_quiet{}
            Button.SetText(AgentToMessage(VoteableAgent, ""))
            Button.OnClick().Subscribe(ButtonPressHandler{Device := Self, Agent := VoteableAgent}.HandlerFunction)
            if(set Buttons[VoteableAgent] = Button){}
             
            # Voted Images
            VotedImage: texture_block = texture_block{DefaultImage := Images.T_Blank}
            if(set VotedImages[VoteableAgent] = VotedImage){}
            
            # Dead Images
            DeadImage: texture_block = texture_block{DefaultImage := Images.T_Blank}

            if(VoteablePlayer.IsDead = true):
                DeadImage.SetImage(InImage := Images.T_DeadLine)

            # Megaphone Images
            MegaphoneImage: texture_block = texture_block{DefaultImage := Images.T_Megaphone}
            if(set MegaphoneImages[VoteableAgent] = MegaphoneImage){}
            
            set DeadImages += array{DeadImage}
            
        if:
            set Players[Agent].Buttons = Buttons
            set Players[Agent].VotedImages = VotedImages
            set Players[Agent].TimerText = TimerText
            set Players[Agent].SkipButton = SkipButton
            set Players[Agent].BackdropImage = BackdropImage
            set Players[Agent].MegaphoneImages = MegaphoneImages
        then:
            var Index: int = 0;

            set Slots += array{
                canvas_slot:
                    Anchors :=  anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.0}
                    ZOrder := 0
                    SizeToContent := false
                    Widget := BackdropImage
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                    Offsets := margin{Left := 560.0, Top := -465.0, Right := 52.0, Bottom := 32.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    ZOrder := 1
                    SizeToContent := false
                    Widget := TimerText
                canvas_slot:
                    Anchors :=  anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                    Offsets := margin{Left := 0.0, Top := 320.0, Right := 420.0, Bottom := 65.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    ZOrder := 1
                    SizeToContent := false
                    Widget := SkipButton
            }

            # for(Key -> Value : MegaphoneImages):
            #     # Show a megaphone image if the player is the agent who reported
            #     if(Agent = ReportedAgent):
            #         if(IsOdd[Index]):
            #             set Slots += array{
            #                 canvas_slot:
            #                     Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
            #                     Offsets := margin{Left := -40.0, Top := -330.0 + ((Index - 1) * 50.0), Right := 30.0, Bottom := 30.0}
            #                     Alignment := vector2{X := 0.5, Y := 0.5}
            #                     ZOrder := 3
            #                     SizeToContent := false
            #                     Widget := Value
            #             }
            #         else:
            #             set Slots += array{
            #                 canvas_slot:
            #                     Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
            #                     Offsets := margin{Left := 70.0, Top := -330.0 + (Index * 50.0), Right := 30.0, Bottom := 30.0}
            #                     Alignment := vector2{X := 0.5, Y := 0.5}
            #                     ZOrder := 3
            #                     SizeToContent := false
            #                     Widget := Value
            #             }

            #         set Index += 1

            # set Index = 0

            # Buttons
            for(Key -> Value : Buttons):
                Print(AgentToMessage(Agent, "Buttons Index: {Index}"))


        

                # Add voteable buttons
                if(IsOdd[Index]):
                    set Slots += array{
                        canvas_slot:
                            Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                            Offsets := margin{Left := -200.0, Top := -330.0 + ((Index - 1) * 50.0), Right := 380.0, Bottom := 65.0}
                            Alignment := vector2{X := 0.5, Y := 0.5}
                            ZOrder := 1
                            SizeToContent := false
                            Widget := Value
                    }
                else:
                    set Slots += array{
                        canvas_slot:
                            Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                            Offsets := margin{Left := 230.0, Top := -330.0 + (Index * 50.0), Right := 380.0, Bottom := 65.0}
                            Alignment := vector2{X := 0.5, Y := 0.5}
                            ZOrder := 1
                            SizeToContent := false
                            Widget := Value
                    }

                set Index += 1

            set Index = 0

            # Voted Images
            for(Key -> Value : VotedImages):
                if(IsOdd[Index]):
                    set Slots += array{
                        canvas_slot:
                            Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                            Offsets := margin{Left := -22.0, Top := -350.0 + ((Index - 1) * 50.0), Right := 50.0, Bottom := 50.0}
                            Alignment := vector2{X := 0.5, Y := 0.5}
                            ZOrder := 2
                            SizeToContent := false
                            Widget := Value
                    }
                else:
                    set Slots += array{
                        canvas_slot:
                            Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                            Offsets := margin{Left := 400.0, Top := -350.0 + (Index * 50.0), Right := 50.0, Bottom := 50.0}
                            Alignment := vector2{X := 0.5, Y := 0.5}
                            ZOrder := 2
                            SizeToContent := false
                            Widget := Value
                    }

                set Index += 1

            set Index = 0
            
            # Dead Images
            for(Key -> Value : DeadImages):
                if(IsOdd[Index]):
                    set Slots += array{
                        canvas_slot:
                            Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                            Offsets := margin{Left := -200.0, Top := -330.0 + ((Index - 1) * 50.0), Right := 260.0, Bottom := 3.0}
                            Alignment := vector2{X := 0.5, Y := 0.5}
                            ZOrder := 1
                            SizeToContent := false
                            Widget := Value
                    }
                else:
                    set Slots += array{
                        canvas_slot:
                            Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                            Offsets := margin{Left := 230.0, Top := -330.0 + (Index * 50.0), Right := 260.0, Bottom := 3.0}
                            Alignment := vector2{X := 0.5, Y := 0.5}
                            ZOrder := 1
                            SizeToContent := false
                            Widget := Value
                    }

        # Create the main UI canvas
        return canvas{ Slots := Slots }

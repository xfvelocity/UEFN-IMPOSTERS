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
    var BackgroundImage: texture_block = texture_block{DefaultImage := Images.SpaceBackground}
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
    var BackdropImage: texture_block = texture_block{DefaultImage := Images.TabletBackground}

voting_device := class(creative_device):
    var Players: [agent]voteable_player = map{}
    var SkipVotes: int = 0
    var VoteSkipped: logic = false
    var VotedUsersCount: int = 0
    var TimerDuration: int = 15

    OnBegin<override>()<suspends>:void=
        for (Player : GetPlayspace().GetPlayers()):
            if:
                Character := Player.GetFortCharacter[]
                NewAgent := Character.GetAgent[]
                
                # Created empty player classes
                set Players[NewAgent] = voteable_player{}

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
            Print("Firing")
            Print(AgentToMessage(CurrentAgent, ""))
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
                        VotedImagesValue.SetImage(InImage := Images.Voted)

            if(VotedUsersCount = Players.Length):
                spawn:
                    HandleVoteTotals()
                
    AddUI(Agent: agent): void=
        spawn:
            AsyncCountdown()

        for (Player : GetPlayspace().GetPlayers()):
            if:
                Character := Player.GetFortCharacter[]
                PlayerUI := GetPlayerUI[Player]
                NewAgent := Character.GetAgent[]

                VoteablePlayer := Players[NewAgent]
            then:
                InitializeTimerUI(VoteablePlayer)

                set VoteablePlayer.Canvas = CreateUI(NewAgent)
                
                PlayerUI.AddWidget(VoteablePlayer.Canvas, player_ui_slot{InputMode := ui_input_mode.All})

    HandleExit(Player: player): void=
        # Remove the UI from the player
        if:
            PlayerUI := GetPlayerUI[Player]
            FortCharacter := Player.GetFortCharacter[]
            Agent := FortCharacter.GetAgent[]
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

            for (Player : GetPlayspace().GetPlayers()):
                if:
                    Character := Player.GetFortCharacter[]
                    NewAgent := Character.GetAgent[]
                    VoteablePlayer := Players[NewAgent]
                then:
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
                    VotedImagesValue.SetImage(InImage := Images.BlankImage)

        set TimerDuration = 0
        set VotedUsersCount = 0

        Sleep(3.0)

        SetResultsUI()

    SetResultsUI()<suspends>: void=
        var HighestVotes: int = 0
        var TiedVote: logic = false
        var HighestVotedPlayer: ?agent = false

        var ResultsCanvasItems: [agent]results_message = map{}

        for(Key -> Player : Players):
            if:
                set ResultsCanvasItems[Key] = results_message{}
                CanvasItem := ResultsCanvasItems[Key]
            then:
                if(Player.Votes > SkipVotes):
                    if(Player.Votes > HighestVotes):
                        CanvasItem.Text.SetText(AgentToMessage(Key, " was ejected!"))
                        set HighestVotedPlayer = option{Key}
                    else if(Player.Votes = HighestVotes):
                        CanvasItem.Text.SetText(StringToMessage("No one was ejected! (Tied)"))
                else:
                    CanvasItem.Text.SetText(StringToMessage("No one was ejected! (Skipped)"))

        for (Key -> Value : Players):
            if:
                Player := player[Key]
                CanvasItem := ResultsCanvasItems[Key]
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
        
        for (Player : GetPlayspace().GetPlayers()):
            HandleExit(Player)

        if:
            TiedVote = false
            Agent := HighestVotedPlayer?
            FortChar := Agent.GetFortCharacter[]
        then:
            FortChar.Damage(100000.0)

        Sleep(3.0)

        for (Key -> Value : Players):
            if:
                Player := player[Key]
                CanvasItem := ResultsCanvasItems[Key]
                PlayerUI := GetPlayerUI[Player]
            then:
                PlayerUI.RemoveWidget(CanvasItem.Canvas)

        set VotedUsersCount = 0;
        set SkipVotes = 0;
        set TimerDuration = 60;

        for(CreativeObject : FindCreativeObjectsWithTag(GameManagerTag{})):
            if(GameManager := game_manager_device[CreativeObject]):
                GameManager.CheckIfImpostersWon()
        
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
                        VotedImagesValue.SetImage(InImage := Images.Voted)

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

    CreateUI(Agent: agent): canvas=
        var Slots: []canvas_slot = array{}
        var Buttons: [agent]button_quiet = map{}
        var VotedImages: [agent]texture_block = map{}
        var DeadImages: []texture_block = array{}
        var TimerText: text_block = text_block{}
        var SkipButton: button_quiet = button_quiet{}
        var BackdropImage: texture_block = texture_block{DefaultImage := Images.TabletBackground}

        TimerText.SetText(StringToMessage("Voting Time: {TimerDuration}s"))
        SkipButton.SetText(StringToMessage("Skip"))
        SkipButton.OnClick().Subscribe(HandleSkip)

        for(Key -> Value : Players):
            # Buttons
            Button: button_quiet = button_quiet{}
            Button.SetText(AgentToMessage(Key, ""))
            Button.OnClick().Subscribe(ButtonPressHandler{Device := Self, Agent := Key}.HandlerFunction)
            if(set Buttons[Key] = Button){}
             
            # Voted Images
            VotedImage: texture_block = texture_block{DefaultImage := Images.BlankImage}
            if(set VotedImages[Key] = VotedImage){}
            
            # Dead Images
            DeadImage: texture_block = texture_block{DefaultImage := Images.BlankImage}

            if(Value.IsDead = true):
                DeadImage.SetImage(InImage := Images.DeadLine)

            set DeadImages += array{DeadImage}
            
        if:
            set Players[Agent].Buttons = Buttons
            set Players[Agent].VotedImages = VotedImages
            set Players[Agent].TimerText = TimerText
            set Players[Agent].SkipButton = SkipButton
            set Players[Agent].BackdropImage = BackdropImage
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

            # Buttons
            for(Key -> Value : Buttons):
                set Slots += array{
                    canvas_slot:
                        Anchors :=  anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Left := 0.0, Top := -385.0 + (Index * 80.0), Right := 420.0, Bottom := 65.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        ZOrder := 1
                        SizeToContent := false
                        Widget := Value
                }

                set Index += 1

            set Index = 0

            # Voted Images
            for(Key -> Value : VotedImages):
                set Slots += array{
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Left := 200.0, Top := -415.0 + (Index * 80.0), Right := 50.0, Bottom := 50.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        ZOrder := 2
                        SizeToContent := false
                        Widget := Value
                }

                set Index += 1

            set Index = 0
            
            # Dead Images
            for(Key -> Value : DeadImages):
                set Slots += array{
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Left := -5.0, Top := -385.0 + (Index * 80.0), Right := 260.0, Bottom := 3.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        ZOrder := 2
                        SizeToContent := false
                        Widget := Value
                }

                set Index += 1

        # Create the main UI canvas
        return canvas{ Slots := Slots }
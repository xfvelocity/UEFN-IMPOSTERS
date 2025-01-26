using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /Verse.org/Colors/NamedColors }

VentPressHandler := class:
    Device: vent_device   
    Vent: selectable_vent
    ButtonIndex: int = 0
    VentIndex: int = 0

    HandlerFunction(Agent: agent): void=
        Device.OnVent(Agent, Vent, ButtonIndex, VentIndex)

selectable_vent := class<concrete>:
    @editable
    Buttons: []button_device = array{}
    @editable
    Cameras: []gameplay_camera_fixed_point_device = array{}

SelectedVent := enum{Admin, Weapons, NavTop, Corridor, NavBottom, Shields, Electrical, Medbay, Security, ReactorTop, ReactorBottom, UpperEngine, LowerEngine}

vent_device := class(creative_device):
    @editable
    AudioPlayer: audio_player_device = audio_player_device{}
    @editable 
    Vents: []selectable_vent = array{}
    @editable
    MoveRightTrigger: input_trigger_device = input_trigger_device{}
    @editable
    MoveLeftTrigger: input_trigger_device = input_trigger_device{}
    @editable
    EscapeTrigger: input_trigger_device = input_trigger_device{}
    @editable
    VentAnalytic: analytics_device = analytics_device{}

    var CurrentCameraIndex: int = 0
    var SelectedVentCopy: selectable_vent = selectable_vent{}
    var UIText: [agent]text_block = map{}
    var UICanvas: [agent]canvas = map{}
    var SelectedVentIndex: int = 0
    var VentNames: [int][int]string = map{
        0 => map {
            0 => "Caffeteria",
            1 => "Admin",
            2 => "Corridor"
        },
        1 => map {
            0 => "Weapons",
            1 => "Navigation (Top)"
        },
        2 => map {
            0 => "Navigation (Bottom)",
            1 => "Shields"
        },
        3 => map {
            0 => "Lower Engine",
            1 => "Reactor (Bottom)"
        },
        4 => map {
            0 => "Reactor (Top)",
            1 => "Upper Engine"
        },
        5 => map {
            0 => "Electrical",
            1 => "Security",
            2 => "Medbay"
        }
    }
    
    OnBegin<override>()<suspends>:void=
        Print("VentDevice OnBegin")
        DisableInputs();

        MoveRightTrigger.PressedEvent.Subscribe(MoveRightPressed)
        MoveLeftTrigger.PressedEvent.Subscribe(MoveLeftPressed)
        EscapeTrigger.PressedEvent.Subscribe(EscapePressed)

        for (VentIndex -> Vent : Vents):            
            for(Index -> Button : Vent.Buttons):
                Button.InteractedWithEvent.Subscribe(VentPressHandler{Device := Self, Vent := Vent, ButtonIndex := Index, VentIndex := VentIndex}.HandlerFunction)

    OnVent(Agent: agent, Vent: selectable_vent, ButtonIndex: int, VentIndex: int): void=
        if:
            Player := player[Agent]
            FortCharacter := Player.GetFortCharacter[]

            FortCharacter.TeleportTo[vector3{X := -10720.0, Y := -33850.0, Z := 2310.0}, FortCharacter.GetTransform().Rotation]
            
        set CurrentCameraIndex = ButtonIndex
        set SelectedVentCopy = Vent
        set SelectedVentIndex = VentIndex
        
        AudioPlayer.Play(Agent)
        MoveRightTrigger.Enable()
        MoveLeftTrigger.Enable()
        EscapeTrigger.Enable()
        VentAnalytic.Submit(Agent)

        SetupUI(Agent)
        ChangeCamera(Agent)

    SetupUI(Agent: agent): void=
        if:
            Player := player[Agent]
            PlayerUI := GetPlayerUI[Player]

            set UIText[Agent] = text_block{DefaultJustification := text_justification.Center, DefaultTextColor := White}
            TextBlock := UIText[Agent]
        then:
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

            if:
                set UICanvas[Agent] = Canvas
            then:
                PlayerUI.AddWidget(Canvas)

    ChangeCamera(Agent: agent): void=
        if:
            TextBlock := UIText[Agent]
            VentName := VentNames[SelectedVentIndex][CurrentCameraIndex]
        then:
            TextBlock.SetText(StringToMessage(VentName))

        if(Camera := SelectedVentCopy.Cameras[CurrentCameraIndex]):
            Camera.AddTo(Agent)

    MoveRightPressed(Agent: agent): void=
        if(CurrentCameraIndex = SelectedVentCopy.Cameras.Length - 1):
            set CurrentCameraIndex = 0
        else:
            set CurrentCameraIndex += 1
        
        ChangeCamera(Agent)

    DisableInputs() :void=
        MoveRightTrigger.Disable()
        MoveLeftTrigger.Disable()
        EscapeTrigger.Disable()

    MoveLeftPressed(Agent: agent): void=
        if(CurrentCameraIndex = 0):
            set CurrentCameraIndex = SelectedVentCopy.Cameras.Length - 1
        else:
            set CurrentCameraIndex -= 1
        
        ChangeCamera(Agent)

    EscapePressed(Agent: agent): void=
        DisableInputs()

        if:
            Player := player[Agent]
            FortCharacter := Player.GetFortCharacter[]

            SelectedButton := SelectedVentCopy.Buttons[CurrentCameraIndex]
            FortCharacter.TeleportTo[SelectedButton.GetTransform().Translation, FortCharacter.GetTransform().Rotation]

        for(Camera : SelectedVentCopy.Cameras):
            Camera.RemoveFrom(Agent)

        if:
            Player := player[Agent]
            PlayerUI := GetPlayerUI[Player]

            Canvas := UICanvas[Agent]
        then:
            PlayerUI.RemoveWidget(Canvas)

        AudioPlayer.Play(Agent)
        set CurrentCameraIndex = 0
        
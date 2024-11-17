using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }

VentPressHandler := class:
    Device: vent_device   
    Vent: selectable_vent
    ButtonIndex: int = 0

    HandlerFunction(Agent: agent): void=
        Device.OnVent(Agent, Vent, ButtonIndex)

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

    var CurrentCameraIndex: int = 0
    var SelectedVentCopy: selectable_vent = selectable_vent{}
    
    OnBegin<override>()<suspends>:void=
        MoveRightTrigger.PressedEvent.Subscribe(MoveRightPressed)
        MoveLeftTrigger.PressedEvent.Subscribe(MoveLeftPressed)
        EscapeTrigger.PressedEvent.Subscribe(EscapePressed)

        for (Vent : Vents):
            for(Index -> Button : Vent.Buttons):
                Button.InteractedWithEvent.Subscribe(VentPressHandler{Device := Self, Vent := Vent, ButtonIndex := Index}.HandlerFunction)

    OnVent(Agent: agent, Vent: selectable_vent, ButtonIndex: int): void=
        if:
            Player := player[Agent]
            FortCharacter := Player.GetFortCharacter[]

            FortCharacter.TeleportTo[vector3{X := 540.0, Y := -1580.0, Z := 820.0}, FortCharacter.GetTransform().Rotation]
            
        set CurrentCameraIndex = ButtonIndex
        set SelectedVentCopy = Vent
        AudioPlayer.Play()

        MoveRightTrigger.Enable()
        MoveLeftTrigger.Enable()
        EscapeTrigger.Enable()
        ChangeCamera(Agent)

    ChangeCamera(Agent: agent): void=
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

        set CurrentCameraIndex = 0
        
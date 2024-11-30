
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors/NamedColors }

camera_device := class(creative_device):
    @editable
    Button: button_device = button_device{}
    @editable
    Cameras: []gameplay_camera_fixed_point_device = array{}
    @editable
    MoveRightTrigger: input_trigger_device = input_trigger_device{}
    @editable
    MoveLeftTrigger: input_trigger_device = input_trigger_device{}
    @editable
    EscapeTrigger: input_trigger_device = input_trigger_device{}
    @editable
    PostProcess: post_process_device = post_process_device{}

    var CurrentCameraIndex: int = 0
    var UIText: [agent]text_block = map{}
    var UICanvas: [agent]canvas = map{}
    var CameraNames: [int]string = map{
            0 => "Security Corridor",
            1 => "Medbay Corridor",
            2 => "Navigation Corridor",
            3 => "Admin Corridor"
    }

    OnBegin<override>()<suspends>:void=
        Button.InteractedWithEvent.Subscribe(ViewCameras)
        MoveRightTrigger.PressedEvent.Subscribe(MoveRightPressed)
        MoveLeftTrigger.PressedEvent.Subscribe(MoveLeftPressed)
        EscapeTrigger.PressedEvent.Subscribe(EscapePressed)

        PostProcess.Enable()

        DisableInputs()

    ViewCameras(Agent: agent): void=
        MoveRightTrigger.Enable()
        MoveLeftTrigger.Enable()
        EscapeTrigger.Enable()
        PostProcess.BlendIn(Agent)
        SetupUI(Agent)

        ChangeCamera(Agent)

    ChangeCamera(Agent: agent): void=
        if(Camera := Cameras[CurrentCameraIndex]):
            Camera.AddTo(Agent)

        if:
            TextBlock := UIText[Agent]
            CameraName := CameraNames[CurrentCameraIndex]
        then:
            TextBlock.SetText(StringToMessage(CameraName))

    MoveRightPressed(Agent: agent): void=
        if(CurrentCameraIndex = 4):
            set CurrentCameraIndex = 0

        set CurrentCameraIndex += 1
        
        ChangeCamera(Agent)

    DisableInputs() :void=
        MoveRightTrigger.Disable()
        MoveLeftTrigger.Disable()
        EscapeTrigger.Disable()

    MoveLeftPressed(Agent: agent): void=
        if(CurrentCameraIndex = 0):
            set CurrentCameraIndex = 4

        set CurrentCameraIndex -= 1
        
        ChangeCamera(Agent)

    EscapePressed(Agent: agent): void=
        DisableInputs()
        PostProcess.BlendOut(Agent)

        set CurrentCameraIndex = 0

        for(Camera : Cameras):
            Camera.RemoveFrom(Agent)

        if:
            Player := player[Agent]
            PlayerUI := GetPlayerUI[Player]

            Canvas := UICanvas[Agent]
        then:
            PlayerUI.RemoveWidget(Canvas)
        
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
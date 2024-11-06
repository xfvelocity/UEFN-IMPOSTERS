
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

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

    OnBegin<override>()<suspends>:void=
        Button.InteractedWithEvent.Subscribe(ViewCameras)
        MoveRightTrigger.PressedEvent.Subscribe(MoveRightPressed)
        MoveLeftTrigger.PressedEvent.Subscribe(MoveLeftPressed)
        EscapeTrigger.PressedEvent.Subscribe(EscapePressed)

        PostProcess.Enable()
        PostProcess.BlendingInCompleteEvent.Subscribe(BlendIn)

        DisableInputs()

    BlendIn(Agent: ?agent): void=
        Print("Blended")

    ViewCameras(Agent: agent): void=
        MoveRightTrigger.Enable()
        MoveLeftTrigger.Enable()
        EscapeTrigger.Enable()
        PostProcess.BlendIn(Agent)

        ChangeCamera(Agent)

    ChangeCamera(Agent: agent): void=
        if(Camera := Cameras[CurrentCameraIndex]):
            Camera.AddTo(Agent)

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
        

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

vent := class<concrete>:
    @editable 
    VentButton: button_device = button_device{}
    @editable 
    SelectableVentButtons: []button_device = array{}


vent_device := class(creative_device):
    @editable 
    Vents: []vent = array{}
    @editable
    AudioPlayer: audio_player_device = audio_player_device{}

    OnBegin<override>()<suspends>:void=
        for (Vent : Vents):
            Vent.VentButton.InteractedWithEvent.Subscribe(OnVent)

    OnVent(Agent: agent): void=
        AudioPlayer.Play()
        Print("Venting")
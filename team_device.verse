
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }

imposter := class<concrete>:
    var CanEliminate: logic = false

team_device := class(creative_device):
    @editable
    EliminateCooldown: float = 5.0
    @editable 
    ImposterClassSelector: class_and_team_selector_device = class_and_team_selector_device{}
    @editable 
    CrewmateClassSelector: class_and_team_selector_device = class_and_team_selector_device{}
    @editable 
    CanEliminateClassSelector: class_and_team_selector_device = class_and_team_selector_device{}
    @editable 
    CanNotEliminateClassSelector: class_and_team_selector_device = class_and_team_selector_device{}
    @editable 
    CrewmateHudDevice: hud_message_device = hud_message_device{}
    @editable 
    ImposterHudDevice: hud_message_device = hud_message_device{}

    var Players: []player = array{}
    var Imposters: [player]imposter = map{}

    OnBegin<override>()<suspends>:void=
        set Players = GetPlayspace().GetPlayers()
        SetImposters();

        for(Player : Players):
            if(Imposters[Player]):
            else:
                # If the player isn't an imposter, add them to the crewmats
                if:
                    FortCharacter := Player.GetFortCharacter[]
                    Agent := FortCharacter.GetAgent[]
                then:
                    AgentName := AgentToMessage(Agent, "[CREW]")
                    Print(AgentName)

                    CrewmateClassSelector.ChangeTeam(Agent)
                    CrewmateHudDevice.Show(Agent)
                        
        # Once the cooldown is up, allow the player to eliminate
        Sleep(EliminateCooldown)

        for (Player -> Imposter : Imposters):
            if:
                FortCharacter := Player.GetFortCharacter[]
                Agent := FortCharacter.GetAgent[]
            then:
                CanEliminateClassSelector.ChangeClass(Agent)

        # HandleMutators()

    SetCooldown(Agent: agent)<suspends>: void=
        Sleep(EliminateCooldown)
        Print("Can now eliminate")
        CanEliminateClassSelector.ChangeClass(Agent)

    SetImposter(Player: player): void=
        if:
            FortCharacter := Player.GetFortCharacter[]
            Agent := FortCharacter.GetAgent[]
        then:
            AgentName := AgentToMessage(Agent, "[IMPOSTER]")
            Print(AgentName)
            # Set to imposters team and show the imposters ui
            ImposterClassSelector.ChangeTeam(Agent)
            ImposterHudDevice.Show(Agent)

            # Add to the imposters array
            if(set Imposters[Player] = imposter{}){}

    SetSecondImposter(): void=
        if(Player := Players[GetRandomInt(0, Players.Length - 1)]):
            if(Imposters[Player]):
                # If player is already an imposter, try to find another one
                SetSecondImposter()
            else:
                SetImposter(Player)

    SetImposters(): void=
        Value: int = GetRandomInt(0, Players.Length - 1)
        if:
            Player := Players[Value]
        then:
            SetImposter(Player)

        if(Players.Length >= 5):
            SetSecondImposter()
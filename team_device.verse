
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }

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

    var CustomPlayers: [player]custom_player = map{}
    var Players: []player = array{}

    OnBegin<override>()<suspends>:void=
        for(CreativeObject : FindCreativeObjectsWithTag(PlayerManagerTag{})):
            if(PlayerManager := player_manager_device[CreativeObject]):
                PlayerManager.PlayersSet.Await()

                set CustomPlayers = PlayerManager.CustomPlayers
                set Players = PlayerManager.Players


        Print("{CustomPlayers.Length}")
        
        SetImposters();


        for(Player -> CustomPlayer : CustomPlayers):
            if:
                CustomPlayer.IsImposter = false

                FortCharacter := Player.GetFortCharacter[]
                Agent := FortCharacter.GetAgent[]
            then:
                # If the player isn't an imposter, add them to the crewmates
                CrewmateClassSelector.ChangeTeam(Agent)
                CrewmateHudDevice.Show(Agent)
                    
        # Once the cooldown is up, allow the player to eliminate
        Sleep(EliminateCooldown)

        for(Player -> CustomPlayer : CustomPlayers):
            if:
                CustomPlayer.IsImposter = true

                FortCharacter := Player.GetFortCharacter[]
                Agent := FortCharacter.GetAgent[]
            then:
                CanEliminateClassSelector.ChangeClass(Agent)

    SetCooldown(Agent: agent)<suspends>: void=
        Sleep(EliminateCooldown)
        Print("Can now eliminate")
        CanEliminateClassSelector.ChangeClass(Agent)

    SetImposter(Player: player): void=
        if:
            FortCharacter := Player.GetFortCharacter[]
            Agent := FortCharacter.GetAgent[]

            CustomPlayer := CustomPlayers[Player]
        then:
            # Set to imposters team and show the imposters ui
            ImposterClassSelector.ChangeTeam(Agent)
            ImposterHudDevice.Show(Agent)

            set CustomPlayer.IsImposter = true

    SetSecondImposter(): void=
        if(Player := Players[GetRandomInt(0, Players.Length - 1)]):
            if:
                CustomPlayer := CustomPlayers[Player]
                CustomPlayer.IsImposter = true
            then:
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
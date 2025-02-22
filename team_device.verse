
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
    CrewmateHudDevice: hud_message_device = hud_message_device{}
    @editable 
    ImposterHudDevice: hud_message_device = hud_message_device{}

    var CustomPlayers: [player]custom_player = map{}
    var Agents: []agent = array{}
    var ImpostersCount: int = 0
    PlayerStatsManager: player_stats_manager = player_stats_manager{}

    OnBegin<override>()<suspends>:void=
        Print("TeamDevice OnBegin")
        for(CreativeObject : FindCreativeObjectsWithTag(PlayerManagerTag{})):
            if(PlayerManager := player_manager_device[CreativeObject]):
                PlayerManager.PlayersSet.Await()
                Print("TasksDevice After Await")
                set CustomPlayers = PlayerManager.CustomPlayers
                set Agents = GetPlayspace().GetParticipants()
        
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

                PlayerStatsManager.RecordPlayerStat(Agent, StatType.CrewmatePlays, 1)

    SetImposter(Player: player): void=
        if:
            FortCharacter := Player.GetFortCharacter[]
            Agent := FortCharacter.GetAgent[]

            CustomPlayer := CustomPlayers[Player]
        then:
            # Set to imposters team and show the imposters ui
            ImposterClassSelector.ChangeTeam(Agent)
            ImposterHudDevice.Show(Agent)
            PlayerStatsManager.RecordPlayerStat(Agent, StatType.ImposterPlays, 1)

            set CustomPlayer.IsImposter = true

    SetSecondImposter(): void=
        if:
            Agent := Agents[GetRandomInt(0, Agents.Length - 1)]
            Player := player[Agent]
        then:
            if:
                CustomPlayer := CustomPlayers[Player]
                CustomPlayer.IsImposter = true
            then:
                # If player is already an imposter, try to find another one
                SetSecondImposter()
            else:
                SetImposter(Player)

    SetImposters(): void=
        set ImpostersCount = 1
        Value: int = GetRandomInt(0, Agents.Length - 1)

        if:
            Player := player[Agents[Value]]
        then:
            SetImposter(Player)

        if(Agents.Length >= 5):
            set ImpostersCount = 2
            SetSecondImposter()
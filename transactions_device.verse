using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Marketplace }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/AI }

using { Definitions }


transactions_device := class(creative_device):
    @editable
    Button: button_device = button_device{}

    var CustomPlayers: [player]custom_player = map{}

    OnBegin<override>()<suspends>: void =
        for (CreativeObject : FindCreativeObjectsWithTag(PlayerManagerTag)):
            if (PlayerManager := player_manager_device[CreativeObject]):
                PlayerManager.PlayersSet.Await()
                set CustomPlayers = PlayerManager.CustomPlayers

        Button.InteractedWithEvent.Subscribe(OnButtonInteraction)

    OnButtonInteraction(Agent: agent): void =
        Print("OnButtonInteraction")
        if (Player := player[Agent]):
            spawn { TryBuySpeedBoost(Player) }

    TryBuySpeedBoost(Player: player)<suspends>: void =
        Result := GrantEntitlement(Player, Definitions.Products.speed_boost)
        if (Result = true):
            ApplySpeedBoost(Player)

    ApplySpeedBoost(Player: player): void =
        if:
            CustomPlayer := CustomPlayers[Player]
            CustomPlayer.HasSpeedBoost = false
            FortCharacter := Player.GetFortCharacter[]
            Nav := FortCharacter.GetNavigatable[]
        then:
            set CustomPlayer.HasSpeedBoost = true
            Nav.SetMovementSpeedMultiplier(1.5)

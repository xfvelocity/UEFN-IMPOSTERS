using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Marketplace }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Colors }
using { /Verse.org/Colors/NamedColors }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }

transactions_device := class(creative_device):
    @editable
    Button: button_device = button_device{}

    # OnBegin<override>()<suspends>:void=
    #     Button.InteractedWithEvent.Subscribe(OnButtonInteraction)

    # OnButtonInteraction(Agent:agent):void=
    #     if (Player := player[Agent]):
    #         # Shows shop UI with list of selected offers
    #         spawn{TryBuyOffer(Player, Definitions.Offers.engineer_access{})}

    # TryBuyOffer(Player:player, Offer : offer)<suspends>:void =
    #     Result := BuyOffer(Player, Offer)
 
    #     if (not Result?):
    #         Print("Failed to buy.")


using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors/NamedColors }

# TargetHitHandler := class:
#     Device: tasks_device   
#     Agent: agent

#     HitTask(): void=
#         Device.HandleTargetHit(Agent)

TaskHandler := class:
    Device: tasks_device   
    SelectedTask: Task

    DownloadTask(Agent: agent): void=
        Device.HandleDownloadTask(Agent, SelectedTask)

    SwipeTask(Agent: agent): void=
        Device.HandleSwipeTask(Agent, SelectedTask)

task_ui := class<concrete>:
    var Canvas: canvas = canvas{}
    var BackgroundImage: texture_block = texture_block{DefaultImage := Images.OpaqueBackground}
    var TextBlocks: [Task]text_block = map{}

Task := enum{AdminUpload, CaffeteriaDownload, CommunicationsDownload, ElectricalDownload, NavDownload, WeaponsDownload, AdminSwipe, ElectricalSwipe, ElectricalCalibration, LowerEngineSwipe, NavigationSwipe, WeaponsShooting, StorageFuel}

FuelTask := enum{RefuelFirst, UpperEngine, RefuelSecond, LowerEngine}

TaskString : [Task]string = map{
    Task.AdminUpload => "Admin: Upload (1/2)",
    Task.CaffeteriaDownload => "Caffeteria: Download (0/2)",
    Task.CommunicationsDownload => "Communications: Download (0/2)",
    Task.ElectricalDownload => "Electrical: Download (0/2)",
    Task.NavDownload => "Navigation: Download (0/2)",
    Task.WeaponsDownload => "Weapons: Download (0/2)",
    Task.AdminSwipe => "Admin: Swipe",
    Task.ElectricalSwipe => "Electrical: Swipe",
    Task.ElectricalCalibration => "Electrical: Calibration",
    Task.LowerEngineSwipe => "Lower Engine: Swipe",
    Task.NavigationSwipe => "Navigation: Swipe",
    Task.WeaponsShooting => "Weapons: Shooting (0/20)",
    Task.StorageFuel => "Storage: Fuel (0/2)"
}

DownloadCombination: [Task]Task = map{
    Task.CommunicationsDownload => Task.AdminUpload,
    Task.CaffeteriaDownload => Task.AdminUpload,
    Task.WeaponsDownload => Task.AdminUpload,
    Task.NavDownload => Task.AdminUpload,
    Task.ElectricalDownload => Task.AdminUpload
}

download_tasks := class<concrete>:
    @editable
    AdminUpload: button_device = button_device{}
    @editable
    CaffeteriaDownload: button_device = button_device{}
    @editable
    CommunicationsDownload: button_device = button_device{}
    @editable
    ElectricalDownload: button_device = button_device{}
    @editable
    NavDownload: button_device = button_device{}
    @editable
    WeaponsDownload: button_device = button_device{}

card_swipe := class<concrete>:
    @editable
    Button: button_device = button_device{}
    @editable
    SkilledInteractionDevice: skilled_interaction_device = skilled_interaction_device{}

card_swipes := class<concrete>:
    @editable
    AdminSwipe: card_swipe = card_swipe{}
    @editable
    ElectricalSwipe: card_swipe = card_swipe{}
    @editable
    ElectricalCalibration: card_swipe = card_swipe{}
    @editable
    LowerEngineSwipe: card_swipe = card_swipe{}
    @editable
    NavigationSwipe: card_swipe = card_swipe{}

weapons_task := class<concrete>:
    @editable
    MutatorZone: mutator_zone_device = mutator_zone_device{}
    @editable
    Triggers: []trigger_device = array{}
    
player_class := class<concrete>:
    @editable 
    ClassSelector: class_and_team_selector_device = class_and_team_selector_device{}
    @editable 
    MapIndictators: []map_indicator_device = array{}

download_task := class<concrete>:
    @editable 
    Button: button_device = button_device{}

fuel_task := class<concrete>:
    @editable 
    Refuel: button_device = button_device{}
    @editable 
    UpperEngine: button_device = button_device{}
    @editable 
    LowerEngine: button_device = button_device{}

tasks_device := class(creative_device):
    @editable
    Downloads: download_tasks = download_tasks{}
    @editable
    PlayerClasses: []player_class = array{}
    @editable
    Swipes: card_swipes = card_swipes{}
    @editable
    WeaponsShooting: weapons_task = weapons_task{}
    @editable
    Fuel: fuel_task = fuel_task{}

    PlayerStatsManager: player_stats_manager = player_stats_manager{}

    var CustomPlayers: [player]custom_player = map{}
    var DownloadTaskComplete: logic = false
    var PlayerTasksCanvas: [agent]task_ui = map{}
    var PlayerTasksMapIndicators: [agent][Task]map_indicator_device = map{}
    var TotalTasksText: [agent]text_block = map{}
    var TotalTasksCompleted: float = 0.0
    var TotalTasksAmount: float = 0.0
    var TargetsHit: [agent]int = map{}
    var DownloadsCompleted: [agent][]Task = map{}
    var CurrentFuelTask: FuelTask = FuelTask.RefuelFirst

    TaskList: [int][]Task = map{
        10 => array{Task.StorageFuel, Task.CaffeteriaDownload, Task.ElectricalCalibration, Task.CommunicationsDownload},
        11 => array{Task.AdminSwipe, Task.ElectricalSwipe, Task.CaffeteriaDownload, Task.LowerEngineSwipe, Task.StorageFuel}
    }

    OnBegin<override>()<suspends>:void=
        for(CreativeObject : FindCreativeObjectsWithTag(PlayerManagerTag{})):
            if(PlayerManager := player_manager_device[CreativeObject]):
                PlayerManager.PlayersSet.Await()
                set CustomPlayers = PlayerManager.CustomPlayers

                if(SelectedTaskItem := TaskList[10]):
                    set TotalTasksAmount = CustomPlayers.Length * (SelectedTaskItem.Length * 1.0)

                
                AssignTasks()
                spawn:
                    TasksUI()
                spawn:
                    TotalTaskUI()
                SetListeners()

    SetListeners()<suspends>: void=
        # Admin Download
        Downloads.AdminUpload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.AdminUpload}.DownloadTask)
            
        # Communications Download
        Downloads.CommunicationsDownload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.CommunicationsDownload}.DownloadTask)

        # Caffeteria Download
        Downloads.CaffeteriaDownload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.CaffeteriaDownload}.DownloadTask)

        # Weapons Download
        Downloads.WeaponsDownload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.WeaponsDownload}.DownloadTask)

        # Navigation Download
        Downloads.NavDownload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.NavDownload}.DownloadTask)

        # Electric Download
        Downloads.ElectricalDownload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.ElectricalDownload}.DownloadTask)

        # Admin Swipe
        Swipes.AdminSwipe.SkilledInteractionDevice.InteractionSucceededEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.AdminSwipe}.SwipeTask)

        # Electrical Swipe
        Swipes.ElectricalSwipe.SkilledInteractionDevice.InteractionSucceededEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.ElectricalSwipe}.SwipeTask)

        # Electrical Calibrate
        Swipes.ElectricalCalibration.SkilledInteractionDevice.InteractionSucceededEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.ElectricalCalibration}.SwipeTask)

        # Lower Engine Swipe
        Swipes.LowerEngineSwipe.SkilledInteractionDevice.InteractionSucceededEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.LowerEngineSwipe}.SwipeTask)

        # Navigation Swipe
        Swipes.NavigationSwipe.SkilledInteractionDevice.InteractionSucceededEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.NavigationSwipe}.SwipeTask)

        # Weapons Shooting
        for(Trigger : WeaponsShooting.Triggers):
            Trigger.TriggeredEvent.Subscribe(HandleTargetHit)

        # Electric Download
        Fuel.Refuel.InteractedWithEvent.Subscribe(HandleRefuelTask)
        Fuel.LowerEngine.InteractedWithEvent.Subscribe(HandleLowerEngineFuelTask)
        Fuel.UpperEngine.InteractedWithEvent.Subscribe(HandleUpperEngineFuelTask)

    AssignTasks(): void=
        # Disable all map indicators
        for (PlayerClass : PlayerClasses):
            for(Index -> MapIndicator : PlayerClass.MapIndictators):
                MapIndicator.Disable()

        for (Player -> CustomPlayer : CustomPlayers):
            RandomClassIndex: int = GetRandomInt(10, TaskList.Length + 9)

            if:
                CustomPlayer.IsImposter = false
                PlayerClass := PlayerClasses[RandomClassIndex - 10]
                FortCharacter := Player.GetFortCharacter[]
                Agent := FortCharacter.GetAgent[]

                SelectedTasks := TaskList[RandomClassIndex]
                set PlayerTasksMapIndicators[Agent] = map{}
            then:
                set CustomPlayer.PlayerClass = RandomClassIndex - 10
                PlayerClass.ClassSelector.ChangeClass(Agent)

                for(Index -> SelectedTask : SelectedTasks):
                    if:
                        set CustomPlayer.Tasks.TaskList[SelectedTask] = false

                        MapIndicator := PlayerClass.MapIndictators[Index]
                        set PlayerTasksMapIndicators[Agent][SelectedTask] = MapIndicator
                    then:
                        MapIndicator.Enable()

                        # Communications Download
                        if:
                            SelectedTask = Task.CommunicationsDownload
                            MapIndicator.TeleportTo[Downloads.CommunicationsDownload.GetTransform()]

                        # Caffeteria Download
                        if:
                            SelectedTask = Task.CaffeteriaDownload
                            MapIndicator.TeleportTo[Downloads.CaffeteriaDownload.GetTransform()]

                        # Weapons Download
                        if:
                            SelectedTask = Task.WeaponsDownload
                            MapIndicator.TeleportTo[Downloads.WeaponsDownload.GetTransform()]

                        #  Navigation Download
                        if:
                            SelectedTask = Task.NavDownload
                            MapIndicator.TeleportTo[Downloads.NavDownload.GetTransform()]

                        # Electric Download
                        if:
                            SelectedTask = Task.ElectricalDownload
                            MapIndicator.TeleportTo[Downloads.ElectricalDownload.GetTransform()]

                        # Admin Swipe
                        if:
                            SelectedTask = Task.AdminSwipe
                            MapIndicator.TeleportTo[Swipes.AdminSwipe.Button.GetTransform()]

                        # Electrical Swipe
                        if:
                            SelectedTask = Task.ElectricalSwipe
                            MapIndicator.TeleportTo[Swipes.ElectricalSwipe.Button.GetTransform()]

                        # Electrical Calibrate
                        if:
                            SelectedTask = Task.ElectricalCalibration
                            MapIndicator.TeleportTo[Swipes.ElectricalCalibration.Button.GetTransform()]

                        # Lower Engine Swipe
                        if:
                            SelectedTask = Task.LowerEngineSwipe
                            MapIndicator.TeleportTo[Swipes.LowerEngineSwipe.Button.GetTransform()]

                        # Navigation Swipe
                        if:
                            SelectedTask = Task.NavigationSwipe
                            MapIndicator.TeleportTo[Swipes.NavigationSwipe.Button.GetTransform()]

                        # Weapons Shooting
                        if:
                            SelectedTask = Task.WeaponsShooting
                            MapIndicator.TeleportTo[WeaponsShooting.MutatorZone.GetTransform()]

                        # Fuel
                        if:
                            SelectedTask = Task.StorageFuel
                            MapIndicator.TeleportTo[Fuel.Refuel.GetTransform()]


    HandleTargetHit(MaybeAgent: ?agent): void=
        if(Agent := agent[MaybeAgent?]):
            if(SelectedTargetsHit := TargetsHit[Agent]):
            else if(set TargetsHit[Agent] = 0):
                
            if:
                SelectedTargetsHit := TargetsHit[Agent]
                SelectedTargetsHit <> 20

                set TargetsHit[Agent] += 1

                SelectedTextBlock := PlayerTasksCanvas[Agent].TextBlocks[Task.WeaponsShooting]
            then:
                SelectedTextBlock.SetText(StringToMessage("Weapons: Shooting ({SelectedTargetsHit + 1}/20)"))

                if(SelectedTargetsHit + 1 = 20):
                    OnTaskComplete(Agent, Task.WeaponsShooting)
                
    HandleSwipeTask(Agent: agent, SelectedTask: Task): void=
        OnTaskComplete(Agent, SelectedTask)

    HandleRefuelTask(Agent: agent): void=
        if:
            SelectedTextBlock := PlayerTasksCanvas[Agent].TextBlocks[Task.StorageFuel]
            SelectedMapIndicator := PlayerTasksMapIndicators[Agent][Task.StorageFuel]
        then:
            SelectedTextBlock.SetTextColor(Yellow)

            if(CurrentFuelTask = FuelTask.RefuelFirst):
                set CurrentFuelTask = FuelTask.UpperEngine
                SelectedTextBlock.SetText(StringToMessage("Upper Engine: Fuel (0/2)"))
                
                if(SelectedMapIndicator.TeleportTo[Fuel.UpperEngine.GetTransform()]):
            else if(CurrentFuelTask = FuelTask.RefuelSecond):
                set CurrentFuelTask = FuelTask.LowerEngine
                SelectedTextBlock.SetText(StringToMessage("Lower Engine: Fuel (1/2)"))

                if(SelectedMapIndicator.TeleportTo[Fuel.LowerEngine.GetTransform()]):

    HandleUpperEngineFuelTask(Agent: agent): void=
        if:
            SelectedTextBlock := PlayerTasksCanvas[Agent].TextBlocks[Task.StorageFuel]
            SelectedMapIndicator := PlayerTasksMapIndicators[Agent][Task.StorageFuel]
        then:
            if(CurrentFuelTask = FuelTask.UpperEngine):
                set CurrentFuelTask = FuelTask.RefuelSecond
                SelectedTextBlock.SetText(StringToMessage("Storage: Fuel (1/2)"))

                if(SelectedMapIndicator.TeleportTo[Fuel.Refuel.GetTransform()]):

    HandleLowerEngineFuelTask(Agent: agent): void=
        if:
            SelectedTextBlock := PlayerTasksCanvas[Agent].TextBlocks[Task.StorageFuel]
            SelectedMapIndicator := PlayerTasksMapIndicators[Agent][Task.StorageFuel]
        then:
            if(CurrentFuelTask = FuelTask.LowerEngine):
                SelectedTextBlock.SetText(StringToMessage("Lower Engine: Fuel (2/2)"))
                OnTaskComplete(Agent, Task.StorageFuel)

                SelectedMapIndicator.Disable()

    HandleDownloadTask(Agent: agent, SelectedTask: Task): void=
        var IsUploading: logic = false

        if(SelectedTask = Task.AdminUpload):
            set IsUploading = true
        else:
            set IsUploading = false

        spawn:
            OnDownload(Agent, SelectedTask, IsUploading)

    TotalTaskUI()<suspends>: void=
        for(Player -> CustomPlayer : CustomPlayers):
            if:
                FortCharacter := Player.GetFortCharacter[]
                Agent := FortCharacter.GetAgent[]
                PlayerUI := GetPlayerUI[Player]

                set TotalTasksText[Agent] = text_block{DefaultTextColor := White, DefaultJustification := text_justification.Center}
                SelectedTaskText := TotalTasksText[Agent]
            then:
                SelectedTaskText.SetText(StringToMessage("Total Tasks Completed: 0%"))
                
                var Canvas: canvas= canvas:
                    Slots := array{
                        canvas_slot:
                            Anchors :=  anchors{Minimum := vector2{X := 0.5, Y := 0.0}, Maximum := vector2{X := 0.5, Y := 0.0}}
                            Offsets := margin{Left := 0.0, Top := 110.0 , Right := 0.0, Bottom := 0.0}
                            Alignment := vector2{X := 0.5, Y := 0.5}
                            ZOrder := 1
                            SizeToContent := false
                            Widget := SelectedTaskText
                    }

                PlayerUI.AddWidget(Canvas)

                for(CreativeObject : FindCreativeObjectsWithTag(GameManagerTag{})):
                    if(GameManager := game_manager_device[CreativeObject]):
                        GameManager.GameEnded.Await()
                        PlayerUI.RemoveWidget(Canvas)

    TasksUI()<suspends>: void=
        for(Player -> CustomPlayer : CustomPlayers):
            if:
                CustomPlayer.IsImposter = false

                FortCharacter := Player.GetFortCharacter[]
                Agent := FortCharacter.GetAgent[]
                set PlayerTasksCanvas[Agent] = task_ui{}
                SelectedCanvas := PlayerTasksCanvas[Agent]
                PlayerUI := GetPlayerUI[Player]
            then:
                var TitleText: text_block = text_block{DefaultText := StringToMessage("Tasks:"), DefaultTextColor := White}
                
                var Slots: []canvas_slot = array{
                    canvas_slot:
                        Anchors :=  anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 0.0, Y := 0.0}}
                        Offsets := margin{Left := 15.0, Top := 15.0, Right := 550.0, Bottom := 380.0}
                        Alignment := vector2{X := 0.0, Y := 0.0}
                        ZOrder := 0
                        SizeToContent := false
                        Widget := SelectedCanvas.BackgroundImage
                    canvas_slot:
                        Anchors :=  anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 0.0, Y := 0.0}}
                        Offsets := margin{Left := 35.0, Top := 35.0 , Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.0, Y := 0.0}
                        ZOrder := 1
                        SizeToContent := false
                        Widget := TitleText
                }

                var TextBlockIndex: int = 0

                for(CustomTask -> CustomTaskComplete : CustomPlayer.Tasks.TaskList):
                    if(SelectedTaskString := TaskString[CustomTask]):
                        var TextBlock : text_block = text_block{DefaultText := StringToMessage(SelectedTaskString), DefaultTextColor := White}

                        set Slots += array{
                            canvas_slot:
                                Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 0.0, Y := 0.0}}
                                Offsets := margin{Left := 35.0, Top := 90.0 + (TextBlockIndex * 40.0), Right := 0.0, Bottom := 0.0}
                                Alignment := vector2{X := 0.0, Y := 0.0}
                                ZOrder := 1
                                SizeToContent := false
                                Widget := TextBlock
                        }

                        if(set SelectedCanvas.TextBlocks[CustomTask] = TextBlock):
                        set TextBlockIndex += 1

                set SelectedCanvas.Canvas = canvas{ Slots := Slots }

                PlayerUI.AddWidget(SelectedCanvas.Canvas)

                for(CreativeObject : FindCreativeObjectsWithTag(GameManagerTag{})):
                    if(GameManager := game_manager_device[CreativeObject]):
                        GameManager.GameEnded.Await()
                        PlayerUI.RemoveWidget(SelectedCanvas.Canvas)

    OnDownload(Agent: agent, SelectedTask: Task, Uploading: logic)<suspends>: void=
        set DownloadTaskComplete = false

        if:
            Player := player[Agent]
            PlayerUI := GetPlayerUI[Player]
        then:
            var Canvas: canvas = canvas{}
            var BackgroundImage: texture_block = texture_block{DefaultImage := Images.TabletBackground}
            var Text: text_block = text_block{DefaultJustification := text_justification.Center}

            if(Uploading = true):
                Text.SetText(StringToMessage("Uploading."))
            else:
                Text.SetText(StringToMessage("Downloading."))

            set Canvas = canvas:
                Slots := array{
                    canvas_slot:
                        Anchors :=  anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                        Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.0, Y := 0.0}
                        ZOrder := 0
                        SizeToContent := false
                        Widget := BackgroundImage
                    canvas_slot:
                        Anchors :=  anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        ZOrder := 1
                        SizeToContent := false
                        Widget := Text
                }

            PlayerUI.AddWidget(Canvas, player_ui_slot{InputMode := ui_input_mode.All})

            spawn:
                UpdateDownloadText(Text, Uploading)            

            Sleep(10.0)

            PlayerUI.RemoveWidget(Canvas)
            set DownloadTaskComplete = true

            if:
                Uploading = true
                SelectedDownloadTask := DownloadsCompleted[Agent][0]
            then:
                OnTaskComplete(Agent, SelectedDownloadTask)

                if:
                    NewArray := DownloadsCompleted[Agent].RemoveElement[0]
                    set DownloadsCompleted[Agent] = NewArray

                    SelectedTextBlock := PlayerTasksCanvas[Agent].TextBlocks[SelectedDownloadTask]
                    SelectedMapIndicator := PlayerTasksMapIndicators[Agent][SelectedTask]
                then:
                    SelectedTextBlock.SetText(StringToMessage("Admin: Upload (2/2)"))

                    if:
                        DownloadsCompleted[Agent].Length > 0
                    then:
                        SelectedMapIndicator.Enable()
            else if:
                SelectedMapIndicator := PlayerTasksMapIndicators[Agent][SelectedTask]
                SelectedTextBlock := PlayerTasksCanvas[Agent].TextBlocks[SelectedTask]

                set DownloadsCompleted[Agent] = array{}
                set DownloadsCompleted[Agent] += array{SelectedTask}
            then:
                SelectedTextBlock.SetText(StringToMessage("Admin: Upload (1/2)"))
                SelectedTextBlock.SetTextColor(Yellow)

                # Admin Download
                if:
                    SelectedMapIndicator.TeleportTo[Downloads.AdminUpload.GetTransform()]


    OnTaskComplete(Agent: agent, SelectedTask: Task): void=
        var TasksPercentage: int = 0
        Print(AgentToMessage(Agent, ""))

        if:
            Player := player[Agent]

            SelectedTextBlock := PlayerTasksCanvas[Agent].TextBlocks[SelectedTask]
            SelectedTaskString := TaskString[SelectedTask]
            SelectedMapIndicator := PlayerTasksMapIndicators[Agent][SelectedTask]

            CustomPlayer := CustomPlayers[Player]
            set CustomPlayer.Tasks.TaskList[SelectedTask] = true
        then:
            SelectedTextBlock.SetTextColor(Green)
            SelectedMapIndicator.Disable()

            if:
                set TotalTasksCompleted += 1.0
                TaskPercentage := Round[(TotalTasksCompleted / TotalTasksAmount) * 100]
            then:
                set TasksPercentage = TaskPercentage

                if(TasksPercentage = 100):
                    for(CreativeObject : FindCreativeObjectsWithTag(GameManagerTag{})):
                        if(GameManager := game_manager_device[CreativeObject]):
                            spawn:
                                GameManager.HandleEndGame(true)

            if:
                CurrentPlayerStats := PlayerStatsManager.GetPlayerStats[Agent]
            then:
                PlayerStatsManager.RecordPlayerStat(Agent, StatType.TasksCompleted, 1)

        for(Player -> CustomPlayer : CustomPlayers):
            if:
                FortCharacter := Player.GetFortCharacter[]
                PlayerAgent := FortCharacter.GetAgent[]
                SelectedTotalTaskText := TotalTasksText[PlayerAgent]
            then:
                SelectedTotalTaskText.SetText(StringToMessage("Total Tasks Completed: {TasksPercentage}%"))

    UpdateDownloadText(Text: text_block, Uploading: logic)<suspends>: void=
        var Index : int = 1
        var States : []string = array{}

        if(Uploading = true):
            set States = array{
                "Uploading.",
                "Uploading..",
                "Uploading..."
            }
        else: 
            set States = array{
                "Downloading.",
                "Downloading..",
                "Downloading..."
            }

        loop:
            if(DownloadTaskComplete = true):
                set Index = 0
                break

            if(CurrentState := States[Index]):
                Text.SetText(StringToMessage(CurrentState))

                if(Index = 2):
                    set Index = 0
                else:
                    set Index += 1

                Sleep(1.0)



        
      
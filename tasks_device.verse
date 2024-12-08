
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors/NamedColors }

TargetHitHandler := class:
    Device: tasks_device   
    Agent: agent

    HitTask(): void=
        Device.HandleTargetHit(Agent)

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

Task := enum{AdminDownload, CaffeteriaDownload, CommunicationsDownload, ElectricalDownload, NavDownload, WeaponsDownload, AdminSwipe, ElectricalSwipe, ElectricalCalibration, LowerEngineSwipe, NavigationSwipe, WeaponsShooting }

TaskString : [Task]string = map{
    Task.AdminDownload => "Admin: Download",
    Task.CaffeteriaDownload => "Caffeteria: Download",
    Task.CommunicationsDownload => "Communications: Download",
    Task.ElectricalDownload => "Electrical: Download",
    Task.NavDownload => "Navigation: Download",
    Task.WeaponsDownload => "Weapons: Download",
    Task.AdminSwipe => "Admin: Swipe",
    Task.ElectricalSwipe => "Electrical: Swipe",
    Task.ElectricalCalibration => "Electrical: Calibration",
    Task.LowerEngineSwipe => "Lower Engine: Swipe",
    Task.NavigationSwipe => "Navigation: Swipe",
    Task.WeaponsShooting => "Weapons: Shooting (0/20)"
}

download_tasks := class<concrete>:
    @editable
    AdminDownload: button_device = button_device{}
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
    Tracker: tracker_device = tracker_device{}

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
    Targets: []shooting_range_target_track_device = array{}
    
player_class := class<concrete>:
    @editable 
    ClassSelector: class_and_team_selector_device = class_and_team_selector_device{}
    @editable 
    MapIndictators: []map_indicator_device = array{}

download_task := class<concrete>:
    @editable 
    Button: button_device = button_device{}

tasks_device := class(creative_device):
    @editable
    Downloads: download_tasks = download_tasks{}
    @editable
    PlayerClasses: []player_class = array{}
    @editable
    Swipes: card_swipes = card_swipes{}
    @editable
    WeaponsShooting: weapons_task = weapons_task{}

    PlayerStatsManager: player_stats_manager = player_stats_manager{}
    var CustomPlayers: [player]custom_player = map{}
    var DownloadTaskComplete: logic = false
    var PlayerTasksCanvas: [agent]task_ui = map{}
    var PlayerTasksMapIndicators: [agent][Task]map_indicator_device = map{}
    var TotalTasksText: [agent]text_block = map{}
    var TotalTasksCompleted: float = 0.0
    var TotalTasksAmount: float = 0.0
    var TargetsHit: [agent]int = map{}

    TaskList: [int][]Task = map{
        10 => array{Task.AdminSwipe, Task.ElectricalSwipe, Task.ElectricalCalibration, Task.LowerEngineSwipe, Task.WeaponsShooting}
        11 => array{Task.AdminSwipe, Task.ElectricalSwipe, Task.ElectricalCalibration, Task.LowerEngineSwipe, Task.WeaponsShooting}
    }

    OnBegin<override>()<suspends>:void=
        for(CreativeObject : FindCreativeObjectsWithTag(PlayerManagerTag{})):
            if(PlayerManager := player_manager_device[CreativeObject]):
                PlayerManager.PlayersSet.Await()
                set CustomPlayers = PlayerManager.CustomPlayers

        set TotalTasksAmount = CustomPlayers.Length * 5.0

        AssignTasks()
        TasksUI()
        TotalTaskUI()

    AssignTasks(): void=
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
                PlayerClass.ClassSelector.ChangeClass(Agent)

                for(Index -> SelectedTask : SelectedTasks):
                    if:
                        set CustomPlayer.Tasks.TaskList[SelectedTask] = false

                        MapIndicator := PlayerClass.MapIndictators[Index]
                        set PlayerTasksMapIndicators[Agent][SelectedTask] = MapIndicator
                    then:
                        MapIndicator.Enable()

                        # Admin Download
                        if:
                            SelectedTask = Task.AdminDownload
                            MapIndicator.TeleportTo[Downloads.AdminDownload.GetTransform()]
                            Downloads.AdminDownload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.AdminDownload}.DownloadTask)
                            
                        # Communications Download
                        if:
                            SelectedTask = Task.CommunicationsDownload
                            MapIndicator.TeleportTo[Downloads.CommunicationsDownload.GetTransform()]
                            Downloads.CommunicationsDownload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.CommunicationsDownload}.DownloadTask)

                        # Caffeteria Download
                        if:
                            SelectedTask = Task.CaffeteriaDownload
                            MapIndicator.TeleportTo[Downloads.CaffeteriaDownload.GetTransform()]
                            Downloads.CaffeteriaDownload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.CaffeteriaDownload}.DownloadTask)

                        # Weapons Download
                        if:
                            SelectedTask = Task.WeaponsDownload
                            MapIndicator.TeleportTo[Downloads.WeaponsDownload.GetTransform()]
                            Downloads.WeaponsDownload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.WeaponsDownload}.DownloadTask)

                        #  Navigation Download
                        if:
                            SelectedTask = Task.NavDownload
                            MapIndicator.TeleportTo[Downloads.NavDownload.GetTransform()]
                            Downloads.NavDownload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.NavDownload}.DownloadTask)

                        # Electric Download
                        if:
                            SelectedTask = Task.ElectricalDownload
                            MapIndicator.TeleportTo[Downloads.ElectricalDownload.GetTransform()]
                            Downloads.ElectricalDownload.InteractedWithEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.ElectricalDownload}.DownloadTask)

                        # Admin Swipe
                        if:
                            SelectedTask = Task.AdminSwipe
                            MapIndicator.TeleportTo[Swipes.AdminSwipe.Button.GetTransform()]
                            Swipes.AdminSwipe.Tracker.CompleteEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.AdminSwipe}.SwipeTask)

                        # Electrical Swipe
                        if:
                            SelectedTask = Task.ElectricalSwipe
                            MapIndicator.TeleportTo[Swipes.ElectricalSwipe.Button.GetTransform()]
                            Swipes.ElectricalSwipe.Tracker.CompleteEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.ElectricalSwipe}.SwipeTask)

                        # Electrical Calibrate
                        if:
                            SelectedTask = Task.ElectricalCalibration
                            MapIndicator.TeleportTo[Swipes.ElectricalCalibration.Button.GetTransform()]
                            Swipes.ElectricalCalibration.Tracker.CompleteEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.ElectricalCalibration}.SwipeTask)

                        # Lower Engine Swipe
                        if:
                            SelectedTask = Task.LowerEngineSwipe
                            MapIndicator.TeleportTo[Swipes.LowerEngineSwipe.Button.GetTransform()]
                            Swipes.LowerEngineSwipe.Tracker.CompleteEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.LowerEngineSwipe}.SwipeTask)

                        # Navigation Swipe
                        if:
                            SelectedTask = Task.NavigationSwipe
                            MapIndicator.TeleportTo[Swipes.NavigationSwipe.Button.GetTransform()]
                            Swipes.NavigationSwipe.Tracker.CompleteEvent.Subscribe(TaskHandler{Device := Self, SelectedTask := Task.NavigationSwipe}.SwipeTask)

                        # Weapons Shooting
                        if:
                            SelectedTask = Task.WeaponsShooting
                            MapIndicator.TeleportTo[WeaponsShooting.MutatorZone.GetTransform()]
                        then:
                            for (Target : WeaponsShooting.Targets):
                                Target.HitEvent.Subscribe(TargetHitHandler{Device := Self, Agent := Agent}.HitTask)

    HandleTargetHit(Agent: agent): void=
        if:
            SelectedTargetsHit := TargetsHit[Agent]
        else if(set TargetsHit[Agent] = 0):
             
        if:
            SelectedTargetsHit := TargetsHit[Agent]
            SelectedTargetsHit <> 20

            set TargetsHit[Agent] += 1

            SelectedCanvas := PlayerTasksCanvas[Agent]
            SelectedTextBlock := SelectedCanvas.TextBlocks[Task.WeaponsShooting]
        then:
            SelectedTextBlock.SetText(StringToMessage("Weapons: Shooting ({SelectedTargetsHit + 1}/20)"))

            if(SelectedTargetsHit + 1 = 20):
                OnTaskComplete(Agent, Task.WeaponsShooting)

    HandleSwipeTask(Agent: agent, SelectedTask: Task): void=
        OnTaskComplete(Agent, SelectedTask)

    HandleDownloadTask(Agent: agent, SelectedTask: Task): void=
        spawn:
            OnDownload(Agent, SelectedTask)

    TotalTaskUI(): void=
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

    TasksUI(): void=
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
                                Anchors :=  anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 0.0, Y := 0.0}}
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

    OnDownload(Agent: agent, SelectedTask: Task)<suspends>: void=
        set DownloadTaskComplete = false

        if:
            Player := player[Agent]
            PlayerUI := GetPlayerUI[Player]
        then:
            var Canvas: canvas = canvas{}
            var BackgroundImage: texture_block = texture_block{DefaultImage := Images.TabletBackground}
            var Text: text_block = text_block{DefaultText := StringToMessage("Downloading."), DefaultJustification := text_justification.Center}

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
                UpdateDownloadText(Text)            

            Sleep(10.0)

            PlayerUI.RemoveWidget(Canvas)
            set DownloadTaskComplete = true

            OnTaskComplete(Agent, SelectedTask)

    OnTaskComplete(Agent: agent, SelectedTask: Task): void=
        if:
            Player := player[Agent]

            SelectedCanvas := PlayerTasksCanvas[Agent]
            SelectedTextBlock := SelectedCanvas.TextBlocks[SelectedTask]

            SelectedTaskString := TaskString[SelectedTask]
            SelectedMapIndicator := PlayerTasksMapIndicators[Agent][SelectedTask]

            CustomPlayer := CustomPlayers[Player]
            set CustomPlayer.Tasks.TaskList[SelectedTask] = true

            SelectedTotalTaskText := TotalTasksText[Agent]
        then:
            SelectedTextBlock.SetTextColor(Green)
            SelectedMapIndicator.Disable()

            if:
                set TotalTasksCompleted += 1.0
                TaskPercentage := Round[(TotalTasksCompleted / TotalTasksAmount) * 100]
            then:
                SelectedTotalTaskText.SetText(StringToMessage("Total Tasks Completed: {TaskPercentage}%"))

            if:
                # Get players current stats
                CurrentPlayerStats := PlayerStatsManager.GetPlayerStats[Agent]
            then:
                PlayerStatsManager.RecordPlayerStat(Agent, StatType.TasksCompleted, 1)
                Print("{CurrentPlayerStats.TasksCompleted + 1}")

    UpdateDownloadText(Text: text_block)<suspends>: void=
        var Index : int = 1
        var States : []string = array{
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



        
      
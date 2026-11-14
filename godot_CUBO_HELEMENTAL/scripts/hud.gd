class_name GameHUD
extends CanvasLayer

signal restart_requested

@onready var timer_label: Label = $TopBar/TimerLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var minimap: Control = $MinimapContainer/MiniMap
@onready var crosshair: Control = $Crosshair
@onready var controls_hint: Label = $ControlsHint

# Panel de Victoria
@onready var victory_panel: PanelContainer = $VictoryPanel
@onready var victory_time_label: Label = $VictoryPanel/VBox/VictoryTimeLabel
@onready var victory_lives_label: Label = $VictoryPanel/VBox/VictoryLivesLabel
@onready var restart_button: Button = $VictoryPanel/VBox/Buttons/RestartBtn
@onready var continue_button: Button = $VictoryPanel/VBox/Buttons/ContinueBtn

# Panel de Game Over
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var retry_button: Button = $GameOverPanel/VBox/RetryBtn

var _time_elapsed: float = 0.0
var _timer_running: bool = true
var _current_lives: int = 3
var _max_lives: int = 3

func _ready() -> void:
	victory_panel.visible = false
	game_over_panel.visible = false
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if retry_button:
		retry_button.pressed.connect(_on_restart_pressed)
	update_lives(3, 3)

func _process(delta: float) -> void:
	if _timer_running:
		_time_elapsed += delta
		var minutes: int = int(_time_elapsed) / 60
		var seconds: int = int(_time_elapsed) % 60
		var millis: int = int((_time_elapsed - int(_time_elapsed)) * 10)
		timer_label.text = "⏱️ Tiempo: %02d:%02d.%d" % [minutes, seconds, millis]

func update_lives(current: int, maximum: int = 3) -> void:
	_current_lives = current
	_max_lives = maximum
	var text: String = ""
	for i in range(maximum):
		if i < current:
			text += "❤️"
		else:
			text += "🖤"
	lives_label.text = "%s Vidas: %d/%d" % [text, current, maximum]

func toggle_minimap() -> void:
	if minimap:
		minimap.visible = not minimap.visible

func toggle_solution() -> void:
	if minimap and minimap.has_method("toggle_solution"):
		minimap.toggle_solution()

func show_victory() -> void:
	_timer_running = false
	var minutes: int = int(_time_elapsed) / 60
	var seconds: int = int(_time_elapsed) % 60
	var millis: int = int((_time_elapsed - int(_time_elapsed)) * 100)
	victory_time_label.text = "Tiempo: %02d:%02d.%02d" % [minutes, seconds, millis]
	
	var hearts: String = ""
	for i in range(_max_lives):
		hearts += "❤️" if i < _current_lives else "🖤"
	victory_lives_label.text = "Vidas conservadas: %s (%d/%d)" % [hearts, _current_lives, _max_lives]
	
	victory_panel.visible = true
	game_over_panel.visible = false

func show_game_over() -> void:
	_timer_running = false
	game_over_panel.visible = true
	victory_panel.visible = false

func reset_timer() -> void:
	_time_elapsed = 0.0
	_timer_running = true
	victory_panel.visible = false
	game_over_panel.visible = false

func _on_restart_pressed() -> void:
	victory_panel.visible = false
	game_over_panel.visible = false
	reset_timer()
	restart_requested.emit()

func _on_continue_pressed() -> void:
	victory_panel.visible = false

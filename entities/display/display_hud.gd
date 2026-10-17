class_name DisplayHud
extends CanvasLayer


@onready var chain_size_label: Label = %ChainSize
@onready var loop_red_label: Label = %LoopRed
@onready var loop_yellow_label: Label = %LoopYellow
@onready var loop_green_label: Label = %LoopGreen
@onready var loop_blue_label: Label = %LoopBlue
@onready var gobble_count_label: Label = %GobbleCount
@onready var phase_label: Label = %PhaseLabel
@onready var result_screen: Label = %ResultScreen

var data: DisplayData:
	set(value_):
		data = value_
		connect_signals()


func _ready() -> void:
	if data != null:
		_on_display_changed()


func connect_signals() -> void:
	if data == null:
		return
	if not data.display_changed.is_connected(_on_display_changed):
		data.display_changed.connect(_on_display_changed)
	_on_display_changed()


func _on_display_changed() -> void:
	if data == null or chain_size_label == null:
		return
	chain_size_label.text = str(data.chain_size)
	loop_red_label.text = str(data.loop_red)
	loop_yellow_label.text = str(data.loop_yellow)
	loop_green_label.text = str(data.loop_green)
	loop_blue_label.text = str(data.loop_blue)
	gobble_count_label.text = str(data.gobble_count)
	if data.forced_hint:
		gobble_count_label.text = "%s  Заполните gobble" % gobble_count_label.text
	phase_label.text = Bozo.enum_to_string(Bozo.Type.PHASE, data.phase)
	var result_name_ := Bozo.enum_to_string(Bozo.Type.RESULT, data.result)
	result_screen.visible = result_name_ != "none"
	result_screen.text = result_name_

extends ProgressBar

var active = true

var box := self.get_theme_stylebox("background")
var fill := self.get_theme_stylebox("fill")

func _ready() -> void:
	box.bg_color = Color(0.2,0.2,0.2)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.is_pressed():
		active = !active
		if active:
			box.bg_color = Color(0.2,0.2,0.2)
		else:
			box.bg_color = Color(0.1,0.1,0.1)

func new_value(newvalue: float):
	if newvalue < 0:
		fill.bg_color = Color(0.2,0.5,1)
		fill_mode = 2
		value = -newvalue
	else:
		fill.bg_color = Color(1,0.6,0.2)
		fill_mode = 3
		value = newvalue

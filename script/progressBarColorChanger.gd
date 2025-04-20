extends ProgressBar

var active = true

var box := self.get_theme_stylebox("background")

func _ready() -> void:
	box.bg_color = Color(0.2,0.2,0.2)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.is_pressed():
		active = !active
		if active:
			box.bg_color = Color(0.2,0.2,0.2)
		else:
			box.bg_color = Color(0.1,0.1,0.1)

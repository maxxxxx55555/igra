extends Control

func _ready() -> void:
	add_to_group("ui_root")
	$VBox/Retry.pressed.connect(func(): Routes.restart_game())
	$VBox/Menu.pressed.connect(func(): Routes.to_menu())
	_add_revive_button()

## Step 5: rewarded-ad revive, once per session (AdService.can_show_reward
## already enforces that + the shared 15-min ad cooldown). Built in code
## like the rest of this scene's dynamic bits — no .tscn edit needed.
func _add_revive_button() -> void:
	if not AdService.can_show_reward(&"revive"):
		return
	var vb: VBoxContainer = $VBox
	var btn := Button.new()
	btn.text = LocalizationManager.t("AD_REVIVE")
	btn.pressed.connect(func() -> void:
		btn.disabled = true
		AdService.show_rewarded(&"revive"))
	vb.add_child(btn)
	vb.move_child(btn, 1)
	AdService.reward_granted.connect(func(reward_id: StringName, _amount: int) -> void:
		if reward_id == &"revive":
			btn.visible = false)

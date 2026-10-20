extends RefCounted
## W1 of docs/VISUAL_PASS.md section 8: the environment preset of the profile (assets/env/night_environment_<mobile|desktop>.tres) copied key by key onto the live environment.
## Not copied: the sky and the background (the scene's own panorama is tuned to a lower energy), the ambient light (the stage of the district owns it), the tone mapper (the table of the graphics
## tier owns it) and the screen-space effects the Compatibility renderer does not have (SSAO, SSIL, SSR, volumetric fog).

const SKIPPED: Array[String] = ["sky", "background", "ambient_light", "tonemap_mode", "ssao", "ssil", "ssr", "volumetric_fog", "resource_", "script", "sdfgi"]

static func profile() -> String:
	return "mobile" if OS.has_feature("mobile") else "desktop"

## The number of keys copied (0 when the preset is missing).
static func apply(env: Environment) -> int:
	var preset := load("res://assets/env/night_environment_%s.tres" % profile()) as Environment
	if preset == null:
		return 0
	var copied: int = 0
	for prop: Dictionary in preset.get_property_list():
		var key: String = prop["name"]
		if (int(prop["usage"]) & PROPERTY_USAGE_STORAGE) == 0 or SKIPPED.any(func(skip: String) -> bool: return key.begins_with(skip)):
			continue
		env.set(key, preset.get(key))
		copied += 1
	return copied

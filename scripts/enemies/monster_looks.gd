extends RefCounted
## Look and gait of the twelve monsters (the ids of data/monsters/*.tres). Metres, y up from the feet, forward is -Z; monster_rig.gd builds and moves it.
## body, head: [shape, a, b, c, centre y, centre z]; cyl = top radius, bottom radius, height; box = width, height, depth; sph = radius.
## legs, arms: [count, thickness, length, spread x, joint y, joint z]; four legs stand at z = -joint z and +joint z (a quadruped), two at 0.
## form: optional, read by scripts/art/monster_meshes.gd (shoulder, pelvis, depth, waist, belly, hunch, plates of a torso; loin, chest, abdomen, arch of a quadruped; jaw, eye, faceless of a head; arm_bend, leg_bend, claw, fist of the limbs; cloak, hem of a funnel body).
## gait: s stride in m per cycle, kl and ka leg and arm swing (kl x the angle that plants the foot, ka in rad), pitch lean, roll shoulder roll, list permanent tilt (rad),
## bob in m, jit phase jitter, asym the second leg's share of the swing, hold pose plateau 0..1, air tuck in rad, rest the arms' angle at rest, stagger a lurch every n seconds.

const LOOKS: Dictionary = {
	&"rotter": {"tint": Color(0.10, 0.10, 0.08), "form": {"shoulder": 1.35, "depth": 0.62, "waist": 0.78, "hunch": 0.3, "jaw": 0.35, "arm_bend": 0.35, "claw": 0.1, "leg_bend": 0.3}, "body": ["cyl", 0.42, 0.5, 1.0, 1.0, 0.0], "head": ["sph", 0.2, 0.0, 0.0, 1.62, -0.2],
		"legs": [2, 0.2, 0.75, 0.22, 0.75, 0.0], "arms": [2, 0.14, 0.95, 0.52, 1.5, -0.05],
		"gait": {"s": 1.1, "kl": 1.0, "ka": 0.5, "pitch": 0.3, "list": 0.14, "bob": 0.02, "asym": 0.4}},
	&"crawler": {"tint": Color(0.07, 0.07, 0.09), "form": {"loin": 0.6, "abdomen": 1.25, "chest": 0.8, "arch": 0.35, "jaw": 0.5, "leg_bend": 1.6}, "body": ["box", 0.55, 0.28, 0.95, 0.38, 0.0], "head": ["box", 0.26, 0.2, 0.26, 0.34, -0.58],
		"legs": [4, 0.07, 0.38, 0.3, 0.38, 0.28], "arms": [0, 0.0, 0.0, 0.0, 0.0, 0.0],
		"gait": {"s": 0.8, "kl": 1.7, "pitch": 0.35, "bob": 0.012}},
	&"hound": {"tint": Color(0.09, 0.08, 0.07), "form": {"loin": 0.55, "chest": 1.1, "abdomen": 0.75, "arch": 0.12, "leg_bend": 1.1}, "body": ["box", 0.38, 0.38, 0.95, 0.62, 0.0], "head": ["box", 0.22, 0.22, 0.4, 0.7, -0.66],
		"legs": [4, 0.1, 0.46, 0.14, 0.46, 0.32], "arms": [0, 0.0, 0.0, 0.0, 0.0, 0.0],
		"gait": {"s": 2.4, "kl": 1.3, "pitch": 0.04, "bob": 0.07, "air": 0.7}},
	&"hunter": {"tint": Color(0.06, 0.07, 0.09), "form": {"shoulder": 1.3, "depth": 0.7, "waist": 0.85, "hunch": 0.06, "jaw": 0.15, "arm_bend": 0.15, "claw": 0.06, "leg_bend": 0.15}, "body": ["cyl", 0.2, 0.24, 0.8, 1.1, 0.0], "head": ["box", 0.18, 0.24, 0.2, 1.6, 0.0],
		"legs": [2, 0.12, 0.72, 0.15, 0.72, 0.0], "arms": [2, 0.09, 0.9, 0.3, 1.4, 0.0],
		"gait": {"s": 1.9, "kl": 0.9, "ka": 0.8, "pitch": 0.05, "bob": 0.015}},
	&"brute": {"tint": Color(0.09, 0.07, 0.06), "form": {"shoulder": 1.25, "pelvis": 0.5, "depth": 0.85, "waist": 0.9, "hunch": 0.2, "jaw": 0.3, "arm_bend": 0.2, "fist": 1.6, "leg_bend": 0.1}, "body": ["box", 1.1, 1.0, 0.65, 1.3, 0.0], "head": ["sph", 0.22, 0.0, 0.0, 1.95, -0.08],
		"legs": [2, 0.26, 0.8, 0.28, 0.8, 0.0], "arms": [2, 0.24, 1.0, 0.7, 1.75, 0.0],
		"gait": {"s": 1.3, "kl": 0.7, "ka": 0.6, "pitch": 0.06, "roll": 0.07, "bob": 0.04}},
	&"shadow": {"tint": Color(0.025, 0.025, 0.035), "form": {"cloak": 1, "hem": 0.18, "jaw": 0.1, "arm_bend": 0.5, "claw": 0.2}, "body": ["cyl", 0.04, 0.4, 1.0, 0.78, 0.0], "head": ["sph", 0.16, 0.0, 0.0, 1.22, -0.05],
		"legs": [2, 0.05, 0.3, 0.12, 0.3, 0.0], "arms": [2, 0.05, 0.8, 0.3, 1.05, 0.0],
		"gait": {"s": 3.0, "kl": 0.5, "ka": 0.1, "bob": 0.0}},
	&"watcher": {"tint": Color(0.08, 0.07, 0.07), "form": {"shoulder": 1.1, "depth": 0.7, "waist": 0.9, "eye": 1, "arm_bend": 0.3, "claw": 0.12}, "body": ["cyl", 0.16, 0.2, 0.9, 1.25, 0.0], "head": ["sph", 0.34, 0.0, 0.0, 1.7, 0.0],
		"legs": [2, 0.08, 0.8, 0.14, 0.8, 0.0], "arms": [2, 0.05, 0.6, 0.26, 1.55, 0.0],
		"gait": {"s": 2.0, "kl": 0.1, "ka": 0.05, "bob": 0.005}},
	&"burner": {"tint": Color(0.14, 0.07, 0.04), "form": {"shoulder": 1.25, "hunch": 0.22, "waist": 0.8, "arm_bend": 0.3, "claw": 0.12}, "body": ["cyl", 0.22, 0.26, 0.8, 1.2, 0.0], "head": ["sph", 0.18, 0.0, 0.0, 1.68, 0.0],
		"legs": [2, 0.12, 0.8, 0.18, 0.8, 0.0], "arms": [2, 0.1, 0.8, 0.34, 1.5, 0.0],
		"gait": {"s": 1.0, "kl": 1.1, "ka": 1.0, "pitch": 0.1, "jit": 0.3, "bob": 0.03}},
	&"sharpshooter": {"tint": Color(0.07, 0.08, 0.07), "form": {"shoulder": 1.3, "depth": 0.65, "waist": 0.85, "arm_bend": 0.1, "leg_bend": 0.12}, "body": ["cyl", 0.17, 0.21, 0.8, 1.2, 0.0], "head": ["box", 0.2, 0.22, 0.2, 1.72, 0.0],
		"legs": [2, 0.11, 0.8, 0.14, 0.8, 0.0], "arms": [2, 0.07, 0.85, 0.26, 1.5, 0.0],
		"gait": {"s": 1.7, "kl": 0.8, "ka": 0.0, "pitch": 0.03, "rest": -1.2}},
	&"tvar": {"tint": Color(0.09, 0.06, 0.06), "form": {"shoulder": 1.1, "depth": 0.9, "waist": 1.0, "belly": 0.3, "hunch": 0.28, "arm_bend": 0.4, "claw": 0.12, "leg_bend": 0.2}, "body": ["cyl", 0.5, 0.58, 1.0, 1.4, 0.0], "head": ["sph", 0.3, 0.0, 0.0, 2.1, -0.2],
		"legs": [2, 0.26, 0.9, 0.3, 0.9, 0.0], "arms": [2, 0.2, 1.3, 0.7, 1.8, 0.0],
		"gait": {"s": 1.4, "kl": 0.9, "ka": 0.7, "pitch": 0.25, "list": 0.1, "asym": 0.6, "stagger": 2.5, "bob": 0.04}},
	&"destroyer": {"tint": Color(0.07, 0.07, 0.08), "form": {"shoulder": 1.3, "pelvis": 0.55, "depth": 0.9, "waist": 0.95, "plates": 1, "arm_bend": 0.1, "leg_bend": 0.05, "jaw": 0.0}, "body": ["box", 1.0, 1.0, 0.7, 1.2, 0.0], "head": ["box", 0.34, 0.3, 0.34, 1.82, 0.0],
		"legs": [2, 0.28, 0.7, 0.28, 0.7, 0.0], "arms": [2, 0.26, 1.0, 0.65, 1.6, 0.0],
		"gait": {"s": 2.2, "kl": 0.5, "ka": 0.4, "hold": 0.6, "bob": 0.06}},
	&"boss": {"tint": Color(0.03, 0.03, 0.05), "form": {"shoulder": 1.45, "depth": 0.55, "waist": 0.7, "arm_bend": 0.25, "claw": 0.22, "leg_bend": 0.2, "jaw": 0.0, "faceless": 1}, "emit": Color(0.03, 0.0, 0.07), "body": ["cyl", 0.42, 0.55, 1.4, 1.7, 0.0], "head": ["sph", 0.3, 0.0, 0.0, 2.75, 0.0],
		"legs": [2, 0.3, 1.0, 0.3, 1.0, 0.0], "arms": [2, 0.2, 1.5, 0.7, 2.3, 0.0],
		"gait": {"s": 2.6, "kl": 0.5, "ka": 0.4, "roll": 0.08, "bob": 0.03}},
}

const DEFAULT_GAIT: Dictionary = {"s": 1.6, "kl": 1.0, "ka": 0.5, "pitch": 0.0, "roll": 0.0, "list": 0.0, "bob": 0.02, "jit": 0.0, "asym": 1.0, "hold": 0.0, "air": 0.0, "rest": 0.0, "stagger": 0.0}

## The look of a monster id; an id that has none (a scene built for a test) gets the rotter's.
static func look(id: StringName) -> Dictionary:
	return LOOKS.get(id, LOOKS[&"rotter"])

static func gait(id: StringName) -> Dictionary:
	return DEFAULT_GAIT.merged(look(id).get("gait", {}), true)

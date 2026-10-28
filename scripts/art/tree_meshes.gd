extends RefCounted
## The bare tree of the dead city: a trunk that forks three times into limbs and twigs, one mesh for every tree of a district. Its origin stands 0.9 m under the top of the trunk of street_props.gd (the trunk is 2.5 m high and its
## canopy is raised 3.4 m), so the limbs start where the trunk ends. Five-sided prisms with no caps, about 300 triangles; the foliage sway shader moves it like the canopy it replaces.

const SIDES: int = 5
const FORKS: int = 3
const SEED: int = 3601
const TRUNK_TOP_Y: float = -0.9

static func build() -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_limb(tool, rng, Vector3(0.0, TRUNK_TOP_Y, 0.0), Vector3.UP, 0.12, 1.0, 0, rng.randf() * TAU)
	return tool.commit()

## One limb and its forks: three at the first fork, two at the next, spread round the limb, and one side twig on the first two limbs.
static func _limb(tool: SurfaceTool, rng: RandomNumberGenerator, from: Vector3, dir: Vector3, radius: float, length: float, depth: int, azimuth: float) -> void:
	var to: Vector3 = from + dir * length
	_prism(tool, from, to, radius, radius * 0.6)
	if depth >= FORKS:
		return
	var forks: int = 3 if depth == 0 else 2
	for i in forks:
		_limb(tool, rng, to - dir * length * 0.08, _bend(rng, dir, azimuth + TAU * i / forks + rng.randf_range(-0.3, 0.3)), radius * 0.6, length * 0.74, depth + 1, rng.randf() * TAU)
	if depth < 2:
		_limb(tool, rng, from + dir * length * 0.55, _bend(rng, dir, azimuth + PI * 0.5), radius * 0.45, length * 0.5, depth + 2, rng.randf() * TAU)

## The direction of a child: the parent's turned by 30 to 55 degrees toward the azimuth round it, and never down.
static func _bend(rng: RandomNumberGenerator, dir: Vector3, azimuth: float) -> Vector3:
	var across: Vector3 = dir.cross(Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.FORWARD).normalized().rotated(dir, azimuth)
	var bent: Vector3 = dir.rotated(across, rng.randf_range(0.5, 0.95))
	bent.y = maxf(bent.y, 0.12)
	return bent.normalized()

static func _prism(tool: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float) -> void:
	var dir: Vector3 = (b - a).normalized()
	var u: Vector3 = dir.cross(Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.FORWARD).normalized()
	var v: Vector3 = dir.cross(u)
	for k in SIDES:
		var n0: Vector3 = u * cos(TAU * k / SIDES) + v * sin(TAU * k / SIDES)
		var n1: Vector3 = u * cos(TAU * (k + 1) / SIDES) + v * sin(TAU * (k + 1) / SIDES)
		_tri(tool, a + n0 * r0, n0, a + n1 * r0, n1, b + n0 * r1, n0)
		_tri(tool, a + n1 * r0, n1, b + n1 * r1, n1, b + n0 * r1, n0)

static func _tri(tool: SurfaceTool, p0: Vector3, n0: Vector3, p1: Vector3, n1: Vector3, p2: Vector3, n2: Vector3) -> void:
	tool.set_normal(n0)
	tool.add_vertex(p0)
	tool.set_normal(n1)
	tool.add_vertex(p1)
	tool.set_normal(n2)
	tool.add_vertex(p2)

extends RefCounted
## The relief of the facades of the visual recovery brief (section 05: real recesses, frames, base courses, ledges, pipes), the part that makes a block read as a building from the side and not as a box with painted
## squares. `dress` adds boxes to the Blocks batch of skyline.gd (base course, floor ledges, cornice, parapet, pilasters on the seams of the panels, drainpipes, a doorway with steps, now and then a stepped top);
## `window` decides what stands at one pane of the grid (a pane in its frame, boards, a bricked-up gap) and `frame_mesh` is the frame itself, one mesh drawn for every pane in a second batch. Every box is in
## the local frame of the block's front face: x along it from the middle, y up, z toward the street, the wall at z = 0.

static var _frame_mesh: ArrayMesh = null

## Two jambs, a lintel and a sill around the 0.9 x 1.3 m pane, standing 0.18 to 0.28 m off the wall: the pane, 0.04 m off it, reads as sunk into the wall from the side.
static func frame_mesh() -> ArrayMesh:
	if _frame_mesh == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_box(st, Vector3(-0.55, 0.0, 0.09), Vector3(0.07, 0.75, 0.09))
		_box(st, Vector3(0.55, 0.0, 0.09), Vector3(0.07, 0.75, 0.09))
		_box(st, Vector3(0.0, 0.76, 0.11), Vector3(0.64, 0.09, 0.11))
		_box(st, Vector3(0.0, -0.74, 0.14), Vector3(0.68, 0.05, 0.14))
		_frame_mesh = st.commit()
	return _frame_mesh

## True when the pane quad is to be drawn at `local` (a place of the window grid in the frame of the front face); a frame is added for every window that exists, boards over one in 16, and one in 16 is bricked up.
static func window(rng: RandomNumberGenerator, frame: Transform3D, local: Vector3, bone: Color, frames: Array[Transform3D], frame_tints: Array[Color], blocks: Array[Transform3D], tints: Array[Color]) -> bool:
	var roll := rng.randf()
	if roll < 0.0625:
		return false
	frames.append(frame * Transform3D(Basis(), local))
	frame_tints.append(bone if rng.randf() < 0.8 else bone.darkened(0.45))
	if roll < 0.125:
		_put(blocks, tints, frame, local + Vector3(0.0, 0.0, 0.14), Vector3(1.0, 1.4, 0.05), Color("#2a211b"))
		return false
	return true

static func dress(rng: RandomNumberGenerator, frame: Transform3D, size: Vector3, tint: Color, blocks: Array[Transform3D], tints: Array[Color]) -> void:
	var width := size.x
	var height := size.y
	var light := tint.lightened(0.16)
	var dark := tint.darkened(0.32)
	_put(blocks, tints, frame, Vector3(0.0, 0.5, 0.07), Vector3(width + 0.2, 1.0, 0.14), dark)
	var ledge := 3.25
	while ledge < height - 1.0:
		if rng.randf() < 0.75:
			_put(blocks, tints, frame, Vector3(0.0, ledge, 0.1), Vector3(width + 0.1, 0.18, 0.2), light)
		ledge += 5.2
	_put(blocks, tints, frame, Vector3(0.0, height - 0.2, 0.25), Vector3(width + 0.4, 0.4, 0.55), light)
	_put(blocks, tints, frame, Vector3(0.0, height + 0.25, -0.1), Vector3(width, 0.5, 0.25), tint)
	if rng.randf() < 0.65:
		var seam := 2.3 - width * 0.5
		while seam < width * 0.5 - 1.0:
			_put(blocks, tints, frame, Vector3(seam, height * 0.5, 0.07), Vector3(0.45, height, 0.14), light)
			seam += 4.4
	for side in [-1.0, 1.0]:
		_put(blocks, tints, frame, Vector3(side * (width * 0.5 - 0.4), height * 0.5, 0.12), Vector3(0.1, height - 0.4, 0.1), dark)
	var door := rng.randf_range(-width * 0.5 + 2.2, width * 0.5 - 2.2)
	_put(blocks, tints, frame, Vector3(door, 1.0, 0.05), Vector3(1.6, 2.0, 0.1), light)
	_put(blocks, tints, frame, Vector3(door, 0.95, 0.12), Vector3(1.25, 1.9, 0.06), Color("#0b0c0d"))
	_put(blocks, tints, frame, Vector3(door, 0.08, 0.4), Vector3(2.0, 0.16, 0.6), dark.lightened(0.1))
	if rng.randf() < 0.35:
		var top := rng.randf_range(2.4, 4.4)
		_put(blocks, tints, frame, Vector3(rng.randf_range(-0.2, 0.2) * width, height + top * 0.5, -size.z * 0.25), Vector3(width * 0.55, top, size.z * 0.5), tint.lightened(0.05))

static func _put(blocks: Array[Transform3D], tints: Array[Color], frame: Transform3D, at: Vector3, size: Vector3, tint: Color) -> void:
	blocks.append(frame * Transform3D(Basis.from_scale(size), at))
	tints.append(tint)

## An axis-aligned box with flat normals, front faces clockwise; `half` is half its size.
static func _box(st: SurfaceTool, centre: Vector3, half: Vector3) -> void:
	for face: Array in [[Vector3.RIGHT, Vector3.UP, Vector3.BACK], [Vector3.LEFT, Vector3.BACK, Vector3.UP], [Vector3.UP, Vector3.BACK, Vector3.RIGHT],
			[Vector3.DOWN, Vector3.RIGHT, Vector3.BACK], [Vector3.BACK, Vector3.RIGHT, Vector3.UP], [Vector3.FORWARD, Vector3.UP, Vector3.RIGHT]]:
		var n: Vector3 = face[0]
		var u: Vector3 = face[1] * half
		var v: Vector3 = face[2] * half
		var c: Vector3 = centre + n * half
		var a := c - u - v
		var b := c - u + v
		var d := c + u + v
		var e := c + u - v
		for point: Vector3 in [a, b, d, a, d, e]:
			st.set_normal(n)
			st.add_vertex(point)

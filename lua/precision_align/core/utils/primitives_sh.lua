-- Shared registry of primitive shapes buildable from PA points; drives the client's dropdown and the server's spawn dispatch.

PrecisionAlign.PRIMITIVE_TYPES = {}
PrecisionAlign.PRIMITIVE_ORDER = {}

-- How box-inscribed shapes (most of them) are fitted to points; shown once, always, above the primitive picker.
PrecisionAlign.PRIMITIVE_GENERIC_DESCRIPTION = "Points 1-2 define an edge. Point 3 defines a plane. Point 4+ scale the shape from this plane."

-- Registers a primitive shape: id is the wire key, data is { label, minPoints, maxPoints, description/notes, entity }.
-- If data.description isn't given, it's just data.notes (if any) - the generic mechanic is shown separately.
function PrecisionAlign.RegisterPrimitive( id, data )
	data.id = id

	if not data.description then
		data.description = data.notes or ""
	end

	PrecisionAlign.PRIMITIVE_TYPES[id] = data
	PrecisionAlign.PRIMITIVE_ORDER[#PrecisionAlign.PRIMITIVE_ORDER + 1] = id
end

PrecisionAlign.RegisterPrimitive( "cone", {
	label = "Cone",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

PrecisionAlign.RegisterPrimitive( "convex_hull", {
	label = "Convex Hull",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_convex_hull",
	notes = "The order of the points do not matter."
} )

PrecisionAlign.RegisterPrimitive( "cube", {
	label = "Cube",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

PrecisionAlign.RegisterPrimitive( "cube_hole", {
	label = "Cube (Hole)",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
	notes = "The hole itself uses the addon's default size."
} )

PrecisionAlign.RegisterPrimitive( "cube_magic", {
	label = "Cube (Magic)",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

PrecisionAlign.RegisterPrimitive( "plate", {
	label = "Cube (Plate)",
	minPoints = 3,
	maxPoints = 10,
	entity = "primitive_shape",
	notes = "The cube is set to have a thickness of 1."
} )

PrecisionAlign.RegisterPrimitive( "cylinder", {
	label = "Cylinder",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

PrecisionAlign.RegisterPrimitive( "dome", {
	label = "Dome",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

PrecisionAlign.RegisterPrimitive( "dome_hollow", {
	label = "Dome (Hollow)",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
	notes = "Wall thickness uses the addon's default size."
} )

PrecisionAlign.RegisterPrimitive( "parallelogram", {
	label = "Parallelogram",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

PrecisionAlign.RegisterPrimitive( "plane", {
	label = "Plane",
	minPoints = 3,
	maxPoints = 3,
	entity = "primitive_shape",
	notes = "No thickness."
} )

PrecisionAlign.RegisterPrimitive( "pyramid", {
	label = "Pyramid",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

PrecisionAlign.RegisterPrimitive( "sphere", {
	label = "Sphere",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

PrecisionAlign.RegisterPrimitive( "torus", {
	label = "Torus",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

PrecisionAlign.RegisterPrimitive( "tube", {
	label = "Tube",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

PrecisionAlign.RegisterPrimitive( "wedge", {
	label = "Wedge",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

PrecisionAlign.RegisterPrimitive( "wedge_corner", {
	label = "Wedge (Corner)",
	minPoints = 4,
	maxPoints = 10,
	entity = "primitive_shape",
} )

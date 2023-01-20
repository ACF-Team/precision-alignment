// Precision Alignment serverside code - By Wenli
if CLIENT then return end

local PA = "precision_align"
local PA_ = PA .. "_"

util.AddNetworkString( PA_ .. "constraint" )
util.AddNetworkString( PA_ .. "click" )
util.AddNetworkString( PA_ .. "ent" )
	
// Used to record each player's last PA action
local action_table = {}

CreateConVar( PA_ .. "stack_delay", 0.01 )

// Undo
local function UndoMove( Undo, ent, pos, ang )
	if IsValid(ent) then
		ent:SetPos( pos )
		ent:SetAngles( ang )
	end
end

// Sounds
local function playsound( ply, bool )
	if bool then
		ply:EmitSound("buttons/button14.wav", 100, 100)
	end
end
		

//********************************************************************************************************************//
// Mirror lists
//********************************************************************************************************************//

// Exceptions lists - all lower case!
// General
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/metal_plate1x2_tri.mdl", Angle(180,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/metal_plate1_tri.mdl", Angle(180,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/metal_plate2x2_tri.mdl", Angle(180,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/metal_plate2x4_tri.mdl", Angle(180,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/metal_plate4x4_tri.mdl", Angle(180,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/plastic/plastic_angle_90.mdl", Angle(180,0,180) )

// Misc
list.Set( "PA_mirror_exceptions_specific", "models/hunter/misc/stair1x1inside.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/misc/stair1x1outside.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/gibs/wooden_wheel1_gib2.mdl", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/gibs/wooden_wheel1_gib3.mdl", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/gibs/wooden_wheel2_gib1.mdl", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/gibs/wooden_wheel2_gib2.mdl", Angle(0,180,0) )

// Robotics
// Most of these are (180,0,0) since it's easier to set the whole of robotics as (0,180,0) in exceptions 2
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/robotics/foot.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/robotics/j1.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/robotics/j2.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/robotics/j3.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/robotics/j4.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/robotics/stand.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/robotics/xfoot.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/roboticslarge/xfoot.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/roboticslarge/j1.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/roboticslarge/j2.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/roboticslarge/j3.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/roboticslarge/j4.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/roboticslarge/claw2l.mdl", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/roboticslarge/clawl.mdl", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/robotics/claw.mdl", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/robotics/claw2.mdl", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/roboticslarge/claw_hub_8.mdl", Angle(180,0,0) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/roboticslarge/claw_hub_8l.mdl", Angle(180,0,0) )

// Solid Steel
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/solid_steel/sheetmetal_90_4.mdl", Angle(0,-90,180) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/solid_steel/sheetmetal_box90_4.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/solid_steel/sheetmetal_h90_4.mdl", Angle(180,0,90) )
list.Set( "PA_mirror_exceptions_specific", "models/mechanics/solid_steel/sheetmetal_t_4.mdl", Angle(0,0,180) )

// Specialized
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/metal_angle90.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/metal_dome90.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/metal_plate_curve.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/metal_plate_curve2x2.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/metal_wire_angle90x1.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/metal_wire_angle90x2.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/glass/glass_angle90.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/glass/glass_curve90x1.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/glass/glass_curve90x2.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/glass/glass_dome90.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/windows/window_angle90.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/windows/window_curve90x1.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/windows/window_curve90x2.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/windows/window_dome90.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/wood/wood_angle90.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/wood/wood_curve90x1.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/wood/wood_curve90x2.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/wood/wood_dome90.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/wood/wood_wire_angle90x1.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/construct/wood/wood_wire_angle90x2.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/misc/platehole1x1b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/misc/platehole1x1d.mdl", Angle(180,90,0) )

list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x1b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x1d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x2b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x2d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x3b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x3d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x4b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x4d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x5b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x5d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x6b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x6d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x8b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube1x1x8d.mdl", Angle(180,90,0) )

list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/circle2x2b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/circle2x2d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/plates/platehole1x1.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/plates/platehole3.mdl", Angle(0,-90,0) )

list.Set( "PA_mirror_exceptions_specific", "models/hunter/misc/shell2x2b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/misc/shell2x2d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/misc/shell2x2e.mdl", Angle(180,135,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/misc/shell2x2x45.mdl", Angle(180,135,0) )

list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x025b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x025d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x05b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x05d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x1b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x1d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x2b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x2d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x4b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x4d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x8b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x8d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2x16d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube2x2xtb.mdl", Angle(0,0,180) )


list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tubebend1x2x90b.mdl", Angle(90,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tubebendinsidesquare.mdl", Angle(-90,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/circle4x4b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/circle4x4d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/misc/platehole4x4b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/misc/platehole4x4d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x025b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x025d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x05b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x05d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x1b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x1d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x2b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x2d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x3b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x3d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x4b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x4d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x5b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x5d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x6b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x6d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x8b.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x8d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tube4x4x16d.mdl", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/tubes/tubebend4x4x90.mdl", Angle(0,0,180) )

list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/025x025.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/05x05.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/075x075.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/2x2.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/3x3.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/4x4.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/5x5.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/6x6.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/7x7.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/8x8.mdl", Angle(180,-90,0) )

list.Set( "PA_mirror_exceptions_specific", "models/hunter/plates/tri2x1.mdl", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/plates/tri3x1.mdl", Angle(0,180,0) )

list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/05x05x05.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x05x05.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x05x1.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1x1.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1x2.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1x3.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1x4.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1x5.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/2x1x1.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/2x2x1.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/2x2x2.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/3x2x2.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/3x3x2.mdl", Angle(0,0,180) )

list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1x1carved.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/2x1x1carved.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/2x2x1carved.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1x2carved.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/2x1x2carved.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/2x2x2carved.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1x4carved.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/2x2x4carved.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1x1carved025.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1x2carved025.mdl", Angle(180,-90,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/triangles/1x1x4carved025.mdl", Angle(180,-90,0) )
	
list.Set( "PA_mirror_exceptions_specific", "models/xqm/panel45.mdl", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/xqm/panel90.mdl", Angle(180,0,90) )

list.Set( "PA_mirror_exceptions_specific", "models/xqm/box2s.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/xqm/box3s.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/xqm/box4s.mdl", Angle(0,90,180) )
list.Set( "PA_mirror_exceptions_specific", "models/xqm/boxtri.mdl", Angle(180,-90,0) )

list.Set( "PA_mirror_exceptions_specific", "models/xqm/deg45.mdl", Angle(0,180,-45) )
list.Set( "PA_mirror_exceptions_specific", "models/xqm/deg45single.mdl", Angle(0,180,-45) )
list.Set( "PA_mirror_exceptions_specific", "models/xqm/deg90.mdl", Angle(0,180,-90) )
list.Set( "PA_mirror_exceptions_specific", "models/xqm/deg90single.mdl", Angle(0,180,-90) )

// Transportation
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/misc/propeller3x_small.mdl", Angle(0,120,180) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/huge/road_curve.mdl", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/trains/tracks/track_turn45.mdl", Angle(180,135,0) )
list.Set( "PA_mirror_exceptions_specific", "models/props_phx/trains/tracks/track_turn90.mdl", Angle(180,90,0) )

// Geometric
list.Set( "PA_mirror_exceptions_specific", "models/hunter/geometric/hex025x1.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/geometric/hex1x05.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/geometric/para1x1.mdl", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions_specific", "models/hunter/geometric/pent1x1.mdl", Angle(0,0,180) )

// Vehicles
list.Set( "PA_mirror_exceptions_specific", "models/nova/airboat_seat.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/nova/chair_office01.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/nova/chair_office02.mdl", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions_specific", "models/nova/jeep_seat.mdl", Angle(0,0,180) )

list.Set( "PA_mirror_exceptions", "models/hunter/tubes/tubebend", Angle(180,0,-90) )
list.Set( "PA_mirror_exceptions", "models/hunter/plates/tri", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions", "models/xqm/quad", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions", "models/xqm/rhombus", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions", "models/xqm/triangle", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions", "models/phxtended/tri", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions", "models/mechanics/robotics", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions", "models/mechanics/solid_steel/steel_beam45", Angle(0,90,180) )
list.Set( "PA_mirror_exceptions", "models/mechanics/solid_steel/type_c_", Angle(0,90,180) )
list.Set( "PA_mirror_exceptions", "models/mechanics/solid_steel/type_d_", Angle(0,135,180) )
list.Set( "PA_mirror_exceptions", "models/mechanics/solid_steel/type_e_", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions", "models/squad/sf_tris/sf_tri", Angle(180,90,0) )
list.Set( "PA_mirror_exceptions", "models/xqm/jettailpiece1", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions", "models/xqm/jetwing2", Angle(0,180,0) )
list.Set( "PA_mirror_exceptions", "models/xqm/wing", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions", "models/xeon133/racewheel/", Angle(0,0,180) )
list.Set( "PA_mirror_exceptions", "models/xeon133/racewheelskinny/", Angle(0,0,180) )

//********************************************************************************************************************//
// Duplicate ents
//********************************************************************************************************************//


local last_ent -- Used for nocollide
local stack_queue = {}
local undo_table = {}
local processing = false

// stack_ID is used to keep track within this file, stackID is used locally within functions
local stack_ID = 0

// Duplicate an entity in the stack queue
local function Queue_Process()
	local ent_table = table.remove( stack_queue, 1 )
	
	// Stop processing the stack queue
	if !ent_table then
		last_ent = nil
		processing = false
		return false
	end
	
	local ply = ent_table.ply
	if !IsValid( ply ) then return false end
	
	// Stack entity
	local ent = duplicator.CreateEntityFromTable( ply, ent_table.data )
	if !IsValid( ent ) then return false end
	
	local stackID = ent_table.stackID
	
	// Apply dupe info
	ent.EntityMods = table.Copy( ent_table.data.EntityMods )
	duplicator.ApplyEntityModifiers( ply, ent )
	duplicator.DoGenericPhysics( ent, ply, ent_table.data )
	ent:SetCollisionGroup( ent_table.collision_group )
	
	// Apply nocollide
	if ent_table.nocollide then
		// Nocollide each stacked ent with previous
		if IsValid( last_ent ) then
			constraint.NoCollide( ent, last_ent )
		end
		
		// Nocollide selected ent with final stacked ent
		if !stack_queue[1] or stackID ~= stack_queue[1].stackID then
			constraint.NoCollide( ent, ent_table.data.Entity )
			last_ent = nil
		else
			last_ent = ent
		end
	else
		last_ent = nil
	end
	
	ent:GetPhysicsObject():EnableMotion( false )
	
	return { ply = ply,
			 ent = ent,
			 stackID = stackID
			}
end

cleanup.Register( "stacks" )

// Create the undo function at the end of each stack_ID queue
local function Stack_Undo( undo_table ) -- if table.Count( undo_table ) == 0 then return end
	local ply = undo_table[1].ply
	
	local model = ""
	if IsValid( undo_table[1].ent ) then
		model = undo_table[1].ent:GetModel() or ""
	end
	
	undo.Create( "PA Stack " .. tostring(#undo_table) .. "x (" .. model .. ")" )
		for i = 1, #undo_table do
			local ent = undo_table[i].ent
			undo.SetPlayer( ply )
			undo.AddEntity( ent )
			ply:AddCleanup( "stacks", ent )
		end
	undo.Finish()
	
	table.Empty( undo_table )
end

// Handle stack queueing (called by timer)
local stackID_old

local function Stack_Loop()
	if #stack_queue > 0 and processing then
		local r, e = pcall( Queue_Process )
		
		if !r then
			ErrorNoHalt( e, "\n" )
		else
			// Create undo if stack_IDs are different
			if !stackID_old then
				stackID_old = e.stackID
			elseif stackID_old ~= e.stackID then
				Stack_Undo( undo_table )
				stackID_old = e.stackID
			end
			table.insert( undo_table, e )
			return true
		end
	end
	
	// Cleanup after stacking
	timer.Destroy( "PA_StackTimer" )
	last_ent = nil
	processing = false
	Stack_Undo( undo_table )
	stackID_old = nil
	
	return false
end

local function Queue_Add( ply, ent, stackID )
	local ent_table = {
		ply = ply,
		nocollide = ply:GetInfoNum( PA_ .. "stack_nocollide", 0 ) ~= 0,
		data = duplicator.CopyEntTable( ent ),
		collision_group = ent:GetCollisionGroup(),
		stackID = stackID
	}
	
	table.insert( stack_queue, ent_table )
	
	// Start processing the stack queue
	if !processing then
		processing = true
		local Delay = GetConVarNumber( PA_ .. "stack_delay", 0.1 )
		
		timer.Create( "PA_StackTimer", Delay, 0, Stack_Loop )
	end
end


//********************************************************************************************************************//
// Move ents
//********************************************************************************************************************//


// Args list:
// 1,2,3 = Movement vector
// 4 = Stack number
// 5 = Repeat flag
function precision_align_move_func( ply, cmd, args )
	if !ply.PA_activeent then return false end
	local ent = ply.PA_activeent
	if !IsValid(ent) then return false end
	if !util.IsValidPhysicsObject(ent, 0) or IsValid(ent:GetParent()) then return false end
	
	local v = Vector(args[1], args[2], args[3])
	if v == Vector(0,0,0) then return false end
	local stack = tonumber(args[4]) or 0
	stack = math.Round(math.Clamp( stack, 0, 20 ))
	
	local startpos = ent:GetPos()
	local startang = ent:GetAngles()
	
	// Begin stacking
	if stack > 0 then
		stack_ID = stack_ID + 1
	end
	
	for stacks = 1, math.max(stack, 1) do
		// Add to stack queue
		if stack > 0 then
			Queue_Add( ply, ent, stack_ID )
		end
		
		// Move entity
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		
		ent:SetPos(pos + v)
	end
	ent:GetPhysicsObject():EnableMotion( false )
	
	local model = ent:GetModel() or ""
	undo.Create("PA Move (" .. model .. ")")
		undo.SetPlayer( ply )
		undo.AddFunction( UndoMove, ent, startpos, startang )
	undo.Finish()
	
	// Record action
	if !args[5] then
		action_table[ply] = args
		action_table[ply][5] = true
		action_table[ply].cmd = precision_align_move_func
	end
	
	playsound( ply, true )
	return true
end
concommand.Add( PA_.. "move", precision_align_move_func )


//********************************************************************************************************************//
// Rotate ents
//********************************************************************************************************************//


// Rotate by world axes
local function rotate_world( ang, rotang )
	if rotang.p != 0 then
		ang:RotateAroundAxis( Vector(0,1,0), rotang.p )
	end
	if rotang.y != 0 then
		ang:RotateAroundAxis( Vector(0,0,1), rotang.y )
	end
	if rotang.r != 0 then
		ang:RotateAroundAxis( Vector(1,0,0), rotang.r )
	end

	return ang
end

// Convert from euler to axis-angle by quaternion method
local function euler_to_axisangle( ang )
	if !ang then return false end

	ang = Angle( math.rad( ang.p ), math.rad( ang.y ), math.rad( ang.r ) ) * 0.5
	
	local c1 = math.cos( ang.y )
	local c2 = math.cos( ang.p )
	local c3 = math.cos( ang.r )
	local s1 = math.sin( ang.y )
	local s2 = math.sin( ang.p )
	local s3 = math.sin( ang.r )
	local c1c2 = c1 * c2
	local s1s2 = s1 * s2
	
	local w = c1 * c2 * c3 + s1 * s2 * s3
	local x = c1c2 * s3 - s1s2 * c3
	local y = c1 * s2 * c3 + s1 * c2 * s3
	local z = s1 * c2 * c3 - c1 * s2 * s3
	
	local angle = 2 * math.deg( math.acos( w ) )
	local axis = Vector( x, y, z )
	
	if axis:Length() < 0.001 then
		axis = Vector( 0, 0, 1 )
	else
		axis = axis:GetNormal()
	end
	
	return axis, angle
end

// Three methods of rotation - absolute(0), relative(1), world(2) and axis/angle(3)
// Args list:
// 1,2,3 = Rotation Angle
// 4,5,6 = Pivot Vector
// 7 = Rotation type
// 8 = Stack number
// 9 = Repeat flag
function precision_align_rotate_func( ply, cmd, args )
	if !ply.PA_activeent then return false end
	local ent = ply.PA_activeent
	if !IsValid(ent) then return false end
	if !util.IsValidPhysicsObject(ent, 0) or IsValid(ent:GetParent()) then return false end
	
	if !tonumber(args[1]) or !tonumber(args[2]) or !tonumber(args[3]) then
		return false
	end
	
	local startpos = ent:GetPos()
	local startang = ent:GetAngles()
	
	// Change angle method depending on the "relative" variable
	local a
	local relative = tonumber(args[7]) or 0
	local test
	if relative == 1 then
		local localang = Angle( tonumber(args[1]), tonumber(args[2]), tonumber(args[3]) )
		if localang == Angle(0, 0, 0) then return false end
		a = ent:LocalToWorldAngles( localang )
		
	elseif relative == 2 then
		a = Angle(startang.p, startang.y, startang.r)
		local rotang = Angle( tonumber(args[1]), tonumber(args[2]), tonumber(args[3]) )
		a = rotate_world( a, rotang )
		
	elseif relative == 3 then
		local axis = Vector( tonumber(args[1]), tonumber(args[2]), tonumber(args[3]) )
		a = Angle(startang.p, startang.y, startang.r)
		a:RotateAroundAxis( axis:GetNormal(), axis:Length() )
		
	else
		a = Angle( tonumber(args[1]), tonumber(args[2]), tonumber(args[3]) )
		if a == startang then return false end
	end
	
	// Get pivot point
	local v
	if !tonumber(args[4]) or !tonumber(args[5]) or !tonumber(args[6]) then
		v = startpos
	else
		v = Vector( tonumber(args[4]), tonumber(args[5]), tonumber(args[6]) )
	end
	
	local stack = tonumber(args[8]) or 0
	stack = math.Round(math.Clamp( stack, 0, 20 ))
	
	// Figure out parameters for relative angle stacking
	if stack >= 2 then
		a = ent:WorldToLocalAngles( a )
	end
	
	// Begin stacking
	for stacks = 1, math.max(stack, 1) do
		// Add to stack queue
		if stack > 0 then
			Queue_Add( ply, ent )
		end
		
		// Rotate entity
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		
		local localv
		
		// Stack by absolute angle
		if stack < 2 then
			if v == pos then
				ent:SetAngles(a)
			else
				localv = ent:WorldToLocal(v)
				ent:SetAngles(a)
				pos = pos + ( v - ent:LocalToWorld(localv) )
				ent:SetPos(pos)
			end
			
		// Stack by relative angle
		else
			if v == pos then
				ent:SetAngles( ent:LocalToWorldAngles( a ) )
			else
				localv = ent:WorldToLocal(v)
				ent:SetAngles( ent:LocalToWorldAngles( a ) )
				pos = pos + ( v - ent:LocalToWorld(localv) )
				ent:SetPos(pos)
			end
		end
	end
	ent:GetPhysicsObject():EnableMotion( false )
	
	local model = ent:GetModel() or ""
	undo.Create("PA Rotate (" .. model .. ")")
		undo.SetPlayer( ply )
		undo.AddFunction( UndoMove, ent, startpos, startang )
	undo.Finish()
	
	// Record action
	if !args[9] then
		action_table[ply] = args
		action_table[ply][9] = true
		action_table[ply].cmd = precision_align_rotate_func
	end
	
	playsound( ply, true )
	return true
end
concommand.Add( PA_.. "rotate", precision_align_rotate_func )


//********************************************************************************************************************//
// Mirror ents
//********************************************************************************************************************//


// This was converted to a server-side command since it involves both rotation + translation in one step, and massCenter isn't available on client
// The mirror exception table can be changed on the server if needed for debugging/updating

// Args list:
// 1,2,3 = Plane Origin Vector
// 4,5,6 = Plane Normal Vector
// 7 = Stack number
// 8 = Repeat flag
function precision_align_mirror_func( ply, cmd, args )
	if !ply.PA_activeent then return false end
	local ent = ply.PA_activeent
	if !IsValid(ent) then return false end
	if !util.IsValidPhysicsObject(ent, 0) or IsValid(ent:GetParent()) then return false end
	
	local origin = Vector(args[1], args[2], args[3])
	local normal = Vector(args[4], args[5], args[6])
	local stack = tonumber(args[7]) or 0
	stack = math.Round(math.Clamp( stack, 0, 1 ))
	
	local pos = ent:GetPos()
	local ang = ent:GetAngles()
	// Mass centre seems to be most reliable way of finding a point on the plane of symmetry
	local v = ent:LocalToWorld(ent:GetPhysicsObject():GetMassCenter())
	
	// Stack before mirroring
	local ent2
	if stack > 0 then
		Queue_Add( ply, ent )
	end
	
	local model = ent:GetModel() or ""
	undo.Create("PA Mirror (" .. model .. ")")
		undo.SetPlayer( ply )
		undo.AddFunction( UndoMove, ent, pos, ang )
	undo.Finish()
	
	// Mirror angle
	// Filter through exceptions for ents that need to be rotated differently
	local exceptionang
	local model = string.lower( ent:GetModel() )
	local PA_mirror_exceptions_specific = list.Get( "PA_mirror_exceptions_specific" )
	
	// Match entire string
	exceptionang = PA_mirror_exceptions_specific[model]
	
	// Match left part of string
	if !exceptionang then
		local PA_mirror_exceptions = list.Get( "PA_mirror_exceptions" )
		for k, v in pairs( PA_mirror_exceptions ) do
			if string.match( model, "^" .. k ) then
				exceptionang = v
				break
			end
		end
	end
	
	if exceptionang then
		ang = ent:LocalToWorldAngles( exceptionang )
	else
		ang = ent:LocalToWorldAngles( Angle(180,0,0) )
	end
	
	ang:RotateAroundAxis( normal, 180 )
	
	// Rotate around v, same method as rotation function
	local localv
	if v == pos then
		ent:SetAngles(ang)
	else
		localv = ent:WorldToLocal(v)
		ent:SetAngles(ang)
		pos = pos + ( v - ent:LocalToWorld(localv) )
	end
	
	// Mirror position
	local length = normal:Dot(origin - v)
	local vec = normal * length * 2
	ent:SetPos(pos + vec)
	ent:GetPhysicsObject():EnableMotion( false )
	
	// Record action
	if !args[8] then
		action_table[ply] = args
		action_table[ply][8] = true
		action_table[ply].cmd = precision_align_mirror_func
	end
	
	playsound( ply, true )
	return true
end
concommand.Add( PA_.. "mirror", precision_align_mirror_func )


//********************************************************************************************************************//
// Constrain ents
//********************************************************************************************************************//

function precision_align_constraint_func( len, ply )
	local data = net.ReadTable()
	
	local constraint_type = data.Type
	
	local Ent1 = Entity( data.Ent1 )
	local Ent2 = Entity( data.Ent2 )
	
	// Entity(0) returns Null rather than World on server
	if Ent1 == NULL then Ent1 = game.GetWorld() end
	if Ent2 == NULL then Ent2 = game.GetWorld() end
	
	if CPPI then
		if Ent1:IsWorld() then
			if !util.IsValidPhysicsObject(Ent2, 0) or !Ent2:CPPICanTool( ply, PA ) then
				return false
			end
		elseif Ent2:IsWorld() then
			if !util.IsValidPhysicsObject(Ent1, 0) or !Ent1:CPPICanTool( ply, PA ) then
				return false
			end
		elseif !util.IsValidPhysicsObject(Ent1, 0) or !util.IsValidPhysicsObject(Ent2, 0) then
			return false
		elseif !Ent1:CPPICanTool( ply, PA ) or !Ent2:CPPICanTool( ply, PA ) then
			return false
		end
	else
		if Ent1:IsWorld() and !util.IsValidPhysicsObject(Ent2, 0) then
			return false
		elseif Ent2:IsWorld() and !util.IsValidPhysicsObject(Ent1, 0) then
			return false
		end
	end
	
	local LPos1 = Vector( data.LPos1.x, data.LPos1.y, data.LPos1.z )
	local LPos2 = Vector( data.LPos2.x, data.LPos2.y, data.LPos2.z )
	local vars = data.vars
	
	local const
	
	if constraint_type == "Axis" then
		local forcelimit = ply:GetInfoNum( PA_.. "axis_forcelimit", 0 )
		local torquelimit = ply:GetInfoNum( PA_.. "axis_torquelimit", 0 )
		local friction = ply:GetInfoNum( PA_.. "axis_friction", 0 )
		local nocollide = ply:GetInfoNum( PA_.. "axis_nocollide", 0 )
		
		local axis
		if vars and vars ~= 0 then
			axis = Ent1:WorldToLocal( Ent1:LocalToWorld(LPos1) + Vector( vars.x, vars.y, vars.z ) )
		end
		
		const = constraint.Axis( Ent1, Ent2, 0, 0, LPos1, LPos2, forcelimit, torquelimit, friction, nocollide, axis )
	elseif constraint_type == "Ballsocket" then
		local forcelimit = ply:GetInfoNum( PA_.. "ballsocket_forcelimit", 0 )
		local torquelimit = ply:GetInfoNum( PA_.. "ballsocket_torquelimit", 0 )
		local nocollide = ply:GetInfoNum( PA_.. "ballsocket_nocollide", 0 )
		
		const = constraint.Ballsocket( Ent2, Ent1, 0, 0, LPos1, forcelimit, torquelimit, nocollide )
		
	elseif constraint_type == "Ballsocket Advanced" then
		local forcelimit = ply:GetInfoNum( PA_.. "ballsocket_adv_forcelimit", 0 )
		local torquelimit = ply:GetInfoNum( PA_.. "ballsocket_adv_torquelimit", 0 )
		local xmin = ply:GetInfoNum( PA_.. "ballsocket_adv_xmin", -180 )
		local ymin = ply:GetInfoNum( PA_.. "ballsocket_adv_ymin", -180 )
		local zmin = ply:GetInfoNum( PA_.. "ballsocket_adv_zmin", -180 )
		local xmax = ply:GetInfoNum( PA_.. "ballsocket_adv_xmax", 180 )
		local ymax = ply:GetInfoNum( PA_.. "ballsocket_adv_ymax", 180 )
		local zmax = ply:GetInfoNum( PA_.. "ballsocket_adv_zmax", 180 )
		local xfric = ply:GetInfoNum( PA_.. "ballsocket_adv_xfric", 0 )
		local yfric = ply:GetInfoNum( PA_.. "ballsocket_adv_yfric", 0 )
		local zfric = ply:GetInfoNum( PA_.. "ballsocket_adv_zfric", 0 )
		local onlyrotation = ply:GetInfoNum( PA_.. "ballsocket_adv_onlyrotation", 0 )
		local nocollide = ply:GetInfoNum( PA_.. "ballsocket_adv_nocollide", 0 )
		
		const = constraint.AdvBallsocket( Ent1, Ent2, 0, 0, LPos1, LPos2, forcelimit, torquelimit, xmin, ymin, zmin, xmax, ymax, zmax, xfric, yfric, zfric, onlyrotation, nocollide )
	
	elseif constraint_type == "Elastic" then
		local constant = ply:GetInfoNum( PA_.. "elastic_constant", 0 )
		local damping = ply:GetInfoNum( PA_.. "elastic_damping", 0 )
		local rdamping = ply:GetInfoNum( PA_.. "elastic_rdamping", 0 )
		local material = ply:GetInfo( PA_.. "elastic_material", "cable/rope" )
		local width = ply:GetInfoNum( PA_.. "elastic_width", 1 )
		local stretchonly = ply:GetInfoNum( PA_.. "elastic_stretchonly", 0 )
		
		const = constraint.Elastic( Ent1, Ent2, 0, 0, LPos1, LPos2, constant, damping, rdamping, material, width, stretchonly )
		
	elseif constraint_type == "Rope" then
		local forcelimit = ply:GetInfoNum( PA_.. "rope_forcelimit", 0 )
		local width = ply:GetInfoNum( PA_.. "rope_width", 1 )
		local material = ply:GetInfo( PA_.. "rope_material", "cable/rope" )
		local rigid = ply:GetInfoNum( PA_.. "rope_rigid", 0 ) != 0
		
		local length = ply:GetInfoNum( PA_.. "rope_setlength", 0 )
		local addlength = 0
		if length <= 0 then
			addlength = ply:GetInfoNum( PA_.. "rope_addlength", 0 )
			length = ( Ent1:LocalToWorld(LPos1) - Ent2:LocalToWorld(LPos2) ):Length()
		end
		
		const = constraint.Rope( Ent1, Ent2, 0, 0, LPos1, LPos2, length, addlength, forcelimit, width, material, rigid )
		
	elseif constraint_type == "Slider" then
		local width = ply:GetInfoNum( PA_.. "slider_width", 0 )
		
		const = constraint.Slider( Ent1, Ent2, 0, 0, LPos1, LPos2, width )
	
	elseif constraint_type == "Wire Hydraulic" then
		local controller = Entity( vars )
		if !IsValid( controller ) then return false end
		if controller:GetClass() ~= "gmod_wire_hydraulic" then
			print( "PA Error: Tried to create wire hydraulic with invalid controller ent" )
			return false
		end
		
		local width = ply:GetInfoNum( PA_.. "wire_hydraulic_width", 1 )
		local material = ply:GetInfo( PA_.. "wire_hydraulic_material", "cable/rope" )
		
		// Create new constraint before removing the old one
		local oldconstraint = controller.constraint
		local oldrope = controller.rope
		
		local rope
		const, rope = MakeWireHydraulic( ply, Ent1, Ent2, 0, 0, LPos1, LPos2, width, material, 0, nil )
		
		if const then
			controller.MyId = controller:EntIndex()
			const.MyCrtl = controller:EntIndex()
			controller:SetConstraint( const )
			controller:DeleteOnRemove( const )
		end
		
		if rope then
			controller:SetRope( rope )
			controller:DeleteOnRemove( rope )
		end
		
		// Remove the existing hydraulic constraint
		if oldconstraint then
			controller:DontDeleteOnRemove( oldconstraint )
			oldconstraint:DontDeleteOnRemove( controller )
			oldconstraint:Remove()
		end
		
		if oldrope then
			controller:DontDeleteOnRemove( oldrope )
			oldrope:DontDeleteOnRemove( controller )
			oldrope:Remove()
		end
		
	end
	
	if const then
		undo.Create( "PA_" .. constraint_type )
			undo.AddEntity( const )
			undo.SetPlayer( ply )
		undo.Finish()
		
		if Ent1 then
			Ent1:GetPhysicsObject():EnableMotion( false )
		end
		
		if Ent2 then
			Ent2:GetPhysicsObject():EnableMotion( false )
		end
		
		playsound( ply, true )
	end
	
	return const
end
net.Receive( PA_.. "constraint", precision_align_constraint_func )


//********************************************************************************************************************//
// Perform last action
//********************************************************************************************************************//


// Keep a record of each player's last PA action
function precision_align_lastaction_func( ply, cmd, args )
	if !ply.PA_activeent then return false end
	local ent = ply.PA_activeent
	if !IsValid(ent) then return false end
	if !util.IsValidPhysicsObject(ent, 0) or IsValid(ent:GetParent()) then return false end
	
	local lastaction = action_table[ply]
	if !lastaction then return false end
	
	return lastaction.cmd( ply, nil, lastaction )
end
concommand.Add( PA_.. "lastaction", precision_align_lastaction_func )
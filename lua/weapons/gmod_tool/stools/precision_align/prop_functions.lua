// Preicsion Alignment maths functions library - By Wenli
if SERVER then return end

local PA = "precision_align"
local PA_ = PA .. "_"

PA_funcs = {}


//********************************************************************************************************************//
// Global  Functions
//********************************************************************************************************************//


local function Message( text )
	if GetConVarNumber(PA_.."display_messages") == 1 then
		LocalPlayer():ChatPrint("(PA) " .. text)
	end
end

local function Warning( text )
	if GetConVarNumber(PA_.."display_warnings") == 1 then
		LocalPlayer():ChatPrint("(PA) ERROR: " .. text)
	end
end


// Set view in direction of world position vector v
PA_funcs.set_playerview = function( v )
	if !v then return false end
	local ply = LocalPlayer()
	local pos = ply:GetShootPos()
	local Ang = (v - pos):Angle()
	ply:SetEyeAngles(Ang)
	return Ang
end

// Sends data to server to move entity - ent1/ent2 are the entities the points are attached to
PA_funcs.move_entity = function( vec1, vec2, activeent )
	if !IsValid(activeent) then
		Warning("No valid entity selected")
		return false
	end
	
	if !vec1 or !vec2 then
		Warning("Incomplete move data")
		return false
	end
	
	local v = vec2 - vec1
	
	// Shift determines whether to stack
	local shift = LocalPlayer():KeyDown( IN_SPEED )
	local stack = 0
	if shift then
		stack = GetConVarNumber( PA_.."stack_num" )
		if stack == 1 then
			Message("Stacked entity by " .. tostring(v))
		else
			Message("Stacked entity " .. tostring(stack) .. " times, by " .. tostring(v))
		end
	else
		Message("Moved entity by " .. tostring(v))
	end
	
	RunConsoleCommand( PA_.. "move",
						tostring(v.x), tostring(v.y), tostring(v.z),
						tostring(stack)
					)
	
	return true
end

// Sends data to server to rotate entity - vector is pivot point
PA_funcs.rotate_entity = function( ang, vec, relative, activeent )
	if !IsValid(activeent) then
		Warning("No valid entity selected")
		return false
	end
	
	if !ang then
		Warning("Incomplete rotation data")
		return false
	end
	
	// Rotate by prop origin by default
	vec = vec or {}
	
	// Shift determines whether to stack
	local msgstring
	local shift = LocalPlayer():KeyDown( IN_SPEED )
	local stack = 0
	if shift then
		stack = GetConVarNumber( PA_.."stack_num" )
		if stack == 1 then
			msgstring = "Stacked Entity "
		else
			msgstring = "Stacked Entity " .. tostring(stack) .. " times, "
		end
	else
		msgstring = "Rotated Entity "
	end
	
	// Set angles relative to prop
	if relative == 1 then
		msgstring = msgstring .. "at local angles "
		
	// Rotate by world axes
	elseif relative == 2 then
		msgstring = msgstring .. "by world axes "
	
	// Rotate by axis/angle, where ang is a vector with magnitude in degrees
	elseif relative == 3 then
		msgstring = msgstring .. "by axis/angle "
		
	// Set absolute angles
	else
		relative = 0
		msgstring = msgstring .. "at angles "
	end
	
	msgstring = msgstring .. tostring(ang)
	Message( msgstring )
	
	RunConsoleCommand( PA_.. "rotate",
						tostring(ang.p), tostring(ang.y), tostring(ang.r), 
						tostring(vec.x), tostring(vec.y), tostring(vec.z),
						tostring(relative), tostring(stack)
					)
	return true
end

PA_funcs.construct_exists = function( construct_type, ID )
	if !construct_type or !ID then return false end

	if construct_type == "Point" then
		if precision_align_points[ID].origin then
			return true
		end
	elseif construct_type == "Line" then
		if precision_align_lines[ID].startpoint and precision_align_lines[ID].endpoint then
			return true
		end
	elseif construct_type == "Plane" then
		if precision_align_planes[ID].origin and precision_align_planes[ID].normal then
			return true
		end
	end
	
	return false
end


//********************************************************************************************************************//
// Point  Functions
//********************************************************************************************************************//


PA_funcs.point_global = function( point )
	local point_temp = table.Copy( precision_align_points[point] )
	
	if !point_temp.origin then
		return false
	end
	
	local ent = point_temp.entity
	if ent then
		if IsValid(ent) then
			point_temp.origin = ent:LocalToWorld( point_temp.origin )
		else
			PA_funcs.delete_point(point)
			return false
		end
	end
	
	return point_temp
end

PA_funcs.point_local = function( point )
	local point_temp = table.Copy( precision_align_points[point] )
	
	if !point_temp.origin then
		return false
	end
	
	local ent = point_temp.entity
	if ent then
		if IsValid(ent) then
			point_temp.origin = ent:WorldToLocal( point_temp.origin )
		else
			PA_funcs.delete_point(point)
			return false
		end
	end
	
	return point_temp
end

PA_funcs.set_point = function( point, origin )
	if !origin then
		Warning("Incomplete point data")
		return false
	end
	
	local vec
	if IsValid( precision_align_points[point].entity ) then
		vec = precision_align_points[point].entity:WorldToLocal(origin)
	else
		vec = origin
	end
	
	precision_align_points[point].origin = vec
	Message("Point [" .. tostring(point) .. "] set at " .. tostring(origin))
	return true
end

PA_funcs.delete_point = function( point )
	precision_align_points[point] = {visible = true}
	Message("Point " .. tostring(point) .. " deleted")
	return true
end

PA_funcs.delete_points = function()
	for k, v in ipairs ( precision_align_points ) do
		precision_align_points[k] = {visible = true}
	end
	Message("All points cleared")
	return true
end

PA_funcs.attach_point = function( point, ent )
	if !precision_align_points[point].origin then
		Warning("Point must be defined before attaching")
		return false
	end
	
	local attached_ent = precision_align_points[point].entity
	
	if !IsValid(ent) then
		if attached_ent then
			precision_align_points[point].origin = attached_ent:LocalToWorld(precision_align_points[point].origin)
			precision_align_points[point].entity = nil
			Message("Point " .. tostring(point) .. " detached")
			return true
		else		
			Warning("No valid entity selected")
			return false
		end
	end
	
	if attached_ent then
		if attached_ent == ent then
			Message("Point is already attached to this entity")
			return false
		else
			precision_align_points[point].origin = attached_ent:LocalToWorld(precision_align_points[point].origin)
		end		
	end
	
	precision_align_points[point].entity = ent
	precision_align_points[point].origin = ent:WorldToLocal(precision_align_points[point].origin)
	Message("Point " .. tostring(point) .. " attached to " .. tostring(ent))
	return true
end

PA_funcs.point_function_average = function( points_table )
	local i = 0
	local vec = Vector(0,0,0)
	for k, v in pairs (points_table) do
		local point_temp = PA_funcs.point_global(v:GetID())
		if point_temp then
			i = i + 1
			vec = vec + point_temp.origin
		end
	end
	
	if i < 2 then
		Warning("Point average requires 2 or more points")
		return false
	end
	
	vec = vec * 1/i
	return vec
end


//********************************************************************************************************************//
// Line  Functions
//********************************************************************************************************************//


PA_funcs.line_global = function( line )
	local line_temp = table.Copy( precision_align_lines[line] )
	
	if !line_temp.startpoint or !line_temp.endpoint then
		return false
	end
	
	local ent = line_temp.entity
	if ent then
		if IsValid(ent) then
			line_temp.startpoint = ent:LocalToWorld( line_temp.startpoint )
			line_temp.endpoint = ent:LocalToWorld( line_temp.endpoint )
		else
			PA_funcs.delete_line(line)
			return false
		end
	end
	
	return line_temp
end

PA_funcs.line_local = function( line )
	local line_temp = table.Copy( precision_align_lines[line] )
	
	if !line_temp.startpoint or !line_temp.endpoint then
		return false
	end
	
	local ent = line_temp.entity
	if ent then
		if IsValid(ent) then
			line_temp.startpoint = ent:WorldToLocal( line_temp.startpoint )
			line_temp.endpoint = ent:WorldToLocal( line_temp.endpoint )
		else
			PA_funcs.delete_line(line)
			return false
		end
	end
	
	return line_temp
end

PA_funcs.set_line = function( line, startpoint, endpoint, direction, length )
	local ent = precision_align_lines[line].entity
	if !IsValid(ent) then
		ent = nil
	end
	
	local startpoint_old = precision_align_lines[line].startpoint
	if startpoint then
		if ent then
			precision_align_lines[line].startpoint = ent:WorldToLocal(startpoint)
		else
			precision_align_lines[line].startpoint = startpoint
		end
		
		if !endpoint and !direction then
			Message("Line [" .. tostring(line) .. "] startpoint set at " .. tostring(startpoint))
			return true
		end
	end
	
	if endpoint then
		if ent then
			precision_align_lines[line].endpoint = ent:WorldToLocal(endpoint)
		else
			precision_align_lines[line].endpoint = endpoint
		end
		
		if startpoint then
			Message("Line [" .. tostring(line) .. "] set from " .. tostring(startpoint) .. " to " .. tostring(endpoint))
		else
			Message("Line [" .. tostring(line) .. "] endpoint set at " .. tostring(endpoint))
		end
		return true
	end
	
	if !precision_align_lines[line].startpoint then
		Warning("Line not defined")
		return false
	end
	
	if direction then
		local len
		if !length then
			//Check to see whether line already exists, if so use that length
			if PA_funcs.construct_exists( "Line", line ) then
				len = startpoint_old:Distance( precision_align_lines[line].endpoint )
			else
				len = GetConVarNumber( PA_.."default_linelength" )
			end
		else
			len = length
		end
		
		if ent then
			direction = ( ent:WorldToLocal(ent:GetPos() + direction) ):GetNormal()
		end
		
		precision_align_lines[line].endpoint = precision_align_lines[line].startpoint + direction * len
		Message("Line [" .. tostring(line) .. "] set at " .. tostring(startpoint) .. " with length " .. tostring(len))
		return true
	end
		
	if length then
		// true regardless of ent
		local dir = ( precision_align_lines[line].endpoint - precision_align_lines[line].startpoint ):GetNormal()
		new_endpoint = precision_align_lines[line].startpoint + dir * length
		Message("Line [" .. tostring(line) .. "] length set to " .. tostring(len))
		return true
	end
	
	return true
end

PA_funcs.delete_line = function( line )
	precision_align_lines[line] = {visible = true}
	Message("Line " .. tostring(line) .. " deleted")
	return true
end

PA_funcs.delete_lines = function()
	for k, v in ipairs (precision_align_lines) do
		precision_align_lines[k] = {visible = true}
	end
	Message("All lines cleared")
	return true
end

PA_funcs.attach_line = function( line, ent )
	if !precision_align_lines[line].startpoint or !precision_align_lines[line].endpoint then
		Warning("Line must be defined before attaching")
		return false
	end
	
	local attached_ent = precision_align_lines[line].entity
	
	if !IsValid(ent) then
		if attached_ent then
			precision_align_lines[line].startpoint = attached_ent:LocalToWorld(precision_align_lines[line].startpoint)
			precision_align_lines[line].endpoint = attached_ent:LocalToWorld(precision_align_lines[line].endpoint)
			precision_align_lines[line].entity = nil
			Message("Line " .. tostring(line) .. " detached")
			return true
		else
			Warning("No valid entity selected")
			return false
		end
	end
	
	if attached_ent then
		if attached_ent == ent then
			Message("Line is already attached to this entity")
			return false
		else
			precision_align_lines[line].startpoint = attached_ent:LocalToWorld(precision_align_lines[line].startpoint)
			precision_align_lines[line].endpoint = attached_ent:LocalToWorld(precision_align_lines[line].endpoint)
		end		
	end
	
	precision_align_lines[line].entity = ent
	precision_align_lines[line].startpoint = ent:WorldToLocal(precision_align_lines[line].startpoint)
	precision_align_lines[line].endpoint = ent:WorldToLocal(precision_align_lines[line].endpoint)
	Message("Line " .. tostring(line) .. " attached to " .. tostring(ent))
	return true
end

PA_funcs.line_function_perpendicular = function( lineID1, lineID2 )
	if PA_funcs.construct_exists( "Line", lineID1 ) and PA_funcs.construct_exists( "Line", lineID2 ) then
		local line1 = PA_funcs.line_global(lineID1)
		local line2 = PA_funcs.line_global(lineID2)
		local dir1 = line1.endpoint - line1.startpoint
		local dir2 = line2.endpoint - line2.startpoint
	
		local vec = ( dir1:Cross(dir2) ):GetNormal()
		if vec:Length() == 0 then
			Warning("Tried to find cross product of two parallel lines")
			return false
		end
		return vec
	end
	Warning("2 lines required to find perpendicular direction")
	return false
end


//********************************************************************************************************************//
// Plane  Functions
//********************************************************************************************************************//


PA_funcs.plane_global = function( plane )
	local plane_temp = table.Copy(precision_align_planes[plane])
	
	if !plane_temp.origin or !plane_temp.normal then
		return false
	end
	
	local ent = plane_temp.entity
	if ent then
		if IsValid(ent) then
			plane_temp.origin = ent:LocalToWorld(plane_temp.origin)
			plane_temp.normal = ( ent:LocalToWorld(plane_temp.normal) - ent:GetPos()):GetNormal()
		else
			PA_funcs.delete_plane(plane)
			return false
		end
	end
	
	return plane_temp
end

PA_funcs.plane_local = function( plane )
	local plane_temp = table.Copy(precision_align_planes[plane])
	
	if !plane_temp.origin or !plane_temp.normal then
		return false
	end
	
	local ent = plane_temp.entity
	if ent then
		if IsValid(ent) then
			plane_temp.origin = ent:WorldToLocal(plane_temp.origin)
			plane_temp.normal = ( ent:WorldToLocal(ent:GetPos() + plane_temp.normal) ):GetNormal()
		else
			PA_funcs.delete_plane(plane)
			return false
		end
	end
	
	return plane_temp
end

PA_funcs.set_plane = function( plane, origin, normal )
	local ent = precision_align_planes[plane].entity
	
	if origin then
		if ent then
			precision_align_planes[plane].origin = ent:WorldToLocal(origin)
		else
			precision_align_planes[plane].origin = origin
		end
	end
	
	if !precision_align_planes[plane].origin then
		Warning("Plane not defined")
		return false
	end
	
	if normal then
		if ent then
			precision_align_planes[plane].normal = ( ent:WorldToLocal(ent:GetPos() + normal) ):GetNormal()
		else
			precision_align_planes[plane].normal = normal
		end
	end
	
	if origin and normal then
		Message("Plane [" .. tostring(plane) .. "] set at " .. tostring(origin) .. " with normal " .. tostring(normal))
	elseif origin then
		Message("Plane [" .. tostring(plane) .. "] origin set to " .. tostring(origin))
	else
		Message("Plane [" .. tostring(plane) .. "] normal set to " .. tostring(normal))
	end
	
	return true
end
	
PA_funcs.delete_plane = function( plane )
	precision_align_planes[plane] = {visible = true}
	Message("Plane " .. tostring(plane) .. " deleted")
	return true
end

PA_funcs.delete_planes = function()
	for k, v in ipairs (precision_align_planes) do
		precision_align_planes[k] = {visible = true}
	end
	Message("All planes cleared")
	return true
end

PA_funcs.attach_plane = function( plane, ent )
	if !precision_align_planes[plane].origin or !precision_align_planes[plane].normal then
		Warning("Plane must be defined before attaching")
		return false
	end
	
	local attached_ent = precision_align_planes[plane].entity
	
	if !IsValid(ent) then
		if attached_ent then
			precision_align_planes[plane].origin = attached_ent:LocalToWorld(precision_align_planes[plane].origin)
			precision_align_planes[plane].normal = ( attached_ent:LocalToWorld(precision_align_planes[plane].normal) - attached_ent:GetPos() ):GetNormal()
			precision_align_planes[plane].entity = nil
			Message("Plane " .. tostring(plane) .. " detached")
			return true
		else
			Warning("No valid entity selected")
			return false
		end
	end

	if attached_ent then
		if attached_ent == ent then
			Message("Plane is already attached to this entity")
			return false
		else
			precision_align_planes[plane].origin = attached_ent:LocalToWorld(precision_align_planes[plane].origin)
			precision_align_planes[plane].normal = ( attached_ent:LocalToWorld(precision_align_planes[plane].normal) - attached_ent:GetPos() ):GetNormal()
		end
	end
	
	precision_align_planes[plane].entity = ent
	precision_align_planes[plane].origin = ent:WorldToLocal(precision_align_planes[plane].origin)
	precision_align_planes[plane].normal = ( ent:WorldToLocal(ent:GetPos() + precision_align_planes[plane].normal) ):GetNormal()
	Message("Plane " .. tostring(plane) .. " attached to " .. tostring(ent))
	return true
end

PA_funcs.plane_function_perpendicular = function( planeID1, planeID2 )
	if PA_funcs.construct_exists( "Plane", planeID1 ) and PA_funcs.construct_exists( "Plane", planeID2 ) then
		local plane1 = PA_funcs.plane_global(planeID1)
		local plane2 = PA_funcs.plane_global(planeID2)
	
		local vec = ( plane1.normal:Cross(plane2.normal) ):GetNormal()
		if vec:Length() == 0 then
			Warning("Tried to find cross product of two parallel planes")
		end
		return vec
	end
	Warning("2 planes required to find perpendicular normal")
	return false
end


//********************************************************************************************************************//
// Combined  Functions
//********************************************************************************************************************//


// Solve simultaneous equations in form:
// a1 + b1 = c1,    a2 + b2 = c2
local function solve_simultaneous_2( a1, b1, c1, a2, b2, c2 )
	local d = a1 * b2 - b1 * a2
	if d == 0 then
		Warning("No real solution found for given coefficients")
		return false
	end
	
	local x = ( b2 * c1 - b1 * c2 )/d
	local y = ( a1 * c2 - a2 * c1 )/d
	return x, y
end

local function solve_point_2line_intersection( line1, line2 )
	local A = line1.endpoint - line1.startpoint
	local B = line2.endpoint - line2.startpoint
	local normal = (A:Cross(B)):GetNormal()
	
	// Check lines are not parallel
	if normal:Length() == 0 then
		Warning("Cannot find intercept of two parallel lines")
		return false
	end
	
	local C = line2.startpoint - line1.startpoint
	
	local a1, a2, b1, b2, c1, c2
	a1 = A:Dot(A)
	b1 = -A:Dot(B)
	c1 = A:Dot(C)
	a2 = -b1
	b2 = -B:Dot(B)
	c2 = B:Dot(C)
	
	// solve simultaneous
	local length1, length2 = solve_simultaneous_2( a1, b1, c1, a2, b2, c2 )
	if !length1 or !length2 then return false end
	
	local dir1, dir2 = A:GetNormal(), B:GetNormal()
	
	local point1 = line1.startpoint + A * length1
	local point2 = line2.startpoint + B * length2
	
	local point3 = ( point1 + point2 ) * 0.5
	return point3
end

PA_funcs.point_2line_intersection = function( lineID1, lineID2 )
	local line1 = PA_funcs.line_global( lineID1 )
	local line2 = PA_funcs.line_global( lineID2 )
	
	return solve_point_2line_intersection( line1, line2 )
end


PA_funcs.point_lineplane_intersection = function( lineID, planeID )
	local line = PA_funcs.line_global( lineID )
	local plane = PA_funcs.plane_global( planeID )
	
	local A = line.endpoint - line.startpoint
	local normal = plane.normal
	
	// Check line and plane are not parallel
	if normal:Dot(A) == 0 then
		Warning("Cannot find intercept of parallel line and plane")
		return false
	end
	
	local length = normal:Dot(plane.origin - line.startpoint) / normal:Dot(A)
	local point = line.startpoint + A * length
	return point
end

PA_funcs.line_2plane_intersection = function( planeID1, planeID2 )
	local plane1 = PA_funcs.plane_global( planeID1 )
	local plane2 = PA_funcs.plane_global( planeID2 )
	
	local dir = plane1.normal:Cross(plane2.normal)
	
	// Check planes are not parallel
	if dir:Length() == 0 then
		Warning("Cannot find intersection of two parallel planes")
		return false
	end
	
	local line1, line2 = {}, {}
	line1.startpoint = plane1.origin
	line1.endpoint = plane1.origin + plane1.normal:Cross(dir)
	line2.startpoint = plane2.origin
	line2.endpoint = plane2.origin + plane2.normal:Cross(dir)
	
	// Construct solved line
	local line = {}
	line.startpoint = solve_point_2line_intersection( line1, line2 )
	line.direction = dir:GetNormal()	-- returns point/direction format as other functions will calculate endpoint anyway
	
	return line	
end

PA_funcs.point_3plane_intersection = function( planeID1, planeID2, planeID3 )
	local plane1 = PA_funcs.plane_global( planeID1 )
	local plane2 = PA_funcs.plane_global( planeID2 )
	local plane3 = PA_funcs.plane_global( planeID3 )
	
	// Check plane normals are not parallel
	local product = plane1.normal:Dot(plane2.normal:Cross(plane3.normal))
	if product == 0 then
		Warning("One or more planes are parallel, no unique point found")
		return false
	elseif math.abs(product) < 0.01 then
		Warning("Planes are almost parallel, computation may be inaccurate")
	end
	
	local line = PA_funcs.line_2plane_intersection( planeID1, planeID2 )
	if !line then return false end
	
	// Calculate line/plane intercept
	local length = plane3.normal:Dot(plane3.origin - line.startpoint) / plane3.normal:Dot(line.direction)
	local point = line.startpoint + line.direction * length
	return point
end

PA_funcs.point_line_projection = function( pointID, lineID )
	local point = PA_funcs.point_global( pointID )
	local line = PA_funcs.line_global( lineID )
	
	local point1 = line.startpoint
	local point2 = line.endpoint
	local point3 = point.origin
	
	local dir = point2 - point1
	
	local vec = point1 + ((point3 - point1):Dot(dir)) / (dir:Dot(dir)) * dir
	return vec
end

PA_funcs.point_plane_projection = function( pointID, planeID )
	local point = PA_funcs.point_global( pointID )
	local plane = PA_funcs.plane_global( planeID )
	
	//Same method as for line/plane intersection
	local normal = plane.normal
	
	local length = normal:Dot(plane.origin - point.origin)
	local vec = point.origin + normal * length
	return vec
end

// These are general functions for mirroring vectors
PA_funcs.point_mirror = function( vec, origin, normal )
	local length = normal:Dot( origin - vec )
	local vec1 = vec + normal * length * 2
	
	return vec1
end

PA_funcs.direction_mirror = function( dir, normal )
	local dir1 = dir - 2 * normal * ( dir:Dot(normal) )
	
	return dir1
end

PA_funcs.line_plane_projection = function( lineID, planeID )
	local line = PA_funcs.line_global( lineID )
	local plane = PA_funcs.plane_global( planeID )
	
	local normal = plane.normal
	
	local length = normal:Dot(plane.origin - line.startpoint)
	line.startpoint = line.startpoint + normal * length
	
	local length = normal:Dot(plane.origin - line.endpoint)
	line.endpoint = line.endpoint + normal * length
	
	if line.startpoint == line.endpoint then
		Warning("Line - plane projection results in a single point! Check line is not perpendicular to plane")
		return false
	end
	
	return line
end

PA_funcs.plane_3points = function( pointID1, pointID2, pointID3 )
	local point1 = PA_funcs.point_global( pointID1 ).origin
	local point2 = PA_funcs.point_global( pointID2 ).origin
	local point3 = PA_funcs.point_global( pointID3 ).origin
	
	local dir1 = point2 - point1
	local dir2 = point3 - point1
	local dir3 = point3 - point2
	
	if dir1:Length() == 0 or dir2:Length() == 0 or dir3:Length() == 0 then
		Warning("Require at least 3 unique points to define plane")
		return false
	end
	
	local plane_temp = {}
	plane_temp.direction = ( dir2:Cross(dir1) ):GetNormal()
	plane_temp.origin = ( point1 + point2 + point3 ) * 1/3
	
	return plane_temp
end


//********************************************************************************************************************//
// Rotation  Functions
//********************************************************************************************************************//


local function matrix_x_vector( matrix, v )
	local v1 = matrix[1]
	local v2 = matrix[2]
	local v3 = matrix[3]
	
	return Vector(
		v1.x * v.x + v1.y * v.y + v1.z * v.z,
		v2.x * v.x + v2.y * v.y + v2.z * v.z,
		v3.x * v.x + v3.y * v.y + v3.z * v.z
	)
end

local function matrix_transpose( matrix )
	local v1 = matrix[1]
	local v2 = matrix[2]
	local v3 = matrix[3]
	
	return {
		Vector( v1.x, v2.x, v3.x ),
		Vector( v1.y, v2.y, v3.y ),
		Vector( v1.z, v2.z, v3.z )
	}
end


// Rotate angle by world angles
PA_funcs.rotate_world = function( ang, rotang )
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

// Rotate line 1 so it ends up in same direction as line 2
PA_funcs.rotate_2lines_parallel = function( pivot, lineID1, lineID2, activeent )
	local line1 = PA_funcs.line_global( lineID1 )
	local line2 = PA_funcs.line_global( lineID2 )
	
	if !pivot then
		pivot = line1.startpoint
	end
	
	local dir1 = ( line1.endpoint - line1.startpoint ):GetNormal()
	local dir2 = ( line2.endpoint - line2.startpoint ):GetNormal()
	
	local vec = dir1:Cross(dir2):GetNormal()
	local ang = activeent:GetAngles()
	
	if dir1 == Vector(-dir2.x, -dir2.y, -dir2.z) then
		ang = Angle(-ang.p, ang.y + 180, -ang.r)
	end
	
	local angle = math.deg( math.acos( dir1:Dot(dir2) ) )
	ang:RotateAroundAxis( vec, angle )
	
	return PA_funcs.rotate_entity(ang, pivot, 0, activeent)
end

// Rotate plane 1 normal to match plane 2 normal
PA_funcs.rotate_2planes_parallel = function( pivot, planeID1, planeID2, activeent )
	local plane1 = PA_funcs.plane_global( planeID1 )
	local plane2 = PA_funcs.plane_global( planeID2 )
	
	if !pivot then
		pivot = plane1.origin
	end
	
	local dir1 = plane1.normal
	local dir2 = plane2.normal
	
	local vec = dir1:Cross(dir2):GetNormal()
	local ang = activeent:GetAngles()
	
	if dir1 == Vector(-dir2.x, -dir2.y, -dir2.z) then
		ang = Angle(-ang.p, ang.y + 180, -ang.r)
	end
	
	local angle = math.deg( math.acos( dir1:Dot(dir2) ) )
	ang:RotateAroundAxis( vec, angle )
	
	return PA_funcs.rotate_entity(ang, pivot, 0, activeent)
end

// NOT USED CURRENTLY ***********************
// Rotate line so it ends up in same direction as plane normal
-- function rotate_lines_planenormal_parallel( pivot, lineID, planeID, activeent )
	-- local line = PA_funcs.line_global( lineID )
	-- local plane = PA_funcs.plane_global( planeID )
	
	-- local dir1 = ( line.endpoint - line.startpoint ):GetNormal()
	-- local dir2 = plane.normal
	
	-- local vec = dir1:Cross(dir2):GetNormal()
	-- local ang = activeent:GetAngles()
	
	-- if dir1 == -dir2 then
		-- ang = Angle(-ang.p, ang.y + 180, -ang.r)
	-- end
	
	-- local angle = math.deg( math.acos( dir1:Dot(dir2) ) )
	-- ang:RotateAroundAxis( vec, angle )
	
	-- return PA_funcs.rotate_entity(ang, pivot, activeent)
-- end

// Rotate line until parallel to plane
PA_funcs.rotate_line_plane_parallel = function( pivot, axis, lineID, planeID, activeent )
	local line = PA_funcs.line_global( lineID )
	local plane = PA_funcs.plane_global( planeID )
	
	local linedir1 = ( line.endpoint - line.startpoint ):GetNormal()
	local normal = plane.normal
	local axisdir
	
	if axis then
		axisdir = ( axis.endpoint - axis.startpoint ):GetNormal()
		
		if axisdir == normal or axisdir == -normal then
			Warning("Rotation axisdir is normal to plane")
			return false
		elseif axisdir == linedir1 or axisdir == -linedir1 then
			Warning("Rotation axisdir is normal to line")
			return false
		// Calculate whether axis/plane angle is not more than axis/line angle
		elseif math.asin(axisdir:Dot(normal)) > math.acos(axisdir:Dot(linedir1)) then
			Warning("Line cannot be rotated parallel to plane along this axis!")
			return false
		end
	else
		axisdir = normal:Cross(linedir1):GetNormal()
	end
	
	// Transform everything relative to plane/axis directions
	local M = {
		-axisdir:Cross(normal):Cross(normal):GetNormal(),
		axisdir:Cross(normal):GetNormal(),
		normal
	}
	
	local MT = matrix_transpose(M)
	
	// Now we just have to set Z = 0 after transform
	local normal2 = Vector(0,0,1)
	local axisdir2 = matrix_x_vector( M, axisdir )
	local linedir2 = matrix_x_vector( M, linedir1 )
	
	// Did the maths, ends up with a quadratic, solving for x component of line
	// Quadratic formula
	local a = axisdir2.x^2 - axisdir2.y^2
	local c = axisdir2.y^2 - (linedir2:Dot(axisdir2))^2
	
	// 2 solutions
	local x1 = math.sqrt(-4 * a * c) / (2 * a)
	local y1 = math.sqrt(1 - x1^2)
	
	local y2 = -y1
	local x2 = math.sqrt(1 - y2^2)
	
	// Find rotation angle given the start/final line directions
	local function solver(x, y)
		// Vec is the rotated direction of the line
		local Vec = Vector(x, y, 0)
		Vec = matrix_x_vector( MT, Vec ):GetNormal()
		
		// Radial line directions around axis
		local v1 = ( linedir1 - axisdir * (linedir1:Dot(axisdir)) ):GetNormal()
		local v2 = ( Vec - axisdir * (Vec:Dot(axisdir)) ):GetNormal()
		
		local Ang = math.deg(math.acos(math.Clamp( v1:Dot(v2), -1, 1)))
		
	
		-- Warning("x/y: " .. tostring(x) .. " : " .. tostring(y) )
		-- Warning("V1/2: " .. tostring(v1) .. " : " .. tostring(v2) )
		-- Warning("Vec: " .. tostring(Vec))
		-- Warning("Ang: " .. tostring(Ang))
	
	
		// Handedness is important - determines which way to rotate the vector
		local Handedness = v1:Dot(v2:Cross(axisdir2))
		
		if Handedness < 0 then
			Ang = -Ang
		end
		
		return Ang
	end
	
	local Ang = solver(x1, y1)
	
	// Determine which way around to rotate
	
	if math.abs(Ang) < 0.5 then
		// Find second solution
		Ang = solver(x2, y2) 
	end
	
	local ang = activeent:GetAngles()
	ang:RotateAroundAxis( axisdir, Ang )
	
	// Use axis as pivot by default
	if !pivot and axis then
		pivot = axis.startpoint
	end
	
	return PA_funcs.rotate_entity( ang, pivot, 0, activeent )
end

// Numerical solution
-- function PA_funcs.rotate_line_plane_parallel( pivot, axis, lineID, planeID, activeent )
	-- local line = PA_funcs.line_global( lineID )
	-- local plane = PA_funcs.plane_global( planeID )
	
	-- local linedir1 = ( line.endpoint - line.startpoint ):GetNormal()
	-- local normal = plane.normal
	-- local axisdir
	
	-- if axis then
		-- axisdir = ( axis.endpoint - axis.startpoint ):GetNormal()
		
		-- if axisdir == normal or axisdir == -normal then
			-- Warning("Rotation axisdir is normal to plane")
			-- return false
		-- elseif axisdir == linedir1 or axisdir == -linedir1 then
			-- Warning("Rotation axisdir is normal to line")
			-- return false
		-- // Calculate whether axis/plane angle is not more than axis/line angle
		-- elseif math.asin(axisdir:Dot(normal)) > math.acos(axisdir:Dot(linedir1)) then
			-- Warning("Line cannot be rotated parallel to plane along this axis!")
			-- return false
		-- end
	-- else
		-- axisdir = normal:Cross(axisdir):GetNormal()
	-- end
	
	-- local dir
	
	-- // Max and min angles of rotation
	-- local ang1 = 0
	-- local ang2 = axisdir:Cross(linedir1):Cross(axisdir)
	
	-- local count = 0
	
	-- while count < 200 do
		-- dir_temp = Vector( linedir1.x, linedir1.y, linedir1.z )
		
	-- end
	
	
	-- // Use axis as pivot by default
	-- if !pivot and axis then
		-- pivot = axis.startpoint
	-- end
	
	-- return PA_funcs.rotate_entity( ang, pivot, activeent )
-- end


// Mirror about selected plane
PA_funcs.plane_mirror_entity = function( planeID, activeent )
	local plane = PA_funcs.plane_global( planeID )
	local origin = plane.origin
	local normal = plane.normal
	
	local shift = LocalPlayer():KeyDown( IN_SPEED )
	local stack = 0
	if shift then
		stack = GetConVarNumber( PA_.."stack_num" )
	end
	
	// Mirror by concommand directly
	RunConsoleCommand( PA_.. "mirror",	tostring(origin.x), tostring(origin.y), tostring(origin.z),
										tostring(normal.x), tostring(normal.y), tostring(normal.z),
										tostring(stack) )
	
	Message("Entity mirrored about plane " .. tostring(planeID))
	return true
end
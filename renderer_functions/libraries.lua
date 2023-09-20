-- The library used by the Renderer, I recommend leaving it alone unless you know what you're doing
RendererLib={

--[[
Rotates a 3D vector by applying X,Y,Z rotations individually.
The rotation order can be changed to Z,Y,X respectively.

Not actually used in the Renderer, but useful nevertheless!
]]
rotate=function(vx,vy,vz,rotx,roty,rotz,reverseOrder)

-- local variables are accessed faster
	local sin,cos=math.sin,math.cos

-- precalculated sin and cos because they are used multiple times in the formulas
	local sin_rotx,cos_rotx,sin_roty,cos_roty,sin_rotz,cos_rotz=
	sin(rotx),cos(rotx),
	sin(roty),cos(roty),
	sin(rotz),cos(rotz)

--[[
the actual formula, much like the 2D rotation one but applied three times for different axis

the way order changes may be a bit messy, but I think it's the best performance-wise
]]
	if reverseOrder then
-- Z axis
		vx,vy=
		 vx* cos_rotz+vy* sin_rotz,
		 vx*-sin_rotz+vy* cos_rotz
-- Y axis
		vx,vz=
		 vx* cos_roty+vz*-sin_roty,
		 vx* sin_roty+vz* cos_roty
	end
-- X axis
		vy,vz=
			vy* cos_rotx+vz* sin_rotx,
			vy*-sin_rotx+vz* cos_rotx
	if not reverseOrder then
-- Y axis
		vx,vz=
		 vx* cos_roty+vz*-sin_roty,
		 vx* sin_roty+vz* cos_roty
-- Z axis
		vx,vy=
		 vx* cos_rotz+vy* sin_rotz,
		 vx*-sin_rotz+vy* cos_rotz
	end

	return vx,vy,vz
end,

--[[
Rotates a 3D vector, but doesn't calculate sin and cos of the rotation degrees, so they can be precalculated outside. Really improves performance!

Is the actual rotation function being used in the Renderer.
]]
rotatePreCalc=function(vx,vy,vz,sin_rotx,cos_rotx,sin_roty,cos_roty,sin_rotz,cos_rotz,reverseOrder)

	if reverseOrder then
-- Z axis
		vx,vy=
		 vx* cos_rotz+vy* sin_rotz,
		 vx*-sin_rotz+vy* cos_rotz
-- Y axis
		vx,vz=
		 vx* cos_roty+vz*-sin_roty,
		 vx* sin_roty+vz* cos_roty
	end
-- X axis
		vy,vz=
		 vy* cos_rotx+vz* sin_rotx,
		 vy*-sin_rotx+vz* cos_rotx
	if not reverseOrder then
-- Y axis
		vx,vz=
		 vx* cos_roty+vz*-sin_roty,
		 vx* sin_roty+vz* cos_roty
-- Z axis
		vx,vy=
		 vx* cos_rotz+vy* sin_rotz,
		 vx*-sin_rotz+vy* cos_rotz
	end

	return vx,vy,vz
end,

--[[
Instead of accepting and outputting a {x,y,z} vector, those "Raw" functions simply input and output x,y,z
variables. Massively improves performance, because of the Lua quirks.
What the functions do is self-explanatory, i hope.
]]
GetDotRaw=function (ax,ay,az,bx,by,bz)
	return ax*bx+ay*by+az*bz
end,

-- Linear interpolation of a 3D vector, modified to work specifically with ClipScene().
UV3DLerp=function (a_vec,b_vec,a_uv_U,a_uv_V,b_uv_U,b_uv_V,n,hasuv,plane_POSz)
	return
	 {x=              a_vec.x+(b_vec.x-a_vec.x)*n,
	  y=              a_vec.y+(b_vec.y-a_vec.y)*n,
	  z=plane_POSz or a_vec.z+(b_vec.z-a_vec.z)*n},

	 hasuv and a_uv_U+(b_uv_U-a_uv_U)*n,
	 hasuv and a_uv_V+(b_uv_V-a_uv_V)*n

end,

-- Some of the functions were originally taken from the works of nequ16, and modified by me.
}

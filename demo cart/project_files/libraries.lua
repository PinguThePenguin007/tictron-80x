Vector=RendererLib

Vector.GetDot=function(a,b)
	return a.x*b.x+a.y*b.y+a.z*b.z
end

Vector.GetNormal=function(a,b,c)
	local va_x,va_y,va_z=a.x-b.x,a.y-b.y,a.z-b.z
	local vb_x,vb_y,vb_z=c.x-b.x,c.y-b.y,c.z-b.z
	return {
	 x=va_y*vb_z-va_z*vb_y,
	 y=va_z*vb_x-va_x*vb_z,
	 z=va_x*vb_y-va_y*vb_x}
end

Vector.NormalizeRaw=function(vx,vy,vz)
	local lenV=math.sqrt(vx*vx+vy*vy+vz*vz)
	return vx/lenV,vy/lenV,vz/lenV
end

Vector.Normalize=function(v)
	local lenV=math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
	return {x=v.x/lenV,y=v.y/lenV,z=v.z/lenV}
end

Vector.GetLen=function(v)
 return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
end

Vector.Lerp=function (a,b,n)
	return {x=a.x+(b.x-a.x)*n,
	        y=a.y+(b.y-a.y)*n,
	        z=a.z+(b.z-a.z)*n}
end


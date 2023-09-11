function Renderer.drawScene(customscene,project,customcam,CenterX,CenterY, UseTTriOnly,Wireframe)

	local scene=customscene or Renderer.data.scene
	local drawdump=scene.drawdump

	local colorToUVMap=Renderer.data.colorToUVMap
	if UseTTriOnly==nil then UseTTriOnly=Renderer.defaultSettings.UseTTriOnly end
	if Wireframe==nil then Wireframe=Renderer.defaultSettings.Wireframe end

	if project or project==nil then Renderer.projectVerts(scene,CenterX,CenterY,customcam) end

	local CAMFOV=Camera.FOV or 120

	local tri,ttri,trib,line,circ,circb,print=tri,ttri,trib,line,circ,circb,print

	for _,element in pairs(drawdump) do
		local element_data=element.data

		if not element_data.hidden then

			if element.type=="t" then
				local p1,p2,p3,color=
				 element[1],element[2],element[3],element_data.c

				local uvtri=element.uv or colorToUVMap[color%16]

				if UseTTriOnly or color==nil then
					ttri(p1.drawx,p1.drawy,
					     p2.drawx,p2.drawy,
					     p3.drawx,p3.drawy,
					     uvtri[1],uvtri[2],
					     uvtri[3],uvtri[4],
					     uvtri[5],uvtri[6],
					     false,-1,p1.z,p2.z,p3.z)
				else
					tri(p1.drawx,p1.drawy,
					    p2.drawx,p2.drawy,
					    p3.drawx,p3.drawy,color)
				end

				if Wireframe then
					trib(p1.drawx,p1.drawy,
					     p2.drawx,p2.drawy,
					     p3.drawx,p3.drawy,12)
				end

			elseif element.type=="c" then
				local p,size,color,circtype=element[1],element_data.s,

				element_data.c,

				(element_data.b and circb) or circ

				size=size/((p.z==0 and .1) or p.z)*CAMFOV

				circtype(p.drawx,p.drawy,size,color)

			elseif element.type=="txt" then

				local p,size,str,color,sf=element[1],
				element_data.s,
				element_data.str,
				element_data.c or 15,
				element_data.sf

				size=math.max(1,size/((p.z==0 and .1) or p.z)*CAMFOV)

				local strlen=print(str,1000,1000,nil,true,size,sf)/2

				print(str,p.drawx-strlen,p.drawy,color,true,size,sf)

			elseif element.type=="s" then
				local p,size,uv,t=element[1],element.data.s,element.data.uv,element.data.t

				size=(size/((p.z==0 and .1) or p.z)*CAMFOV)/2

				ttri(
				 p.drawx-size,p.drawy-size,
				 p.drawx+size,p.drawy-size,
				 p.drawx-size,p.drawy+size,
				 uv[1],uv[2],
				 uv[3],uv[2],
				 uv[1],uv[4],false,t)
				ttri(
				 p.drawx+size,p.drawy-size,
				 p.drawx-size,p.drawy+size,
				 p.drawx+size,p.drawy+size,
				 uv[3],uv[2],
				 uv[1],uv[4],
				 uv[3],uv[4],false,t)

			elseif element.type=="l" then

				local p1,p2,color=element[1],element[2],
				element_data.c

				line(
				 p1.drawx,p1.drawy,
				 p2.drawx,p2.drawy,color)

			end

		end
	end

end

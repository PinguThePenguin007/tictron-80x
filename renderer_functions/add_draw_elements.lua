function Renderer.addDrawElements(customscene, BackfaceCulling)

	local scene=customscene or Renderer.data.scene
	local drawdump=scene.drawdump
	local vertexdump=scene.vertexdump

	if BackfaceCulling==nil then BackfaceCulling=Renderer.defaultSettings.BackfaceCulling end
	local nobackfaceculling=not BackfaceCulling

	local GetDotRaw,GetNormalRaw=RendererLib.GetDotRaw,RendererLib.GetNormalRaw

	for key,vertlist in pairs(vertexdump) do if key~="clippedverts" then local object=vertlist.object

		for etype,drawelement in pairs(object.mesh.drawdata) do
			local IsTrisOnly= type(etype)=="number"
			local drawdump_len=#drawdump

			if IsTrisOnly or etype=="t" then
				local tritable
				if IsTrisOnly then tritable=object.mesh.drawdata
				else tritable=drawelement end

				for _,triangle in pairs(tritable) do local triangle_p=triangle.p

					local p1,p2,p3,normal=
					 vertlist[ triangle_p[1] ],
					 vertlist[ triangle_p[2] ],
					 vertlist[ triangle_p[3] ],
					 (triangle.n or 1)

					if nobackfaceculling or normal==2 or normal==((
						GetDotRaw(
						 p1.x,p1.y,p1.z,
						 GetNormalRaw(p1.x,p1.y,p1.z,p2.x,p2.y,p2.z,p3.x,p3.y,p3.z)
						)>0) and 0 or 1)
					then
						drawdump[drawdump_len+1]={p1,p2,p3; nofverts=3,type="t",
						 data=triangle,uv=triangle.uv,object=object}
						drawdump_len=drawdump_len+1
					end

				end

			if IsTrisOnly then break end

			elseif etype=="l" then

				for _,line in pairs(drawelement) do local line_p=line.p

						drawdump[drawdump_len+1]={vertlist[line_p[1]],vertlist[line_p[2]]; nofverts=2,type="l",
						 data=line,object=object}
						drawdump_len=drawdump_len+1

				end

			else

				for _,dot in pairs(drawelement) do

						drawdump[drawdump_len+1]={vertlist[dot.p]; nofverts=1,type=etype,
						 data=dot,object=object}
						drawdump_len=drawdump_len+1

				end

			end
		end
	end end

end

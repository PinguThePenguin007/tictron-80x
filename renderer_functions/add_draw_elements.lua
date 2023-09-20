function Renderer.addDrawElements(customscene, BackfaceCulling)

	local scene=customscene or Renderer.data.scene
	local drawdump=scene.drawdump
	local vertexdump=scene.vertexdump

	if BackfaceCulling==nil then BackfaceCulling=Renderer.defaultSettings.BackfaceCulling end
	local nobackfaceculling=not BackfaceCulling

	for key,vertlist in pairs(vertexdump) do if key~="clippedverts" then local object=vertlist.object

		for etype,drawelement in pairs(object.mesh.drawdata) do
			local IsTrisOnly= type(etype)=="number"

			if IsTrisOnly or etype=="t" then
				local tritable
				if IsTrisOnly then tritable=object.mesh.drawdata
				else tritable=drawelement end

				for _,triangle in pairs(tritable) do
					local p1,p2,p3,normal=
					 vertlist[ triangle.p[1] ],
					 vertlist[ triangle.p[2] ],
					 vertlist[ triangle.p[3] ],
					 (triangle.n or 1)

					if not (p1==nil or p2==nil or p3==nil) then

						local p1_drawx,p1_drawy=p1.drawx,p1.drawy

						if nobackfaceculling or normal==2 or
							((normal==((p2.drawx-p1_drawx)*(p3.drawy-p1_drawy)-
							           (p3.drawx-p1_drawx)*(p2.drawy-p1_drawy)>0 and 1 or 0))
							~= (p1.z>0) ~= (p2.z>0) ~= (p3.z>0))
						then
							drawdump[#drawdump+1]={p1,p2,p3; nofverts=3,type="t",
							 data=triangle,uv=triangle.uv,object=object}
						end
					end

				end

			if IsTrisOnly then break end

			elseif etype=="l" then

				for _,line in pairs(drawelement) do
					local p1,p2=vertlist[line.p[1]],vertlist[line.p[2]]
					if not (p1==nil or p2==nil) then
						drawdump[#drawdump+1]={p1,p2; nofverts=2,type="l",
						 data=line,object=object}
					end
				end

			else

				for _,dot in pairs(drawelement) do
					local p1=vertlist[dot.p]
					if p1~=nil then
						drawdump[#drawdump+1]={p1; nofverts=1,type=etype,
						 data=dot,object=object}
					end
				end

			end
		end
	end end

end

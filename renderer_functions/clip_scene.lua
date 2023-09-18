function Renderer.clipScene(customscene, customcam, customplanes)

	local scene=customscene or Renderer.data.scene
	local vertexdump=scene.vertexdump
	local drawdump=scene.drawdump

	local camera=customcam or Camera
	local cplanes=customplanes or camera.CPlane

	local clippedverts=vertexdump.clippedverts

	local GetDotRaw,lerp=RendererLib.GetDotRaw,RendererLib.Lerp

	for _,cPlane in pairs(cplanes) do
		local cPlanePOSx,cPlanePOSy,cPlanePOSz,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz=
		 cPlane.position.x,cPlane.position.y,cPlane.position.z,
		 cPlane.normal.x,cPlane.normal.y,cPlane.normal.z

		for eid=#drawdump,1,-1 do
			local element=drawdump[eid]
			local NofVerts=element.nofverts

		if NofVerts==3 then

			local P1,P2,P3=element[1],element[2],element[3]
			local SubP1x,SubP2x,SubP3x,SubP1y,SubP2y,SubP3y,SubP1z,SubP2z,SubP3z=
			 P1.x-cPlanePOSx,P2.x-cPlanePOSx,P3.x-cPlanePOSx,
			 P1.y-cPlanePOSy,P2.y-cPlanePOSy,P3.y-cPlanePOSy,
			 P1.z-cPlanePOSz,P2.z-cPlanePOSz,P3.z-cPlanePOSz
			local DotP={
			 GetDotRaw(SubP1x,SubP1y,SubP1z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz),
			 GetDotRaw(SubP2x,SubP2y,SubP2z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz),
			 GetDotRaw(SubP3x,SubP3y,SubP3z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)
			}

			local d=DotP


			if d[1]<0 and d[2]<0 and d[3]<0 then
				table.remove(drawdump,eid)
			elseif d[1]<0 or d[2]<0 or d[3]<0 then

				local out={}

				local v=element
				local hasuv=not (element.data.uv==nil)

				local uv
				if hasuv then local element_uv=element.uv
					uv={{x=element_uv[1],y=element_uv[2],z=0},
			        {x=element_uv[3],y=element_uv[4],z=0},
			        {x=element_uv[5],y=element_uv[6],z=0}}
			end

				for i=1,3 do
					if d[i]>=0 and d[i%3+1]>=0 then
						local newuv
						if hasuv then newuv=uv[i] end

						out[#out+1]={p=v[i],uv=newuv}
					end
					if d[i]>=0 and d[i%3+1]<0 then
						local vSlide=d[i]/(d[i]-d[i%3+1])
						local newuv,newuv2
						if hasuv then newuv=uv[i]
							newuv2=lerp(uv[i],uv[i%3+1],vSlide)
						end

						out[#out+1]={p=v[i],uv=newuv}

						local p=lerp(v[i],v[i%3+1],vSlide)
						out[#out+1]={
						 p=p,
						 uv=newuv2}
						 clippedverts[#clippedverts+1]=p
					end
					if d[i]<0 and d[i%3+1]>=0 then
						local vSlide=d[i]/(d[i]-d[i%3+1])
						local newuv
						if hasuv then
							newuv=lerp(uv[i],uv[i%3+1],vSlide)
						end

						local p=lerp(v[i],v[i%3+1],vSlide)
						out[#out+1]={
						 p=p,
						 uv=newuv}
						 clippedverts[#clippedverts+1]=p
					end
				end


				element[1]=out[1].p
				element[2]=out[2].p
				element[3]=out[3].p
				if hasuv then
				 element.uv={
				  out[1].uv.x,out[1].uv.y,out[2].uv.x,
				  out[2].uv.y,out[3].uv.x,out[3].uv.y} end
				if #out==4 then
					local uvlist
					if hasuv then uvlist={
					 out[1].uv.x,out[1].uv.y,out[3].uv.x,
					 out[3].uv.y,out[4].uv.x,out[4].uv.y}
					end
				 table.insert(drawdump,{out[1].p,out[3].p,out[4].p;  type="t",nofverts=3,data=element.data,uv=uvlist,object=element.object})
				end
			end
		elseif NofVerts==2 then

			local P1,P2=element[1],element[2]
			local SubP1x,SubP2x,SubP1y,SubP2y,SubP1z,SubP2z=
			 P1.x-cPlanePOSx,P2.x-cPlanePOSx,
			 P1.y-cPlanePOSy,P2.y-cPlanePOSy,
			 P1.z-cPlanePOSz,P2.z-cPlanePOSz
			local DotP={
			 GetDotRaw(SubP1x,SubP1y,SubP1z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz),
			 GetDotRaw(SubP2x,SubP2y,SubP2z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz),
			}

			local d=DotP

			if d[1]<0 and d[2]<0 then
				table.remove(drawdump,eid)
			elseif d[1]<0 or d[2]<0 then

					if d[1]<0 then
						P1=lerp(P1,P2,d[1]/(d[1]-d[2]))
						clippedverts[#clippedverts+1]=P1
					end
					if d[2]<0 then
						P2=lerp(P2,P1,d[2]/(d[2]-d[1]))
						clippedverts[#clippedverts+1]=P2
					end

					element[1],element[2]=P1,P2
			end
		else

			local P=element[1]
			local SubPx,SubPy,SubPz=
			 P.x-cPlanePOSx,P.y-cPlanePOSy,P.z-cPlanePOSz
			local DotP=
			 GetDotRaw(SubPx,SubPy,SubPz,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)

			if DotP<0 then
				table.remove(drawdump,eid)
			end
		end
		end
	end


end

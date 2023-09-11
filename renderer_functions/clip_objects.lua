function Renderer.clipObjects(customscene)

	local scene=customscene or Renderer.data.scene
	local objectorigins=scene.objectorigins
	local vertexdump=scene.vertexdump

	local NormalizeRaw,GetDotRaw=RendererLib.NormalizeRaw,RendererLib.GetDotRaw

	Renderer.transformVerts({vertexdump=objectorigins},nil,false)

	for _,cPlane in pairs(Renderer.CuttingPlanes.Full) do
		local cPlanePOSx,cPlanePOSy,cPlanePOSz,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz=
		 cPlane.position.x,cPlane.position.y,cPlane.position.z,
		 cPlane.normal.x,cPlane.normal.y,cPlane.normal.z

		local normPx,normPy,normPz=
		 NormalizeRaw(cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)

		for key,list in pairs(objectorigins) do; local P=list[1]

			local radius=P.radius
			local SubPx,SubPy,SubPz=
			 P.x-cPlanePOSx,P.y-cPlanePOSy,P.z-cPlanePOSz

			local radPx,radPy,radPz=
			 SubPx+(normPx*radius),
			 SubPy+(normPy*radius),
			 SubPz+(normPz*radius)

			local DotP=
			 GetDotRaw(radPx,radPy,radPz,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)

			if DotP<0 then
				vertexdump[key]=nil
			end

		end

	end
end

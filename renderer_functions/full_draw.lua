-- Does everything required to draw a scene, while still having customizability.
-- You still need to reset the scene yourself, though.
function Renderer.fullDraw(objects,customscene,settings,centerx,centery)

	settings=settings or {}
	if settings.ClipObjects==nil then settings.ClipObjects=Renderer.defaultSettings.ClipObjects end
	if settings.Sort==nil then settings.Sort=Renderer.defaultSettings.Sort end
	if settings.EnableLabels==nil then settings.EnableLabels=Renderer.defaultSettings.EnableLabels end


	Renderer.addObjectsToScene(objects,customscene,nil,settings.clipObjects)
	if settings.ClipObjects then
		Renderer.clipObjects(customscene)
	end

	local verts=Renderer.transformVerts(customscene)
	Renderer.projectVerts(customscene,centerx,centery)
	Renderer.addDrawElements(customscene, settings.BackfaceCulling)
	if settings.EnableLabels then
		Renderer.replaceLabels(customscene)
	end

	Renderer.clipScene(customscene)
	if settings.Sort then
		Renderer.sortScene(customscene, settings.SimpleSort)
	end

	Renderer.drawScene(customscene,true,centerx,centery, settings.UseTTriOnly, settings.Wireframe)

	return verts
end

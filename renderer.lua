
package.path = package.path..";/home/pingu/tic80-folder/tictron-80x/renderer_functions/?.lua"

require "libraries"

Renderer={

defaultSettings={

-- Whether to display the back face of triangles ("false") or not ("true").
-- Improves performance if set to "true".
BackfaceCulling=true,

-- If disabled, gives more accurate results, at cost of performance.
SimpleSort=true,

-- Option to use tri for untextured triangles (if set to "false").
-- Not recommended to disable, although performance is better this way.
UseTTriOnly=true,

-- Draws a wireframe for triangles.
Wireframe=false,


EnableLabels=true,
ClipObjects=true,
Sort=true,

},

-- the Renderer's data, which is (usually) used during processing.
data={

scene={

-- contains vertices for transformation and other uses
vertexdump={
clippedverts={}, --contains vertices resulted from clipping the scene
},

-- contains draw elements (triangles, lines, etc.) for drawing, sorting, etc.
drawdump={},

camera={

position=    {x=0,y=0,z=0},
rotation=    {x=0,y=0,z=0},
originoffset={x=0,y=0,z=0},
FOV=120,
CPlane=nil

},

},


-- if the UseTTriOnly setting is enabled, this map is used for proper coloring
colorToUVMap={},

},

-- Debug variables.
debug={

},

-- The default cutting planes for clipping the scene.
CuttingPlanes={

NearOnly={}, --for clipping directly in front of the camera (usually the fastest)
NearFar={}, --for clipping in the front, both close and at a distance (recommended)
Full={} --for full clipping, both near, far, and at all the sides (usually the slowest)

},

}

Renderer.data.scene.camera.CPlane=Renderer.CuttingPlanes.NearFar

Rscene=Renderer.data.scene

-- Resets the default scene and setups some other variables for the Renderer, if need be.
-- Should be reset at least 1 time during program execution befofe doing anything else!
function Renderer.resetScene(customscene,newcamera)

	local scene=customscene or Renderer.data.scene
	local camera=newcamera or scene.camera


	-- we clear our working tables and out vertex count
	scene.vertexdump={clippedverts={}}
	scene.drawdump={}
	scene.objectorigins=nil
	scene.camera=camera

	-- we create our plane and map data if they were not created yet, so you have less work to do
	if #Renderer.CuttingPlanes==0 then Renderer.recalculateCPlanes(camera) end
	if #Renderer.data.colorToUVMap==0  then Renderer.buildColorMap(255) end

end

-- Builds a color map based on a special sprite where each color corresponds to
-- UV coordinates of the color on the sprite.
function Renderer.buildColorMap(sprite)

	local colorToUVMap={} --prepare a table
	for color=0,15 do --do for each color:
		--transform a sprite's ID to its starting coordinates and add an offset based on the color
		local u,v=
		 (sprite%16)*8+(color%4)*2+1,
		 (sprite//16)*8+(color//4)*2+1
		colorToUVMap[color]={u,v,u,v,u,v} --add that to the table
	end

	Renderer.data.colorToUVMap=colorToUVMap --apply to global table
end

function Renderer.recalculateCPlanes(customcam)
	local camera=customcam or Camera or {}

	local camFOV=camera.FOV or 120


	local NearPlane={position={x=0,y=0,z=camera.NearDistance or .1},normal={x=0,y=0,z=1}}
	local FarPlane={position={x=0,y=0,z=camera.FarDistance or 64},normal={x=0,y=0,z=-1}}
	local UpPlane={position={x=0,y=0,z=0},normal={x=0,y=1,z=68/camFOV}}
	local DownPlane={position={x=0,y=0,z=0},normal={x=0,y=-1,z=68/camFOV}}
	local LeftPlane={position={x=0,y=0,z=0},normal={x=-1,y=0,z=120/camFOV}}
	local RightPlane={position={x=0,y=0,z=0},normal={x=1,y=0,z=120/camFOV}}



	Renderer.CuttingPlanes.NearOnly[1]=NearPlane

	Renderer.CuttingPlanes.NearFar[1]=NearPlane
	Renderer.CuttingPlanes.NearFar[2]=FarPlane

	Renderer.CuttingPlanes.Full[1]=NearPlane
	Renderer.CuttingPlanes.Full[2]=FarPlane
	Renderer.CuttingPlanes.Full[3]=UpPlane
	Renderer.CuttingPlanes.Full[4]=DownPlane
	Renderer.CuttingPlanes.Full[5]=LeftPlane
	Renderer.CuttingPlanes.Full[6]=RightPlane

end

require "add_single_object"
require "add_objects_to_scene"
require "transform_verts"
require "clip_objects"
require "add_draw_elements"
require "replace_labels"
require "sort_scene"
require "clip_scene"
require "project_verts"
require "draw_scene"
require "full_draw"

return Renderer

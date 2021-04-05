package;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.nape.FlxNapeSpace;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import nape.constraint.WeldJoint;
import nape.dynamics.InteractionFilter;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;
import openfl.display.BitmapData;

class PhysicsMeshSprite extends FlxSprite
{
	private static inline var FILL_COLOR = 0x00FF00; // 0x7C7088;

	private var _vertices:DrawData<Float>;
	private var _indices:DrawData<Int>;

	private var _uvtData:DrawData<Float>;
	private var colors:DrawData<Int>;

	private var _drawOffset:FlxPoint;

	private var meshPixels:BitmapData;

	private var bodies:Array<Body>;
	private var innerBodies:Array<Body>;
	private var joints:Array<WeldJoint>;

	public var minX(default, null):Float = 0;
	public var maxX(default, null):Float = 0;
	public var minY(default, null):Float = 0;
	public var maxY(default, null):Float = 0;

	private var filterBit:Int;
	private var circleRadius:Float;

	public function new(meshAsset:String, meshScale:Float, startX:Float, startY:Float, filterBit:Int, circleRadius:Float = 5)
	{
		super(0, 0);

		_uvtData = null;
		colors = null;
		_drawOffset = FlxPoint.get();

		this.filterBit = filterBit;
		this.circleRadius = circleRadius;

		setMesh(meshAsset, meshScale, startX, startY);
	}

	private function setMesh(asset:String, scale:Float, startX:Float, startY:Float)
	{
		meshPixels = new BitmapData(100, 100, true, FlxColor.TRANSPARENT);

		var mesh = MeshUtils.load(asset, scale);
		var perimiter = MeshUtils.findPerimiter(mesh);

		_indices = new DrawData();
		for (t in mesh.triangles)
		{
			_indices.push(t);
		}

		_uvtData = new DrawData();
		for (uv in mesh.uvs)
		{
			_uvtData.push(uv.x);
			_uvtData.push(uv.y);
		}

		bodies = new Array<Body>();
		for (v in mesh.points)
		{
			var body = new Body(BodyType.DYNAMIC, Vec2.weak(v.x + startX, v.y + startY));
			body.shapes.add(new Circle(circleRadius));
			body.allowRotation = false;
			body.setShapeMaterials(new Material(1, 0.1, 2, 1, 0.001));
			// body.isBullet = true;
			body.space = FlxNapeSpace.space;

			var filter = new InteractionFilter(filterBit, ~filterBit);
			body.setShapeFilters(filter);

			bodies.push(body);
		}

		innerBodies = new Array<Body>();
		for (i in 0...bodies.length)
		{
			if (!perimiter.contains(i))
			{
				innerBodies.push(bodies[i]);
			}
		}

		// Connect circle bodies using distance joints to create soft body.
		joints = new Array<WeldJoint>();

		var b1:Body = null;
		var b2:Body = null;
		for (l in mesh.lines)
		{
			b1 = bodies[l.a];
			b2 = bodies[l.b];

			var median = new Vec2(b1.position.x + (b2.position.x - b1.position.x) / 2, b1.position.y + (b2.position.y - b1.position.y) / 2);
			var constrain:WeldJoint = new WeldJoint(b1, b2, b1.worldPointToLocal(median), b2.worldPointToLocal(median), 0);

			///constrain.damping = 1;
			constrain.frequency = 5;
			constrain.stiff = false;
			constrain.space = FlxNapeSpace.space;

			joints.push(constrain);
		}
	}

	override function destroy()
	{
		_drawOffset = FlxDestroyUtil.put(_drawOffset);
		meshPixels = FlxDestroyUtil.dispose(meshPixels);

		for (j in joints)
		{
			j.space = null;
		}
		joints = null;

		for (b in bodies)
		{
			b.space = null;
		}
		bodies = null;
		innerBodies = null;

		super.destroy();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	override function kill()
	{
		super.kill();

		for (b in bodies)
		{
			b.space = null;
		}
	}

	override function revive()
	{
		super.revive();

		for (b in bodies)
		{
			b.space = FlxNapeSpace.space;
		}
	}

	override function drawSimple(camera:FlxCamera):Void
	{
		calcImage();
		drawImage();

		if (isPixelPerfectRender(camera))
			_point.floor();

		_point.addPoint(_drawOffset).copyToFlash(_flashPoint);
		camera.copyPixels(_frame, meshPixels, meshPixels.rect, _flashPoint, colorTransform, blend, antialiasing);
	}

	override function drawComplex(camera:FlxCamera):Void
	{
		calcImage();
		drawFrame();

		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		if (isPixelPerfectRender(camera))
			_point.floor();

		if (_frameGraphic == null)
			_frameGraphic = FlxGraphic.fromBitmapData(framePixels, false, null, false);

		camera.drawTriangles(_frameGraphic, _vertices, _indices, _uvtData, colors, _point.addPoint(_drawOffset), blend, antialiasing);
	}

	function calcImage():Void
	{
		_vertices = new DrawData();

		// get bounds
		minX = 9999999;
		maxX = -9999999;
		minY = 9999999;
		maxY = -9999999;

		for (p in bodies)
		{
			_vertices.push(p.position.x);
			_vertices.push(p.position.y);

			minX = Math.min(minX, p.position.x);
			maxX = Math.max(maxX, p.position.x);
			minY = Math.min(minY, p.position.y);
			maxY = Math.max(maxY, p.position.y);
		}

		_drawOffset.set(minX, minY);

		var i:Int = 0;
		while (i < _vertices.length - 1)
		{
			_vertices[i] = _vertices[i] - minX;
			_vertices[i + 1] = _vertices[i + 1] - minY;
			i += 2;
		}

		if (meshPixels == null)
		{
			return;
		}

		// Check if the bitmapData is smaller than the current image and create new one if needed
		var w:Int = Std.int(Math.max(meshPixels.width, maxX - minX));
		var h:Int = Std.int(Math.max(meshPixels.height, maxY - minY));

		if (meshPixels.width < w || meshPixels.height < h)
		{
			meshPixels = new BitmapData(w, h, true, FlxColor.TRANSPARENT);
		}
		else
		{
			meshPixels.fillRect(meshPixels.rect, FlxColor.TRANSPARENT);
		}
	}

	function drawImage():Void
	{
		if (meshPixels != null)
		{
			FlxSpriteUtil.flashGfx.clear();
			FlxSpriteUtil.flashGfx.beginFill(FILL_COLOR, 1);
			FlxSpriteUtil.flashGfx.drawTriangles(_vertices, _indices);
			FlxSpriteUtil.flashGfx.endFill();

			meshPixels.draw(FlxSpriteUtil.flashGfxSprite);
		}
	}

	public function findNearestNode(p:Vec2)
	{
		var nd:Float = -1;
		var n:Body = null;

		for (b in bodies)
		{
			var cd = Vec2.distance(b.position, p);
			if (nd < 0 || cd < nd)
			{
				n = b;
				nd = cd;
			}
		}

		return n;
	}

	public function findNodesNear(pos:Vec2, distance:Float):Array<Body>
	{
		var res:Array<Body> = new Array<Body>();

		for (b in bodies)
		{
			if (Vec2.distance(b.position, pos) < distance)
			{
				res.push(b);
			}
		}

		return res;
	}
}

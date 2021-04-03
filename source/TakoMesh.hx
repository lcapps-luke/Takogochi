package;

import nape.dynamics.InteractionFilter;
import nape.shape.Circle;

using flixel.util.FlxSpriteUtil;

class TakoMesh extends PhysicsMeshSprite
{
	public static inline var ANI_CONTENTED:String = "contented";
	public static inline var ANI_HAPPY:String = "happy";
	public static inline var ANI_BONK:String = "bonk";

	private static var nextMask:Int = 2;

	private var restWidth:Float;
	private var restHeight:Float;

	public var lastEmote(default, null):String;

	public function new(startX:Float, startY:Float)
	{
		super(AssetPaths.tako_mid__obj, 1, startX, startY, nextMask);
		nextMask = nextMask * 2;

		loadGraphic(AssetPaths.tako_sheet__png, true, 256, 204);
		animation.add(ANI_CONTENTED, [0]);
		animation.add(ANI_HAPPY, [1]);
		animation.add(ANI_BONK, [2]);

		emote(ANI_CONTENTED);

		calcImage();
		restWidth = maxX - minX;
		restHeight = maxY - minY;
	}

	override function setMesh(asset:String, scale:Float, startX:Float, startY:Float)
	{
		super.setMesh(asset, scale, startX, startY);

		var ibx:Float = 0;
		var iby:Float = 0;

		for (ib in innerBodies)
		{
			ib.shapes.clear();
			ib.shapes.add(new Circle(20));

			var filter = new InteractionFilter(filterBit, ~filterBit);
			ib.setShapeFilters(filter);

			ibx = ib.position.x;
			iby = ib.position.y;
		}

		for (b in bodies)
		{
			for (s in b.shapes)
			{
				var dir = Math.atan2(iby - b.position.y, ibx - b.position.x);
				s.localCOM.setxy(Math.cos(dir) * circleRadius, Math.sin(dir) * circleRadius);
			}
		}
	}

	public function getHorizontalStretch():Float
	{
		return (maxX - minX) / restWidth;
	}

	public function getVerticalStretch():Float
	{
		return (maxY - minY) / restHeight;
	}

	public function emote(ani:String)
	{
		lastEmote = ani;
		animation.play(ani);
	}
}

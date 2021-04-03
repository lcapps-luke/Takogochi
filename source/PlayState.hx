package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.Material;

class PlayState extends FlxState
{
	private var holdNode:Body = null;
	private var holdOffset:FlxPoint;

	private var takoGroup:FlxTypedSpriteGroup<Tako>;
	private var tako:Array<Tako>;

	override public function create()
	{
		super.create();
		this.bgColor = 0x00FFFFFF;

		FlxNapeSpace.init();

		FlxNapeSpace.createWalls(0, 0, 960, 540, 5, new Material(1, 1, 2, 1, 0.001));
		FlxNapeSpace.space.gravity.setxy(0, 500);

		takoGroup = new FlxTypedSpriteGroup<Tako>();
		add(takoGroup);

		tako = new Array<Tako>();

		var margin = 60;
		var space = 960 - margin * 2;
		for (i in 0...4)
		{
			var x = margin + (space / 4) * i;
			var t = new Tako(x, 100);
			takoGroup.add(t);
			tako.push(t);
		}

		holdOffset = FlxPoint.get();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed)
		{
			var mousePos = new Vec2(FlxG.mouse.x, FlxG.mouse.y);

			var nd:Float = -1;
			holdNode = null;
			for (t in tako)
			{
				var b = t.mesh.findNearestNode(mousePos);
				var d = Vec2.distance(b.position, mousePos);
				if (holdNode == null || d < nd)
				{
					holdNode = b;
					nd = d;
				}
			}

			holdOffset.set(holdNode.position.x - mousePos.x, holdNode.position.y - mousePos.y);
		}

		if (FlxG.mouse.justReleased)
		{
			holdNode = null;
		}

		if (holdNode != null)
		{
			var holdPoint = FlxPoint.get();
			FlxG.mouse.getPosition().copyTo(holdPoint);
			holdPoint.addPoint(holdOffset);

			var vx = (holdPoint.x - holdNode.position.x) * 50;
			var vy = (holdPoint.y - holdNode.position.y) * 50;

			FlxDestroyUtil.put(holdPoint);

			holdNode.velocity.setxy(vx, vy);
		}

		takoGroup.sort(takoOrder, FlxSort.DESCENDING);
	}

	private inline function takoOrder(order:Int, a:Tako, b:Tako)
	{
		return a.mesh.maxY < b.mesh.maxY ? order : -order;
	}
}

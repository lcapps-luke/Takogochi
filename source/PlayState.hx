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
	private static inline var TOUCH_RADIUS:Float = 20;
	private static inline var GRAB_DISTANCE:Float = 100;
	private static inline var MAX_PAT_TIME:Float = 0.5;

	private var holdNodes:List<HoldNode>;
	private var heldTako:Tako;
	private var holdTime:Float = 0;

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

		holdNodes = new List<HoldNode>();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed)
		{
			grab();
		}

		if (FlxG.mouse.justReleased)
		{
			releaseHold();
		}

		if (!holdNodes.isEmpty())
		{
			updateHold(elapsed);
		}

		takoGroup.sort(takoOrder, FlxSort.DESCENDING);
	}

	private inline function grab()
	{
		var mousePos = Vec2.get(FlxG.mouse.x, FlxG.mouse.y);

		clearHoldNodes();

		for (t in tako)
		{
			for (b in t.mesh.findNodesNear(mousePos, TOUCH_RADIUS))
			{
				holdNodes.add({
					body: b,
					offset: FlxPoint.get(b.position.x - mousePos.x, b.position.y - mousePos.y)
				});
			}

			if (!holdNodes.isEmpty())
			{
				heldTako = t;
				holdTime = 0;
				break;
			}
		}

		mousePos.dispose();
	}

	private inline function releaseHold()
	{
		if (holdTime < MAX_PAT_TIME)
		{
			heldTako.pat();

			for (n in holdNodes)
			{
				n.body.velocity.addeq(Vec2.get(0, 100, true));
			}
		}

		clearHoldNodes();
	}

	private inline function clearHoldNodes()
	{
		for (n in holdNodes)
		{
			FlxDestroyUtil.put(n.offset);
		}
		holdNodes.clear();
	}

	private inline function updateHold(elapsed:Float)
	{
		holdTime += elapsed;
		var holdPoint = FlxPoint.get();

		for (n in holdNodes)
		{
			FlxG.mouse.getPosition().copyTo(holdPoint);
			holdPoint.addPoint(n.offset);

			var vx = (holdPoint.x - n.body.position.x) * 50;
			var vy = (holdPoint.y - n.body.position.y) * 50;

			n.body.velocity.setxy(vx, vy);
		}

		FlxDestroyUtil.put(holdPoint);
	}

	private inline function takoOrder(order:Int, a:Tako, b:Tako)
	{
		return a.mesh.maxY < b.mesh.maxY ? order : -order;
	}
}

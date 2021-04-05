package;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class Tako extends FlxSpriteGroup
{
	public var mesh(default, null):TakoMesh;

	private var halo:FlxSprite;

	private var squishTime:Float = 0;

	private var patCount:Int = 0;
	private var patCooldown:Float = 0;

	public function new(sx:Float, sy:Float)
	{
		super();

		halo = new FlxSprite(0, 0, AssetPaths.halo__png);
		halo.scale.set(0.3, 0.3);
		add(halo);

		mesh = new TakoMesh(sx, sy);
		add(mesh);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		halo.x = mesh.minX + (mesh.maxX - mesh.minX) / 2;
		halo.x = halo.x - halo.width / 2;
		halo.y = mesh.minY - 50;

		if (mesh.getVerticalStretch() < 0.8)
		{
			squishTime += elapsed;
		}
		else
		{
			squishTime = 0;
		}

		if (squishTime > 0.5 && mesh.lastEmote != TakoMesh.ANI_BONK)
		{
			mesh.emote(TakoMesh.ANI_BONK);
		}

		if (mesh.getVerticalStretch() > 0.8 && mesh.lastEmote == TakoMesh.ANI_BONK)
		{
			mesh.emote(TakoMesh.ANI_CONTENTED);
		}

		if (patCooldown > 0)
		{
			patCooldown -= elapsed;
			if (patCooldown <= 0)
			{
				mesh.emote(TakoMesh.ANI_CONTENTED);
			}
		}
	}

	public function pat()
	{
		if (patCooldown > 0)
		{
			return;
		}

		patCount++;

		if (patCount > 5)
		{
			patCooldown = 30;
			patCount = 0;
			mesh.emote(TakoMesh.ANI_HAPPY);
		}
	}
}

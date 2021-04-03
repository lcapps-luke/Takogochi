package;

import flixel.addons.editors.ogmo.FlxOgmo3Loader.Point;
import flixel.math.FlxPoint;
import flixel.util.FlxArrayUtil;
import haxe.io.BytesInput;
import lime.utils.Assets;
import mme.format.obj.Reader;

class MeshUtils
{
	public static function load(path:String, scale:Float):Mesh
	{
		var bytes = Assets.getBytes(path);
		var reader = new Reader(new BytesInput(bytes));

		var data = reader.read();
		var points = new Array<FlxPoint>();
		var uvs = new Array<FlxPoint>();
		var uvis = new Array<Int>();
		var triangles = new Array<Int>();
		var lines = new Array<Line>();
		for (l in data)
		{
			switch (l)
			{
				case CVertex(v):
					points.push(new FlxPoint(v.x * scale, -v.y * scale));
				case CFace(f):
					var a = f[0].vertexIndex - 1;
					var b = f[1].vertexIndex - 1;
					var c = f[2].vertexIndex - 1;

					triangles.push(a);
					triangles.push(b);
					triangles.push(c);

					uvis[a] = f[0].uvIndex - 1;
					uvis[b] = f[1].uvIndex - 1;
					uvis[c] = f[2].uvIndex - 1;

					registerFaceLine(lines, a, b);
					registerFaceLine(lines, b, c);
					registerFaceLine(lines, c, a);
				case CTextureUV(vt):
					uvs.push(new FlxPoint(vt.u, 1 - vt.v));
				default:
			}
		}

		var uv = new Array<FlxPoint>();
		for (i in uvis)
		{
			uv.push(uvs[i]);
		}

		return {
			points: points,
			uvs: uv,
			triangles: triangles,
			lines: lines
		};
	}

	private static function findLine(list:Array<Line>, a:Int, b:Int):Line
	{
		for (l in list)
		{
			if ((a == l.a && b == l.b) || (a == l.b && b == l.a))
			{
				return l;
			}
		}
		return null;
	}

	private static function registerFaceLine(list:Array<Line>, a:Int, b:Int)
	{
		var l = findLine(list, a, b);
		if (l == null)
		{
			l = {
				a: a,
				b: b,
				faceCount: 0
			};

			list.push(l);
		}

		l.faceCount++;
	}

	public static function findPerimiter(mesh:Mesh):Array<Int>
	{
		var res:Array<Int> = new Array<Int>();

		var perimiterLines:Array<Line> = new Array<Line>();
		for (l in mesh.lines)
		{
			if (l.faceCount == 1)
			{
				perimiterLines.push(l);
			}
		}

		var firstLine:Line = perimiterLines.pop();
		res.push(firstLine.a);
		res.push(firstLine.b);
		var lastIdx = firstLine.b;

		while (perimiterLines.length > 0)
		{
			for (l in perimiterLines)
			{
				if (l.a == lastIdx)
				{
					res.push(l.b);
					lastIdx = l.b;
					perimiterLines.remove(l);
					break;
				}

				if (l.b == lastIdx)
				{
					res.push(l.a);
					lastIdx = l.a;
					perimiterLines.remove(l);
					break;
				}
			}
		}

		return res;
	}
}

typedef Mesh =
{
	var points:Array<FlxPoint>;
	var uvs:Array<FlxPoint>;
	var triangles:Array<Int>;
	var lines:Array<Line>;
}

typedef Line =
{
	var a:Int;
	var b:Int;
	var faceCount:Int;
}

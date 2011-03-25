package fplanet{
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.geom.Rectangle;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.events.Event;

	import com.adobe.utils.*;

	public class Earth {
		private static var instance : Earth;
		private static var root : Stage;
		private static var stage : Stage3D;
		private static var context : Context3D;
		private static var program : Program3D;

		private static var stageHeight : uint;
		private static var stageWidth : uint;

		private static const segmentsH : uint = 40;
		private static const segmentsW : uint = 40;

		private static const textureW : uint = 2048;
		private static const textureH : uint = 1024;

		private static const radius : Number = textureW * 0.5 / Math.PI;

		public function Earth(theStage : Stage) : void {
			if(instance) throw new Error("Our planet is unique!");

			stageWidth = theStage.stageWidth;
			stageHeight = theStage.stageHeight;
			root = theStage;
			stage = theStage.stage3Ds[0];

			getContext3D();
		}
		
		public static function init(stage : Stage) : Earth {
			if(instance == null) {
				instance = new Earth(stage);
			}
			return instance;
		}

		private function getContext3D() : void {
			stage.viewPort = new Rectangle(0, 0, stageWidth, stageHeight);
			stage.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
			stage.requestContext3D(Context3DRenderMode.AUTO);
		}
		
		private function onContext3DCreate(evt : Event) : void {
			context = stage.context3D;
			context.configureBackBuffer(stageWidth, stageHeight, 4, true);

			var s : EarthShader = EarthShader.getInstance(context);
			createSphere();
			createTexture();
			essemble();
			createPerspective();

			root.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}


		//this function comes from away3d
		private var vertices : Vector.<Number>;
		private var vertexNormals : Vector.<Number>;
		private var vertexTangents : Vector.<Number>;

		private var indices : Vector.<uint>;
		private var uvData : Vector.<Number>;

		private var indexBuffer : IndexBuffer3D;

		private function createSphere() : void {
			var i : uint, j : uint, triIndex : uint;

			var numVerts : uint = (segmentsH + 1) * (segmentsW + 1);
			var numUvs : uint = numVerts * 2;

			vertices = new Vector.<Number>(numVerts * 3, true);
			vertexNormals = new Vector.<Number>(numVerts * 3, true);
			vertexTangents = new Vector.<Number>(numVerts * 3, true);

			indices = new Vector.<uint>((segmentsH - 1) * segmentsW * 6, true);
			uvData = new Vector.<Number>(numUvs, true);

			numVerts = 0;
			numUvs = 0;
			for (j = 0; j <= segmentsH; ++j) {
				var horangle : Number = Math.PI * j / segmentsH;
				var z : Number = -radius * Math.cos(horangle);
				var ringradius : Number = radius * Math.sin(horangle);

				for (i = 0; i <= segmentsW; ++i) {
					var verangle : Number = 2 * Math.PI * i / segmentsW;
					var x : Number = ringradius * Math.cos(verangle);
					var y : Number = ringradius * Math.sin(verangle);
					var normLen : Number = 1 / Math.sqrt(x * x + y * y + z * z);
					var tanLen : Number = Math.sqrt(y * y + x * x);

					vertexNormals[numVerts] = x * normLen;
					vertexTangents[numVerts] = tanLen > .007 ? -y / tanLen : 1;
					vertices[numVerts++] = x;
					vertexNormals[numVerts] = y * normLen;
					vertexTangents[numVerts] = tanLen > .007 ? x / tanLen : 0;
					vertices[numVerts++] = y;
					vertexNormals[numVerts] = z * normLen;
					vertexTangents[numVerts] = 0;
					vertices[numVerts++] = z;

					if (i > 0 && j > 0) {
						var a : int = (segmentsW + 1) * j + i;
						var b : int = (segmentsW + 1) * j + i - 1;
						var c : int = (segmentsW + 1) * (j - 1) + i - 1;
						var d : int = (segmentsW + 1) * (j - 1) + i;

						if (j == segmentsH) {
							indices[triIndex++] = a;
							indices[triIndex++] = c;
							indices[triIndex++] = d;
						}
						else if (j == 1) {
							indices[triIndex++] = a;
							indices[triIndex++] = b;
							indices[triIndex++] = c;
						}
						else {
							indices[triIndex++] = a;
							indices[triIndex++] = b;
							indices[triIndex++] = c;
							indices[triIndex++] = a;
							indices[triIndex++] = c;
							indices[triIndex++] = d;
						}
					}

					uvData[numUvs++] = i / segmentsW;
					uvData[numUvs++] = j / segmentsH;
				}
			}

			trace("vertices: " + vertices.length + " | indices: " + indices.length + " | uvs: " + uvData.length);
		}

		private function essemble() : void {
			var v_assembler : AGALMiniAssembler = new AGALMiniAssembler();
			v_assembler.assemble(Context3DProgramType.VERTEX, 
					"mov vt0, va0 \n" + 
					"mov vt1, va1 \n" + 
					"mov vt2, va2 \n" + 
					"m44 op, vt0, vc0 \n" + 
					"mov v0, vt1 \n" + 
					"mov v1, vt2");

			var f_assembler : AGALMiniAssembler = new AGALMiniAssembler();
			f_assembler.assemble( Context3DProgramType.FRAGMENT,
					"mov ft0, v0\n"+
					//add textures
					"tex ft1, ft0, fs0 <2d,clamp,linear>\n"+ 
					"tex ft2, ft0, fs1 <2d,clamp,linear>\n"+ 
					"tex ft3, ft0, fs2 <2d,clamp,linear>\n"+ 
					//"tex ft4, ft0, fs3 <2d,clamp,linear>\n"+ 

					//"mul ft5, ft1, ft4\n"+//merge earth and terminator map
					//"sub ft6, fc0, ft4\n"+//invert twilight zone
					//"mul ft7, ft2, ft6\n"+//merge night and inverted terminator map
					//"add ft0, ft7, ft5\n"+//merge night and earth
					"dp3 ft4, fc2, v1\n"+ //dp light and uv
					"mul ft5, fc3, ft4\n"+ //invert light
					"sge ft6, ft5, fc4\n"+ //make mask
					"mul ft1, ft1, ft6\n"+ //mask day
					"sge ft6, fc4, ft6\n"+ //invert mask
					"mul ft2, ft2, ft6\n"+ //invert mask

					"mul ft3, ft3, fc1\n"+//make a little alpha for clouds
					"add oc, ft1, ft2"
					);

			var program : Program3D = context.createProgram();
			program.upload(v_assembler.agalcode, f_assembler.agalcode);
			context.setProgram(program);

			var num_v : int = vertices.length/3; 
			var vb : VertexBuffer3D = context.createVertexBuffer(num_v, 3);
			vb.uploadFromVector(vertices, 0, num_v);

			var uvb : VertexBuffer3D = context.createVertexBuffer(num_v, 2);
			uvb.uploadFromVector(uvData, 0, num_v);

			var nb : VertexBuffer3D = context.createVertexBuffer(num_v, 3);
			nb.uploadFromVector(vertexNormals, 0, num_v);

			//var tb : VertexBuffer3D = context.createVertexBuffer(num_v, 3);
			//tb.uploadFromVector(vertexTangents, 3, num_v);

			context.setVertexBufferAt(0, vb, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(1, uvb, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(2, nb, 0, Context3DVertexBufferFormat.FLOAT_3);
			//context.setVertexBufferAt(3, tb, 0, Context3DVertexBufferFormat.FLOAT_3);

			var num_i : uint = indices.length;
			indexBuffer = context.createIndexBuffer(num_i);
			indexBuffer.uploadFromVector(indices, 0, num_i);

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([1, 1, 1, 1]));

			var cloudAlpha : Number = 0.8;
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([cloudAlpha, cloudAlpha, cloudAlpha, 1]));

			var geoClock : GeoClock = GeoClock.getInstance();
			solarPosition = geoClock.updateTerminatorMap();

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([solarPosition.x, solarPosition.y, solarPosition.z, 1]));

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, Vector.<Number>([-1, -1, -1, 1]));

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 4, Vector.<Number>([0, 0, 0, 0]));
			

			//context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([solarPosition.x, solarPosition.y, solarPosition.z, 1]));

		}

		[Embed(source="../../res/earth.jpg")]
		private var EarthSrc : Class;
		private var earthSrc : Bitmap = new EarthSrc() as Bitmap;

		[Embed(source="../../res/night.jpg")]
		private var NightSrc : Class;
		private var nightSrc : Bitmap = new NightSrc() as Bitmap;

		[Embed(source="../../res/clouds.jpg")]
		private var CloudsSrc : Class;
		private var cloudsSrc : Bitmap = new CloudsSrc() as Bitmap;

		private var solarPosition : Vector3D;

		private function createTexture() : void {

			var t0 : Texture = context.createTexture(textureW, textureH, Context3DTextureFormat.BGRA, true );
			t0.uploadFromBitmapData( earthSrc.bitmapData );
			context.setTextureAt(0, t0);

			var t1: Texture = context.createTexture(textureW, textureH, Context3DTextureFormat.BGRA, true );
			t1.uploadFromBitmapData( nightSrc.bitmapData );
			context.setTextureAt(1, t1);

			var t2 : Texture = context.createTexture(textureW, textureH, Context3DTextureFormat.BGRA, true );
			t2.uploadFromBitmapData( cloudsSrc.bitmapData );
			context.setTextureAt(2, t2);

			//var mask : Texture = context.createTexture(textureW, textureH, Context3DTextureFormat.BGRA, true );
			//mask.uploadFromBitmapData(bd);
			//context.setTextureAt(3, mask);
		}

		private var rotation : Number = 0;
		private var pers : PerspectiveMatrix3D;
		private var camera : Matrix3D;
		private var modelView : Matrix3D;

		private function createPerspective() : void {
			pers = new PerspectiveMatrix3D();
			pers.perspectiveLH(1, 1/7.5 * 4.6, 3, 1000000);

			camera = new Matrix3D();
			camera.appendTranslation(0, 0, radius*10);
		
			modelView = new Matrix3D();
		}

		private function onEnterFrame(evt : Event) : void {
			rotation -= 0.2;
			modelView.identity();
			modelView.appendRotation(90, Vector3D.X_AXIS);
			modelView.appendRotation(rotation, Vector3D.Y_AXIS);

			var m : Matrix3D = new Matrix3D();
			m.identity();
			m.append(modelView);
			m.append(camera);
			m.append(pers);

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
			context.clear();

			context.drawTriangles(indexBuffer);
			context.present();
		}

	}
}

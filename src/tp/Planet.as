package tp{
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.geom.Rectangle;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.events.Event;

	import com.adobe.utils.*;

	public class Planet {
		private static var instance : Planet;
		private static var root : Stage;
		private static var stage : Stage3D;
		private static var context : Context3D;
		private static var program : Program3D;

		private static var stageHeight : uint;
		private static var stageWidth : uint;

		private static const segmentsH : uint = 40;
		private static const segmentsW : uint = 40;
		private static const radius : uint = 162;


		public function Planet(theStage : Stage) : void {
			if(instance) throw new Error("Our planet is unique!");

			stageWidth = theStage.stageWidth;
			stageHeight = theStage.stageHeight;
			root = theStage;
			stage = theStage.stage3Ds[0];

			getContext3D();
		}
		
		public static function init(stage : Stage) : Planet {
			if(instance == null) {
				instance = new Planet(stage);
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

			createSphere();
			testDraw();
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

		[Embed(source="../../res/march.jpg")]
		private var BlueMarblePic : Class;
		private var bm : Bitmap = new BlueMarblePic() as Bitmap;

		private function testDraw() : void {
			trace("BitmapData: " + bm.width + "x" + bm.height);

			var texture : Texture = context.createTexture(1024, 512, Context3DTextureFormat.BGRA, true );
			texture.uploadFromBitmapData( bm.bitmapData );
			context.setTextureAt(1, texture);

			var v_assembler : AGALMiniAssembler = new AGALMiniAssembler();
			v_assembler.assemble(Context3DProgramType.VERTEX, 
					"mov vt0, va0 \n" + 
					"mov vt1, va1 \n" + 
					"m44 op, vt0, vc0 \n" + 
					"mov v0, vt1");

			var f_assembler : AGALMiniAssembler = new AGALMiniAssembler();
			f_assembler.assemble( Context3DProgramType.FRAGMENT,
					"mov ft0, v0\n"+
					"tex ft1, ft0, fs1 <2d,clamp,linear>\n"+ 
					"sge ft2, ft1, fc0 \n"+
					"mov oc, ft1\n"
					);

			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([0, 0, 0.001, 1]));

			var program : Program3D = context.createProgram();
			program.upload(v_assembler.agalcode, f_assembler.agalcode);
			context.setProgram(program);

			var num_v : int = vertices.length/3; 
			var vb : VertexBuffer3D = context.createVertexBuffer(num_v, 3);
			vb.uploadFromVector(vertices, 0, num_v);

			var uvb : VertexBuffer3D = context.createVertexBuffer(num_v, 2);
			uvb.uploadFromVector(uvData, 0, num_v);

			context.setVertexBufferAt(0, vb, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(1, uvb, 0, Context3DVertexBufferFormat.FLOAT_2);

			
			var num_i : uint = indices.length;
			indexBuffer = context.createIndexBuffer(num_i);
			indexBuffer.uploadFromVector(indices, 0, num_i);

			root.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private var rotation : Number = 0;
		private function onEnterFrame(evt : Event) : void {
			var pers : PerspectiveMatrix3D = new PerspectiveMatrix3D();
			pers.identity();
			pers.perspectiveLH(7.5, 4.6, 5, 1000000);
			var modelView : Matrix3D = new Matrix3D();
			modelView.identity();
			modelView.appendRotation(90, Vector3D.X_AXIS);
			rotation -= 0.2;
			modelView.appendRotation(rotation, Vector3D.Y_AXIS);
			modelView.appendTranslation(0, 0, 512);

			var m : Matrix3D = new Matrix3D();
			m.identity();
			m.append(modelView);
			m.append(pers);

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
			context.clear();

			context.drawTriangles(indexBuffer);

			context.present();
		}

	}
}

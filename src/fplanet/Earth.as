package fplanet{
	import flash.display.*;
	import flash.text.*;
	import flash.filters.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.geom.*;
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

		private static var info : TextField;

		private static const segmentsH : uint = 30;
		private static const segmentsW : uint = 25;

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

			Assembler.context = context;

			info = new TextField();
			info.textColor = 0xFFFFFF;
			info.htmlText = "Hello, Live Planet!";
			info.autoSize = "left";

			root.addChild(info);

			getPicture();

			root.addEventListener(Event.ENTER_FRAME, render);
		}

		private var vertices : Vector.<Number>;
		private var vertexNormals : Vector.<Number>;
		private var vertexTangents : Vector.<Number>;

		private var indices : Vector.<uint>;
		private var uvData : Vector.<Number>;

		private var indexBuffer : IndexBuffer3D;

		private function createVertices() : void {
			var numVerts : uint = (segmentsH + 1) * (segmentsW + 1);
			var numUvs : uint = numVerts * 2;

			vertices = new Vector.<Number>(numVerts * 3, true);
			vertexNormals = new Vector.<Number>(numVerts * 3, true);
			vertexTangents = new Vector.<Number>(numVerts * 3, true);

			indices = new Vector.<uint>((segmentsH - 1) * segmentsW * 6, true);
			uvData = new Vector.<Number>(numUvs, true);

			Sphere.create(segmentsW, segmentsH, radius, vertices, vertexNormals, vertexTangents, indices, uvData);
			trace("vertices: " + vertices.length + " | indices: " + indices.length + " | uvs: " + uvData.length);

			Assembler.uploadBuffers(vertices, uvData, vertexNormals, indices);
		}

		private var solarPosition : Vector3D;

		private var p_index : int = 0;
		private var pictures : Vector.<String> = Vector.<String>(["earth.jpg", "night.jpg", "clouds.jpg"]);
		private var start : Boolean = false;

		private function getPicture() : void {
			PictureLoader.getPicture(pictures[p_index], createTexture);
		}

		private function createTexture(bd : BitmapData) : void {

			var texture : Texture = context.createTexture(textureW, textureH, Context3DTextureFormat.BGRA, true );
			texture.uploadFromBitmapData( bd );

			context.setTextureAt(p_index, texture);

			if(p_index < 2){
				p_index++;
				getPicture();
			}else{
				createVertices();
				createPerspective();

				info.htmlText = "<b>To get the original 'Living Earth HD' on IPhone, click <a href='http://itunes.apple.com/us/app/id379869627?mt=8&ign-mpt=uo%3D4'><font color='#0099FF'>HERE</font></a>.</b>";
				start = true;
			}

		}

		private var rotation : Number = 0;
		private var pers : PerspectiveMatrix3D;
		private var camera : Matrix3D;
		private var modelView : Matrix3D;

		private var camera_pos : Number = radius * 12;

		private function createPerspective() : void {
			pers = new PerspectiveMatrix3D();
			pers.perspectiveLH(1, 1/7.5 * 4.6, 3, 1000000);

			camera = new Matrix3D();
			camera.appendTranslation(0, 0, camera_pos);
		
			modelView = new Matrix3D();
		}

		private function render(evt : Event) : void {
			if(!start){
				info.htmlText = "loading " + pictures[p_index] + " source: " + PictureLoader.getLoaded() + "/" + PictureLoader.getTotal();
				return;
			}

			context.clear();

			context.setCulling(Context3DTriangleFace.BACK);
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.DESTINATION_COLOR);
			drawGround();

			context.setCulling(Context3DTriangleFace.FRONT);

			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.DESTINATION_COLOR);
			drawAtomsphere(1.15);

			context.setBlendFactors(Context3DBlendFactor.SOURCE_COLOR, Context3DBlendFactor.DESTINATION_COLOR);
			drawAtomsphere(1.01, 1);

			context.present();
		}

		private var matrix : Matrix3D = new Matrix3D();

		private function drawGround() : void {
			var fc : Vector.<Vector.<Number>> = new	Vector.<Vector.<Number>>();
			fc.push(Vector.<Number>([1, 1, 1, 1]));//0
			
			var geoClock : GeoClock = GeoClock.getInstance();

			solarPosition = geoClock.updateTerminatorMap();

			fc.push(Vector.<Number>([solarPosition.x, solarPosition.y, solarPosition.z, 1]));//1

			fc.push(Vector.<Number>([-1, -1, -1, 1]));//2

			fc.push(Vector.<Number>([0.5, 0.5, 0.5, 1]));//3

			fc.push(Vector.<Number>([5, 5, 5, 1]));//4

			fc.push(Vector.<Number>([0.25, 0.25, 0.25, 1]));//5

			Assembler.uploadFragmentConstants(fc);

			var v_assembler : String = 
					"mov vt0, va0 \n" + 
					"mov vt1, va1 \n" + 
					"mov vt2, va2 \n" + 
					"m44 op, vt0, vc0 \n" + 
					"mov v0, vt1 \n" + 
					"mov v1, vt2";

			var f_assembler : String = 
					"mov ft0, v0\n"+
					//add textures
					"tex ft1, ft0, fs0 <2d,clamp,linear>\n"+ 
					"tex ft2, ft0, fs1 <2d,clamp,linear>\n"+ 
					"tex ft3, ft0, fs2 <2d,clamp,linear>\n"+ 

					"dp3 ft4, fc1, v1\n"+ //dp light and uv
					"mul ft5, fc2, ft4\n"+ //invert light
					"mul ft5, ft5, fc4\n"+//mul 5
					"sat ft5, ft5\n"+//0..1
					"mul ft1, ft1, ft5\n"+//get day
					"sub ft6, fc0, ft5\n"+//invert
					"mul ft2, ft2, ft6\n"+//get night
					"mul ft2, ft2, fc3\n"+//make a little darker to night
					"mul ft3, ft3, fc3\n"+//make a little darker to cloud
					"mul ft6, ft3, ft6\n"+//get night cloud
					"mul ft6, ft6, fc5\n"+//make a little darker to night cloud
					"mul ft5, ft3, ft5\n"+//get day cloud
					"add ft3, ft5, ft6\n"+//get cloud
					"add ft1, ft2, ft1\n"+//get day&night
					"add oc, ft1, ft3\n";//add cloud
			
			Assembler.assemble(v_assembler, f_assembler);

			rotation -= 0.2;
			modelView.identity();
			modelView.appendRotation(90, Vector3D.X_AXIS);
			modelView.appendRotation(rotation, Vector3D.Y_AXIS);

			matrix.identity();
			matrix.append(modelView);
			matrix.append(camera);
			matrix.append(pers);

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);

			Assembler.render(matrix, Assembler.indexBuffer);
		}

		private function drawAtomsphere(scale : Number = 1, layer : Number = 0) : void {
			var fc : Vector.<Vector.<Number>> = new	Vector.<Vector.<Number>>();
			fc.push(Vector.<Number>([1, 1, 1, 1]));//0
			
			var geoClock : GeoClock = GeoClock.getInstance();

			solarPosition = geoClock.updateTerminatorMap();

			fc.push(Vector.<Number>([solarPosition.x, solarPosition.y, solarPosition.z, 1]));//1

			fc.push(Vector.<Number>([-1, -1, -1, 1]));//2

			fc.push(Vector.<Number>([0.65, 0.85, 1.55, 1]));//3

			fc.push(Vector.<Number>([camera_pos, camera_pos, camera_pos, 1]));//4
			fc.push(Vector.<Number>([radius, radius, radius, 1]));//5

			fc.push(Vector.<Number>([0.95, 0.95, 0.95, 1]));//6

			fc.push(Vector.<Number>([1.5, 1.5, 1.5, 1]));//7

			Assembler.uploadFragmentConstants(fc);

			var v_assembler : String = 
					"mov vt0, va0 \n" + 
					"mov vt1, va1 \n" + 
					"mov vt2, va2 \n" + 
					"m44 vt3, vt0, vc0 \n" + 
					"mov op, vt3 \n" +

					"mov v0, vt1 \n" + //uvs
					"mov v1, vt2 \n" + //normals

					"mov v2, vt3.z \n";

			var f_assembler : String;

			if(layer == 0){
				f_assembler = 
						"mov ft0, v0\n"+
						//add textures
						"tex ft1, ft0, fs0 <2d,clamp,linear>\n"+ 
						"tex ft2, ft0, fs1 <2d,clamp,linear>\n"+ 
						"tex ft3, ft0, fs2 <2d,clamp,linear>\n"+ 

						"dp3 ft4, fc1, v1\n"+ //dp light with normals
						"mul ft6, fc2, ft4\n"+ //invert light
						"mul ft6, ft6, fc3\n"+ //a little blue

						"sub ft7.rgb, v2.rgb, fc4.rgb\n"+
						"div ft7, ft7, fc5\n"+
						"mul ft6, ft7, ft6\n"+
						"mul ft6, ft6, fc6\n"+

						"mov oc, ft6"//get atomsphere
			}else{
				f_assembler = 
						"mov ft0, v0\n"+
						//add textures
						"tex ft1, ft0, fs0 <2d,clamp,linear>\n"+ 
						"tex ft2, ft0, fs1 <2d,clamp,linear>\n"+ 
						"tex ft3, ft0, fs2 <2d,clamp,linear>\n"+ 

						"dp3 ft4, fc1, v1\n"+ //dp light with normals
						"mul ft6, fc2, ft4\n"+ //invert light
						"mul ft6, ft6, fc7\n"+ 
						"sat ft6, ft6\n"+ 
						"mul ft6, ft6, fc3\n"+ //a little blue

						"mov oc, ft6"//get atomsphere
			}

			Assembler.assemble(v_assembler, f_assembler);

			modelView.identity();
			modelView.appendRotation(90, Vector3D.X_AXIS);
			modelView.appendRotation(rotation, Vector3D.Y_AXIS);
			modelView.appendScale(scale, scale, scale);

			matrix.identity();
			matrix.append(modelView);
			matrix.append(camera);
			matrix.append(pers);

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);

			Assembler.render(matrix, Assembler.indexBuffer);

		}

	}
}

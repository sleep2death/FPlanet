package fplanet {
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.geom.*;
	import flash.events.Event;
	import flash.utils.ByteArray;

	import com.adobe.pixelBender3D.*;
	import com.adobe.pixelBender3D.utils.*;

	import com.adobe.utils.*;

	public class Assembler {
		public static var context : Context3D;
		public static var indexBuffer : IndexBuffer3D;

		public static function assemble(vertex : String, fragment : String) : void {
			var v_assembler : AGALMiniAssembler = new AGALMiniAssembler();
			v_assembler.assemble(Context3DProgramType.VERTEX, vertex);

			var f_assembler : AGALMiniAssembler = new AGALMiniAssembler();
			f_assembler.assemble( Context3DProgramType.FRAGMENT, fragment);

			var program : Program3D = context.createProgram();
			program.upload(v_assembler.agalcode, f_assembler.agalcode);
			context.setProgram(program);
		}


		public static function uploadBuffers(vertices : Vector.<Number>, uvData : Vector.<Number>, vertexNormals : Vector.<Number>, indices : Vector.<uint> ) : void {
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

			var num_i : uint = indices.length;
			indexBuffer = context.createIndexBuffer(num_i);
			indexBuffer.uploadFromVector(indices, 0, num_i);
		}

		public static function uploadTextures(day : Texture, night : Texture, cloud : Texture) : void {
			context.setTextureAt(0, day);
			context.setTextureAt(1, night);
			context.setTextureAt(2, cloud);
		}

		public static function uploadFragmentConstants(f : Vector.<Vector.<Number>>) : void {
			var len : uint = f.length;
			for(var i : int = 0; i < len; i++) {
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, i, f[i]);
			}
		}

		public static function render(matrix : Matrix3D, indexBuffer : IndexBuffer3D) : void {
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
			context.clear();

			context.drawTriangles(indexBuffer);
			context.present();
		}

	}
}

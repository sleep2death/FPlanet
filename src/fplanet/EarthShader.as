package fplanet{
	import flash.display3D.*;
	import flash.utils.ByteArray;
	import com.adobe.pixelBender3D.*;
	import com.adobe.pixelBender3D.utils.*;

	public class EarthShader{
		private static var instance : EarthShader;

		public static function getInstance(context : Context3D) : EarthShader {
			if(instance == null) {
				instance = new EarthShader(context);
			}

			return instance;
		}

		private var context : Context3D;

		[Embed (source="../../shaders/vertexProgram.pbasm", mimeType="application/octet-stream")]
		private static const VertexProgram : Class;

		[Embed (source="../../shaders/matVertProg.pbasm", mimeType="application/octet-stream")]
		private static const MatVertProg : Class;

		[Embed (source="../../shaders/fragProgram.pbasm", mimeType="application/octet-stream")]
		private static const FragProgram : Class;

		public function EarthShader(context : Context3D) : void {
			this.context = context;
			initPrograms();
		}

		private function readFile( f : Class ) : String
		{
			var bytes:ByteArray;
			
			bytes = new f();
			return bytes.readUTFBytes( bytes.bytesAvailable );
		}

		public function initPrograms() : void {
			var inputVertexProgram : PBASMProgram = new PBASMProgram( readFile( VertexProgram ) );
			
			var inputMaterialVertexProgram : PBASMProgram = new PBASMProgram( readFile( MatVertProg ) );
			var inputFragmentProgram : PBASMProgram = new PBASMProgram( readFile( FragProgram ) );
			
			var programs : com.adobe.pixelBender3D.AGALProgramPair = com.adobe.pixelBender3D.PBASMCompiler.compile( inputVertexProgram, inputMaterialVertexProgram, inputFragmentProgram );
			
			var agalVertexBinary : ByteArray = programs.vertexProgram.byteCode;
			var agalFragmentBinary : ByteArray = programs.fragmentProgram.byteCode;
		}
	}
}

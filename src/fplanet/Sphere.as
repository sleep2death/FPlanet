package fplanet {
	public class Sphere {
		public static function create(segmentsW : uint, segmentsH : uint, radius : uint, vertices : Vector.<Number>, vertexNormals : Vector.<Number>, vertexTangents : Vector.<Number>, indices : Vector.<uint>, uvData : Vector.<Number>) : void {
			var i : uint, j : uint, triIndex : uint;

			var numVerts : uint = 0;
			var numUvs : uint = 0;
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

			//trace("vertices: " + vertices.length + " | indices: " + indices.length + " | uvs: " + uvData.length);

		}
	}
}

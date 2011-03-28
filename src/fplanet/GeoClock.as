package fplanet{
	import flash.display.*;
	import flash.geom.*;

	public class GeoClock {
		private static const K : Number = Math.PI/180;
		private static const R2D : Number = 180/Math.PI;

		private static var instance : GeoClock;
		private static var graphics : Graphics;

		public function GeoClock() : void {
			if(instance) throw new Error("One clock is enough!");
		}
		
		public static function getInstance() : GeoClock {
			if(instance == null) {
				instance = new GeoClock();
			}

			return instance;
		}

		private var declination : Number;

		public function updateTerminatorMap() : Vector3D {
			var currentDay : Date = new Date();
			var year : Number = currentDay.fullYear;
			var month : Number = currentDay.month + 1;
			var date : Number = currentDay.date;
			var hours : Number = currentDay.hours;
			var minutes : Number = currentDay.minutes;
			var seconds : Number = currentDay.seconds;
			var offset : Number = currentDay.timezoneOffset;
			if(offset > 1380) offset -= 1440;

			var UT : Number = currentDay.getUTCHours() + currentDay.getUTCMinutes()/60 + currentDay.getUTCSeconds()/3600;
			trace("UT: " + UT);

			//Julian day
			if (year < 1900) year = year + 1900;
			if (month <= 2) {month = month + 12; year = year-1}
			var B : Number = Math.floor(year/400) - Math.floor(year/100)  + Math.floor(year/4)
			var A : Number = 365 * year - 679004
			var JD : Number = A + B + Math.floor(30.6001 * (month + 1)) + date + UT/24.0;
			JD = JD + 2400000.5;
			trace("Julian Day: " + JD);

			var T : Number = (JD - 2451545.0) / 36525.0;
			
			//Sun light
			var L : Number = 280.46645 + 36000.76983*T + 0.0003032*T*T	
			L = L % 360		
			if (L<0) L = L + 360

			//EPS
			var LS : Number = L;
			var LM : Number = 218.3165 + 481267.8813*T;
			var eps0 : Number =  23.0 + 26.0/60.0 + 21.448/3600.0 - (46.8150*T + 0.00059*T*T - 0.001813*T*T*T)/3600;
			var omega : Number = 125.04452 - 1934.136261*T + 0.0020708*T*T + T*T*T/450000;
			var deltaEps : Number = (9.20*Math.cos(K*omega) + 0.57*Math.cos(K*2*LS) + 0.10*Math.cos(K*2*LM) - 0.09*Math.cos(K*2*omega))/3600;
			var eps : Number = eps0 + deltaEps;

			//Declination
			var M : Number = 357.52910 + 35999.05030*T - 0.0001559*T*T - 0.00000048*T*T*T
			M = M % 360;	
			if (M<0) M = M + 360;
			var C : Number = (1.914600 - 0.004817*T - 0.000014*T*T)*Math.sin(K*M);
			C = C + (0.019993 - 0.000101*T)*Math.sin(K*2*M);
			C = C + 0.000290*Math.sin(K*3*M);		
			var theta : Number = L + C; // true longitude of the Sun						
			eps = eps + 0.00256*Math.cos(K*(125.04 - 1934.136*T));
			var lambda : Number = theta - 0.00569 - 0.00478*Math.sin(K*(125.04 - 1934.136*T)); // apparent longitude of the Sun
			var delta : Number = Math.asin(Math.sin(K*eps)*Math.sin(K*lambda));
			delta = delta/K;	
			declination = delta;
			trace("Declination: " + declination);

			var tau : Number = 360 * (UT - 12) / 24;
			var dec : Number = declination;

			trace("TAU: " + tau);

			tau = 180 - tau + 180;
			dec = 90 - dec;

			var v : Vector3D = new Vector3D(1.1, 0, 0);
			
			var mtx : Matrix3D = new Matrix3D();
			mtx.appendRotation(tau, Vector3D.Y_AXIS);
			mtx.appendRotation(dec, Vector3D.X_AXIS);

			v = Utils3D.projectVector(mtx, v);

			return v;

			//var shape : Shape = new Shape();
			//var g : Graphics = shape.graphics;

			//var scale : Number = w*0.5/180;
			//var x0 : Number = 180*scale;
			//var y0 : Number = 90*scale;

			//g.beginFill(0x000000);
			//g.drawRect(0, 0, 2*x0, 2*y0);
			//g.endFill();

			//g.beginFill(0xFFFFFF, 1);

			//var i : Number = -190*scale;
			//g.moveTo(0,0);
			//g.lineStyle(0, 0, 0);

			//var mtx : Matrix = new Matrix();

			//while(i < 190*scale){
			//	var longitude : Number =i/scale+tau;
			//	var tanLat : Number = -Math.cos(longitude*K)/Math.tan(dec*K);						
			//	var arctanLat : Number = Math.atan(tanLat)/K;
			//	var y1 : Number = y0 - arctanLat*scale;
			//	
			//	longitude=longitude+(1/scale);
			//	tanLat = - Math.cos(longitude*K)/Math.tan(dec*K);
			//	arctanLat = Math.atan(tanLat)/K;
			//	var y2 : Number  = y0 - arctanLat*scale;

			//	var a1 : Number = (x0 + i);
			//	var a2 : Number = (x0 + (i + 1));
			//	g.lineTo(a1, y1);
			//	var W: Number = Math.sqrt((a2 - a1)*(a2 - a1) + (y2 -y1)*(y2 - y1));
			//	mtx.identity();
			//	var rad : Number = Math.atan((y2-y1)/(a2-a1)); 
			//	mtx.createGradientBox(32, 32, rad - Math.PI/2, a1 - 16, y1 - 16);
			//	g.lineStyle(32, 0, 1, true, "noScale");
			//	g.lineGradientStyle(GradientType.LINEAR, [0x000000, 0xFFFFFF], [1, 1], [0, 255], mtx);
			//	g.lineTo(a2, y2);
			//	i+=1;

			//	g.lineStyle(0, 0, 0);
			//}

			//g.lineStyle(0, 0, 0);
			//g.lineTo(w, 0);
			//g.lineTo(0, 0);

			//g.endFill();

			//return shape;
			
		}
	}
}

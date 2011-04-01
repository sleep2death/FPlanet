package fplanet {
	import flash.display.*;
	import flash.net.URLRequest;
	import flash.events.Event;

	public class PictureLoader {
		private static var loader : Loader = new Loader();
		private static var info : LoaderInfo = loader.contentLoaderInfo;
		private static var req : URLRequest = new URLRequest();

		private static var callBack : Function;

		public static function getPicture(url : String, callBack : Function) : void {
			PictureLoader.callBack = callBack;

			info.addEventListener(Event.INIT, initHandler);

			req.url = url;
			loader.load(req);

		}

		public static function initHandler(evt : Event) : void {
			trace(Bitmap(info.content).bitmapData);
			trace(callBack);
			callBack.call(null, Bitmap(info.content).bitmapData);
		}

		public static function getLoaded() : int {
			return info.bytesLoaded;
		}

		public static function getTotal() : int {
			return info.bytesTotal;
		}

	}
}

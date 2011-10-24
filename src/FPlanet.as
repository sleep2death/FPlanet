package{

	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.events.Event;

	import fplanet.Earth;
	import fplanet.GeoClock;
	import shader.*;

	public class FPlanet extends Sprite {
		public function FPlanet() : void {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}

		public function onAdded(evt : Event) : void {
			//var earth : Earth2 = new Earth2(this.stage);
			Earth.init(stage);
			//var sp : Shape = GeoClock.getInstance().updateTerminatorMap(750, 460);
			//addChild(sp);
		}
	}
}

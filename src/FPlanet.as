package{

	import flash.display.Sprite;
	import flash.events.Event;

	import fplanet.Earth;

	public class FPlanet extends Sprite {
		public function FPlanet() : void {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}

		public function onAdded(evt : Event) : void {
			Earth.init(stage);
		}
	}
}

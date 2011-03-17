package{

	import flash.display.Sprite;
	import flash.events.Event;

	import tp.Planet;

	public class TalkingPlanet extends Sprite {
		public function TalkingPlanet() : void {
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}

		public function onAdded(evt : Event) : void {
			Planet.init(stage);
		}
	}
}

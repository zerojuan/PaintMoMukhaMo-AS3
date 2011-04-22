package tests
{
	import flash.display.Sprite;
	
	import org.flexunit.listeners.CIListener;
	import org.flexunit.runner.FlexUnitCore;
	
	public class TestRunner extends Sprite
	{
		private var core:FlexUnitCore;
		public function TestRunner()
		{
			core = new FlexUnitCore();
			core.addListener(new CIListener());
			core.run(FacebookTest);
		}
	}
}
package com.tada.engine
{
	import com.tada.utils.debug.Logger;
	
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	public class TEngine
	{
		private static var _started:Boolean = false;
		
		private static var _main:Sprite = null;
		//private static var _versionDetails:VersionDetails;
				
		
		public function TEngine(){
		}
		
		public static function log(reporter:*, message:String):void{
			Logger.print(reporter, message);
		}
		
		public static function get mainClass():Sprite{
			return _main;
		}
		
		public static function get mainStage():Stage{
			if(!_main)
				throw new Error("Cannot retrieve the global stage instance until mainClass has been set on startup");
			
			return _main.stage;
		}
		
		
		
		public static function startup(mainClass:Sprite):void{
			if(_started)
				throw new Error("You can only start TEngine once.");
				
			if(!mainClass)
				throw new Error("A mainClass must be specified");
			
			if(!mainClass.stage)
				throw new Error("Your mainClass must be added to the stage before starting up");
			
			_main = mainClass;
			
			mainClass.stage.align = StageAlign.TOP_LEFT;
			mainClass.stage.scaleMode = StageScaleMode.NO_SCALE;
			
			Logger.startup();
			
		}
	}
}
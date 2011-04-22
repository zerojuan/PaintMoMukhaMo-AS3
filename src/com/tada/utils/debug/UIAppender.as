package com.tada.utils.debug
{
	import com.tada.engine.TEngine;
	
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;

	public class UIAppender implements ILogAppender
	{
		protected var _logViewer:LogViewer;
		
		public function UIAppender(){
			TEngine.mainStage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			
			_logViewer = new LogViewer();
		}
		
		private function onKeyDown(event:KeyboardEvent):void{
			//Default keycode for ui is tilde					
			if(event.keyCode != 192)
				return;
			
			if(_logViewer){
				if(_logViewer.parent){
					_logViewer.parent.removeChild(_logViewer);
					_logViewer.deactivate();
				}else{
					TEngine.mainStage.addChild(_logViewer);
					var char:String = String.fromCharCode(event.charCode);
					//disallow hot key character
					_logViewer.restrict = "^"+char.toUpperCase() + char.toLowerCase();
					_logViewer.activate();
				}
			}
		}
		
		public function addLogMessage(level:String, loggerName:String, message:String):void{
			if(_logViewer){
				_logViewer.addLogMessage(level, loggerName, message);
			}
		}
			
	}
}
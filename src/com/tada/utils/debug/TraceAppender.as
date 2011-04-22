package com.tada.utils.debug
{	

	public class TraceAppender implements ILogAppender
	{
		public function addLogMessage(level:String, loggerName:String, message:String):void{
			trace(level + ": " + loggerName + " - " + message);
		}
	}
}
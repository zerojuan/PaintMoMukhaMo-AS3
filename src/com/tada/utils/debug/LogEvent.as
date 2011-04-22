package com.tada.utils.debug
{
	import com.pblabs.engine.debug.LogEntry;
	
	import flash.events.Event;

	public class LogEvent extends Event
	{
		public static const ENTRY_ADDED_EVENT:String = "ENTRY_ADDED_EVENT";
		
		public var entry:LogEntry = null;
		
		public function LogEvent(type:String, entry:LogEntry, bubbles:Boolean = false, cancelable:Boolean = false){
			entry = entry;
			super(type, bubbles, cancelable);
			
		}
	}
}
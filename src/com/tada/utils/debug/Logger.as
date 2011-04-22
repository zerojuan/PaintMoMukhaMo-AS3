package com.tada.utils.debug
{	
	import com.tada.utils.TypeUtility;
	
	import flash.net.getClassByAlias;
	import flash.utils.getQualifiedClassName;

	public class Logger
	{
		static protected var listeners:Array = [];
		static protected var started:Boolean = false;
		static protected var pendingEntries:Array = [];
		static protected var disabled:Boolean = false;
		
		public static function registerListener(listener:ILogAppender):void{
			listeners.push(listener);
		}
		
		public static function startup():void{
			registerListener(new TraceAppender());
			
			registerListener(new UIAppender());
			
			//Process pending messages
			started = true;
			
			for(var i:int = 0; i < pendingEntries.length; i++){
				processEntry(pendingEntries[i]);
			}
			
			//Free up the pending entries memory
			pendingEntries.length = 0;
			pendingEntries = null;
		}
		
		/**
		 * Call to destructively disable logging.
		 */
		public static function disable():void{
			pendingEntries = null;
			started = false;
			listeners = null;
			disabled = true;
		}
		
		protected static function processEntry(entry:LogEntry):void{
			//Quick exit if disabled
			if(disabled)
				return;
			
			//If we haven't started yet, just save it to a list
			if(!started){
				pendingEntries.push(entry);
				return;
			}
			
			//Let all the listeners process it
			for(var i:int = 0; i < listeners.length; i++){
				(listeners[i] as ILogAppender).addLogMessage(entry.type, TypeUtility.getObjectClassName(entry.reporter), entry.message );
			}
		}
		
		public static function print(reporter:*, message:String):void{
			if(disabled)
				return;
			
			var entry:LogEntry = new LogEntry();
			entry.reporter = TypeUtility.getClass(reporter);
			entry.message = message;
			entry.type = LogEntry.MESSAGE;
			processEntry(entry);
		}
		
		public static function warn(reporter:*, method:String, message:String):void{
			if(disabled)
				return;
			
			var entry:LogEntry = new LogEntry();
			entry.reporter = TypeUtility.getClass(reporter);
			entry.method = method;
			entry.message = method + " - " + message;
			entry.type = LogEntry.WARNING;
			processEntry(entry);
		}
		
		public static function info(reporter:*, method:String, message:String):void{
			if(disabled)
				return;
			
			var entry:LogEntry = new LogEntry();
			entry.reporter = TypeUtility.getClass(reporter);
			entry.method = method;
			entry.message = method + " - " + message;
			entry.type = LogEntry.INFO;
			processEntry(entry);
		}
		
		public static function debug(reporter:*, method:String, message:String):void{
			if(disabled)
				return;
			
			var entry:LogEntry = new LogEntry();
			entry.reporter = TypeUtility.getClass(reporter);
			entry.method = method;
			entry.message = method + " - " + message;
			entry.type = LogEntry.WARNING;
			processEntry(entry);
		}
		
		public static function error(reporter:*, method:String, message:String):void{
			if(disabled)
				return;
			
			var entry:LogEntry = new LogEntry();
			entry.reporter = TypeUtility.getClass(reporter);
			entry.method = method;
			entry.message = method + " - " + message;
			entry.type = LogEntry.ERROR;
			processEntry(entry);
		}
		
		public static function printCustom(reporter:*, method:String, message:String, type:String):void{
			if(disabled)
				return;
			
			var entry:LogEntry = new LogEntry();
			entry.reporter = TypeUtility.getClass(reporter);
			entry.method = method;
			entry.message = method + " - " + message;
			entry.type = type;
			processEntry(entry);
		}
		
		public var enabled:Boolean;
		protected var owner:Class;
		
		public function Logger(_owner:Class, defaultEnabled:Boolean = true){
			owner = _owner;
			enabled = defaultEnabled;
		}
		
		public function info(method:String, message:String):void{
			if(enabled)
				Logger.info(owner, method, message);
		}
		
		public function warn(method:String, message:String):void{
			if(enabled)
				Logger.warn(owner, method, message);
		}
		
		public function error(method:String, message:String):void{
			if(enabled)
				Logger.error(owner, method, message);
		}
		
		public function print(message:String):void{
			if(enabled)
				Logger.print(owner, message);
		}
	}
}
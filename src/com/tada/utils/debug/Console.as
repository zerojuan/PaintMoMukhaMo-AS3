package com.tada.utils.debug
{
	import com.tada.engine.TEngine;
	import com.tada.utils.GameUtil;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	/**
	 * Process simple text commands form the user. Useful for debugging
	 */
	public class Console
	{
		/**
		 * The commands, indexed by name		 
		 */
		protected static var commands:Object = {};
		
		/**
		 * Alphabetically ordered list of commands
		 */
		protected static var commandList:Array = [];
		protected static var commandListOrdered:Boolean = false;
		
		protected static var _hotKeyCode:uint = 192;
		
		//protected static var _stats:Stats;
		
		protected static var _prevTimescale:Number;
		
		public static var verbosity:int = 0;
		public static var showStackTrace:Boolean = false;
		
		
		public static function registerCommand(name:String, callback:Function, docs:String = null):void{
			//Sanity checks
			if(callback == null)
				Logger.error(Console, "registerCommand", "Command '" + name + "' has no callback!");
			if(!name || name.length == 0)
				Logger.error(Console, "registerCommand", "Command has no name!");
			if(name.indexOf(" ") != -1)
				Logger.error(Console, "registerCommand", "Command '" + name + "' has a space in it, it will not work.");
			
			//Fill in description
			var c:ConsoleCommand = new ConsoleCommand();
			c.name = name;
			c.callback = callback;
			c.docs = docs;
			
			if(commands[name.toLowerCase()])
				Logger.warn(Console, "registerCommand", "Replacing existing command '" + name + "'.");
			
			//Set it
			commands[name.toLowerCase()] = c;
			
			//Update the list
			commandList.push(c);
			commandListOrdered = false;
		}
		
		public static function getCommandList():Array{
			ensureCommandsOrdered();
			
			return commandList;
		}
		
		protected static function ensureCommandsOrdered():void{
			if(commandListOrdered == true)
				return;
			
			//register default commands
			if(commands.help == null)
				init();
			
			//Note we are done
			commandListOrdered = true;
			
			//Do the sort
			commandList.sort(function(a:ConsoleCommand, b:ConsoleCommand):int{
				if(a.name > b.name)
					return 1;
				else
					return -1;
			});
		}
		
		public static function processLine(line:String):void{
			//Make sure everything is in order
			ensureCommandsOrdered();
			
			//Match Tokens, this allows for text to be split by spaces
			var pattern:RegExp = /[^\s"']+|"[^"]*"|'[^']*'/g;
			var args:Array = [];
			var test:Object = {};
			
			while(test){
				test = pattern.exec(line);
				if(test){
					var str:String = test[0];
					str = GameUtil.trim(str, "'");
					str = GameUtil.trim(str, "\"");
					args.push(str); //If no more matches can be found, test will be null
				}
			}
			
			//Look up the command
			if(args.length == 0)
				return;
			
			var potentialCommand:ConsoleCommand = commands[args[0].toString().toLowerCase()];
			
			if(!potentialCommand){
				Logger.warn(Console, "processLine", "No such command '" + args[0].toString() + "'!");
				return;
			}
			
			//Now call the command
			try{
				potentialCommand.callback.apply(null, args.slice(1));
			}catch(e:Error){
				var errorStr:String = "Error: " + e.toString();
				if(showStackTrace){
					errorStr += " - " + e.getStackTrace();
				}
				Logger.error(Console, args[0], errorStr);
			}
		}
		
		/**
		 * Internal initialization, this will get called on its own
		 */		
		public static function init():void{
			registerCommand("listDisplayObjects", function():void{
				var sum:int = Console._listDisplayObjects(TEngine.mainStage, 0);
				Logger.print(Console, " " + sum + " total display objects.");				
			}, "Outputs the display list");
						
		}
		
		protected static function _listDisplayObjects(current:DisplayObject, indent:int):int{
			if(!current)
				return 0;
			
			Logger.print(Console,
				Console.generateIndent(indent) + 
				current.name + 
				" (" + current.x + "," + current.y + ") visible=" +
				current.visible);
			
			var parent:DisplayObjectContainer = current as DisplayObjectContainer;
			if(!parent)
				return 1;
			
			var sum:int = 1;
			for(var i:int = 0; i < parent.numChildren; i++){
				sum += _listDisplayObjects(parent.getChildAt(i), indent + 1);
			}
			
			return sum;
		}
		
		protected static function generateIndent(indent:int):String{
			var str:String = "";
			for(var i:int = 0; i < indent; i++){
				//Add 2 spaces for indent
				str += "  ";
			}
			return str;
		}
		
		public static function set hotKeyCode(value:uint):void{
			Logger.print(Console, "Setting hotKeyCode to: " + value);
			_hotKeyCode = value;
		}
		
		public static function get hotKeyCode():uint{
			return _hotKeyCode;
		}

	}
}

final class ConsoleCommand
{
	public var name:String;
	public var callback:Function;
	public var docs:String;
}

package com.tada.utils.debug
{
		
	import com.tada.engine.TEngine;
	import com.tada.utils.GameUtil;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;

	/**
	 * Console UI, which shows console log activity in-game and accepts input from the user
	 */
	public class LogViewer extends Sprite implements ILogAppender
	{
		protected var _messageQueue:Array = [];
		protected var _maxLength:uint = 2000000;
		protected var _truncating:Boolean = false;
		
		protected var _width:uint = 500;
		protected var _height:uint = 150;
		
		protected var _consoleHistory:Array = [];
		protected var _historyIndex:uint = 0;
		
		protected var _outputBitmap:Bitmap = new Bitmap(new BitmapData(640,480, false, 0x0));
		protected var _input:TextField;
		
		protected var tabCompletionPrefix:String = "";
		protected var tabCompletionCurrentStart:int = 0;
		protected var tabCompletionCurrentEnd:int = 0;
		protected var tabCompletionCurrentOffset:int = 0;
		
		protected var glyphCache:GlyphCache = new GlyphCache();
		
		protected var bottomLineIndex:int = int.MAX_VALUE;
		protected var logCache:Array = [];
		protected var _dirtyConsole:Boolean = true;
		
		public function LogViewer(){
			layout();
			_input.addEventListener(KeyboardEvent.KEY_DOWN, onInputKeyDown);
			//addListeners();
			
			//name = "Console";
		}
		
		protected function layout():void{
			if(!_input) createInputField();
			
			resize();
			
			_outputBitmap.name = "ConsoleOutput";
			addEventListener(MouseEvent.CLICK, onBitmapClick);
			addEventListener(MouseEvent.DOUBLE_CLICK, onBitmapDoubleClick);
			
			addChild(_outputBitmap);
			addChild(_input);
			
			graphics.clear();
			graphics.beginFill(0x111111, .95);
			graphics.drawRect(0,0, _width+1, _height);
			graphics.endFill();
			
			mouseEnabled = true;
			doubleClickEnabled = true;
			
			_dirtyConsole = true;
		}
		
		protected function addListeners():void{
			_input.addEventListener(KeyboardEvent.KEY_DOWN, onInputKeyDown);
			addEventListener(Event.ENTER_FRAME, onFrame);
		}
		
		protected function removeListeners():void{
			_input.removeEventListener(KeyboardEvent.KEY_DOWN, onInputKeyDown);
			removeEventListener(Event.ENTER_FRAME, onFrame);
		}
		
		protected function onBitmapClick(me:MouseEvent):void{
			TEngine.mainStage.focus = _input;
		}
		
		protected function onBitmapDoubleClick(me:MouseEvent = null):void{
			var logString:String = "";
			for(var i:int = 0; i < logCache.length; i++){
				logString += logCache[i].text + "\n";
			}
			
			System.setClipboard(logString);
			
			Logger.print(this, "Copied console contents to clipboard");
		}
		
		protected function onClearCommand():void{
			logCache = [];
			bottomLineIndex = -1;
			_dirtyConsole = true;
		}
		
		protected function resize():void{
			_outputBitmap.x = 5;
			_outputBitmap.y = 0;
			_input.x = 5;
			
			if(stage){
				_width = stage.stageWidth-1;
				_height = (stage.stageHeight / 3) * 2;
			}
			
			//Resize display surface
			_outputBitmap.bitmapData.dispose();
			_outputBitmap.bitmapData = new BitmapData(_width - 10, _height - 30);
			
			_input.height = 18;
			_input.width = _width - 10;
			
			_input.y = _outputBitmap.height + 7;
			
			_dirtyConsole = true;
		}
		
		protected function createInputField():TextField{
			_input = new TextField();
			_input.type = TextFieldType.INPUT;
			_input.border = true;
			_input.borderColor = 0xcccccc;
			_input.multiline = false;
			_input.wordWrap = false;
			_input.condenseWhite = false;
			var format:TextFormat = _input.getTextFormat();
			format.font = "_typewriter";
			format.size = 11;
			format.color = 0xffffff;
			_input.setTextFormat(format);
			_input.defaultTextFormat = format;
			_input.name = "ConsoleInput";
			
			return _input;
		}
		
		protected function onInputKeyDown(event:KeyboardEvent):void{
			if(event.keyCode != Keyboard.TAB && event.keyCode != Keyboard.SHIFT){
				tabCompletionPrefix = _input.text;
				tabCompletionCurrentStart = -1;
				tabCompletionCurrentOffset = 0;
			}
			
			if(event.keyCode == Keyboard.ENTER){
				//Execute entered command
				if(_input.text.length <= 0){
					addLogMessage("CMD", ">", _input.text);
					return;
				}
				
				//If Enter command was pressed, process command
				processCommand();
			}else if(event.keyCode == Keyboard.UP){
				//Go to previous command
				if(_historyIndex > 0){
					setHistory(_consoleHistory[--_historyIndex]);
				}else if(_consoleHistory.length > 0){
					setHistory(_consoleHistory[0]);
				}
				
				event.preventDefault();
			}else if(event.keyCode == Keyboard.DOWN){
				//Go to next command
				if(_historyIndex < _consoleHistory.length - 1){
					setHistory(_consoleHistory[++_historyIndex]);
				}else if(_historyIndex == _consoleHistory.length-1){
					_input.text = "";
				}
				
				event.preventDefault();
			}else if(event.keyCode == Keyboard.PAGE_UP){
				//Page the console view up
				if(bottomLineIndex == int.MAX_VALUE)
					bottomLineIndex = logCache.length - 1;
				
				bottomLineIndex -= getScreenHeightInLines() - 2;
				
				if(bottomLineIndex < 0){
					bottomLineIndex  = 0;
				}
			}else if(event.keyCode == Keyboard.PAGE_DOWN){
				// Page the console view down.
				if(bottomLineIndex != int.MAX_VALUE)
				{
					bottomLineIndex += getScreenHeightInLines() - 2;
					
					if(bottomLineIndex + getScreenHeightInLines() >= logCache.length)
						bottomLineIndex = int.MAX_VALUE;                    
				}
			}else if(event.keyCode == Keyboard.TAB){
				//We are doing tab searching
				var list:Array = Console.getCommandList();
				
				//Is this the first step?
				var isFirst:Boolean = false;
				if(tabCompletionCurrentStart == -1){
					tabCompletionPrefix = _input.text.toLowerCase();
					tabCompletionCurrentStart = int.MAX_VALUE;
					tabCompletionCurrentEnd = -1;
					
					for(var i:int = 0; i < list.length; i++){
						//If we found a prefix match
						if(list[i].name.substr(0, tabCompletionPrefix.length).toLowerCase() == tabCompletionPrefix){
							//Not it
							if(i < tabCompletionCurrentStart)
								tabCompletionCurrentStart = i;
							if(i > tabCompletionCurrentEnd)
								tabCompletionCurrentEnd = i;
							
							isFirst = true;
						}
					}
					tabCompletionCurrentOffset = tabCompletionCurrentStart;
				}
				
				//If there is a match, tab complete
				if(tabCompletionCurrentEnd != -1){
					//Update offset if appropriate
					if(!isFirst){
						if(event.shiftKey)
							tabCompletionCurrentOffset--;
						else 
							tabCompletionCurrentOffset++;
						
						//Wrap the offset
						if(tabCompletionCurrentOffset < tabCompletionCurrentStart){
							tabCompletionCurrentOffset = tabCompletionCurrentEnd;
						}else if(tabCompletionCurrentOffset > tabCompletionCurrentEnd){
							tabCompletionCurrentOffset = tabCompletionCurrentStart;
						}
					}
					
					//Get the match
					var potentialMatch:String = list[tabCompletionCurrentOffset].name;
					
					//Update the text with the current completion, caret at the end
					_input.text = potentialMatch;
					_input.setSelection(potentialMatch.length + 1, potentialMatch.length + 1);
				}
				
				var oldfr:* = stage.stageFocusRect;
				stage.stageFocusRect = false;
				stage.focus = _input;
				stage.stageFocusRect = oldfr;
			}else if(event.keyCode == 192){
				//Hide the console window
				parent.removeChild(this);
				deactivate();
			}
			
			_dirtyConsole = true;
			
			//Keep console input from propagating up to the stage
			event.stopImmediatePropagation();
			
			
		}
		
		protected function setHistory(old:String):void{
			_input.text = old;
			_input.setSelection(_input.length, _input.length);
		}
		
		protected function processCommand():void{
			addLogMessage("CMD", ">", _input.text);
			Console.processLine(_input.text);
			_consoleHistory.push(_input.text);
			_historyIndex = _consoleHistory.length;
			_input.text = "";
			
			_dirtyConsole = true;
		}
		
		public function getScreenHeightInLines():int{
			var roundedHeight:int = _outputBitmap.bitmapData.height;
			return Math.floor(roundedHeight / glyphCache.getLineHeight());
		}
		
		public function onFrame(evt:Event):void{
			//Don't draw if we are clean or invisible
			if(_dirtyConsole == false || parent == null)
				return;
			_dirtyConsole = false;
			
			var lineHeight:int = getScreenHeightInLines() - 1;
			var startLine:int = 0;
			var endLine:int = 0;
			
			if(bottomLineIndex == int.MAX_VALUE)
				startLine = GameUtil.clamp(logCache.length - lineHeight, 0, int.MAX_VALUE);
			else 
				startLine = GameUtil.clamp(bottomLineIndex - lineHeight, 0, int.MAX_VALUE);
			
			endLine = GameUtil.clamp(startLine + lineHeight, 0, logCache.length - 1);
			
			startLine--;
			
			//Wipe it
			var bd:BitmapData = _outputBitmap.bitmapData;
			bd.fillRect(bd.rect, 0x0);
			
			//Draw Lines
			for(var i:int=endLine; i >= startLine; i--){
				//skip empty
				if(!logCache[i])
					continue;
				
				glyphCache.drawLineToBitmap(logCache[i].text, 0, _outputBitmap.height - (endLine+1-i)*glyphCache.getLineHeight(), logCache[i].color, _outputBitmap.bitmapData);
			}						
		}
		
		public function addLogMessage(level:String, loggerName:String, message:String):void{
			var color:String = LogColor.getColor(level);
			
			//Cut down on the logger level if verbosity requests
			if(Console.verbosity < 2){
				var dotIdx:int = loggerName.lastIndexOf("::");
				if(dotIdx != -1)
					loggerName = loggerName.substr(dotIdx + 2);
			}
			
			//Split message by newline and add to the list
			var messages:Array = message.split("\n");
			for each(var msg:String in messages){
				var text:String = ((Console.verbosity > 0) ? level + ": " : "") + loggerName + " - " + msg;
				logCache.push({"color": parseInt(color.substr(1), 16), "text" : text });
			}
			
			_dirtyConsole = true;
		}
		
		public function activate():void{
			layout();
			_input.text = "";
			addListeners();
			TEngine.mainStage.focus = _input;
		}
		
		public function deactivate():void{
			removeListeners();
			TEngine.mainStage.focus = null;
		}
		
		public function set restrict(value:String):void{
			_input.restrict = value;
		}
		
		public function get restrict():String{
			return _input.restrict;
		}

	}
}
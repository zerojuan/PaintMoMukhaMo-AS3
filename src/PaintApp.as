package
{
	import com.adobe.images.JPGEncoder;
	import com.bit101.components.ColorChooser;
	import com.bit101.components.PushButton;
	import com.facebook.graph.Facebook;
	import com.facebook.graph.data.FacebookSession;
	import com.tada.engine.TEngine;
	import com.tada.utils.debug.Logger;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	import flash.system.LoaderContext;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	
	public class PaintApp extends Sprite
	{
		private var _sketch:Sprite;
		
		private var colorValue:uint = 0x000000;
		
		private var _colorPicker:ColorChooser;
		private var _submitButton:PushButton;
		
		private var _facebookSession:FacebookSession;
		
		private var _isMouseDown:Boolean = false;
		
		private var _myLoader:Loader;
		
		public function PaintApp()
		{
			TEngine.startup(this);			
			//Facebook.init("209188982437810");
			
			//_facebookSession = Facebook.getSession();
			
			_sketch = new Sprite();
			addChild(_sketch);
			
			var linkUID:String = getFlashVars().linkUid || "FAILED";
			
			Logger.print(this, "UID: " + linkUID);
			
			_sketch.x = 0;
			_sketch.y = 0;
			
			if(linkUID != "FAILED"){
				Logger.print(this, "Loading: " + "/"+linkUID+"/sketch.jpg");
				_myLoader = new Loader();
				
				_myLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
				_myLoader.load(new URLRequest("http://codeanginamo.com/paintapp/"+linkUID+"/sketch.jpg"), new LoaderContext());				
			}else{
				_sketch.graphics.beginFill(0xffffff);
				_sketch.graphics.drawRect(0,0, 760, 400);
				_sketch.graphics.endFill();
			}
			
			
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
			_colorPicker = new ColorChooser(this, 10, 10, 0xffffff, onColorChosen);
			_colorPicker.usePopup = true;
			
			_submitButton = new PushButton(this, 10, 30, "Save and Post", onSaveButton);
		}
		
		private function onImageLoaded(evt:Event):void{
			Logger.print(this, "Done loading bitmap" );
			Logger.print(this, "Target:"+evt.target.content.bitmapData);				
			_sketch.graphics.beginBitmapFill(BitmapData(evt.target.content.bitmapData));
			_sketch.graphics.drawRect(0,0, 760, 400);
			_sketch.graphics.endFill();
			Logger.print(this, "Done loading bitmap2");
		}
		
		private function getFlashVars():Object {
			return Object( LoaderInfo( this.loaderInfo ).parameters );
		}
		
		
		private function onMouseDown(evt:MouseEvent):void{
			_isMouseDown = true;
		}
		
		private function onMouseUp(evt:MouseEvent):void{
			Logger.print(this, "Done MouseUp");
			_isMouseDown = false;
		}
		
		private function onColorChosen(evt:Event):void{
			Logger.print(this, "Value: " + _colorPicker.value);
			colorValue = _colorPicker.value;
			
		}
		
		private function onSaveButton(evt:Event):void{
			Logger.print(this, "Saved");
			saveImage();
		}
		
		private function onEnterFrame(evt:Event):void{	
			if(_isMouseDown){
				_sketch.graphics.beginFill(colorValue);
				_sketch.graphics.drawCircle(mouseX, mouseY, Math.random() * 20);
				_sketch.graphics.endFill();
			}
		}
		
		private function saveImage():void{
			Logger.print(this, "_facebookSession: " + _facebookSession);
			Logger.print(this, "Your UID: " + _facebookSession.uid);
			var jpgSource:BitmapData = new BitmapData (760, 400);
			jpgSource.draw(_sketch);
			
			var jpgEncoder:JPGEncoder = new JPGEncoder(85);
			var jpgStream:ByteArray= jpgEncoder.encode(jpgSource);
			
			var header:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
			var jpgURLRequest:URLRequest = new URLRequest("saveImage.php?name=sketch.jpg&folder="+_facebookSession.uid);
			jpgURLRequest.requestHeaders.push(header);
			jpgURLRequest.method = URLRequestMethod.POST;
			jpgURLRequest.data = jpgStream;
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, onPictureSaved);
			urlLoader.load(jpgURLRequest);
		}
		
		private function onPictureSaved(evt:Event):void{
			var obj:Object = 
				{
					method: 'stream.publish',
					name: "Paint, Your Face!",
					//link: "http://www.codeanginamo.com/paintapp/"+_facebookSession.uid+"/sketch.jpg",
					link: "http://apps.facebook.com/paintmomukhamo/launch.php?uid="+_facebookSession.uid, // canvas page ng game.					
					picture: "http://www.codeanginamo.com/paintapp/"+_facebookSession.uid+"/sketch.jpg",
					caption: "Look at this drawing I made and paint over it. It is the boringest facebook app ever.",
					description: "Boringest facebook app made in half a day!! Also, I still can't believe Miley Cyrus will do this.",
					message: "SRSLY, guys. Miley Cyrus is looking at your profile."
				}
			Facebook.ui("feed",obj,null);	
		}
	}
}
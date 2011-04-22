package com.tada.utils
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	/**
	 * TypeUtility is a static class containing methods that aid in introspection and reflection
	 */ 
	public class TypeUtility
	{
		public static function getObjectClassName(object:*):String{
			return getQualifiedClassName(object);
		}
		
		public static function getClassForName(className:String):Class{
			return getDefinitionByName(className) as Class;
		}
		
		public static function getClass(item:*):Class{
			if(item is Class || item == null)
				return item;
			
			return Object(item).constructor;
		}
	}
}
<?php
namespace Test;

class Mock
{
	private static $id;
	
	public static function generate($class_name = null) 
	{
		if ($class_name === null) 
		{
			$id = self::$id++;
			$class_name = "__GeneratedMock{$id}__";
		}
		
		return new MockSpecification($class_name);
	}
	
	public static function method_matches_pattern($method, $pattern) 
	{
		// TODO: support wildcards
		return strcmp($method, $pattern) === 0;
	}
}
?>
<?php
namespace Application;

/**
 * The singleton pattern implementation based on the late static binding.
 * Requires a protected static variable named <code>$instance</code> to be 
 * declared at the appropriate level of the inheritance hierarchy.
 *
 * @author Szymon Wrozynski
 * @package Application
 */
abstract class Singleton
{	
	protected function __construct() {}
	
	/**
	 * Returns the instance of the descendant or creates a new one.
	 * 
	 * @return Singleton
	 */
	public static function &instance()
	{
		if (!static::$instance)
		{
			$class = get_called_class();
			static::$instance = new $class;
		}
		
		return static::$instance;
	}
	
	private final function __clone() {}
}
?>
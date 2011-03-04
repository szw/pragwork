<?php
namespace Application;

abstract class Singleton
{	
	protected function __construct() {}

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
	
	/**
	 * Destroys the instance.
	 */
	public function clean_up()
	{
		static::$instance = null;
	}
}
?>
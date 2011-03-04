<?php
namespace Application;

/**
 * The base class for module configuration objects. It provides a unique way of managing different environments.
 * Configuration entries are set (and get) as virtual properties. The properties might be appended directly 
 * to the current environment:
 *
 * <code>
 * $config->foo = 'foo';
 * </code>
 *
 * or (within an array) to many environments at once:
 *
 * <code>
 * $config->foo = array(
 *     'development' => 'foo_dev',
 *     'test' => 'foo_test',
 *     'production' => 'foo_production'
 * );
 * </code>
 *
 * The special virtual property is named <code>environment</code>. It is used to set the current environment. 
 * By default it is set to 'development'.
 *
 * The environment named 'test' is required by integrated <code>Test</code> module. 
 * And the environment having 'production' in its name is recognized as the final production stage. 
 * Notice, it does not have to equal to 'production' exactly. It might be 'en_production' as well. 
 * In that way you may have many production environments. This is helpful with some localization strategies.
 *
 * @author Szymon Wrozynski
 * @package Application
 */
abstract class ModuleConfiguration extends Singleton
{
	protected static $defaults = array();
	protected static $env = 'development';
	protected $env_vars;
	
	protected function __construct()
	{
		$this->env_vars[self::$env] = static::$defaults;
	}
	
	/**
	 * Allows configuration initialization using a closure.
	 *
	 * <code>
	 * Configuration::initialize(new function($config)
	 * {
	 *     $config->foo = 'foo';
	 *
	 *     $config->bar = array(
	 *         'development' => 'bar_dev',
	 *         'test' => 'bar_test',
	 *         'production' => 'bar_production'
	 *     );
	 * });
	 * </code>
	 *
	 * @param \Closure $initializer A closure
	 */
	public static function initialize($initializer)
	{
		$initializer(parent::instance());
	}
	
	/**
	 * If the <code>$name</code> equals to 'environment' the <code>$value</code> is used as the environment
	 * name. Otherwise it sets the configuration entry for the current environment or (in the <code>$value</code> 
	 * is an array), for many environments at once.
	 *
	 * @param string $name The property name
	 * @param mixed $value The property value
	 */
	public function __set($name, $value)
	{
		if ($name === 'environment')
		{
			self::$env = $value;
			if (!isset($this->env_vars[$value]))
				$this->env_vars[$value] = static::$defaults;
		}
		elseif ((array) $value === $value)
		{	
			foreach ($value as $env => $val)
			{
				if (!isset($this->env_vars[$env]))
					$this->env_vars[$env] = static::$defaults;
				
				$this->env_vars[$env][$name] = $val;
			}
		}
		else
			$this->env_vars[self::$env][$name] = $value;
	}
	
	/**
	 * If the <code>$name</code> equals to 'environment' the current environment name is returned. 
	 * Otherwise it returns the configuration variable value for the current environment.
	 *
	 * @param string $name The property name
	 * @return mixed The environment name or configuration variable value
	 */
	public function __get($name)
	{
		return ($name === 'environment') ? self::$env : $this->env_vars[self::$env][$name];
	}
	
	/**
	 * Returns an array containing the selected property values in all available environments.
	 * 
	 * <code>
	 * $config->all_for('foo');
	 * # returns:
	 * # array(3) {
	 * #   ["development"]=>
	 * #   string(7) "bar_dev"
	 * #   ["test"]=>
	 * #   string(8) "bar_test"
	 * #   ["production"]=>
	 * #   string(14) "bar_production"
	 * # }
	 * </code>
	 *
	 * @param string $name The property name
	 * @return array Property values in all available environments
	 */
	public function all_for($name)
	{
		$result = array();
		
		foreach ($this->env_vars as $env => $data)
		{
			if (array_key_exists($name, $data))
				$result[$env] = $data[$name];
		}
		
		return $result;
	}
}
?>
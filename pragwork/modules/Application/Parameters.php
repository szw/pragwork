<?php
namespace Application;

/**
 * The class holding {@link Controller}'s request parameters.
 *
 * The parameters can come both from the request and from the URI path. Path parameters are strings and they 
 * are always present (if not mispelled) because they are parsed before the action was fired.
 * The regular parameters are strings usually but it is possible to pass a parameter as an array of strings 
 * (with the help of the <code>[]</code> suffix) therefore you should be careful and never make an assumption 
 * that the 'plain' regular parameter is a string every time.
 *
 * To help with that, the {@link Parameters} class has two additional methods: {@link get_string()} 
 * and {@link get_array()}. Both will return the parameter value only if it belongs to a certain type.
 *
 * Path parameters always override the the regular ones if there is a clash of names.
 *
 * Parameters can be iterated in the <code>foreach</code> loop and therefore they might be passed directly 
 * to the {@link ActiveRecord\Model} instances.
 *
 * @author Szymon Wrozynski
 * @package Application
 */
class Parameters extends Store
{
	protected static $instance;

	protected function __construct()
	{	
		$request = Request::instance();
		$this->store = $request->path_parameters + $request->request_parameters + $request->query_parameters;
	}

	/**
	 * Returns the parameter only if it contains a string value. 
	 * The <code>null</code> is returned if the parameter neither has the string
	 * value nor exists.
	 *
	 * @param string $name Name of a parameter
	 * @return string
	 */
	public function &get_string($name)
	{
		$value = null;
		
		if (isset($this->store[$name]) && ((string) $this->store[$name] === $this->store[$name]))
			$value =& $this->store[$name];
			
		return $value;
	}
	
	/**
	 * Returns the parameter only if it contains an array. 
	 * The <code>null</code> is returned if the parameter neither contains 
	 * the array value nor exists.
	 *
	 * @param string $name Name of a parameter
	 * @return array
	 */
	public function &get_array($name)
	{
		$value = null;
		
		if (isset($this->store[$name]) && ((array) $this->store[$name] === $this->store[$name]))
			$value =& $this->store[$name];
		
		return $value;
	}
	
	/**
	 * Returns the parameters array copy.
	 *
	 * @return array
	 */
	public function to_a()
	{
		return $this->store;
	}
	
	/**
	 * Returns the filtered parameters array copy without specified ones.
	 *
	 * @param string ... Variable-length list of parameter names
	 * @return array
	 */
	public function except(/*...*/)
	{
		$params = $this->store;

		foreach (func_get_args() as $name)
			unset($params[$name]);
		
		return $params;
	}
	
	/**
	 * Returns the filtered parameters array copy containing only specified
	 * parameters.
	 *
	 * @param string ... Variable-length list of parameter names
	 * @return array
	 */
	public function only(/*...*/)
	{
		$params = array();
		
		foreach (func_get_args() as $name)
			$params[$name] = $this->store[$name];
			
		return $params;
	}
}
?>
<?php
namespace Application;

/**
 * The abstract class providing common mechanics for {@link Session},
 * {@link Parameters}, {@link Cookies}, and {@link Flash} classes. 
 *
 * @author Szymon Wrozynski
 * @package Application
 */
abstract class Store extends Singleton implements \IteratorAggregate
{
	protected $store;
	
	protected function __construct(array &$store)
	{
		$this->store =& $store;
	}
			
	/**
	 * Sets a new variable in the store.
	 *
	 * @param string $name Name of the variable
	 * @param mixed $value Variable value
	 */
	public function __set($name, $value)
	{
		$this->store[$name] = $value;
	}

	/**
	 * Gets a variable from the store.
	 *
	 * @param string $name Name of the variable
	 * @return mixed Variable value or null
	 */
	public function &__get($name)
	{
		$value = null;
		
		if (isset($this->store[$name]))
			$value =& $this->store[$name];
		
		return $value;
	}
	
	/**
	 * Checks if a variable is present in the store.
	 *
	 * @param string $name Name of the variable
	 * @return bool True if the variable exists, false otherwise
	 */
	public function __isset($name)
	{
		return isset($this->store[$name]);
	}
	
	/**
	 * Removes the variable if present.
	 *
	 * @param string $name Name of the variable
	 */
	public function __unset($name)
	{
		unset($this->store[$name]);
	}

	/**
	 * Returns an iterator to stored variables. This will allow to iterate
	 * over using <code>foreach</code>. 
	 *
	 * @return \ArrayIterator
	 */
	public function getIterator()
	{
		return new \ArrayIterator($this->store);
	}
}
?>
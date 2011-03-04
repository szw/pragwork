<?php
namespace Test;

/**
 * Simulates the disk storage for example to simulate caching operations of the 
 * {@link Application\Controller} in the test environment. It might be used in other
 * mock objects as well.
 *
 * @author Szymon Wrozynski
 * @package Test
 */
class Storage
{
	private $_storages = array(array());
	
	/**
	 * Adds a location to the storage.
	 *
	 * @params string $path The location path e.g. TEMP
	 */
	public function add_location($path)
	{
		if (is_string($path))
			$path = rtrim($path, DIRECTORY_SEPARATOR);
		
		if (!isset($this->_storages[$path]))
			$this->_storages[$path] = array();
	}
	
	/**
	 * Returns the reference to an array simulating the storage. If the <code>$path</code> is 
	 * omitted the array simulating the current working directory is returned.
	 *
	 * @param string $path The path
	 * @return array
	 */
	public function &get_location($path=0)
	{
		if (is_string($path))
			$path = rtrim($path, DIRECTORY_SEPARATOR);
		
		if (isset($this->_storages[$path]))
			return $this->_storages[$path];
	}
	
	private final function get_storage_and_relative_path($path)
	{
		foreach ($this->_storages as $p => &$s)
		{
			if (is_string($p) && (strpos($path, $p) === 0))
				return array(&$s, trim(substr($path, strlen($p)), DIRECTORY_SEPARATOR));
		}
		return array(&$this->_storages[0], trim($path, DIRECTORY_SEPARATOR));
	}
	
	/**
	 * Sets a content a the last path node. It might be a string (representing a file) or an array
	 * (a directory structure).
	 *
	 * @param string $path The full path
	 * @param mixed $content The array with the directory structure or a string
	 */
	public function set_content($path, $content)
	{
		$storage_and_path = $this->get_storage_and_relative_path($path);
		$handle =& $storage_and_path[0];
		$path = $storage_and_path[1];
		$path_parts = explode(DIRECTORY_SEPARATOR, $path);
		
		foreach ($path_parts as $i => $part)
		{
			if (!isset($path_parts[$i + 1])) # if last
				$handle[$part] = $content;
			elseif (is_array($handle) && isset($handle[$part]) && is_array($handle[$part]))
				$handle =& $handle[$part];
			else
				throw new \ErrorException("Wrong path: $path");
		}
	}
	
	/**
	 * Returns the reference to the concrete node of the storage structure.
	 *
	 * @param string $path The path to the node
	 * @return mixed The node reference
	 */
	public function &get_handle($path)
	{
		$storage_and_path = $this->get_storage_and_relative_path($path);
		$handle =& $storage_and_path[0];
		$path = $storage_and_path[1];

		foreach (explode(DIRECTORY_SEPARATOR, $path) as $part)
		{
			if (is_array($handle))
			{
				if (isset($handle[$part]))
					$handle =& $handle[$part];
				else
				{
					unset($handle);
					$handle = null;
					break;
				}
			}
			else
				break;
		}
		return $handle;
	}
	
	/**
	 * Removes the whole structure node. Simulates the <code>unlink()</code> and recursive
	 * <code>rmdir()</code> functions.
	 *
	 * @param string $path The path
	 */
	public function unlink($path)
	{
		$handle =& $this->get_handle($path);
		
		if ($handle !== null)
			$handle = null;
	}
	
	/**
	 * Checks if a node exists.
	 *
	 * @param string $path The path
	 * @return bool True if exists, false otherwise
	 */
	public function file_exists($path)
	{
		return $this->get_handle($path) !== null;
	}
	
	/**
	 * Simulates the <code>file_put_contents()</code> function.
	 *
	 * @param string $path Path to the node
	 * @param string $text Content
	 */
	public function file_put_contents($path, $text)
	{
		if (!$this->is_dir($path))
			$this->set_content($path, $text);
	}
	
	/**
	 * Simulates the <code>file_put_contents()</code> function.
	 *
	 * @param string $path Path to the node
	 * @return string The content of the node (it has to be a file)
	 */
	public final function file_get_contents($path)
	{
		if ($this->is_file($path))
			return $this->get_handle($path);
	}
	
	/**
	 * Simulates a <code>scandir()</code> function but it does not return '.' and '..' entries.
	 *
	 * @param string $path Path to the node
	 * @param string $sorting_order 0 for the ascending alphabetical order, non 0 for descending
	 * @return array The array of entries
	 */
	public final function scandir($path, $sorting_order=0)
	{
		if ($this->is_dir($path))
		{
			$result = array_keys($this->get_handle($path));
			
			if ($sorting_order === 0)
				sort($result);
			else
				rsort($result);
			
			return $result;
		}
	}
	
	/**
	 * Simulates the <code>is_file()</code> function.
	 *
	 * @param string $path Path to the node
	 * @return bool True if the node exists and it is a file
	 */
	public final function is_file($path)
	{
		$handle = $this->get_handle($path);
		return $handle !== null && !is_array($path);
	}
	
	/**
	 * Simulates the <code>is_dir()</code> function.
	 *
	 * @param string $path Path to the node
	 * @return bool True if the node exists and it is a directory
	 */
	public final function is_dir($path)
	{
		$handle = $this->get_handle($path);
		return $handle !== null && is_array($path);
	}
	
	/**
	 * Simulates the <code>mkdir()</code> function in the recursive mode.
	 *
	 * @param string $path Path containing nodes.
	 */
	public final function mkdir($path)
	{
		$storage_and_path = $this->get_storage_and_relative_path($path);
		$handle =& $storage_and_path[0];
		$path = $storage_and_path[1];

		foreach (explode(DIRECTORY_SEPARATOR, $path) as $part)
		{
			if (isset($handle[$part]) && !is_array($handle[$part]))
				throw new \ErrorException("$part is a file, not a directory.");
			else
				$handle[$part] = array();
				
			$handle =& $handle[$part];
		}
	}
}
?>
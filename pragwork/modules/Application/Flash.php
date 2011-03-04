<?php
namespace Application;

/**
 * The class for reading and writing message stored in the session. Once read they are discarded upon the next request. 
 *
 * This class requires session to be enabled.
 * 
 * Examples:
 *
 * <code>
 * $this->flash->notice = 'This is a notice.'; # saves the message
 * </code>
 *
 * <code>
 * echo $this->flash->notice; # gets the message - now it is marked as read
 * </code>
 *
 * @author Szymon Wrozynski
 * @package Application
 */
class Flash extends Store
{	
	protected static $instance;
	
	protected function __construct($session)
	{		 
		if ($session->__PRAGWORK_FLASH_STORAGE)
		{
			foreach ($session->__PRAGWORK_FLASH_STORAGE as $name => $msg) 
			{
				if ($msg[1])
					unset($session->__PRAGWORK_FLASH_STORAGE[$name]);
			}
		}
		else
			$session->__PRAGWORK_FLASH_STORAGE = array();
		
		parent::__construct($session->__PRAGWORK_FLASH_STORAGE);
	}
	
	/**
	 * Returns the {@link Flash} instance only if the sessions are available (see {@link Configuration}).
	 * Otherwise returns <code>null</code>.
	 * 
	 * @return Flash
	 */
	public static function &instance()
	{
		if (!static::$instance)
		{
			$session = Session::instance();
			if ($session)
				static::$instance = new Flash($session);
		}
		
		return static::$instance;
	}
	
	/**
	 * Writes the instant message stored in the session. It requires a session to be enabled.
	 *
	 * @param string $name Message name
	 * @param mixed $message Message
	 */
	public function __set($name, $message)
	{	
		$this->store[$name] = array($message, false);
	}
	
	/**
	 * Reads the instant message stored in the session. Once read it is discarded upon the next request. 
	 * 
	 * @param string $name Message name
	 * @return mixed Message
	 */
	public function &__get($name)
	{
		$value = null;
		
		if (isset($this->store[$name])) 
		{
			$this->store[$name][1] = true;
			$value =& $this->store[$name][0];
		}
		
		return $value;
	}
}
?>
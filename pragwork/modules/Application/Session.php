<?php
namespace Application;

/**
 * The class simplifying the session usage.
 * 
 * <code>
 * $login = $session->login;
 * # the same as:
 * # $login = $_SESSION['login'];
 *
 *
 * $session->login = $login;
 * # the same as: 
 * # $_SESSION['login'] = $login;
 *
 *
 * unset($session->login);
 * # the same as: 
 * # unset($_SESSION['login']);
 *
 *
 * isset($session->login);
 * # the same as: 
 * # isset($_SESSION['login']);
 * </code>
 *
 * @author Szymon Wrozynski
 * @package Application
 */
class Session extends Store
{	
	protected static $instance;
	
	protected function __construct($session_name)
	{
		if ($session_name !== true)
			session_name($session_name);
		
		session_start();
		parent::__construct($_SESSION);
	}
	
	/**
	 * Returns the {@link Session} instance only if the session is enable through the {@link Configuration} instance.
	 * Otherwise returns null.
	 * 
	 * @return Session
	 */
	public static function &instance()
	{
		if (!static::$instance)
		{
			$session = Configuration::instance()->session;
			
			if ($session)
				static::$instance = new Session($session);
		}
		
		return static::$instance;
	}
	
	/**
	 * Destroys the current session and causes the browser to remove the session cookie.
	 */
	public function kill()
	{
		$_SESSION = array();
		session_destroy();
		setcookie(session_name(), '', $_SERVER['REQUEST_TIME'] - 60000, '/', '', 0, 0);
	}
}
?>
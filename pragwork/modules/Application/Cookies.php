<?php
namespace Application;

/**
 * The class simplifying handling cookies.
 *
 * @author Szymon Wrozynski
 * @package Application
 */
class Cookies extends Store
{
	protected static $instance;
	
	protected function __construct()
	{		 
		parent::__construct($_COOKIE);
	}
	
	/**
	 * If <code>$value</code> is a string this method sends a cookie just like the <code>setcookie()</code> PHP
	 * function, except the default path. It is set to '/'.
	 * 
	 * If the <code>$value</code> is an array, the following options are available:
	 *
	 * <ul>
	 * <li><b>value</b>: the value of the cookie
	 * <li><b>expire</b>: the time the cookie expires (default 0)</li>
	 * <li><b>path</b>: the path on the server in which the cookie will be available on (default <code>/</code>)</li>
	 * <li><b>domain</b>: the domain that the cookie is available to</li>
	 * <li><b>secure</b>: indicates that cookie should be transmitted through SSL (default false)</li>
	 * <li><b>http_only</b>: if true the cookie will use HTTP protocol only (default false)</li>
	 * <li><b>raw</b>: if true the cookie will not be url-encoded</li>
	 * </ul>
	 * 
	 * @param string $name The name of the cookie
	 * @param mixed $value The value of the cookie or the array of options
	 */
	public function __set($name, $value)
	{
		if ((array) $value === $value)
		{
			$val = isset($value['value']) ? $value['value'] : '';
			parent::__set($name, $val);
			Response::instance()->add_header(
				self::create_cookie_header(
					$name, 
					$val,
					isset($value['expire']) ? $value['expire'] : 0,
					isset($value['path']) ? $value['path'] : '/',
					isset($value['domain']) ? $value['domain'] : '',
					isset($value['secure']) ? $value['secure'] : false,
					isset($value['http_only']) ? $value['http_only'] : false,
					isset($value['raw']) ? $value['raw'] : false
				), 
				false
			);
		}
		else
		{
			parent::__set($name, $value);
			Response::instance()->add_header(self::create_cookie_header($name, $value),	false);
		}
	}
	
	/**
	 * Causes the browser to remove the session cookie.
	 *
	 * @param string $name The name of the cookie
	 */
	public function __unset($name)
	{
		parent::__unset($name);
		Response::instance()->add_header(self::create_cookie_header($name, '', $_SERVER['REQUEST_TIME'] - 60000),false);
	}
	
	private final function create_cookie_header($name, $val='', $exp=0, $path='/', $domain='',
		$sec=false, $http=false, $raw=false)
	{	
		if ($domain)
		{
			if (strtolower(strpos($domain, 'www.')) === 0)
				$domain = substr($domain, 4);
				
			if ($domain[0] !== '.')
				$domain = '.' . $domain;
			
			$port = strpos($domain, ':');
			if ($port !== false)
				$domain = substr($domain, 0, $port);
		}
		return 'Set-Cookie: ' . rawurlencode($name) . '=' 
			. ($raw ? $value : rawurlencode($value))
			. ($domain ? "; Domain=$domain" : '')
			. (exp ? '; expires=' . gmdate('D, d-M-Y H:i:s', $exp) . ' GMT' :'')									   
			. ($path ? "; Path=$path" : '')
			. ($sec ? '; Secure' : '')
			. ($http ? '; HttpOnly' : '');
		
	}
}
?>
<?php
namespace Application;

/**
 * The Application module configuration class.
 *
 * Contains several properties:
 * 
 * <ul>
 * <li><b>server_path</b>: The optional server path, i.e. the part of the URL appended to the domain name. 
 *     E.g. a server directory.</li>
 * <li><b>http_port</b>: The optional number of the server port for the HTTP protocol. If null (default) the 80 
 *     is used.</li>
 * <li><b>ssl_port</b>: The optional number of the server port for the HTTPS protocol. If null (default) the 443 
 *     is used.</li>
 * <li><b>images_path</b>: The path to the images assets. May be relative and points to the current server or absolute 
 *     (with http://) and points to any server on the net. By default: '/images'.</li>
 * <li><b>javascripts_path</b>: The path to the javascript assets. May be relative and points to the current server 
 *     or absolute (with http://) and points to any server on the net. By default: '/javascripts'.</li>
 * <li><b>stylesheets_path</b>: The path to the css stylesheets. May be relative and points to the current server 
 *     or absolute (with http://) and points to any server on the net. By default: '/stylesheets'.</li>
 * <li><b>localization</b>: Turns on/off (true/false) the localization or explicitly lock it to the chosen one 
 *     (string).</li>
 * <li><b>session</b>: Turns on/off (true/false) the session or explicitly sets it on, along with the given name
 *     (string).</li>
 * <li><b>cache</b>: Enables/disables (true/false) caching features.</li>
 * </ul>
 *
 * Notice, all paths should NOT end with a separator (a slash <code>/</code>).
 *
 * @author Szymon Wrozynski
 * @package Application
 */
class Configuration extends ModuleConfiguration
{	
	protected static $instance;
	
	protected static $defaults = array(
		'server_path' => null,
		'http_port' => null,
		'ssl_port' => null,
		'images_path' => '/images',
		'javascripts_path' => '/javascripts',
		'stylesheets_path' => '/stylesheets',
		'localization' => false,
		'session' => true,
		'cache' => false
	);
	
	/**
	 * Return an HTTP URL part based on configuration properties used to construct URLs.
	 *
	 * @return string
	 */
	public function http_url()
	{
		return $this->env_vars[self::$env]['http_port']
			? 'http://' . $_SERVER['SERVER_NAME'] . ':' . $this->env_vars[self::$env]['http_port'] . $this->server_path
			: 'http://' . $_SERVER['SERVER_NAME'] . $this->server_path;
	}
	
	/**
	 * Return an HTTPS URL part based on configuration properties used to construct URLs.
	 *
	 * @return string
	 */
	public function ssl_url()
	{
		return $this->env_vars[self::$env]['ssl_port']
			? 'https://' . $_SERVER['SERVER_NAME'] . ':' . $this->env_vars[self::$env]['ssl_port'] . $this->server_path
			: 'https://' . $_SERVER['SERVER_NAME'] . $this->server_path;
	}
}
?>
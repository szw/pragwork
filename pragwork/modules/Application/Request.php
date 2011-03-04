<?php
namespace Application;

/**
 * Class encapsulating the request details parsed on processing.
 * 
 * @package Application
 * @author Szymon Wrozynski
 */
class Request extends Singleton
{ 
	/**
	 * The reference to the parsed routing entry from the <code>$ROUTES</code> array.
	 *
	 * @internal
	 * @var array
	 */
	public $route;
	
	/**
	 * The path parameters array.
	 *
	 * @internal
	 * @var array
	 */
	public $path_parameters = array();
	
	/**
	 * The query parameters array.
	 *
	 * @internal
	 * @var array
	 */
	public $query_parameters;
	
	/**
	 * The request parameters array (passed in the request body).
	 *
	 * @internal
	 * @var array
	 */
	public $request_parameters;
	
	protected static $instance;
	private $_uri;
	
	protected function __construct($uri) 
	{
		$this->_uri = $uri;
		$this->query_parameters = $_GET;
		
		if ($_SERVER['REQUEST_METHOD'] === 'POST')
			$this->request_parameters = $_POST;
		else
			parse_str(file_get_contents('php://input'), $this->request_parameters);
	}
	
	/**
	 * Returns the {@link Request} instance.
	 * 
	 * @param string $uri URI used once while creating the instance
	 * @return Request
	 */
	public static function &instance($uri=null)
	{
		if (!static::$instance && $uri)
			static::$instance = new Request($uri);
		
		return static::$instance;
	}
	
	/**
	 * Gets the request URI path (without the specified server path).
	 * 
	 * @return string
	 */
	public function uri()
	{
		return $this->_uri;
	}
	
	/**
	 * Gets the client remote IP.
	 *
	 * @return string
	 */
	public function remote_ip()
	{
		return $_SERVER['REMOTE_ADDR'];
	}

	/**
	 * Returns the current HTTP request method.
	 *
	 * @return string Current HTTP method
	 */
	public function method()
	{
		return $_SERVER['REQUEST_METHOD'];
	}

	/**
	 * Determines if the current HTTP request is secure (SSL) or not.
	 *
	 * @return bool True if SSL is used, false otherwise
	 */
	public function is_ssl()
	{
		return $_SERVER['SERVER_PORT'] == (Configuration::instance()->ssl_port ?: 443);
	}

	/**
	 * Determines if the current HTTP request uses a GET method.
	 *
	 * @return bool True if a GET method is used, false otherwise
	 */
	public function is_get()
	{
		return $_SERVER['REQUEST_METHOD'] === 'GET';
	}

	/**
	 * Determines if the current HTTP request uses a POST method.
	 *
	 * @return bool True if a POST method is used, false otherwise
	 */
	public function is_post()
	{
		return $_SERVER['REQUEST_METHOD'] === 'POST';
	}
	
	/**
	 * Determines if the current HTTP request uses a PUT method.
	 *
	 * @return bool True if a PUT method is used, false otherwise
	 */
	public function is_put()
	{
		return $_SERVER['REQUEST_METHOD'] === 'PUT';
	}

	/**
	 * Determines if the current HTTP request uses a DELETE method.
	 *
	 * @return bool True if a DELETE method is used, false otherwise
	 */
	public function is_delete()
	{
		return $_SERVER['REQUEST_METHOD'] === 'DELETE';
	}
}
?>
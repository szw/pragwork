<?php
namespace Test;
use Application\Controller;

class TestRequest extends \Application\Request
{	 
	private $_ip;
	private $_method;
	private $_ssl;
	
	protected function __construct($uri, $m, $ssl, $ip, $route, $pp, $qp, $rp) 
	{
		parent::__construct($uri);
		$this->_method = $m;
		$this->_ssl = $ssl;
		$this->_ip = $ip;
		$this->route = $route;
		$this->path_parameters = $pp;
		$this->query_parameters = $qp;
		$this->request_parameters = $rp;
	}
	
	/**
	 * Sets the test environment and creates a new request or returns 
	 * the existing one.
	 *
	 * The following options are available:
	 *
	 * <ul>
	 * <li><b>locale</b>: the locale code used in the simulated request</li>
	 * <li><b>path_params</b>: the parameters passed via the path
	 * <li><b>query_params</b>: the parmeters passed as the query string</li>
	 * <li><b>request_params</b>: the parameters passed through the request
	 *	   body</li>
	 * <li><b>session</b>: the array used in the {@link Session}</li>
	 * <li><b>cookies</b>: the array used in the {@link Cookies}</li>
	 * <li><b>method</b>: the request method (GET, POST, PUT, DELETE)</li>
	 * <li><b>ip</b>: the client ip (default 127.0.0.1)</li>
	 * </ul>
	 *
	 * @param string $action The action name or null if the request exists
	 * @param array $options Options
	 * @return TestRequest The TestRequest instance
	 */
	public static function &instance($action=null, $options=array())
	{
		if (!static::$instance && $action)
		{
			global $ROUTES, $LOCALE;
			
			$c = Controller::instance();
			
			if (!method_exists($c, $action))
				throw new \ErrorException("The action '$action' of controller " . substr(get_class($c), 12, -10) 
					. " does not exists.");
			
			$r = $ROUTES[$ROUTES['__RC'][substr(get_class($c), 12, -10)][$action]];
			$locale = isset($options['locale']) ? $options['locale'] : null;

			$config = \Application\Configuration::instance();
			$localization = $config->localization;
			
			if ($localization === true)
			{
				if ($locale)
					require LOCALES . $locale . '.php';
				elseif ($r[0] !== '/')
					throw new \ErrorException('Locale required.');
			}
			elseif ($localization)
				require LOCALES . $localization . '.php';		
		
			$_COOKIE = isset($options['cookies']) ? $options['cookies'] : array();
			$_SESSION = isset($options['session']) ? $options['session'] : array();
		
			$rp = isset($options['request_params']) ? $options['request_params'] : array();
			$qp = isset($options['query_params']) ? $options['query_params'] : array();
		
			$pp = isset($options['path_params']) ? $options['path_params'] : array();
		
			$ssl = isset($r['ssl']) ? $r['ssl'] : false;
			$_SERVER['SERVER_PORT'] = $ssl ? $config->ssl_port : $config->http_port;

			$available_methods = explode(' ', $r['methods']);

			if (isset($options['method']))
			{
				if (in_array($options['method'], $available_methods))
					$m = $options['method'];
				else
					throw new \ErrorException('The HTTP method ' . $options['method'] 
						. " is not allowed for the action '$action'.");
			}
			else
				$m = $available_methods[0];
			
			$_SERVER['REQUEST_METHOD'] = $m;
			
			$ip = isset($options['ip']) ? $options['ip'] : '127.0.0.1';
			
			$c->request = new \stdClass; # a fake request (required by url_for)
			$c->request->path_parameters =& $pp;
			$c->request->route =& $r;
			
			$uri = substr(url_for(array('params' => ($pp + $qp) ?: null)), 
				strlen($ssl ? $config->ssl_url() : $config->http_url()));
			
			static::$instance = new TestRequest($uri, $m, $ssl, $ip, $r, $pp, $qp, $rp);
		}
		return static::$instance;
	}
	
	public function remote_ip()
	{
		return $this->_ip;
	}
	
	public function method()
	{
		return $this->_method;
	}

	public function is_ssl()
	{
		return $this->_ssl;
	}

	public function is_get()
	{
		return $this->_method === 'GET';
	}

	public function is_post()
	{
		return $this->_method === 'POST';
	}

	public function is_put()
	{
		return $this->_method === 'PUT';
	}

	public function is_delete()
	{
		return $this->_method === 'DELETE';
	}
}
?>
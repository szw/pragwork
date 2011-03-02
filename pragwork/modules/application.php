<?php
/**
 * The Application Module of Pragwork 1.1.0
 *
 * @copyright Copyright (c) 2009-2011 Szymon Wrozynski
 * @license Licensed under the MIT License
 * @version 1.1.0
 * @package Application
 */

namespace Application
{	 
	/**
	 * Starts request processing. This function should be used only once as the entry point while starting 
	 * the Pragwork application.
	 *
	 * @author Szymon Wrozynski
	 */
	function start() 
	{	
		$qpos = strpos($_SERVER['REQUEST_URI'], '?');
		
		$config = Configuration::instance();
		$server_path = $config->server_path;
		
		if ($qpos === false)
			$path = $server_path ? substr($_SERVER['REQUEST_URI'], strlen($server_path)) : $_SERVER['REQUEST_URI'];
		elseif (!$server_path) 
			$path = substr($_SERVER['REQUEST_URI'], 0, $qpos);
		else 
		{
			$splen = strlen($server_path);
			$path = substr($_SERVER['REQUEST_URI'], $splen, $qpos - $splen);
		}
		
		$request = Request::instance($path);
		$response = Response::instance();
		
		global $LOCALE, $ROUTES;
		
		$error = null;
		
		$localization = $config->localization;
		
		if ($localization === true)
		{
			if ($path !== '/')
			{
				$second_slash = strpos($path, '/', 1);
				
				$locale_file = $second_slash
					? LOCALES . substr($path, 1, $second_slash - 1) . '.php'
					: LOCALES . substr($path, 1) . '.php';
				
				if (!is_file($locale_file))
					$error = 404;
				else
					require $locale_file;
				
				$path = $second_slash ? substr($path, $second_slash) : '/';
			}
		}
		elseif ($localization)
			require LOCALES . $localization . '.php';
		
		require CONFIG . 'routes.php';
		
		if ($ROUTES)
			$ROUTES[0][0] = '/';
		
		$found = $error;
		$rc = $rc2 = null;
		
		$p_tokens = array(strtok($path, '/.'));
		
		while (($t = strtok('/.')) !== false)
			$p_tokens[] = $t;
			
		foreach ($ROUTES as $n => $r) 
		{	
			$rc[$r['controller']][$r['action']] = $rc2["{$r['controller']}\\{$r['action']}"] = $n;
			
			if ($found)
			{
				$t = strtok($r[0], '/.');

				if (($t !== false) && $t[0] === ':')
					$ROUTES[$n]['pp'][] = substr($t, 1);

				while (($t = strtok('/.')) !== false)
				{
					if ($t[0] === ':')
						$ROUTES[$n]['pp'][] = substr($t, 1);
				}
				continue;
			}
			else
			{
				$match = true;
				$t = strtok($r[0], '/.');

				if (($t !== false) && $t[0] === ':')
				{
					$pp = substr($t, 1);
					$ROUTES[$n]['pp'][] = $pp;
					$request->path_parameters[$pp] = $p_tokens[0];
				}
				elseif ($t !== $p_tokens[0])
					$match = false;

				$i = 0;
				while (($t = strtok('/.')) !== false)
				{
					if ($t[0] === ':')
					{
						$pp = substr($t, 1);
						$ROUTES[$n]['pp'][] = $pp;
						
						if (isset($p_tokens[++$i]))
							$request->path_parameters[$pp] = $p_tokens[$i];
						else
							$match = false;
					}
					elseif (!isset($p_tokens[++$i]) || ($t !== $p_tokens[$i]))
						$match = false;
				}
				if (!$match || isset($p_tokens[++$i]))
				{
					$request->path_parameters = array();
					continue;
				}
			}	
			
			if (strpos($r['methods'], $_SERVER['REQUEST_METHOD']) === false)
			{
				$error = 405;
				continue;
			}
			
			if (isset($r['ssl']) && $r['ssl'] && ($_SERVER['SERVER_PORT'] != ($config->ssl_port ?: 443)))
			{
				if ($_SERVER['REQUEST_METHOD'] === 'GET')
				{
					$error = 301;
					$response->location = $config->ssl_url() . ($server_path 
						? substr($_SERVER['REQUEST_URI'], strlen($server_path))
						: $_SERVER['REQUEST_URI']);
					break;
				}
				$error = 403;
				continue;
			}
				
			$found = $r;
		}
		
		$ROUTES['__RC'] =& $rc;
		$ROUTES['__RC2'] =& $rc2;

		if ($found && ($found !== $error))
		{
			$request->route =& $found;
			$controller_name = "Controllers\\{$found['controller']}Controller";
			$controller = $controller_name::instance();
			$controller->process($request, $response);
		}
		else
			$response->status = $error ?: 404;
		
		$response->render();
	}
}

namespace
{
	/**
	 * Absolute path to the application directory. 
	 *
	 * @internal
	 */
	define('APPLICATION', dirname(__DIR__));
	
	/**
	 * Absolute path to the modules directory. 
	 *
	 * @internal
	 */
	define('MODULES', APPLICATION . DIRECTORY_SEPARATOR . 'modules' . DIRECTORY_SEPARATOR);
	
	/**
	 * Absolute path to the configuration directory. 
	 *
	 * @internal
	 */
	define('CONFIG', APPLICATION . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR);
	
	/**
	 * Absolute path to the user application code.
	 *
	 * @internal
	 */
	define('APP', APPLICATION . DIRECTORY_SEPARATOR . 'app' . DIRECTORY_SEPARATOR);
	
	/**
	 * Absolute path to helpers directory.
	 *
	 * @internal
	 */
	define('HELPERS', APPLICATION . DIRECTORY_SEPARATOR . 'app' . DIRECTORY_SEPARATOR . 'helpers' .DIRECTORY_SEPARATOR);
	
	/**
	 * Absolute path to views directory.
	 *
	 * @internal
	 */
	define('VIEWS', APPLICATION . DIRECTORY_SEPARATOR . 'app' . DIRECTORY_SEPARATOR .'views'. DIRECTORY_SEPARATOR);
	
	/**
	 * Absolute path to locales directory.
	 *
	 * @internal
	 */
	define('LOCALES', APPLICATION . DIRECTORY_SEPARATOR . 'locales' . DIRECTORY_SEPARATOR);
	
	/**
	 * Absolute path to the directory for temporary files.
	 *
	 * @internal
	 */
	define('TEMP', APPLICATION . DIRECTORY_SEPARATOR . 'temp' . DIRECTORY_SEPARATOR);
	
	/**
	 * Adds the internal class loader to the class loaders chain. The class loader searches classes in the 
	 * 'app' directory. 
	 *
	 * The provided class name should not start with a backslash <code>\</code> character. 
	 * Notice, PHP strips the leading backslashes automatically even if you provide it in the code:
	 * 
	 * <code>
	 * $bar = new \Foo\Bar;
	 * # it passes 'Foo\Bar' string to the class loader if class has not been
	 * # loaded yet
	 * </code>
	 *
	 * However, a user may provide a leading backslash accidentally while dealing with classes loaded from strings:
	 *
	 * <code>
	 * $class_name = '\Foo\Bar'; # WRONG!
	 * $bar = new $class_name;
	 *
	 * $class_name = 'Foo\Bar';	 # CORRECT
	 * $bar = new $class_name;	 # It is an equivalent of: $bar = new \Foo\Bar;
	 * </code>
	 *
	 * Remember, namespaces in strings are always regarded as absolute ones.
	 */
	spl_autoload_register(function($class)
	{
		$file = APP . str_replace('\\', DIRECTORY_SEPARATOR, $class) . '.php';
		
		if (is_file($file))
			require $file;
		elseif (strpos($class, 'Application\\') === 0)
			require MODULES . str_replace('\\', DIRECTORY_SEPARATOR, $class) . '.php';
	});
	
	set_error_handler(function($errno, $errstr, $errfile, $errline)
	{
		throw new ErrorException($errstr, 0, $errno, $errfile, $errline);
	});
	
	require CONFIG . 'application.php';
	
	/**
	 * Constructs URL based on the route name or an action (or a controller) passed as $options. 
	 * The routes are defined in the application configuration directory ('routes.php').
	 *
	 * The following options are available:
	 *
	 * <ul>
	 * <li><b>name</b>: explicit name of the route
	 * <li><b>action</b>: name of the action</li>
	 * <li><b>controller</b>: name of the controller</li>
	 * <li><b>ssl</b>: value must be a bool</li>
	 * <li><b>anchor</b>: anchor part of the URL</li>
	 * <li><b>params</b>: array of parameters or a model</li>
	 * <li><b>locale</b>: custom locale code</li>
	 * </ul>
	 *
	 * <h4>1. URL for a specified route</h4>
	 *
	 * <code>
	 * url_for(array('name' => 'help'));
	 * </code> 
	 *
	 * Returns a URL for the route named <code>help</code>.
	 *
	 * <h4>2. URL for the action and the controller</h4>
	 * 
	 * <code>
	 * url_for();
	 * </code>
	 *
	 * Returns a URL for the current action of the current controller. If the action or controller is not given 
	 * the current one is used instead. If there is no controller at all (e.g. inside error templates) the root
	 * controller is assumed.
	 *
	 * <code>
	 * url_for('/');
	 * </code>
	 *
	 * Returns a URL to the root route of the application (<code>/</code>). The root route is always the first 
	 * entry (0th index) in the <code>$ROUTES</code> array.
	 *
	 * <code>
	 * url_for('index'); 
	 * url_for(array('index'));
	 * url_for(array('action' => 'index'));
	 * </code>
	 *
	 * Returns the URL for the <code>index</code> action of the current controller.
	 *
	 * <code>
	 * url_for('Shop\index');
	 * url_for(array('Shop\index'));
	 * url_for(array('action' => 'index', 'controller' => 'Shop'));
	 * </code>
	 * 
	 * Returns the URL for the <code>index</code> action of the <code>Shop</code> controller. 
	 * The controllers should be specified with the enclosing namespace (if any), 
	 * e.g. <code>Admin\Configuration</code> - for the controller with the full name:
	 * <code>\Controllers\Admin\ConfigurationController</code>.
	 *
	 * <h4>3. Static assets</h4>
	 *
	 * If the string (2 characters length min.) starting with a slash <code>/</code> is passed as 
	 * <code>$options</code> or the first (0th index) element of the options array then it is treated 
	 * as a URI path to a static asset. This feature is used by special assets tags in the <code>Tags</code>
	 * module, therefore rarely there is a need to explicit use it.
	 *
	 * <code>
	 * url_for('/img/foo.png');
	 * url_for($this->request->uri());
	 * </code>
	 *
	 * <h4>4. SSL</h4>
	 *
	 * <code> 
	 * url_for(array('index', 'ssl' => true));
	 * url_for(array('name' => 'help', 'ssl' => false));
	 * </code>
	 *
	 * Returns the URL with the secure protocol or not. If the <code>ssl</code> option is omitted the default 
	 * SSL setting is used (from the corresponding entry in the 'routes.php' configuration file). 
	 * The HTTP and HTTPS protocols use the ports defined in the {@link Configuration} instance. By default
	 * they are set to 80 (HTTP) and and 443 (HTTPS).
	 *
	 * <h4>5. Anchor</h4>
	 * 
	 * <code>
	 * url_for(array('index', 'anchor' => 'foo'));
	 * </code>
	 *
	 * Generates the URL with the anchor <code>foo</code>, for example: 'http://www.mydomain.com/index#foo'.
	 *
	 * <h4>6. Parameters</h4>
	 *
	 * Parameters are passed an an option named <code>params</code>. There are two kind of parameters 
	 * in the URL: path parameters and query parameters. Path parameters are used to compose the URI path, 
	 * and query parameters are used to create the query appended to the URL. Usually, parameters are passed 
	 * as an array where the keys are parameter names. However, path parameters can be passed without keys at all. 
	 * In such case, they are taken first depending on their order. Path parameters always have higher priority 
	 * than query parameters, and keyless path parameters have higher priority than others.
	 *
	 * If there is only one keyless parameter, the array may be omitted.
	 *
	 * Consider the simplest example:
	 *
	 * <code>
	 * url_for(array('show', 'params' => array(
	 *	   'id' => 12, 
	 *	   'size' => 25, 
	 *	   'color' => 'blue'
	 * )));
	 * </code>
	 * 
	 * The result could be (assuming the according route is e.g. <code>'/items/:id'</code>):
	 * <code>'http://www.mydomain.com/items/12?size=25&color=blue'</code>.
	 * 
	 * But you can also write it in a short manner, using the 0th array element:
	 * 
	 * <code>
	 * url_for(array('show', 'params' => array(12,'size'=>25,'color'=>'blue')));
	 * </code>
	 *
	 * Also, if there had not been other parameters than the path one, you would have written it even shorter:
	 * 
	 * <code>
	 * url_for(array('show', 'params' => 12));
	 * </code>
	 *
	 * <h4>7. Locale</h4>
	 * 
	 * If the localization is set to <code>true</code> this option affects the locale code used to construct the URL. 
	 * It could be useful e.g. to provide language choice options. Notice, if the localization is set 
	 * to <code>true</code> the root action omits the autoloading of the locale and thus the locale remains undefined
	 * (unloaded). In such case, in the root action, you have to specify the locale manually or you will get an error.
	 *
	 * @see Controller
	 * @see Configuration
	 * @param mixed $options Array of options
	 * @return string URL generated from given $options
	 * @author Szymon Wrozynski
	 */
	function url_for($options=array())
	{
		if ((array) $options !== $options)
			$options = array($options);
		
		global $ROUTES, $LOCALE;
		
		static $duo, $controller, $action, $http_url, $ssl_url, $ssl_port, $localization;
		
		if (!isset($duo))
		{	
			$c = Application\Controller::instance();
			
			if ($c)
			{
				$duo = $c->default_url_options() ?: false;
				$controller = $c->controller;
				$action = $c->action;
			}
			else
			{
				$duo = false;
				$controller = $ROUTES[0]['controller'];
				$action = $ROUTES[0]['action'];
			}
			
			$config = Application\Configuration::instance();
			$http_url = $config->http_url();
			$ssl_url = $config->ssl_url();
			$ssl_port = $config->ssl_port;
			$localization = $config->localization;
		}
		
		if ($duo)
		{
			if (isset($duo['params'], $options['params']))
				$options['params'] = array_merge(
					((array) $duo['params'] === $duo['params'])
						? $duo['params'] : array($duo['params']),
					((array) $options['params'] === $options['params'])
						? $options['params'] : array($options['params'])
				);
			
			$options = array_merge($duo, $options);
		}
		
		if (isset($options[0][0]))
		{
			if ($options[0] === '/')
				$name = 0;
			elseif ($options[0][0] === '/')
			{
				if (isset($options['ssl']))
					return ($options['ssl'] ? $ssl_url : $http_url) . $options[0];
				else
					return (($_SERVER['SERVER_PORT'] == ($ssl_port ?: 443)) ? $ssl_url : $http_url) . $options[0];		
			}
			elseif (strpos($options[0], '\\') > 0)
				$name = $ROUTES['__RC2'][$options[0]];
			else
				$name = $ROUTES['__RC'][$controller][$options[0]];
		}
		elseif (isset($options['name']))
			$name = $options['name'];
		else
			$name = $ROUTES['__RC'][isset($options['controller']) ? $options['controller'] : $controller]
				[isset($options['action']) ? $options['action'] : $action];
		
		if ($localization === true)
		{
			$uri = '/' . (isset($options['locale']) ? $options['locale'] : $LOCALE[0]);
			
			if ($ROUTES[$name][0] !== '/')
				$uri .= $ROUTES[$name][0];
		}
		else
			$uri = $ROUTES[$name][0];
		
		if (isset($options['anchor']))
			$uri .= '#' . $options['anchor'];
		
		if (isset($options['params']))
		{
			$params = $options['params'];
			
			if (isset($ROUTES[$name]['pp']))
			{
				if ((array) $params !== $params)
				{
					$uri = str_replace(':' . $ROUTES[$name]['pp'][0], $params, $uri);
					$params = null;
				}	 
				else
				{
					foreach ($ROUTES[$name]['pp'] as $i => $pp)
					{
						if (isset($params[$i]))
						{
							$uri = str_replace(":$pp", $params[$i], $uri);
							unset($params[$i]);
						}
						elseif (isset($params[$pp]))
						{
							$uri = str_replace(":$pp", $params[$pp], $uri);
							unset($params[$pp]);
						}
					}
				}
			}
			
			if ($params)
				$uri .= '?' . http_build_query($params);
		}
		
		if (isset($options['ssl']))
			return ($options['ssl'] ? $ssl_url : $http_url) . $uri;
		elseif (isset($ROUTES[$name]['ssl']))
			return ($ROUTES[$name]['ssl'] ? $ssl_url : $http_url) . $uri;
		
		return $http_url . $uri;
	}
	
	/**
	 * Loads the modules listed in the argument list.
	 *
	 * <code>
	 * modules('tags', 'activerecord');
	 * </code>
	 *
	 * @param string ... Variable-length list of module names
	 * @author Szymon Wrozynski
	 */
	function modules(/*...*/)
	{
		foreach (func_get_args() as $m)
			require_once MODULES . $m . '.php';
	}
	
	/**
	 * Translates the given key according to the current locale loaded.
	 *
	 * If the translation was not found the given key is returned back. The key can be a string but it is strongly
	 * advised not to use the escape characters like <code>\</code> inside though it is technically possible. 
	 * Instead, use double quotes to enclose single quotes and vice versa. This will help the <b>Prag</b> tool to
	 * recognize such keys and maintain locale files correctly. Otherwise, you will have to handle such keys by hand.
	 * The same applies to compound keys evaluated dynamically.
	 *
	 * <code>
	 * t('Editor\'s Choice');	# Avoid!
	 * t($editor_msg);			# Avoid!
	 * t("Editor's Choice");	# OK
	 * </code>
	 *
	 * Pragwork requires the first entry (0th index) in the locale file array contains the locale code therefore, 
	 * by specifying <code>t(0)</code> or just <code>t()</code>, the current locale code is returned.
	 * Also, if there is no locale loaded yet this will return 0 (the passed or implied locale key). 
	 * Such test against 0 (int) might be helpful while translating and customizing error pages, where there is no
	 * certainty that the locale code was parsed correctly (e.g. a 404 error).
	 *
	 * @param mixed $key Key to translation (string) or 0 (default)
	 * @return string Localized text or the locale code (if 0 passed)
	 * @author Szymon Wrozynski
	 */
	function t($key=0)
	{
		global $LOCALE;
		return isset($LOCALE[$key]) ? $LOCALE[$key] : $key;
	}
	
	/**
	 * Returns the array of strings with available locale codes based on filenames found in the 'locales' directory.
	 * Filenames starting with a dot '.' are omitted.
	 *
	 * @return array Available locale codes as strings in alphabetical order
	 * @author Szymon Wrozynski
	 */
	function locales()
	{
		static $locales;
		
		if (isset($locales))
			return $locales;
		
		$locales = array();
		$handler = opendir(LOCALES);
		
		while (false !== ($file = readdir($handler)))
		{
			if ($file[0] !== '.')
				$locales[] = substr($file, 0, -4);
		}
		
		closedir($handler);
		
		sort($locales);
		return $locales;
	}
}
?>
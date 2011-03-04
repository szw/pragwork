<?php
namespace Application;

/**
 * The abstract base class for your controllers.
 *
 * @author Szymon Wrozynski
 * @package Application
 */ 
abstract class Controller extends Singleton
{
	/**
	 * Sets the name of the default layout for templates of this {@link Controller}. All layouts are placed under 
	 * the 'layouts' subdirectory. A layout may be placed in its own subdirectory as well.
	 * The subdirectories are separated with a backslash <code>\</code>. If there is a backslash in the specified 
	 * value then the given value is treated as a path starting from the 'views' directory.
	 * The backslash should not be a first character.
	 * 
	 * Examples:
	 *
	 * <code>
	 * class MyController extends \Application\Controller
	 * {
	 *	   static $layout = 'main'; # views/layouts/main.php
	 *	   static $layout = '\Admin\main'; # bad!
	 *	   static $layout = 'Admin\main'; # views/layouts/Admin/main.php
	 * }
	 * </code>
	 *
	 * The layout(s) may be specified with modifiers:
	 *
	 * <ul>
	 * <li><b>only</b>: the layout will be used only for the specified 
	 *	   action(s)</li>
	 * <li><b>except</b>: the layout will be used for everything but the 
	 *	   specified action(s)</li>
	 * </ul>
	 *
	 * Example: 
	 *
	 * <code>
	 * class MyController extends \Application\Controller
	 * {
	 *	   static $layout = array(
	 *		   array('custom', 'only' => array('index', 'show')),
	 *		   'main'
	 *	   );
	 *	   # ...
	 * } 
	 * </code>
	 *
	 * In the example above, the <code>custom</code> layout is used only for <code>index</code> and <code>show</code>
	 * actions. For all other actions the <code>main</code> layout is used.
	 *
	 * All layout entries are evaluated in the order defined in the array until the first matching layout.
	 *
	 * @var mixed
	 */
	static $layout = null;
	
	/**
	 * Sets public filter methods to run before firing the requested action.
	 *
	 * According to the general Pragwork rule, single definitions may be kept as strings whereas the compound ones
	 * should be expressed within arrays.
	 *
	 * Filters can be extended or modified by class inheritance. The filters defined in a subclass can alter 
	 * the modifiers of the superclass. Filters are fired from the superclass to the subclass.
	 * If a filter method returns a boolean false then the filter chain execution is stopped.
	 * 
	 * <code>
	 * class MyController extends \Application\Controller
	 * {
	 *	   $before_filter = 'init';
	 *
	 *	   # ...
	 * }
	 * </code>
	 *
	 * There are two optional modifiers: 
	 *
	 * <ul>
	 * <li><b>only</b>: action or an array of actions that trigger off the filter</li>
	 * <li><b>except</b>: action or an array of actions excluded from the filter triggering</li>
	 * </ul>
	 *
	 * <code>
	 * class MyController extends \Application\Controller
	 * {
	 *	   static $before_filter = array(
	 *		   'alter_breadcrumbs', 
	 *		   'except' => 'write_to_all'
	 *	   );
	 *
	 *	   # ...
	 * }
	 * </code>
	 *
	 * <code>
	 * class ShopController extends \Application\Controller
	 * {
	 *	   static $before_filter = array(
	 *		   array('redirect_if_no_payments', 'except' => 'index'),
	 *		   array('convert_floating_point', 
	 *			   'only' => array('create', 'update'))
	 *	   );
	 *
	 *	   # ...
	 * }
	 * </code>
	 *
	 * @see $before_render_filter
	 * @see $after_filter
	 * @see $exception_filter
	 * @var mixed
	 */
	static $before_filter = null;
	
	/**
	 * Sets public filter methods to run just before the first rendering a view (excluding partials).
	 *
	 * According to the general Pragwork rule, single definitions may be kept as strings whereas the compound ones
	 * should be expressed within arrays.
	 * 
	 * There are two optional modifiers: 
	 *
	 * <ul>
	 * <li><b>only</b>: action or an array of actions that trigger off the filter</li>
	 * <li><b>except</b>: action or an array of actions excluded from the filter triggering</li>
	 * </ul>
	 *
	 * See {@link $before_filter} for syntax details.
	 *
	 * @see $before_filter
	 * @see $after_filter
	 * @see $exception_filter
	 * @var mixed
	 */
	static $before_render_filter = null;
	
	/**
	 * Sets public filter methods to run after rendering a view.
	 *
	 * According to the general Pragwork rule, single definitions may be kept as strings whereas the compound ones
	 * should be expressed within arrays. 
	 *
	 * There are two optional modifiers: 
	 *
	 * <ul>
	 * <li><b>only</b>: action or an array of actions that trigger off the filter</li>
	 * <li><b>except</b>: action or an array of actions excluded from the filter triggering</li>
	 * </ul>
	 *
	 * See {@link $before_filter} for syntax details.
	 *
	 * @see $before_filter
	 * @see $before_render_filter
	 * @see $exception_filter
	 * @var mixed
	 */
	static $after_filter = null;
	
	/**
	 * Sets filter methods to run after rendering a view. 
	 * 
	 * Filter methods must be public or protected. The exception is passed  as a parameter.
	 * 
	 * Unlike in other filter definitions, there are also three (not two) optional modifiers: 
	 *
	 * <ul>
	 * <li><b>only</b>: action or an array of actions that trigger off the filter</li>
	 * <li><b>except</b>: action or an array of actions excluded from the filter triggering</li>
	 * <li><b>exception</b>: the name of the exception class that triggers off the filter</li>
	 * </ul>
	 *
	 * <code>
	 * class PeopleController extends \Application\Controller
	 * {
	 *	   static $exception_filter = array(
	 *		   array(
	 *			   'record_not_found', 
	 *			   'exception' => 'ActiveRecord\RecordNotFound'
	 *		   ),
	 *		   array(
	 *			   'undefined_property',
	 *			   'only' => array('create', 'update'),
	 *			   'exception' => 'ActiveRecord\UndefinedPropertyException'
	 *		   )
	 *	   );
	 *
	 *	   # ...
	 * }
	 * </code>
	 * 
	 * <code>
	 * class AddressesController extends \Application\Controller
	 * {
	 *	   static $exception_filter = array(
	 *		   'undefined_property', 
	 *		   'only' => array('create', 'update'),
	 *		   'exception' => 'ActiveRecord\UndefinedPropertyException'
	 *	   );
	 *
	 *	   # ...
	 * }
	 * </code>
	 *
	 * If the <code>exception</code> modifier is missed, any exception triggers off the filter method. If the modifier
	 * is specified, only a class specified as a string triggers off the filter method. 
	 *
	 * Only a string is allowed to be a value of the <code>exception</code> modifier. This is because of the nature of
	 * exception handling. Exceptions are most often constructed with the inheritance in mind and they are grouped by
	 * common ancestors. 
	 *
	 * The filter usage resembles the <code>try-catch</code> blocks where the single exception types are allowed 
	 * in the <code>catch</code> clause. In fact, the {@link $exception_filter} may be considered as a syntactic sugar
	 * to <code>try-catch</code> blocks, where the same <code>catch</code> clause may be adopted to different actions.
	 * 
	 * See {@link $before_filter} for more syntax details.
	 *
	 * @see $before_filter
	 * @see $before_render_filter
	 * @see $after_filter
	 * @var mixed
	 */
	static $exception_filter = null;
	
	/**
	 * Caches the actions using the page-caching approach. The cache is stored within the public directory, 
	 * in a path matching the requested URL. All cached files have the '.html' extension if needed. 
	 * They can be loaded with the help of the <b>mod_rewrite</b> module (Apache) or similar (see the Pragwork default
	 * .htaccess file). Notice, caching usually requires the 'DirectorySlash Off' directive (<b>mod_dir</b>) 
	 * or equivalent to prevent appending a trailing slash to the path (and automatic redirection) if the web server
	 * finds a directory named similarly to the cached file.
	 *
	 * The parameters in the query string are not cached.
	 *
	 * Available options:
	 *
	 * <ul>
	 * <li><b>if</b>: name(s) of (a) callback method(s)</li>
	 * </ul>
	 *
	 * The writing of cache may be prevented by setting a callback method or an array of callback methods in the
	 * <code>if</code> option. The callback methods are run just before cache writing at the end of the 
	 * {@link $after_filter} chain. If one of them returns a value evaluated to false the writing is not performed. 
	 * You may also prevent caching by redirecting, throwing the {@link StopException}, or interrupting the
	 * {@link $after_filter} chain.
	 *
	 * <code>
	 * class MyController extends \Application\Controller
	 * {
	 *	   static $caches_page = array( 
	 *		   array(
	 *			   'page',
	 *			   'post',
	 *			   'if' => array('no_forms', 'not_logged_and_no_flash')
	 *		   ),
	 *		   'index', 
	 *		   'if' => 'not_logged_and_no_flash'
	 *	   );
	 *
	 *	   public function no_forms()
	 *	   {
	 *		   return (isset($this->page) && !$this->page->form)
	 *			   || (isset($this->post) && !$this->post->allow_comments);
	 *	   }
	 *
	 *	   public function not_logged_and_no_flash()
	 *	   {
	 *		   return !$this->session->admin && !$this->flash->notice;
	 *	   }
	 *
	 *	   # ...
	 * } 
	 * </code>
	 *
	 * Notice that caching is working properly only if the cache is enable in the configuration 
	 * (see {@link Configuration}).
	 *
	 * @see expire_page()
	 * @see $caches_action
	 * @see Configuration
	 * @var mixed String or array containing action name(s)
	 */
	static $caches_page = null;
	
	/**
	 * Caches the actions views and stores cache files in the 'temp' directory. Action caching differs from page 
	 * caching because action caching always runs {@link $before_filter}(s). 
	 *
	 * Available options:
	 *
	 * <ul>
	 * <li><b>if</b>: name(s) of (a) callback method(s)</li>
	 * <li><b>cache_path</b>: custom cache path</li>
	 * <li><b>expires_in</b>: expiration time for the cached action in seconds</li>
	 * <li><b>layout</b>: set to false to cache the action only (without the default layout)</li>
	 * </ul>
	 *
	 * The writing of cache may be prevented by setting a callback method or an array of callback methods in the
	 * <code>if</code> option. The callback methods are run just before cache writing at the end of the 
	 * {@link $after_filter} chain. If one of them returns a value evaluated to false the writing is not performed. 
	 * You may also prevent caching by redirecting, throwing the {@link StopException}, or interrupting the
	 * {@link $after_filter} chain.
	 *
	 * The <code>cache_path</code> option may be a string started from <code>/</code> or just a name of a method
	 * returning the path. If a method is used, then its returned value should be a string beginning with the
	 * <code>/</code> or a full URL (starting with 'http') as returned by the {@link url_for()} function.
	 *
	 * <code>
	 * class MyController extends \Application\Controller
	 * {
	 *	   static $caches_action = array(
	 *		   'edit', 
	 *		   'cache_path' => 'edit_cache_path'
	 *	   );
	 *	   
	 *	   public function edit_cache_path()
	 *	   {
	 *		   return url_for(array(
	 *			   'edit', 
	 *			   'params' => $this->params->only('lang')
	 *		   ));
	 *	   }
	 *
	 *	   # ...
	 * }
	 * </code>
	 *
	 * Notice that caching is working properly only if the cache is enable in the configuration 
	 * (see {@link Configuration}).
	 *
	 * @see expire_action()
	 * @see $caches_page
	 * @var mixed String or array with action name(s)
	 */
	static $caches_action = null;
	
	/**
	 * The {@link Parameters} object that contains request parameters. 
	 *
	 * @see Parameters
	 * @var Parameters
	 */
	public $params;
	
	/**
	 * The {@link Session} object that simplifies the session usage or null if sessions are disabled.
	 *
	 * @see Session
	 * @see Configuration
	 * @var Session
	 */
	public $session;
	
	/**
	 * The {@link Cookies} object that simplifies handling cookies.
	 *
	 * @see Cookies
	 * @var Cookies
	 */
	public $cookies;
	
	/**
	 * The {@link Flash} object for easy handling flash messages or null if sessions are disabled.
	 *
	 * @see Flash
	 * @see Session
	 * @var Flash
	 */
	public $flash;
	
	/**
	 * The {@link Request} object storing data and informative methods about the current request.
	 *
	 * @see Request
	 * @var Request
	 */
	public $request;
	
	/**
	 * The {@link Response} object storing data about the request response being generated.
	 *
	 * @see Response
	 * @var Response
	 */
	public $response;
	
	/**
	 * The name of the current action.
	 *
	 * @var string
	 */
	public $action;
	
	/**
	 * The simplified name of the current controller (e.g. 'Admin\People', 'Index', etc.). 
	 *
	 * @var string
	 */
	public $controller;
	
	protected static $instance;
	
	private static $_content;
	private static $_ch_file;
	private static $_ch_dir;
	private static $_ch_layout;
	private static $_ch_if;
	private static $_rendered;
	private static $_http_url;
	private static $_ssl_url;
	private static $_cache;
	
	protected function __construct()
	{
		$config = Configuration::instance();
		
		self::$_http_url = $config->http_url();
		self::$_ssl_url = $config->ssl_url();
		self::$_cache = $config->cache;
		
		$this->params = Parameters::instance();
		$this->session = Session::instance();
		$this->flash = Flash::instance();
		$this->cookies = Cookies::instance();
		
		$class = get_class($this);
		do 
		{
			require HELPERS . str_replace('\\', DIRECTORY_SEPARATOR, substr($class, 12, -10)) . 'Helper.php';
		}
		while (($class = get_parent_class($class)) !== __CLASS__);
	}
	
	/**
	 * The method name reserved for testing environment
	 */
	private final function clean_up() {}
	
	/**
	 * Starts request processing. It starts the the proper action depending on the {@link Request} object. 
	 * It is called automatically by the {@link Application\start()} function.
	 *
	 * @param Request $request The Request object instance
	 * @internal
	 */
	public function process($request, $response)
	{
		$this->request = $request;
		$this->response = $response;
		$this->action = $action = $request->route['action'];
		$this->controller = $request->route['controller'];
		
		try
		{
			$this->invoke_filters('before_filter');
			
			if (self::$_cache)
			{
				if (static::$caches_action)
					$this->set_action_cache($request->uri());
				
				if (static::$caches_page)
					$this->set_page_cache($request->uri());
			}	
			
			ob_start();
			
			$this->$action();

			if (!self::$_rendered)
				$this->render();
			
			$this->response->body = ob_get_clean();
			
			$this->invoke_filters('after_filter');
		}
		catch (StopException $e)
		{
			$this->response->body = ob_get_clean();
		}
		catch (\Exception $e) 
		{
			if ($this->invoke_filters('exception_filter', $e) !== false)
			{
				$this->response->body = ob_get_clean();
				$this->response->status = 500;
				$this->response->exception = $e;
			}
		}
	}
	
	/**
	 * Returns the default URL options used by all functions based on the {@link url_for()} function. 
	 * This method should return an array of default options or nothing (a null value). 
	 * Each default option may be overridden by each call to the {@link url_for()} function.
	 *
	 * @see url_for()
	 * @return array Default URL options or null
	 */
	public function default_url_options() {}
	
	/**
	 * Deletes the cached page, cached via the {@link $caches_page}. 
	 * 
	 * The cache path is computed from options passed internally to the {@link url_for()} function. 
	 * Therefore see the {@link url_for()} function for options syntax.
	 *
	 * @see $caches_page
	 * @param mixed $options Options array or action name (string)
	 */
	public function expire_page($options=array())
	{
		$key = url_for($options);
		$qpos = strpos($key, '?');
		$start = strlen(($key[4] === 's') ? self::$_ssl_url : self::$_http_url);
		$key = ($qpos === false) 
			? trim(substr($key, $start), '/.')
			: trim(substr($key, $start, $qpos - $start), '/.');
		
		if (isset($key[0]))
		{
			$cached_page = str_replace('/', DIRECTORY_SEPARATOR, $key);
			
			if (substr($key, -5) !== '.html')
				$cached_page .= '.html';
		}
		else
			$cached_page = 'index.html';
		
		if (is_file($cached_page))
		{
			unlink($cached_page);
		
			while (($dir = dirname($cached_page)) !== '.')
			{
				$empty = true;
				$handler = opendir($dir);
				
				while (false !== ($file = readdir($handler)))
				{
					if (($file !== '.') && ($file !== '..'))
					{
						$empty = false;
						break;
					}
				}
				
				closedir($handler);
			
				if (!$empty)
					break;
					
				rmdir($dir);
				$cached_page = $dir;
			}
		}
	}
	
	/**
	 * Deletes the cached action view, cached via the  {@link $caches_action}. 
	 * 
	 * The cache path is computed from options passed internally to the {@link url_for()} function. 
	 * Therefore see the {@link url_for()} function for options syntax. 
	 *
	 * @see $caches_action
	 * @param mixed $options Options array or action name (string)
	 */
	public function expire_action($options=array())
	{
		$key = url_for($options);
		$key = substr($key, strlen(($key[4]==='s') ? self::$_ssl_url : self::$http_url));
		
		# if longer than 1 char (e.g. longer than '/')
		if (isset($key[1])) 
			$key = rtrim($key, '/.');
			
		$cached_dir = TEMP . 'ca_' . md5($key);
		
		if (is_dir($cached_dir))
		{
			$handler = opendir($cached_dir);

			while (false !== ($file = readdir($handler)))
			{
				if ($file[0] !== '.')
					unlink($cached_dir . DIRECTORY_SEPARATOR . $file);
			}

			closedir($handler);
			rmdir($cached_dir);
		}
		
		$cached_action = $cached_dir . '.cache';
		
		if (is_file($cached_action))
			unlink($cached_action);
	}
	
	/**
	 * Returns true if the cached fragment is available. 
	 * 
	 * The cache path is computed from options passed internally to the {@link url_for()} function. 
	 * Therefore see the {@link url_for()} function for options syntax. 
	 * Moreover, the additional following options are available:
	 *
	 * <ul>
	 * <li><b>action_suffix</b>: the path suffix allowing many fragments in the same action</li>
	 * </ul>
	 *
	 * @see cache()
	 * @see expire_fragment()
	 * @param mixed $options Options array or action name (string)
	 * @return bool True if the fragment exists, false otherwise
	 */
	public function fragment_exists($options=array())
	{
		return is_file(self::fragment_file($options));
	}
	
	/**
	 * Deletes a cached fragment. 
	 * 
	 * The cache path is computed from options passed internally to the {@link url_for()} function. 
	 * Therefore see the {@link url_for()} function for options syntax. 
	 * Moreover, the additional following options are available:
	 *
	 * <ul>
	 * <li><b>action_suffix</b>: the path suffix allowing many fragments in the same action</li>
	 * </ul>
	 *
	 * @see cache()
	 * @see fragment_exists()
	 * @param mixed $options Options array or action name (string)
	 */
	public function expire_fragment($options=array())
	{
		$fragment = self::fragment_file($options);
		if (is_file($fragment))
			unlink($fragment);
	}
	
	/**
	 * Caches the fragment enclosed in the closure. 
	 *
	 * The cache path is computed from options passed internally to the {@link url_for()} function. 
	 * Therefore see the {@link url_for()} function for options syntax. 
	 * Moreover, the additional following options are available:
	 *
	 * <ul>
	 * <li><b>action_suffix</b>: the suffix allowing many fragments in the same action</li>
	 * <li><b>expires_in</b>: time-to-live for the cached fragment (in sec)</li>
	 * </ul>
	 *
	 * Notice, this method will write and read cached fragments only if the cache is enable in the configuration 
	 * (see {@link Configuration}).
	 *
	 * @see expire_fragment()
	 * @see fragment_exists()
	 * @param mixed $options Options array or action name (string)
	 * @param \Closure $closure Content to be cached and displayed
	 */
	public function cache($options, $closure)
	{
		if (!self::$_cache)
			return $closure($this);
		
		$frag = self::fragment_file($options);
		
		if (is_file($frag))
		{
			if (isset($options['expires_in']))
			{
				if ((filemtime($frag) + $options['expires_in']) > $_SERVER['REQUEST_TIME'])
					return readfile($frag);
			}
			else
				return readfile($frag);
		}
		
		ob_start();
		$closure($this);
		$output = ob_get_clean();
		file_put_contents($frag, $output);
		echo $output;
	}
	
	private static final function fragment_file($options)
	{
		$key = url_for($options);
		$key = substr($key,strlen(($key[4]==='s') ? self::$_ssl_url : self::$_http_url));   
		
		if (isset($options['action_suffix']))
			$key .= $options['action_suffix'];
		
		return TEMP . 'cf_' . md5($key) . '.cache';
	}
	
	private final function render_cache_in_layout()
	{
		if (is_dir(self::$_ch_dir))
		{
			$handler = opendir(self::$_ch_dir);

			while (false !== ($file = readdir($handler)))
			{
				if ($file[0] !== '.')
					self::$_content[$file] = file_get_contents(self::$_ch_dir . DIRECTORY_SEPARATOR . $file);
			}

			closedir($handler);
		}
		
		$this->render(array('text' => file_get_contents(self::$_ch_file), 'layout' => true));
		throw new StopException;
	}
	
	private final function set_action_cache($key)
	{
		if (self::$_ch_file)
			return;
		
		foreach (self::normalize_defs(static::$caches_action) as $ch)
		{
			if ($ch[0] !== $this->action)
				continue;
			
			if (isset($ch['cache_path']))
			{
				if ($ch['cache_path'][0] === '/')
					self::$_ch_dir = TEMP . 'ca_' . md5($ch['cache_path']);
				else
				{
					$chp = $this->$ch['cache_path']();
						
					if ($chp[0] === '/')
						self::$_ch_dir = TEMP . 'ca_' . md5($chp);
					elseif ($chp[4] === 's')
						self::$_ch_dir = TEMP . 'ca_' . md5(substr($chp, strlen(self::$_ssl_url)));
					else
						self::$_ch_dir = TEMP . 'ca_' . md5(substr($chp, strlen(self::$_http_url)));
				}
			}
			else
				self::$_ch_dir = TEMP . 'ca_' . md5(isset($key[1]) ? rtrim($key, '/.') : $key);

			self::$_ch_file = self::$_ch_dir . '.cache';
			
			if (isset($ch['layout']) && !$ch['layout'])
			{ 
				if (is_file(self::$_ch_file))
				{
					if (isset($ch['expires_in']))
					{ 
						if ((filemtime(self::$_ch_file)+$ch['expires_in'])>$_SERVER['REQUEST_TIME'])
							$this->render_cache_in_layout();
					}
					else
						$this->render_cache_in_layout();
				}
				self::$_ch_layout = self::resolve_layout($this->action);
				static::$layout = null;
			}
			elseif (is_file(self::$_ch_file))
			{
				if (isset($ch['expires_in']))
				{ 
					if ((filemtime(self::$_ch_file) + $ch['expires_in']) > $_SERVER['REQUEST_TIME'])
					{
						readfile(self::$_ch_file);
						throw new StopException;
					}
				}
				else
				{
					readfile(self::$_ch_file);
					throw new StopException;
				}
			}
			
			if (isset($ch['if']))
				self::$_ch_if = $ch['if'];
			   
			self::add_to_filter('after_filter', 'write_and_show_cache');
			break;
		}
	}
	
	private final function set_page_cache($key)
	{
		if (self::$_ch_file)
			return;
		
		foreach (self::normalize_defs(static::$caches_page) as $ch)
		{	
			if ($ch[0] !== $this->action)
				continue;
						
			$key = trim($key, '/.');
				
			if (isset($key[0]))
			{
				self::$_ch_file = str_replace('/', DIRECTORY_SEPARATOR, $key);
									
				if (!strpos($key, '.'))
					self::$_ch_file .= '.html';
			}
			else
				self::$_ch_file = 'index.html';
			
			if (isset($ch['if']))
				self::$_ch_if = $ch['if'];
			
			self::add_to_filter('after_filter', 'write_and_show_cache');
			break;
		}
	}
	
	private final function write_and_show_cache()
	{			 
		if (self::$_ch_if)
		{
			if ((array) self::$_ch_if === self::$_ch_if)
			{
				foreach (self::$_ch_if as $ifm)
				{
					if (!$this->$ifm())
						return;
				}
			}
			else
			{
				$ifm = self::$_ch_if;
				
				if (!$this->$ifm())
					return;
			}
		}
		
		if (!self::$_ch_dir) # if caches page
		{
			$dir = dirname(self::$_ch_file);
				
			if (!is_dir($dir))
				mkdir($dir, 0775, true);
		}
		
		file_put_contents(self::$_ch_file, $this->response->body);
		
		if (self::$_ch_layout)
		{
			if (self::$_content)
			{
				if (is_dir(self::$_ch_dir))
				{
					$handler = opendir(self::$_ch_dir);

					while (false !== ($f = readdir($handler)))
					{
						if ($f[0] !== '.')
							unlink(self::$_ch_dir .DIRECTORY_SEPARATOR .$f);
					}

					closedir($handler);
				}
				else
					mkdir(self::$_ch_dir, 0775);
				
				foreach (self::$_content as $r => $c)
					file_put_contents(self::$_ch_dir.DIRECTORY_SEPARATOR.$r,$c);	   
			}
			
			ob_start();
			$this->render(array('text' => $this->response->body, 'layout' => self::$_ch_layout));
			$this->response->body = ob_get_clean();
		}
	}
	
	/**
	 * Sends a location in the HTTP header causing a HTTP client to redirect. 
	 * 
	 * The location URL is obtained from {@link url_for()} function. See {@link url_for()} function for options syntax.
	 *
	 * Additionally, following options are available:
	 * 
	 * <ul>
	 * <li><b>status</b>: HTTP status code (default: 302). It might be an int or a symbolic name (e.g. 'found')</li>
	 * <li><b>[name]</b>: additional flash message</li>
	 * </ul>
	 *
	 * Example:
	 *
	 * <code>
	 * $this->redirect_to(array('index', 'notice' => 'Post updated.'));
	 * # Redirects to the action 'index' and sets the appropriate flash
	 * # message.
	 * </code>
	 *
	 * @see url_for()
	 * @see redirect_to_url()
	 * @param mixed $options Options array or action name (string)
	 * @throws {@link StopException} In order to stop further execution
	 */
	public function redirect_to($options=array())
	{
		if ((array) $options !== $options)
			$this->redirect_to_url(url_for($options));
		elseif (!$this->session)
			$this->redirect_to_url(url_for($options), $options);
		
		$url = url_for($options);
		
		unset(
			$options['params'], 
			$options[0],
			$options['name'],
			$options['ssl'], 
			$options['anchor'],
			$options['locale'],
			$options['action'], 
			$options['controller']
		);
		
		$this->redirect_to_url($url, $options);
	}
	
	/**
	 * Sends a location in the HTTP header causing a HTTP client to redirect. 
	 * 
	 * The following options are available:
	 * 
	 * <ul>
	 * <li><b>status</b>: HTTP status code (default: 302) It might be an int or a symbolic name (e.g. 'found')</li>
	 * <li><b>[name]</b>: additional flash message</li>
	 * </ul>
	 *
	 * @see redirect_to()
	 * @param string $url URL of the location
	 * @param mixed $options Options array
	 * @throws {@link StopException} In order to stop further execution
	 */
	public function redirect_to_url($url, $options=array())
	{
		if (isset($options['status']))
		{
			$this->response->status = $options['status'];
			unset($options['status']);
		}
		else 
			$this->response->status = 302;
		
		if ($this->flash)
		{
			foreach ($options as $name => $msg)
				$this->flash->$name = $msg;
		}
		
		$this->response->location = $url;
		throw new StopException;
	}
	
	/**
	 * Renders a template depending on parameters passed via $options.
	 * 
	 * The rendering topic may be divided into two big areas of use: rendering of templates and rendering of partial
	 * templates.
	 * 
	 * <h4>A. General rendering of templates</h4>
	 *
	 * Templates are placed under the directory 'views' of the application code. They fill the directory structure
	 * according to the controllers structure.
	 *
	 * <h4>A.1. Rendering a template in the current controller</h4>
	 *
	 * <code>
	 * class ShopController extends \Application\Controller
	 * {
	 *	   public function index()
	 *	   {
	 *		   # $this->render();
	 *	   }
	 *
	 *	   public function show()
	 *	   {
	 *		   $this->render('index');
	 *		   $this->render(array('index'));
	 *		   $this->render(arary('action' => 'index'));
	 *	   }
	 * }
	 * </code>
	 *
	 * Each of the method calls in the action <code>show</code> above renders the template of the action
	 * <code>index</code> of the current controller. However you should render a template once. 
	 * Notice also, rendering the template does not stop the further action execution.
	 *
	 * The {@link render()} with no arguments renders the template of the current action. 
	 * But the action renders its own template implicitly if no other render is used (except partial templates).
	 * Therefore there is no need to explicit call {@link render()} in the <code>index</code> action above.
	 *
	 * <h4>A.2. Rendering a template of another controller</h4>
	 *
	 * <code>
	 * class CustomersController extends \Application\Controller
	 * {
	 *	   public function edit() {}
	 * }
	 *
	 * class ShopController extends \Application\Controller
	 * {
	 *	   public function show()
	 *	   {
	 *		   $this->render(array(
	 *			   'action' => 'edit', 
	 *			   'controller' => 'Customers'
	 *		   ));
	 *
	 *		   # or just: $this->render('Customers\edit')
	 *	   }
	 * }
	 * </code>
	 *
	 * Renders the template of the <code>edit</code> action of the Customers controller.
	 *
	 * <h4>A.3. Rendering a custom template</h4>
	 *
	 * <code>
	 * $this->render('my_custom_template');
	 * $this->render('my_templates\my_custom_template');
	 * $this->render(array('my_custom_template', 'layout' => false))
	 * $this->render(array('my_custom_template', 'layout' => 'my_layout'));
	 * </code>
	 *
	 * Renders a custom template. The custom template may be placed in a subdirectory. 
	 * The subdirectories are separated with a backslash <code>\</code>. If there is a backslash in the string,
	 * the path starts from the root (the 'views' directory).
	 *
	 * Each of the examples from the part <b>A</b> can be altered with an option <code>layout</code> which can point 
	 * to a certain {@link $layout}. Also, this option can be set to <code>false</code> disabling the global
	 * layout defined in the controller. The layout file should be put in the 'views/layouts' subdirectory.
	 *
	 * <code>
	 * class ShopController extends \Application\Controller
	 * {
	 *	   static $layout = 'shop';
	 *
	 *	   public function index()
	 *	   {
	 *		   # use the default layout ('views/layouts/shop.php')
	 *	   }
	 *
	 *	   public function show()
	 *	   {
	 *		   $this->render(array('layout' => false));
	 *
	 *		   # do not use any layout, same as self::$layout = null;
	 *	   }
	 *
	 *	   public function edit()
	 *	   {
	 *		   $this->render(array(
	 *			   'action' => 'show',
	 *			   'layout' => 'custom_layout'
	 *		   ));
	 *
	 *		   # or just:
	 *		   # $this->render(array('show', 'layout' => 'custom_layout'));
	 *
	 *		   # use the template 'views/Shop/show.php' with 
	 *		   # the layout 'views/layouts/custom_layout.php'.
	 *	   }
	 * }
	 * </code>
	 *
	 * <h4>A.4. Content Format and Status</h4>
	 *
	 * It is possible to specify a content format in the header sended with the first use of the {@link render()} 
	 * method (excluding partials). It can be done with help of the <code>content_type</code> option.
	 *
	 * <code>
	 * $this->render(array('show', 'content_type' => 'text/xml'));
	 * </code>
	 *
	 * Also, you can set a status for your content:
	 *
	 * <code>
	 * $this->render(array('status' => 200)); # 200 OK
	 * $this->render(array('status' => 'created')); # 201 Created
	 * </code>
	 *
	 * If a status denotes the client error (400 - 499) and there is no template to selected explicitly to render 
	 * then the error template (from 'errors' directory) is rendered. For server errors (greater or equal than 500),
	 * the special template (500.php) is rendered.
	 *
	 * <code>
	 * $this->render(array('status' => 'not_found')); # renders errors/404.php
	 * $this->render(array('status' => 405)); #renders errors/405.php
	 * </code>
	 *
	 * <h4>A.5. Format</h4>
	 *
	 * Format enables additional headers to be sent on the first call of {@link render()} (again partials does not
	 * count). Also, it provides additional, specific behavior, depending on the chosen format.
	 *
	 * Currently there is only one format available: <b>xml</b>.
	 *
	 * <code>
	 * $this->render(array('format' => 'xml'));
	 * </code>
	 *
	 * It renders the template (the default one in this particular example) with the header: "Content-Type: text/xml;
	 * charset=utf-8" (no content format was specified). Moreover, it disables the global layout. You can always use 
	 * a layout by specifying a layout template:
	 *
	 * <code>
	 * $this->render(array('format' => 'xml', 'layout' => 'my_xml_layout'));
	 * </code>
	 *
	 * Or, you can turn on the global layout by setting <code>layout</code> to <code>true</code> explicitly.
	 *
	 * <h4>A.6. Text, XML, JSON</h4>
	 * 
	 * You can also specify a text (or xml, json) instead of a template. 
	 * It is useful especially in the AJAX applications.
	 *
	 * <code>
	 * $this->render(array('text' => 'OK'));
	 * $this->render(array('xml' => $xml));
	 * $this->render(array('json' => array('a' => 1, 'b' => 2, 'c' => 3)));
	 * </code>
	 *
	 * If you do not set the custom content format, the 'application/xml' is  used for XML and 'application/json' 
	 * is used for JSON.
	 * 
	 * The <code>json</code> option allows to pass <code>json_options</code> bitmask, just like it is done 
	 * in the global <code>json_encode()</code> function.
	 * 
	 * <code>
	 * $this->render(array(
	 *	   'json' => array(array(1, 2, 3)), 
	 *	   'json_options' => JSON_FORCE_OBJECT
	 * ));
	 * </code>
	 *
	 *
	 * <h4>B. Rendering partial templates</h4>
	 *
	 * Partial templates are placed in the same directory structure as normal templates. They differ from the normal
	 * ones in extensions. Partial templates ends with the '.part.php' extension.
	 *
	 * Whereas normal rendering of templates is taking place in the controller, the rendering of partials is the domain
	 * of template files mainly. Usually partial templates represent repetitive portions of code used to construct more
	 * compound structures. The result of rendering the partial template is returned as a string - it is not
	 * displayed immediately and therefore it should be displayed explicitly with the <code>echo</code> function.
	 *
	 * If the '.part.php' file is not found the '.php' one is used instead and the template is rendered in the normal
	 * way described in the section A.
	 *
	 * <h4>B.1. Rendering the partial template</h4>
	 * 
	 * <code>
	 * <?php echo $this->render('item') ?>
	 * </code>
	 *
	 * The code above renders the partial template 'item.part.php' placed under the controller's directory in the views
	 * structure. If the partial template name contains a backslash <code>\</code> the absolute path will be used 
	 * (with the root set to 'views' directory).
	 *
	 * <code>
	 * <?php echo $this->render('shared\header') ?>
	 * # renders /views/shared/header.part.php
	 * </code>
	 *
	 * Everything (except <code>collection</code>) passed as named array elements are converted to local variables
	 * inside the partial template.
	 * 
	 * <code>
	 * <?php echo $this->render(array('item', 'text' => 'Hello')) ?>
	 * # renders the partial template ('item.part.php') and creates a local 
	 * # variable named $text there.
	 * </code>
	 *
	 * <h4>B.2. Rendering a partial template with a collection</h4>
	 *
	 * If you use the <code>collection</code> option you can render the partial template a few times, according to items
	 * passed in an array as the <code>collection</code>. The current item from the collection is named after 
	 * the template name, and the array key name has the <code>'_key'</code> suffix.
	 *
	 * The code below:
	 *
	 * <code>
	 * <?php $this->render(array(
	 *	   'person', 
	 *	   'collection' => array('John', 'Frank'),
	 *	   'message' => 'The message.'
	 * )) ?>
	 * </code>
	 *
	 * could be used in the 'person.part.php' like here:
	 *
	 * <code>
	 * <h1><?php echo Hello $person ?></h1>
	 * <p><?php echo $message ?></p>
	 * <p>And the current key is: <?php echo $person_key ?></p>
	 * </code>
	 * 
	 * In the above example the 'person.part.php' will be rendered twice, with different names (<code>$person</code>)
	 * and keys (<code>$person_key</code>). The whole collection will be still available under 
	 * the <code>$collection</code> variable.
	 *
	 * @see $layout
	 * @param mixed $options Options array or string
	 * @return mixed Rendered partial template or null
	 */
	public function render($options=array())
	{	
		if ((array) $options !== $options)
		{
			$template = VIEWS . ((strpos($options, '\\') === false)
				? str_replace('\\', DIRECTORY_SEPARATOR, $this->controller) . DIRECTORY_SEPARATOR . $options
				: str_replace('\\', DIRECTORY_SEPARATOR, $options));
			
			$partial = $template . '.part.php';
			
			if (is_file($partial))
			{
				ob_start();
				require $partial;
				return ob_get_clean();
			}
			
			if (!self::$_rendered)
			{
				$this->invoke_filters('before_render_filter');
				self::$_rendered = true;
			}
			
			$layout = self::resolve_layout($this->action);
			
			if ($layout)
			{
				ob_start();
				require $template . '.php';
				self::$_content[0] = ob_get_clean();
				require VIEWS . 'layouts' . DIRECTORY_SEPARATOR
					. str_replace('\\', DIRECTORY_SEPARATOR, $layout) . '.php';
			}
			else
				require $template . '.php';
			return;
		}
		elseif (isset($options[0]))
		{
			$template = VIEWS . ((strpos($options[0], '\\') === false)
				? str_replace('\\', DIRECTORY_SEPARATOR, $this->controller) . DIRECTORY_SEPARATOR . $options[0]
				: str_replace('\\', DIRECTORY_SEPARATOR, $options[0]));
			
			$partial = $template . '.part.php';
			
			if (is_file($partial))
			{
				unset($options[0]);
				ob_start();
			
				if (isset($options['collection']))
				{
					$name = basename($partial, '.part.php');		
					$key_name = $name . '_key';
				
					foreach ($options['collection'] as $key => $item)
						$this->render_partial($partial, array($name => $item, $key_name => $key) + $options);
				}
				else
					$this->render_partial($partial, $options);
			
				return ob_get_clean();
			}
		}
		elseif (isset($options['xml']))
		{
			if (!isset($options['content_type']))
				$options['content_type'] = 'application/xml';
			
			$options['text'] = $xml;
		}
		elseif (isset($options['json']))
		{
			if (!isset($options['content_type']))
				$options['content_type'] = 'application/json';
			
			$options['text'] = isset($options['json_options'])
				? json_encode($options['json'], $options['json_options'])
				: json_encode($options['json']);
		}
		elseif (!isset($options['text']))	 
			$template = VIEWS . str_replace('\\', DIRECTORY_SEPARATOR,
				isset($options['controller']) ? $options['controller'] : $this->controller) 
				. DIRECTORY_SEPARATOR . (isset($options['action']) ? $options['action'] : $this->action);
		
		if (isset($options['status']))
			$this->response->status = $options['status'];
		
		if (isset($options['text']))
		{
			if (isset($options['content_type']))
				$this->response->content_type = $options['content_type'];
				
			if (!self::$_rendered)
			{
				$this->invoke_filters('before_render_filter');
				self::$_rendered = true;
			}
						
			if (isset($options['layout']))
			{
				if ($options['layout'] === true)
					$options['layout'] = self::resolve_layout($this->action);
				
				self::$_content[0] = $options['text'];
				require VIEWS . 'layouts' . DIRECTORY_SEPARATOR . 
					str_replace('\\', DIRECTORY_SEPARATOR, $options['layout']) . '.php';
			}
			else
				echo $options['text'];
			
			return;
		}
		
		if (!isset($options[0]) && !isset($options['action']) && !isset($options['controller']) 
			&& $this->response->status_code() >= 400)
		{
			if (isset($options['content_type']))
				$this->response->content_type = $options['content_type'];
			
			throw new StopException;
		}
		
		if (isset($options['format']) && $options['format'] === 'xml')
		{
			if (!isset($options['content_type']))
				$options['content_type'] = 'text/xml';
			
			if (!isset($options['layout']))
				$options['layout'] = false;
		}
		elseif (!isset($options['layout']))
			$options['layout'] = self::resolve_layout($this->action);
		
		if (isset($options['content_type']))
			$this->response->content_type = $options['content_type'];
		
		if (!self::$_rendered)
		{
			$this->invoke_filters('before_render_filter');
			self::$_rendered = true;
		}
		
		if ($options['layout'])
		{
			ob_start();
			require $template . '.php';
			self::$_content[0] = ob_get_clean();
			require VIEWS . 'layouts' . DIRECTORY_SEPARATOR 
				. str_replace('\\', DIRECTORY_SEPARATOR, $options['layout']) . '.php';
		}
		else
			require $template . '.php';
	}
	
	/**
	 * Renders the template just like the {@link render()} method but returns
	 * the results as a string.
	 *
	 * @see render()
	 * $param mixed $options Options array or string
	 * @return string
	 */
	public function render_to_string($options=array())
	{
		ob_start();
		$str = $this->render($options);
		return ob_get_clean() ?: $str;
	}
	
	private function render_partial($___path___, $___args___)
	{	
		foreach ($___args___ as $___n___ => $___v___) 
			$$___n___ = $___v___;
		
		require $___path___;
	}

	/**
	 * Returns a rendered template or a template region constructed with the {@link content_for()} method and a name
	 * passed as a parameter. 
	 *
	 * This method should be used directly from a layout template. If the region does not exist the null is returned
	 * instead.
	 *
	 * <code>
	 * <?php echo $this->yield() ?>
	 * </code>
	 *
	 * <code>
	 * <?php echo $this->yield('title') ?>
	 * </code>
	 *
	 * @see content_for()
	 * @see render()
	 * @param string $region Optional region name
	 * @return mixed Rendered template, template region, or null
	 */
	public function yield($region=0)
	{
		if (isset(self::$_content[$region]))
			return self::$_content[$region];
	}
	
	/**
	 * Inserts a named content block into a layout view directly from a template. 
	 * 
	 * The region name can be used in the layout with the {@link yield()} method. The closure with the content may have
	 * an argument. If so, the current controller instance is passed there allowing to get to controller methods and
	 * variables. 
	 *
	 * <code>
	 * <?php $this->content_for('title', function() { ?>
	 *	   Just simple title
	 * <?php }) ?>
	 * </code>
	 *
	 * <code>
	 * <?php $this->content_for('title', function($that) { ?>
	 *
	 *	   # the current controller is named '$that' by convention
	 *	   # and because '$this' cannot be used in the closure context
	 *
	 *	   Records found: <?php echo count($that->records) ?>
	 * <?php }) ?>
	 * </code>
	 *
	 * @see yield()
	 * @param string $region Region name
	 * @param \Closure $closure Content for partial yielding
	 */
	public function content_for($region, $closure)
	{
		ob_start();
		$closure($this);
		self::$_content[$region] = ob_get_clean();
	}
	
	private final function resolve_layout($action)
	{
		if (!static::$layout)
			return;
		
		static $layout;
		
		if (!isset($layout))
		{
			$layout = null;
			
			foreach (self::normalize_defs(static::$layout) as $l)
			{
				if (isset($l['only']))
				{
					if ((((array) $l['only'] === $l['only']) && in_array($action, $l['only'], true))
						|| ($l['only'] === $action))
					{
						$layout = $l[0];
						break;
					}
					continue;
				}
				elseif (isset($l['except']) && ((((array) $l['except'] === $l['except']) 
					&& in_array($action, $l['except'], true)) || ($l['except'] === $action)))
					continue;
				
				$layout = $l[0];
				break;
			}
		}
		
		return $layout;
	}
	
	private static final function get_filter_mods(&$entry)
	{
		$modifiers = array();
		if (isset($entry['only']))
		{
			$modifiers['only'] = ((array) $entry['only'] === $entry['only']) 
				? $entry['only'] : array($entry['only']);
			unset($entry['only']);
		}
		if (isset($entry['except']))
		{
			$modifiers['except'] = ((array) $entry['except'] === $entry['except'])
				? $entry['except'] : array($entry['except']);
			unset($entry['except']);
		}
		if (isset($entry['exception']))
		{
			$modifiers['exception'] = $entry['exception'];
			unset($entry['exception']);
		}
		return $modifiers;
	}
	
	private static final function normalize_defs($definitions)
	{	
		if ((array) $definitions !== $definitions)
			return array(array($definitions));

		$normalized_definitions = array();
		$outer_options = array();

		foreach ($definitions as $key => $body)
		{	
			if ((string) $key === $key)
				$outer_options[$key] = $body;
			elseif ((array) $body === $body)
			{	 
				$inner_options = array();

				foreach ($body as $k => $v)
				{
					if ((string) $k === $k)
					{
						$inner_options[$k] = $v;
						unset($body[$k]);
					}
				}

				foreach ($body as $b)
					$normalized_definitions[] = array($b) + $inner_options;
			}
			else
				$normalized_definitions[] = array($body);						 
		}

		if ($outer_options)
		{
			foreach ($normalized_definitions as &$nd)
				$nd += $outer_options;
		}

		return $normalized_definitions;
	}
	
	private static final function add_to_filter($filter, $method)
	{
		if (!static::$$filter)
			static::$$filter = $method;
		elseif ((array) static::$$filter === static::$$filter)
		{
			if (array_key_exists('except', static::$$filter) || array_key_exists('only', static::$$filter))
				static::$$filter = self::normalize_defs(static::$$filter);
			
			array_push(static::$$filter, $method);
		}
		else
			static::$$filter = array(static::$$filter, $method);
	}
	
	private final function invoke_filters($filter, $value=null)
	{	
		$filter_chain = array();
		
		$class = get_class($this);
		do 
		{
			$class_filters = $class::$$filter;
			
			if (!$class_filters)
				continue;
				
			if ((array) $class_filters !== $class_filters)
			{
				if (!isset($filter_chain[$class_filters]))
					$filter_chain[$class_filters] = null;
			}
			else
			{
				$class_mods = self::get_filter_mods($class_filters);
			
				foreach (array_reverse($class_filters) as $entry)
				{
					if ((array) $entry !== $entry)
					{
						if (!isset($filter_chain[$entry]))
							$filter_chain[$entry] = $class_mods;
					}
					else
					{
						$mods = self::get_filter_mods($entry);
					
						foreach (array_reverse($entry) as $e)
						{
							if (!isset($filter_chain[$e]))
								$filter_chain[$e] = $mods ?: $class_mods;
						}
					}
				}
			}
		} while (($class = get_parent_class($class)) !== __CLASS__);
		
		foreach (array_reverse($filter_chain) as $flt => $mods)
		{
			if (isset($mods['only']) && !in_array($this->action, $mods['only']))
				continue;
			elseif (isset($mods['except']) && in_array($this->action, $mods['except']))
				continue;
			elseif (isset($mods['exception']) && !($value && is_a($value, $mods['exception'])))
				continue;

			if ($this->$flt($value) === false)
				return false;
		}
	}
}
?>
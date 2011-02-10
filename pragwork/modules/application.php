<?php
/**
 * The Application Module of Pragwork 1.0.2.1
 *
 * @copyright Copyright (c) 2009-2011 Szymon Wrozynski
 * @license Licensed under the MIT License
 * @version 1.0.2.1
 * @package Application
 */

namespace Application
{    
    /**
     * Starts request processing. This function should be used only once as 
     * the entry point while starting the Pragwork application.
     *
     * @author Szymon Wrozynski
     */
    function start() 
    {   
        $qpos = strpos($_SERVER['REQUEST_URI'], '?');
        
        if ($qpos === false)
            $path = $key = SERVER_PATH 
                ? substr($_SERVER['REQUEST_URI'], strlen(SERVER_PATH))
                : $_SERVER['REQUEST_URI'];
        elseif (!SERVER_PATH) 
            $path = $key = substr($_SERVER['REQUEST_URI'], 0, $qpos);
        else 
        {
            $splen = strlen(SERVER_PATH);
            $path = $key = substr($_SERVER['REQUEST_URI'],$splen,$qpos-$splen);
        }
        
        global $LOCALE, $ROUTES, $CONTROLLER, $ACTION, $RENDERED, $RC, $RC_2;
        
        $error = null;
        
        if (LOCALIZATION === true)
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
        elseif (LOCALIZATION)
            require LOCALES . LOCALIZATION . '.php';
        
        require CONFIG . 'routes.php';
        
        if ($ROUTES)
            $ROUTES[0][0] = '/';
        
        $found = $p_params = null;
        
        $p_tokens = array(strtok($path, '/.'));
            
        while (($t = strtok('/.')) !== false)
            $p_tokens[] = $t;
            
        foreach ($ROUTES as $n => $r) 
        {   
            $RC[$r['controller']][$r['action']] = 
                $RC_2["{$r['controller']}\\{$r['action']}"] = $n;
            
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
                $p_params = array();
                $t = strtok($r[0], '/.');

                if (($t !== false) && $t[0] === ':')
                {
                    $pp = substr($t, 1);
                    $ROUTES[$n]['pp'][] = $pp;
                    $p_params[$pp] = $p_tokens[0];
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
                            $p_params[$pp] = $p_tokens[$i];
                        else
                            $match = false;
                    }
                    elseif (!isset($p_tokens[++$i]) || ($t !== $p_tokens[$i]))
                        $match = false;
                }
                if (!$match || isset($p_tokens[++$i]))
                    continue;
            }   
            
            if (strpos($r['methods'], $_SERVER['REQUEST_METHOD']) === false)
            {
                $error = 405;
                continue;
            }
            
            if (isset($r['ssl']) && $r['ssl'] 
                && ($_SERVER['SERVER_PORT'] != (SSL_PORT ?: 443)))
            {
                if ($_SERVER['REQUEST_METHOD'] === 'GET')
                {
                    header('HTTP/1.1 301 Moved Permanently');
                    header('Location: ' . SSL_URL . (SERVER_PATH 
                        ? substr($_SERVER['REQUEST_URI'], strlen(SERVER_PATH))
                        : $_SERVER['REQUEST_URI'])
                    );
                    return;
                }
                $error = 403;
                continue;
            }
                
            $found = $r;
        }

        if ($found)
        {        
            $CONTROLLER = $found['controller'];
            $ACTION = $found['action'];
            $RENDERED = false;
            
            Parameters::instance($p_params);
            $cn = "Controllers\\{$CONTROLLER}Controller";
            $c = $cn::instance();
            
            try
            {
                if (CACHE)
                {
                    if ($cn::$caches_action)
                        $cn::add_to_filter('before_filter', 'set_action_cache');
                    
                    if ($cn::$caches_page)
                        $cn::add_to_filter('before_filter', 'set_page_cache');
                    
                    $c->invoke_filters('before_filter', $key);
                }
                else
                    $c->invoke_filters('before_filter');
                
                $c->$ACTION();

                if (!$RENDERED)
                    $c->render();
                
                $c->invoke_filters('after_filter');
            }
            catch (StopException $e)
            {
                return;
            }
            catch (\Exception $e) 
            {
                if ($c->invoke_filters('exception_filter', $e) !== false)
                    _send_500($e);
            }
        }
        elseif ($error === 403)
            send_403(false);
        elseif ($error === 405)
            send_405(false);
        else
            send_404(false);
    }
    
    /**
     * Prints the error information and optionally logs the error depending on
     * whether the application is in the LIVE mode or not.
     *
     * @internal This function should not be used explicitly! Internal use only.
     * @param \Exception $e The exception with error details
     * @author Szymon Wrozynski
     */
    function _send_500($e)
    {
	    $date = "Date/Time: " . date('Y-m-d H:i:s');
	    
	    if (LIVE) 
	    {
	        error_log(
	            get_class($e) .': ' .$e->getMessage(). ' at line '.$e->getLine() 
	                . ' in file ' . $e->getFile() . PHP_EOL . $date . PHP_EOL
	                . 'Stack trace:' . PHP_EOL . $e->getTraceAsString() 
	                . PHP_EOL . '------------------------------' . PHP_EOL,
	            3,
	            TEMP . 'errors.log'
	        );
		    header('HTTP/1.0 500 Internal Server Error');
		    require APPLICATION_PATH . DIRECTORY_SEPARATOR . 'errors' 
                . DIRECTORY_SEPARATOR . '500.php';
            return;
	    }
	    
	    echo '<p>', get_class($e), ': <b>', $e->getMessage(),
            '</b> at line ', $e->getLine(), ' in file ', $e->getFile(),
            '. ', $date, '</p><p>Local trace:<ol>';
            
        $app_path_cut_point = strlen(realpath(APPLICATION_PATH)) + 1;
            
        $trace = $e->getTrace();
        array_pop($trace); # remove the last entry (public/index.php)
            
        foreach ($trace as $entry)
        {
            # ignore if the entry neither has 'file' nor 'line' keys
            if (!isset($entry['file'], $entry['line']))
                continue;
                
            $file = substr($entry['file'], $app_path_cut_point);
                
            # omit the modules
            if (strpos($file, 'modules') === 0)
                continue;
                
            echo '<li><b>', $file, ':', $entry['line'], '</b> &mdash; ';
                    
            if (isset($entry['class']) && $entry['class'])
                echo 'method: <i>', $entry['class'], $entry['type'];
            else
                echo 'function: <i>';
                    
            echo $entry['function'], '(', implode(', ', array_map(function($a) {
                if (($a === null) || ((bool) $a === $a))
                    return gettype($a);
                elseif ((object) $a === $a)
                    return get_class($a);
                elseif ((string) $a === $a)
                    return "'$a'";
                else
                    return strval($a);
            }, $entry['args'])), ')</i></li>';
        }
        echo '</ol></p>';
    }
    
    /**
     * An exception throwing to stop the action processing. Throw it instead of 
     * calling 'die()' or 'exit()' functions.
     */
    final class StopException extends \Exception {}
    
    /**
     * The class holding {@link Controller}'s request parameters.
     *
     * The parameters can come both from the request and from the URI path. 
     * Path parameters are strings and they are always present (if not
     * mispelled) because they are parsed before the action was fired.
     * The regular parameters are strings usually but it is possible to pass 
     * a parameter as an array of strings (with the help of the '[]' suffix)
     * therefore you should be careful and never make an assumption that the
     * "plain" regular parameter is a string every time.
     *
     * To help with that, the {@link Parameters} class has two additional
     * methods: 'get_string' and 'get_array'. Both will return the parameter
     * value only if it is of a certain type.
     *
     * Path parameters always override the the regular ones if there is 
     * a clash of names.
     *
     * Parameters can be interated in the foreach loop and therefore they
     * might be passed directly to the ActiveRecord\Model instances.
     *
     * @author Szymon Wrozynski
     * @package Application
     */
    final class Parameters implements \IteratorAggregate
    {
    	private $_params;
    	private static $_instance;

    	private function __construct(&$path_params)
    	{   
    		if ($_SERVER['REQUEST_METHOD'] === 'GET') 
                $this->_params = $_GET;
            elseif ($_SERVER['REQUEST_METHOD'] === 'POST') 
                $this->_params = $_POST + $_GET;
            else
                parse_str(file_get_contents('php://input'), $this->_params);
            
            if ($path_params)
                $this->_params = $path_params + $this->_params;
    	}
    	
    	/**
    	 * Returns the instance of the {@link Parameters} object or create
    	 * a new one if needed.
    	 *
    	 * @param array $path_params Optional path parameters
    	 * return Parameters
       	 */
    	public static function &instance($path_params=null)
    	{
    	    if (!self::$_instance)
    	        self::$_instance = new Parameters($path_params);
    	    
    	    return self::$_instance;
    	}

    	/**
    	 * Sets a new parameter.
    	 *
    	 * @param string $name Name of the parameter
    	 * @param mixed $value Parameter value
    	 */
    	public function __set($name, $value)
    	{
    	    $this->_params[$name] = $value;
    	}

    	/**
    	 * Gets a parameter value.
    	 *
    	 * @param string $name Name of the parameter
    	 * @return mixed String, array or null
    	 */
    	public function &__get($name)
    	{
    	    $value = null;
    	    
    	    if (isset($this->_params[$name]))
    	        $value =& $this->_params[$name];
    	    
    	    return $value;
    	}
    	
    	/**
    	 * Checks if a parameter is present and is not null.
    	 *
    	 * @param string $name Name of a parameter
    	 * @return bool True if a parameter exists, false otherwise
    	 */
    	public function __isset($name)
    	{
    	    return isset($this->_params[$name]);
    	}
    	
    	/**
    	 * Removes the parameter.
    	 *
    	 * @param string $name Name of a parameter
    	 */
    	public function __unset($name)
    	{
    	    unset($this->_params[$name]);
    	}

    	/**
    	 * Returns the parameter only if it contains a string value. 
    	 * The null is returned if the parameter neither has the string
    	 * value nor exists.
    	 *
    	 * @param string $name Name of a parameter
    	 * @return string
    	 */
    	public function &get_string($name)
    	{
    	    $value = null;
    	    
    	    if (isset($this->_params[$name]) 
    	        && ((string) $this->_params[$name] === $this->_params[$name]))
    	        $value =& $this->_params[$name];
    	        
    	    return $value;
    	}
    	
    	/**
    	 * Returns the parameter only if it contains an array. 
    	 * The null is returned if the parameter neither contains 
    	 * the array value nor exists.
    	 *
    	 * @param string $name Name of a parameter
    	 * @return array
    	 */
    	public function &get_array($name)
    	{
    	    $value = null;
    	    
    	    if (isset($this->_params[$name]) 
    	        && ((array) $this->_params[$name] === $this->_params[$name]))
    	        $value =& $this->_params[$name];
    	    
    	    return $value;
    	}
    	
    	/**
    	 * Returns the parameters array copy.
    	 *
    	 * @return array
    	 */
    	public function to_a()
    	{
    	    return $this->_params;
    	}
    	
    	/**
    	 * Returns the filtered parameters array copy without specified ones.
    	 *
    	 * @param string ... Variable-length list of parameter names
    	 * @return array
    	 */
    	public function except(/*...*/)
    	{
    	    $params = $this->_params;

    	    foreach (func_get_args() as $name)
    	        unset($params[$name]);
    	    
    	    return $params;
    	}
    	
    	/**
    	 * Returns the filtered parameters array copy containing only specified
    	 * parameters.
    	 *
    	 * @param string ... Variable-length list of parameter names
    	 * @return array
    	 */
    	public function only(/*...*/)
    	{
    	    $params = array();
    	    
    	    foreach (func_get_args() as $name)
    	        $params[$name] = $this->_params[$name];
    	        
    	    return $params;
    	}
    	
    	/**
    	 * Returns an iterator to parameters. This will allow to iterate
    	 * over the {@link Parameters} using foreach. 
    	 *
    	 * <code>
    	 * foreach ($params as $name => $value) ...
    	 * </code>
    	 *
    	 * @return \ArrayIterator
    	 */
    	public function getIterator()
    	{
    		return new \ArrayIterator($this->_params);
    	}
    }
    
    /**
     * The class simplifing the session usage.
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
    final class Session implements \IteratorAggregate
    {
        private static $_instance;
        
        private function __construct()
        {
            if (SESSION !== true)
                session_name(SESSION);
            
            session_start();
            
            if (isset($_SESSION['__PRAGWORK_10_FLASH']))
            {
                foreach ($_SESSION['__PRAGWORK_10_FLASH'] as $name => $msg) 
                {
                    if ($msg[1])
                        unset($_SESSION['__PRAGWORK_10_FLASH'][$name]);
                }
            }
        }
        
        /**
         * Returns the {@link Session} instance only if the SESSION constant
         * is set to true or contains the session name. Otherwise returns null.
         * 
         * @return Session
         */
        public static function &instance()
        {
            if (!self::$_instance && SESSION)
                self::$_instance = new Session;
            
            return self::$_instance;
        }
        
        /**
         * Destroys the current session and causes the browser to remove 
         * the session cookie.
         */
        public function kill()
        {
            $_SESSION = array();
            session_destroy();
            setcookie(session_name(), '', $_SERVER['REQUEST_TIME'] - 3600, 
                '/', '', 0, 0);
        }
        
    	/**
    	 * Sets a new session variable.
    	 *
    	 * @param string $name Name of the session variable
    	 * @param mixed $value Variable value
    	 */
    	public function __set($name, $value)
    	{
    	    $_SESSION[$name] = $value;
    	}

    	/**
    	 * Gets a session variable.
    	 *
    	 * @param string $name Name of the session variable
    	 * @return mixed Variable value or null
    	 */
    	public function &__get($name)
    	{
    	    $value = null;
    	    
    	    if (isset($_SESSION[$name]))
    	        $value =& $_SESSION[$name];
    	    
    	    return $value;
    	}
    	
    	/**
    	 * Checks if a session variable exists.
    	 *
    	 * @param string $name Name of the session variable
    	 * @return bool True if the session variable exists, false otherwise
    	 */
    	public function __isset($name)
    	{
    	    return isset($_SESSION[$name]);
    	}
    	
    	/**
    	 * Removes the session variable if exists.
    	 *
    	 * @param string $name Name of the session variable
    	 */
    	public function __unset($name)
    	{
    	    unset($_SESSION[$name]);
    	}

    	/**
    	 * Returns an iterator to session variables. This will allow to iterate
    	 * over the {@link Session} using foreach. 
    	 *
    	 * <code>
    	 * foreach ($this->session as $name => $value) ...
    	 * </code>
    	 *
    	 * @return \ArrayIterator
    	 */
    	public function getIterator()
    	{
    		return new \ArrayIterator($_SESSION);
    	}
    }
    
    /**
     * The abstract base class for your controllers.
     *
     * @author Szymon Wrozynski
     * @package Application
     */ 
    abstract class Controller
    {
        /**
    	 * Sets the name of the default layout for templates of this 
    	 * {@link Controller}. All layouts are placed under the 'layouts' 
    	 * subdirectory. A layout may be placed in its own subdirectory as well.
    	 * The subdirectories are separated with a backslash \. 
    	 * If there is a backslash in the in the specified value then the given
    	 * value is treated as a path starting from the 'views' directory.
    	 * The backslash should not be a first character.
    	 * 
    	 * Examples:
    	 *
    	 * <code>
    	 * class MyController extends \Application\Controller
    	 * {
    	 *     static $layout = 'main'; # views/layouts/main.php
    	 *     static $layout = '\Admin\main'; # bad!
    	 *     static $layout = 'Admin\main'; # views/layouts/Admin/main.php
    	 * }
    	 * </code>
    	 *
    	 * The layout(s) may be specified with modifiers:
    	 *
    	 * <ul>
     	 * <li><b>only</b>: the layout will be used only for the specified 
     	 *     action(s)</li>
     	 * <li><b>except</b>: the layout will be used for everything but the 
     	 *     specified action(s)</li>
     	 * </ul>
    	 *
    	 * Example: 
    	 *
    	 * <code>
    	 * class MyController extends \Application\Controller
     	 * {
     	 *     static $layout = array(
     	 *         array('custom', 'only' => array('index', 'show')),
     	 *         'main'
     	 *     );
     	 *     # ...
     	 * } 
    	 * </code>
    	 *
    	 * In the example above, the 'custom' layout is used only for 'index'
    	 * and 'show' actions. For all other actions the 'main' layout is used.
    	 *
    	 * All layout entries are evaluated in the order defined in the array
    	 * until the first matching layout.
    	 *
    	 * @var mixed
    	 */
        static $layout = null;
        
        /**
    	 * Sets public filter methods to run before firing the requested action.
    	 *
    	 * According to the general Pragwork rule, single definitions may be
    	 * kept as strings whereas the compound ones should be expressed within
    	 * arrays.
    	 *
    	 * Filters can be extended or modified by class inheritance. The filters
     	 * defined in a subclass can alter the modifiers of the superclass.
     	 * Filters are fired from the superclass to the subclass. 
     	 * If a filter method returns a boolean false then the filter chain
     	 * execution is stopped.
    	 * 
    	 * <code>
    	 * class MyController extends \Application\Controller
    	 * {
    	 *     $before_filter = 'init';
    	 *
    	 *     # ...
    	 * }
    	 * </code>
    	 *
    	 * There are two optional modifiers: 
    	 *
    	 * <ul>
    	 * <li><b>only</b>: action or an array of actions that trigger off
    	 *     the filter</li>
    	 * <li><b>except</b>: action or an array of actions excluded from 
    	 *     the filter triggering</li>
    	 * </ul>
    	 *
    	 * <code>
     	 * class MyController extends \Application\Controller
     	 * {
     	 *     static $before_filter = array(
         *         'alter_breadcrumbs', 
         *         'except' => 'write_to_all'
         *     );
         *
         *     # ...
     	 * }
     	 * </code>
    	 *
    	 * <code>
    	 * class ShopController extends \Application\Controller
    	 * {
    	 *     static $before_filter = array(
    	 *         array('redirect_if_no_payments', 'except' => 'index'),
         *         array('convert_floating_point', 
         *             'only' => array('create', 'update'))
         *     );
    	 *
    	 *     # ...
    	 * }
    	 * </code>
    	 *
    	 * @see before_render_filter
     	 * @see after_filter
     	 * @see exception_filter
    	 * @var mixed
    	 */
        static $before_filter = null;
        
        /**
    	 * Sets public filter methods to run just before the first rendering 
    	 * a view (excluding partials).
    	 *
    	 * According to the general Pragwork rule, single definitions may be
    	 * kept as strings whereas the compound ones should be expressed within
    	 * arrays.
    	 * 
    	 * There are two optional modifiers: 
     	 *
     	 * <ul>
     	 * <li><b>only</b>: action or an array of actions that trigger off
     	 *     the filter</li>
     	 * <li><b>except</b>: action or an array of actions excluded from 
     	 *     the filter triggering</li>
     	 * </ul>
    	 *
    	 * See {@link before_filter $before_filter} for syntax details.
    	 *
    	 * @see before_filter
     	 * @see after_filter
     	 * @see exception_filter
    	 * @var mixed
    	 */
        static $before_render_filter = null;
        
        /**
    	 * Sets public filter methods to run after rendering a view.
    	 *
    	 * According to the general Pragwork rule, single definitions may be
    	 * kept as strings whereas the compound ones should be expressed within
    	 * arrays. 
    	 *
    	 * There are two optional modifiers: 
     	 *
     	 * <ul>
     	 * <li><b>only</b>: action or an array of actions that trigger off
     	 *     the filter</li>
     	 * <li><b>except</b>: action or an array of actions excluded from 
     	 *     the filter triggering</li>
     	 * </ul>
    	 *
    	 * See {@link before_filter $before_filter} for syntax details.
    	 *
    	 * @see before_filter
     	 * @see before_render_filter
     	 * @see exception_filter
    	 * @var mixed
    	 */
        static $after_filter = null;
        
        /**
    	 * Sets filter methods to run after rendering a view. 
    	 * Filter methods must be public or protected. The exception is passed
    	 * as a parameter.
    	 * 
    	 * Unlike in other filter definitions, there are also three (not two) 
    	 * optional modifiers: 
     	 *
     	 * <ul>
     	 * <li><b>only</b>: action or an array of actions that trigger off
     	 *     the filter</li>
     	 * <li><b>except</b>: action or an array of actions excluded from 
     	 *     the filter triggering</li>
     	 * <li><b>exception</b>: the name of the exception class that triggers 
     	 *     off the filter</li>
     	 * </ul>
    	 *
    	 * <code>
    	 * class PeopleController extends \Application\Controller
    	 * {
    	 *     static $exception_filter = array(
         *         array(
         *             'record_not_found', 
         *             'exception' => 'ActiveRecord\RecordNotFound'
         *         ),
         *         array(
         *             'undefined_property',
         *             'only' => array('create', 'update'),
         *             'exception' => 'ActiveRecord\UndefinedPropertyException'
         *         )
         *     );
         *
         *     # ...
    	 * }
    	 * </code>
    	 * 
    	 * <code>
    	 * class AddressesController extends \Application\Controller
    	 * {
    	 *     static $exception_filter = array(
         *         'undefined_property', 
         *         'only' => array('create', 'update'),
         *         'exception' => 'ActiveRecord\UndefinedPropertyException'
         *     );
         *
         *     # ...
    	 * }
    	 * </code>
    	 *
    	 * If the <b>exception</b> modifier is missed, any exception triggers 
    	 * off the filter method. If the modifier is specified, only a class 
    	 * specified as a string triggers off the filter method. 
    	 *
    	 * Only a string is allowed to be a value of the <b>exception</b> 
    	 * modifier. This is because of the nature of exception handling. 
    	 * Exceptions are most often constructed with the inheritance in mind
    	 * and they are grouped by common ancestors. 
    	 *
    	 * The filter usage resembles the 'try-catch' blocks where the single
    	 * exception types are allowed in the 'catch' clause. In fact,
    	 * the {@link exception_filter} may be considered as a syntactic sugar
    	 * to 'try-catch' blocks, where the same 'catch' clause may be adopted
    	 * to different actions.
    	 * 
    	 * See {@link before_filter $before_filter} for more syntax details.
    	 *
    	 * @see before_filter
     	 * @see before_render_filter
     	 * @see after_filter
    	 * @var mixed
    	 */
        static $exception_filter = null;
        
        /**
         * Caches the actions using the page-caching approach. The cache is
         * stored within the public directory, in a path matching the requested
         * URL. All cached files have the '.html' extension if needed. 
         * They can be loaded with the help of the <b>mod_rewrite</b> module
         * (Apache) or similar (see the Pragwork default .htaccess file). 
         * The parameters in the query string are not cached.
         *
         * Available options:
         *
         * <ul>
         * <li><b>if</b>: name(s) of (a) callback method(s)</li>
         * </ul>
         *
         * The writing of cache may be prevented by setting a callback method or
         * an array of callback methods in the 'if' option. The callback methods 
         * are run just before cache writing, in the 'after_filter' chain. 
         * If one of them returns a value evaluated to false the writing is not
         * performed:
         *
         * <code>
         * class MyController extends \Application\Controller
         * {
         *     static $caches_page = array( 
         *         array(
         *             'page',
         *             'post',
         *             'if' => array('no_forms', 'not_logged_and_no_flash')
         *         ),
         *         'index', 
         *         'if' => 'not_logged_and_no_flash_messages'
         *     );
         *
         *     public function no_forms()
         *     {
         *         return (isset($this->page) && !$this->page->form)
         *             || (isset($this->post) && !$this->post->allow_comments);
         *     }
         *
         *     public function not_logged_and_no_flash_messages()
         *     {
         *         return !$this->session->admin && !flash('notice');
         *     }
         *
         *     # ...
         * } 
         * </code>
         *
         * Because caching is done entirely in {@link before_filter} and 
         * {@link after_filter} filter chains it can be prevented by 
         * interrupting the filter chain (a filter method should return
         * a boolean <b>false</b>). It can be prevented also by redirecting 
         * or throwing the {@link StopException}.
         *
         * Notice that caching is working properly only if the CACHE constant 
         * is set to true.
         *
         * @see expire_page
         * @see caches_action
         * @var mixed String or array containing action name(s)
         */
        static $caches_page = null;
        
        /**
         * Caches the actions views and stores cache files in the 'temp'
         * directory. Action caching differs from page caching because action
         * caching always runs {@link before_filter}(s). 
         *
         * Available options:
         *
         * <ul>
         * <li><b>if</b>: name(s) of (a) callback method(s)</li>
         * <li><b>cache_path</b>: custom cache path</li>
         * <li><b>expires_in</b>: expiration time for the cached action in 
         *     seconds</li>
         * <li><b>layout</b>: set to false to cache the action only (without the        
         *     default layout)</li>
         * </ul>
         *
         * The writing of cache may be prevented by setting a callback method or
         * an array of callback methods in the 'if' option. The callback methods 
         * are run just before cache writing, in the 'after_filter' chain. 
         * If one of them returns a value evaluated to false the writing is not
         * performed.
         *
         * Because caching is done entirely in the {@link before_filter} and 
         * {@link after_filter} filter chains it can be prevented by 
         * interrupting the filter chain (a filter method should return
         * a boolean <b>false</b>). It can be prevented also by redirecting 
         * or throwing the {@link StopException}.
         *
         * The 'cache_path' option may be a string started from '/' or just a 
         * name of a method returning the path. If a method is used, then its
         * returned value should be a string beginning with '/' or a full
         * URL (starting with 'http') as returned by the {@link url_for} 
         * function.
         *
         * <code>
         * class MyController extends \Application\Controller
         * {
         *     static $caches_action = array(
         *         'edit', 
         *         'cache_path' => 'edit_cache_path'
         *     );
         *     
         *     public function edit_cache_path()
         *     {
         *         return url_for(array(
         *             'edit', 
         *             'params' => $this->params->only('lang')
         *         ));
         *     }
         *
         *     # ...
         * }
         * </code>
         *
         * Notice that caching is working properly only if the CACHE constant 
         * is set to true.
         *
         * @see expire_action
         * @see caches_page
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
         * The {@link Session} object that simplifies the session usage 
         * or null if sessions are disabled.
         *
         * @see Session
         * @var Session
         */
        public $session;
        
        private static $_content;
        private static $_instance;
        private static $_ch_file;
        private static $_ch_dir;
        private static $_ch_layout;
        private static $_ch_if;
        
        private final function __construct()
        {
            $this->params = Parameters::instance();
            $this->session = Session::instance();
            
            $class = get_class($this);
            do 
            {
                require HELPERS . str_replace('\\', DIRECTORY_SEPARATOR, 
                    substr($class, 12, -10)) . 'Helper.php';
            }
            while (($class = get_parent_class($class)) !== __CLASS__);
        }
        
        /**
         * Returns the current instance of a controller or creates a new one.
         *
         * If there is no instance yet and this method is used within 
         * a subclass of the {@link Controller} class it creates the new one.
         * Usually controller is created automatically in the 
         * {@link Application\start()} function.
         * 
         * return Controller
         */
        public static final function &instance()
        {
            if (!self::$_instance)
            {
                $controller = get_called_class();
                
                if ($controller !== __CLASS__)
                    self::$_instance = new $controller;
            }
            
            return self::$_instance;
        }

        /**
         * Returns the actual URI path without a specified server path.
         * 
     	 * @return string Current URI path
         */
        public function uri()
        {
            return SERVER_PATH 
                ? substr($_SERVER['REQUEST_URI'], strlen(SERVER_PATH))
                : $_SERVER['REQUEST_URI']; 
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
            return $_SERVER['SERVER_PORT'] == (SSL_PORT ?: 443);
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
        
        /**
         * Returns the default URL options used by all functions based on 
         * the {@link url_for} function. This method should return an array of
         * default options or nothing (a null value). Each default option may be
         * overridden by each call to the {@link url_for} function.
         *
         * @see url_for
         * @return array Default URL options or null
         */
        public function default_url_options() {}
        
        /**
         * Deletes the cached page, cached via the {@link $caches_page}.
         * The cache path is computed from options passed internally to the 
         * {@link url_for} function. Therefore see the {@link url_for} function
         * for options syntax.
         *
         * @see caches_page
         * @param mixed $options Options array or action name (string)
         */
        public function expire_page($options=array())
        {
            $key = url_for($options);
            $qpos = strpos($key, '?');
            $start = strlen(($key[4] === 's') ? SSL_URL : HTTP_URL);
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
         * Deletes the cached action view, cached via the 
         * {@link $caches_action}. The cache path is computed from options
         * passed internally to the {@link url_for} function. Therefore see
         * the {@link url_for} function for options syntax. 
         *
         * @see caches_action
         * @param mixed $options Options array or action name (string)
         */
        public function expire_action($options=array())
        {
            $key = url_for($options);
            $key = substr($key, strlen(($key[4]==='s') ? SSL_URL : HTTP_URL));
            
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
         * Returns true if the cached fragment is available. The cache path is 
         * computed from options passed internally to the {@link url_for}
         * function. Therefore see the {@link url_for} function for options 
         * syntax. Moreover, the additional following options are available:
         *
         * <ul>
         * <li><b>action_suffix</b>: the path suffix allowing many fragments in 
         *     the same action</li>
         * </ul>
         *
         * @see cache
         * @see expire_fragment
         * @param mixed $options Options array or action name (string)
         * @return bool True if the fragment exists, false otherwise
         */
        public function fragment_exists($options=array())
        {
            return is_file(self::fragment_file($options));
        }
        
        /**
         * Deletes a cached fragment. The cache path is computed from options 
         * passed internally to the {@link url_for} function. Therefore see 
         * the {@link url_for} function for options syntax. Moreover, 
         * the additional following options are available:
         *
         * <ul>
         * <li><b>action_suffix</b>: the path suffix allowing many fragments in
         *     the same action</li>
         * </ul>
         *
         * @see cache
         * @see fragment_exists
         * @param mixed $options Options array or action name (string)
         */
        public function expire_fragment($options=array())
        {
            $fragment = self::fragment_file($options);
            if (is_file($fragment))
                unlink($fragment);
        }
        
        /**
         * Caches the fragment enclosed in the closure. The cache path is 
         * computed from options passed internally to the {@link url_for}
         * function. Therefore see the {@link url_for} function for options 
         * syntax. Moreover, the additional following options are available:
         *
         * <ul>
         * <li><b>action_suffix</b>: the suffix allowing many fragments in the
         *     same action</li>
         * <li><b>expires_in</b>: time-to-live for the cached fragment 
         *     (in sec)</li>
         * </ul>
         *
         * Notice, this method will write and read cached fragments only 
         * if the CACHE constant is set to true.
         *
         * @see expire_fragment
         * @see fragment_exists
         * @param mixed $options Options array or action name (string)
         * @param \Closure $closure Content to be cached and displayed
         */
        public function cache($options, $closure)
        {
            if (!CACHE)
                return $closure($this);
            
            $frag = self::fragment_file($options);
            
            if (is_file($frag))
            {
                if (isset($options['expires_in']))
                {
                    if ((filemtime($frag) + $options['expires_in']) 
                        > $_SERVER['REQUEST_TIME'])
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
            $key = substr($key,strlen(($key[4]==='s') ?SSL_URL:HTTP_URL));   
            
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
                        self::$_content[$file] = file_get_contents(
                            self::$_ch_dir . DIRECTORY_SEPARATOR . $file
                        );
                }

                closedir($handler);
            }
            
            $this->render(array(
                'text' => file_get_contents(self::$_ch_file),
                'layout' => true
            ));
            
            throw new StopException;
        }
        
        /**
         * A filter method added automatically to {@link before_filter} chain to
         * perform action caching (render or create).
         * 
         * @param string $key The cache path passed automatically to the filter
         * @throws {@link StopException} If cache was loaded and rendered
         * @internal
         */
        protected final function set_action_cache($key)
        {
            if (self::$_ch_file)
                return;
            
            global $ACTION;
            
            foreach (self::normalize_defs(static::$caches_action) as $ch)
            {
                if ($ch[0] !== $ACTION)
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
                            self::$_ch_dir = TEMP . 'ca_' 
                                . md5(substr($chp, strlen(SSL_URL)));
                        else
                            self::$_ch_dir = TEMP . 'ca_' 
                                . md5(substr($chp, strlen(HTTP_URL)));
                    }
                }
                else
                    self::$_ch_dir = TEMP . 'ca_' 
                        . md5(isset($key[1]) ? rtrim($key, '/.') : $key);

                self::$_ch_file = self::$_ch_dir . '.cache';
                
                if (isset($ch['layout']) && !$ch['layout'])
                { 
                    if (is_file(self::$_ch_file))
                    {
                        if (isset($ch['expires_in']))
                        { 
                            if ((filemtime(self::$_ch_file) + $ch['expires_in']) 
                                > $_SERVER['REQUEST_TIME'])
                                $this->render_cache_in_layout();
                        }
                        else
                            $this->render_cache_in_layout();
                    }
                    self::$_ch_layout = self::get_layout();
                    static::$layout = null;
                }
                elseif (is_file(self::$_ch_file))
                {
                    if (isset($ch['expires_in']))
                    { 
                        if ((filemtime(self::$_ch_file) + $ch['expires_in']) 
                            > $_SERVER['REQUEST_TIME'])
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
                ob_start();
                break;
            }
        }
        
        /**
         * A filter method added automatically to {@link before_filter} chain to
         * create page cache.
         * 
         * @param string $key The cache path passed automatically to the filter
         * @internal
         */
        protected final function set_page_cache($key)
        {
            if (self::$_ch_file)
                return;
            
            global $ACTION;
            
            foreach (self::normalize_defs(static::$caches_page) as $ch)
            {   
                if ($ch[0] !== $ACTION)
                    continue;
                            
                $key = trim($key, '/.');
                    
                if (isset($key[0]))
                {
                    self::$_ch_file = str_replace('/',DIRECTORY_SEPARATOR,$key);
                                        
                    if (!strpos($key, '.'))
                        self::$_ch_file .= '.html';
                }
                else
                    self::$_ch_file = 'index.html';
                
                if (isset($ch['if']))
                    self::$_ch_if = $ch['if'];
                
                self::add_to_filter('after_filter', 'write_and_show_cache');
                ob_start();
                break;
            }
        }
        
        /**
         * A filter method added automatically to {@link after_filter} chain to
         * write and render cache file prepared in {@link set_page_cache} or 
         * {@link set_action_cache} methods.
         *
         * @internal
         */
        protected final function write_and_show_cache()
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
            
            $output = ob_get_clean();
            file_put_contents(self::$_ch_file, $output);    
            
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
                        file_put_contents(self::$_ch_dir.DIRECTORY_SEPARATOR.$r,
                            $c);       
                }
                
                $this->render(array(
                    'text' => $output,
                    'layout' => self::$_ch_layout
                ));
            }
            else
                echo $output;
        }
        
        /**
    	 * Sends a location in the HTTP header causing a HTTP client 
    	 * to redirect. The location URL is obtained from {@link url_for}
    	 * function. See {@link url_for} function for options syntax.
    	 *
    	 * Additionally, following options are available:
    	 * 
    	 * <ul>
         * <li><b>status</b>: HTTP status code (default: 302, see below)</li>
         * <li><b>[name]</b>: additional flash message</li>
         * </ul>
         *
    	 * Available HTTP 1.1 statuses:
    	 *
    	 * <ul>
    	 * <li><b>301</b>: 301 Moved Permanently</li>
    	 * <li><b>302</b>: 302 Found (default)</li>
    	 * <li><b>303</b>: 303 See Other</li>
    	 * <li><b>307</b>: 307 Temporary Redirect</li>
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
    	 * @see url_for
    	 * @see redirect_to_url
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
    	 * Sends a location in the HTTP header causing a HTTP client 
     	 * to redirect. The following options are available:
     	 * 
     	 * <ul>
         * <li><b>status</b>: HTTP status code (default: 302, see below)</li>
         * <li><b>[name]</b>: additional flash message</li>
         * </ul>
         *
     	 * Available HTTP 1.1 statuses:
     	 *
     	 * <ul>
     	 * <li><b>301</b>: 301 Moved Permanently</li>
     	 * <li><b>302</b>: 302 Found (default)</li>
     	 * <li><b>303</b>: 303 See Other</li>
     	 * <li><b>307</b>: 307 Temporary Redirect</li>
     	 * </ul>
     	 *
    	 * @see redirect_to
    	 * @param string $url URL of the location
         * @param mixed $options Options array
    	 * @throws {@link StopException} In order to stop further execution
    	 */
        public function redirect_to_url($url, $options=array())
        {
            if (isset($options['status']))
            {
                if ($options['status'] === 301)
                    header('HTTP/1.1 301 Moved Permanently');
                elseif ($options['status'] === 303)
                    header('HTTP/1.1 303 See Other');
                elseif ($options['status'] === 307)
                    header('HTTP/1.1 307 Temporary Redirect');
                
                unset($options['status']);
            }
            
            foreach ($options as $name => $msg)
                $_SESSION['__PRAGWORK_10_FLASH'][$name] = array($msg, false);
            
            header('Location: ' . $url);
            throw new StopException;
        }
        
        /**
         * Renders a template depending on parameters passed via $options.
         * The rendering topic may be divided into two big areas of use:
         * rendering of templates and rendering of partial templates.
         * 
         * A. General rendering of templates
         *
         * Templates are placed under the directory 'views' of the application
         * code. They fill the directory structure according to the controllers
         * structure.
         *
         * A.1. Rendering a template in the current controller 
         *
         * <code>
         * class ShopController extends \Application\Controller
         * {
         *     public function index()
         *     {
         *         # $this->render();
         *     }
         *
         *     public function show()
         *     {
         *         $this->render('index');
         *         $this->render(array('index'));
         *         $this->render(arary('action' => 'index'));
         *     }
         * }
         * </code>
         *
         * Each of the method calls in the action 'show' above renders 
         * the template of the action 'index' of the current controller.
         * However you should render a template once. Notice also, rendering
         * the template does not stop the further action execution.
         *
         * The 'render()' with no arguments renders the template of the current
         * action. But the action renders its own template implicitly if no
         * other render is used (except partial templates). Therefore there is
         * no need to explicit call 'render()' in the 'index' action above.
         *
         * A.2. Rendering a template of another controller 
         *
         * <code>
         * class CustomersController extends \Application\Controller
         * {
         *     public function edit() {}
         * }
         *
         * class ShopController extends \Application\Controller
         * {
         *     public function show()
         *     {
         *         $this->render(array(
         *             'action' => 'edit', 
         *             'controller' => 'Customers'
         *         ));
         *
         *         # or just: $this->render('Customers\edit')
         *     }
         * }
         * </code>
         *
         * Renders the template of the 'edit' action of the Customers 
         * controller.
         *
         * A.3. Rendering a custom template
         *
         * <code>
         * $this->render('my_custom_template');
         * $this->render('my_templates\my_custom_template');
         * $this->render(array('my_custom_template', 'layout' => false))
         * $this->render(array('my_custom_template', 'layout' => 'my_layout'));
         * </code>
         *
         * Renders a custom template. The custom template may be placed 
         * in a subdirectory. The subdirectories are separated with 
         * a backslash \. If there is a backslash in the string, the path 
         * starts from the root (the 'views' directory).
         *
         * Each of the examples from the part A can be altered with an option
         * 'layout' which can point to a certain {@link $layout}. 
         * Also, this option can be set to <b>false</b> disabling the global
         * layout defined in the controller. The layout file should be put 
         * in the 'views/layouts' directory.
         *
         * <code>
         * class ShopController extends \Application\Controller
         * {
         *     static $layout = 'shop';
         *
         *     public function index()
         *     {
         *         # use the default layout ('views/layouts/shop.php')
         *     }
         *
         *     public function show()
         *     {
         *         $this->render(array('layout' => false));
         *
         *         # do not use any layout, same as self::$layout = null;
         *     }
         *
         *     public function edit()
         *     {
         *         $this->render(array(
         *             'action' => 'show',
         *             'layout' => 'custom_layout'
         *         ));
         *
         *         # or just:
         *         # $this->render(array('show', 'layout' => 'custom_layout'));
         *
         *         # use the template 'views/Shop/show.php' with 
         *         # the layout 'views/layouts/custom_layout.php'.
         *     }
         * }
         * </code>
         *
         * A.4. Content Format
         *
         * It is possible to specify a content format in the header sended with 
         * the first use of the render() method (excluding partials). It can be
         * done with help of the 'content_status' option.
         *
         * <code>
         * $this->render(array('show', 'content_format' => 'text/xml'));
         * </code>
         *
         * A.5. Format
         *
         * Format enables additional headers to be sent on the first call of 
         * render() (again partials does not count). Also, it provides
         * additional, specific behavior, depending on the chosen format.
         *
         * Currently there is only one format available: <b>xml</b>.
         *
         * <code>
         * $this->render(array('format' => 'xml'));
         * </code>
         *
         * It renders the template (the default one in this particular example)
         * with the header: "Content-Type: text/xml; charset=utf-8" (no content
         * format was specified). Moreover, it disables the global layout. 
         * You can always use a layout by specifying a layout template:
         *
         * <code>
         * $this->render(array('format' => 'xml', 'layout' => 'my_xml_layout'));
         * </code>
         *
         * Or, you can turn on the global layout by setting 'layout' to true 
         * explicitly.
         *
         * A.6. Text, XML, JSON
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
         * If you do not set the custom content format, the 'application/xml' is
         * used for XML and 'application/json' is used for JSON (the header is
         * set in the first method call).
         * 
         * The 'json' option allows to pass 'json_options' bitmask, just like 
         * it is done in the global json_encode() function.
         * 
         * <code>
         * $this->render(array(
         *     'json' => array(array(1, 2, 3)), 
         *     'json_options' => JSON_FORCE_OBJECT
         * ));
         * </code>
         *
         *
         * B. Rendering partial templates
         *
         * Partial templates are placed in the same directory structure as
         * normal templates. They differ from the normal ones in extensions.
         * Partial templates ends with the '.part.php' extension.
         *
         * Whereas normal rendering of templates is taking place in 
         * the controller, the rendering of partials is the domain of template
         * files mainly. Usually partial templates represent repetitive portions
         * of code used to construct more compound structures. The result of
         * rendering the partial template is returned as a string - it is not
         * displayed immediately and therefore it should be displayed explicitly
         * with the 'echo' function.
         *
         * If the '.part.php' file is not found the '.php' one is used instead
         * and the template is rendered in the normal way described in the
         * section A.
         *
         * B.1. Rendering the partial template
         * 
         * <code>
         * <?php echo $this->render('item') ?>
         * </code>
         *
         * The code above renders the partial template 'item.part.php' placed
         * under the controller's directory in the views structure. 
         * If the partial template name contains a backslash \ the absolute path
         * will be used (with the root set to 'views' directory).
         *
         * <code>
         * <?php echo $this->render('shared\header') ?>
         * # renders /views/shared/header.part.php
         * </code>
         *
         * Everything (except 'collection') passed as named array elements are
         * converted to local variables inside the partial template.
         * 
         * <code>
         * <?php echo $this->render(array('item', 'text' => 'Hello')) ?>
         * # renders the partial template ('item.part.php') and creates a local 
         * # variable named $text there.
         * </code>
         *
         * B.2. Rendering a partial template with a collection
         *
         * If you use the 'collection' option you can render the partial
         * template a few times, according to items passed in an array 
         * as 'collection'. The current item from the collection is named 
         * after the template name, and the array key name has the '_key'
         * suffix.
         *
         * So the code below:
         *
         * <code>
         * <?php $this->render(array(
         *     'person', 
         *     'collection' => array('John', 'Frank'),
         *     'message' => 'The message.'
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
         * In the above example the 'person.part.php' will be rendered twice,
         * with different names ($person) and keys ($person_key). The whole
         * collection will be still available under the $collection variable.
         *
         * @see layout
         * @param mixed $options Options array or string
         * @return mixed Rendered partial template or null
         */
        public function render($options=array())
        {
            global $CONTROLLER, $ACTION, $RENDERED;
            
            if ((array) $options !== $options)
            {
                $template = VIEWS . ((strpos($options, '\\') === false)
                    ? str_replace('\\', DIRECTORY_SEPARATOR, $CONTROLLER) 
                        . DIRECTORY_SEPARATOR . $options
                    : str_replace('\\', DIRECTORY_SEPARATOR, $options));
                
                $partial = $template . '.part.php';
                
                if (is_file($partial))
                {
                    ob_start();
                    require $partial;
                    return ob_get_clean();
                }
                
                if (!$RENDERED)
                {
                    $this->invoke_filters('before_render_filter');
                    $RENDERED = true;
                }
                
                $layout = self::get_layout();
                
                if ($layout)
                {
                    ob_start();
                    require $template . '.php';
                    self::$_content[0] = ob_get_clean();
                    require VIEWS . 'layouts' . DIRECTORY_SEPARATOR
                        . str_replace('\\', DIRECTORY_SEPARATOR, $layout)
                        . '.php';
                }
                else
                    require $template . '.php';
                
                return;
            }
            elseif (isset($options[0]))
            {
                $template = VIEWS . ((strpos($options[0], '\\') === false)
                    ? str_replace('\\', DIRECTORY_SEPARATOR, $CONTROLLER) 
                        . DIRECTORY_SEPARATOR . $options[0]
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
                        {
                            $this->render_partial($partial, array(
                                $name => $item,
                                $key_name => $key
                            ) + $options);
                        }
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
                    isset($options['controller']) 
                        ? $options['controller'] : $CONTROLLER) 
                    . DIRECTORY_SEPARATOR . (isset($options['action'])
                        ? $options['action'] : $ACTION);
            
            if (isset($options['text']))
            {
                if (!$RENDERED)
                {
                    $RENDERED = true;
                    $this->invoke_filters('before_render_filter');
                    
                    if (isset($options['content_type']))
                        header('Content-Type: ' . $options['content_type']
                            . '; charset=utf-8');
                }
                
                if (isset($options['layout']))
                {
                    if ($options['layout'] === true)
                        $options['layout'] = self::get_layout();
                    
                    self::$_content[0] = $options['text'];
                    require VIEWS . 'layouts' . DIRECTORY_SEPARATOR.str_replace(
                        '\\', DIRECTORY_SEPARATOR, $options['layout']) . '.php';
                }
                else
                    echo $options['text'];
                
                return;
            }
            
            if (isset($options['format']) && $options['format'] === 'xml')
            {
                if (!isset($options['content_type']))
                    $options['content_type'] = 'text/xml';
                if (!isset($options['layout']))
                    $options['layout'] = false;
            }
            elseif (!isset($options['layout']))
                $options['layout'] = self::get_layout();
            
            if (!$RENDERED)
            {
                $this->invoke_filters('before_render_filter');
                $RENDERED = true;
                
                if (isset($options['content_type']))
                    header('Content-Type: ' . $options['content_type']
                        . '; charset=utf-8');
            }
            
            if ($options['layout'])
            {
                ob_start();
                require $template . '.php';
                self::$_content[0] = ob_get_clean();
                require VIEWS . 'layouts' . DIRECTORY_SEPARATOR 
                    . str_replace('\\', DIRECTORY_SEPARATOR, $options['layout']) 
                    . '.php';
            }
            else
                require $template . '.php';
        }
        
        /**
         * Renders the template just like the {@link render} method but returns
         * the results as a string. Also, this method does not send any
         * headers and does not cause {@link before_render_filter} filters 
         * to run.
         *
         * @see render
         * $param mixed $options Options array or string
         * @return string
         */
        public function render_to_string($options=array())
        {
            global $RENDERED;
            ob_start();
            
            if ($RENDERED)
                $str = $this->render($options);
            else
            {
                $RENDERED = true;
                $str = $this->render($options);
                $RENDERED = false;
            }
            
            return ob_get_clean() ?: $str;
        }
        
        private function render_partial($___path___, $___args___)
        {   
            foreach ($___args___ as $___n___ => $___v___) 
                $$___n___ = $___v___;
            
            require $___path___;
        }

        /**
         * Returns a rendered template or a template region constructed 
         * with the {@link content_for} method and a name passed as a parameter. 
         * This method should be used directly from a layout template. 
         * If the region does not exist the null is returned instead.
         *
         * <code>
         * <?php echo $this->yield() ?>
         * </code>
         *
         * <code>
         * <?php echo $this->yield('title') ?>
         * </code>
         *
         * @see content_for
         * @see render
         * @param string $region Optional region name
         * @return mixed Rendered template, template region, or null
         */
        public function yield($region=0)
        {
            if (isset(self::$_content[$region]))
                return self::$_content[$region];
        }
        
        /**
         * Inserts a named content block into a layout view directly from 
         * a template. The region name can be used in the layout with the 
         * {@link yield} function. The closure with the content may have 
         * an argument. If so, the current controller instance is passed 
         * there allowing to get to controller methods and variables. 
         *
         * <code>
         * <?php $this->content_for('title', function() { ?>
         *     Just simple title
         * <?php }) ?>
         * </code>
         *
         * <code>
         * <?php $this->content_for('title', function($that) { ?>
         *
         *     # the current controller is named '$that' by convention
         *     # and because '$this' cannot be used in the closure context
         *
         *     Records found: <?php echo count($that->records) ?>
         * <?php }) ?>
         * </code>
         *
         * @see yield
         * @param string $region Region name
         * @param \Closure $closure Content for partial yielding
         */
        public function content_for($region, $closure)
        {
            ob_start();
            $closure($this);
            self::$_content[$region] = ob_get_clean();
        }
        
        private static final function get_layout()
        {
            if (!static::$layout)
                return;
            
            static $layout;
            
            if (!isset($layout))
            {
                $layout = null;
                global $ACTION;
                
                foreach (self::normalize_defs(static::$layout) as $l)
                {
                    if (isset($l['only']))
                    {
                        if ((((array) $l['only'] === $l['only']) 
                            && in_array($ACTION, $l['only'], true))
                            || ($l['only'] === $ACTION))
                        {
                            $layout = $l[0];
                            break;
                        }
                        continue;
                    }
                    elseif (isset($l['except'])
                        && ((((array) $l['except'] === $l['except']) 
                        && in_array($ACTION, $l['except'], true))
                        || ($l['except'] === $ACTION)))
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
                    ? $entry['only']
                    : array($entry['only']);
                unset($entry['only']);
            }
            if (isset($entry['except']))
            {
                $modifiers['except'] = 
                    ((array) $entry['except'] === $entry['except'])
                        ? $entry['except']
                        : array($entry['except']);
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
        
        /**
         * Appends a filter method to the given chain. It allows to alter the
         * filter chain dynamically during the execution time.
         *
         * @param string $filter Name of filter chain
         * @param string $method Name of filter method to append
         * @internal
         */
        public static final function add_to_filter($filter, $method)
        {
            if (!static::$$filter)
                static::$$filter = $method;
            elseif ((array) static::$$filter === static::$$filter)
            {
                if (array_key_exists('except', static::$$filter) 
                    || array_key_exists('only', static::$$filter))
                    static::$$filter = self::normalize_defs(static::$$filter);
                
                array_push(static::$$filter, $method);
            }
            else
                static::$$filter = array(static::$$filter, $method);
        }
        
        /**
         * Runs the filters with the specified name and an optional value.
         * This method is intended to use internally by framework router.
         * You do not have to trigger filters manually. 
         *
    	 * @see before_filter
    	 * @see before_render_filter
    	 * @see after_filter
    	 * @see exception_filter 
    	 * @internal
    	 * @param string $filter Name of filter chain to run
    	 * @param mixed $value Optional value passed to filter chain methods
    	 * @return bool False if one of filter methods interrupts filter chain
    	 */
        public function invoke_filters($filter, $value=null)
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
            
            global $ACTION;
            
            foreach (array_reverse($filter_chain) as $flt => $mods)
            {
                if (isset($mods['only']) 
                    && !in_array($ACTION, $mods['only']))
                    continue;
                elseif (isset($mods['except']) 
                    && in_array($ACTION, $mods['except']))
                    continue;
                elseif (isset($mods['exception']) 
                    && !($value && is_a($value, $mods['exception'])))
                    continue;

                if ($this->$flt($value) === false)
                    return false;
            }
        }
    }
}

namespace
{
    /**
     * Absolute path to the configuration directory. 
     *
     * @internal
     */
    define('CONFIG', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'config' 
        . DIRECTORY_SEPARATOR);
    
    /**
     * Absolute path to the user application code directory.
     *
     * @internal
     */
     define('APP', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'app' . 
        DIRECTORY_SEPARATOR);
    
    /**
     * HTTP URL part used to construct URLs.
     *
     * @internal
     */
    define('HTTP_URL', 'http://' . $_SERVER['SERVER_NAME'] 
        . (HTTP_PORT ? ':' . HTTP_PORT : '') . SERVER_PATH);

    /**
     * HTTPS URL part used to construct URLs.
     *
     * @internal
     */
    define('SSL_URL', 'https://' . $_SERVER['SERVER_NAME'] 
        . (SSL_PORT ? ':' . SSL_PORT : '') . SERVER_PATH);
    
    /**
     * Absolute path to helpers directory.
     *
     * @internal
     */
    define('HELPERS', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'app' 
        . DIRECTORY_SEPARATOR . 'helpers' . DIRECTORY_SEPARATOR);
    
    /**
     * Absolute path to views directory.
     *
     * @internal
     */
    define('VIEWS', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'app' 
        . DIRECTORY_SEPARATOR . 'views' . DIRECTORY_SEPARATOR);
    
    /**
     * Absolute path to locales directory.
     *
     * @internal
     */
    define('LOCALES', APPLICATION_PATH . DIRECTORY_SEPARATOR 
        . 'locales' . DIRECTORY_SEPARATOR);
    
    /**
     * Absolute path to the directory for temporary files.
     *
     * @internal
     */
    define('TEMP', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'temp' 
        . DIRECTORY_SEPARATOR);
    
    /*
     * Adds the internal class loader to the class loaders chain. The class 
     * loader searches classes in the '/app' directory. 
     *
     * The provided class name should not start with a backslash <b>\</b>
     * character. Notice, that PHP strips the leading backslashes automatically
     * even if you provide it in the code:
     * 
     * <code>
     * $bar = new \Foo\Bar;
     * # it passes 'Foo\Bar' string to the class loader if class has not been
     * # loaded yet
     * </code>
     *
     * However, a user may provide a leading backslash accidentally while
     * dealing with classes loaded from strings:
     *
     * <code>
     * $class_name = '\Foo\Bar'; # WRONG!
     * $bar = new $class_name;
     *
     * $class_name = 'Foo\Bar';  # CORRECT
     * $bar = new $class_name;   # It is an equivalent of: $bar = new \Foo\Bar;
     * </code>
     *
     * Remember, namespaces in strings are always regarded as absolute ones.
     */
    spl_autoload_register(function($class)
    {
        $file = APP . str_replace('\\', DIRECTORY_SEPARATOR, $class) . '.php';
        
        if (is_file($file))
            require $file;
    });
    
    /**
     * Internal error handler.
     *
     * @internal This function should not be used explicitly! Internal use only.
     */
    function exception_error_handler($errno, $errstr, $errfile, $errline) 
    {
        throw new ErrorException($errstr, 0, $errno, $errfile, $errline);
    }
    
    set_error_handler('exception_error_handler');
    
    /**
     * Constructs URL based on the route name or an action (or a controller)
     * passed as $options. The routes are defined in the application
     * configuration directory ('routes.php').
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
     * 1. URL for a specified route
     *
     * <code>
     * url_for(array('name' => 'help'));
     * </code> 
     *
     * Returns an URL for the route name 'help'.
     *
     * 2. URL for the action and the controller
     * 
     * <code>
     * url_for();
     * </code>
     *
     * Returns an URL for the current action of the current controller. 
     * If the action or controller is not given the current one is used instead.
     * If there is no controller at all (e.g. inside error templates) the root
     * controller is assumed.
     *
     * <code>
     * url_for('/');
     * </code>
     *
     * Returns an URL to the root route of the application ('/'). The root 
     * route is always the first entry (0th index) in the $ROUTES array.
     *
     * <code>
     * url_for('index'); 
     * url_for(array('index'));
     * url_for(array('action' => 'index'));
     * </code>
     *
     * Returns the URL for the 'index' action of the current controller.
     *
     * <code>
     * url_for('Shop\index');
     * url_for(array('Shop\index'));
     * url_for(array('action' => 'index', 'controller' => 'Shop'));
     * </code>
     * 
     * Returns the URL for the 'index' action of the Shop controller.
     * The controllers should be specified with the enclosing namespace 
     * (if any), e.g. 'Admin\Configuration' - for the controller with the full 
     * name: \Controllers\Admin\ConfigurationController.
     *
     * 3. Static assets
     *
     * If the string (2 characters length min.) starting with a slash <b>/</b> 
     * is passed as $options or the first (0th index) element of the options
     * array then it is treated as an URI path to a static asset. 
     * This feature is used by special assets tags in the Tags module, 
     * therefore rarely there is a need to explicit use it.
     *
     * <code>
     * url_for('/img/foo.png');
     * url_for($this->uri());
     * </code>
     *
     * 4. SSL
     *
     * <code> 
     * url_for(array('index', 'ssl' => true));
     * url_for(array('name' => 'help', 'ssl' => false));
     * </code>
     *
     * Returns the URL with the secure protocol or not. If the 'ssl' option is
     * omitted the default SSL setting is used (from the corresponding entry
     * in the 'routes.php' configuration file). The HTTP and HTTPS protocols use
     * the ports defined in the 'index.php' file in the 'public' directory. 
     * If those ports are set to null, default values are used (80 and 443).
     *
     * 5. Anchor
     * 
     * <code>
     * url_for(array('index', 'anchor' => 'foo'));
     * </code>
     *
     * Generates the URL with the anchor 'foo', for example: 
     * 'http://www.mydomain.com/index#foo'.
     *
     * 6. Parameters
     *
     * Parameters are passed an an option named 'params'. There are two kind 
     * of parameters in the URL: path parameters and query parameters. 
     * Path parameters are used to compose the URI path, and query parameters
     * are used to create the query appended to the URL. Usually, parameters are 
     * passed as an array where the keys are parameter names. However, path
     * parameters can be passed without keys at all. In such case, they are
     * taken as first ones depending on their order. Path parameters always 
     * have higher priority than query parameters, and keyless path parameters
     * have higher priority than others.
     *
     * If there is only one keyless parameter, the array may be omitted.
     *
     * Consider the simplest example:
     *
     * <code>
     * url_for(array('show', 'params' => array(
     *     'id' => 12, 
     *     'size' => 25, 
     *     'color' => 'blue'
     * )));
     * </code>
     * 
     * The result could be (assuming the according route is e.g. '/items/:id'):
     * 'http://www.mydomain.com/items/12?size=25&color=blue'.
     * 
     * But you can also write it in a short manner, using the 0th array element:
     * 
     * <code>
     * url_for(array('show', 'params' => array(12,'size'=>25,'color'=>'blue')));
     * </code>
     *
     * Also, if there had not been other parameters than the path one, you would
     * have written it even shorter:
     * 
     * <code>
     * url_for(array('show', 'params' => 12));
     * </code>
     *
     * 7. Locale
     * 
     * If the LOCALIZATION constant is set to true, this option affects 
     * the locale code used to construct the URL. It could be useful e.g. to
     * provide language choice options. Notice, if the LOCALIZATION is set to 
     * true the root action allows the localization to be omitted and thus 
     * the locale remains undefined (unloaded). In such case, in the root action
     * flow, you have to specify the locale manually or you will get an error.
     *
     * @see Controller
     * @param mixed $options Array of options
     * @return string URL generated from given $options
     * @author Szymon Wrozynski
     */
    function url_for($options=array())
    {
        if ((array) $options !== $options)
            $options = array($options);
        
        global $ROUTES, $CONTROLLER, $ACTION, $LOCALE, $RC, $RC_2;
        
        static $duo;
        
        if (!isset($duo))
        {
            if (isset($CONTROLLER, $ACTION))
                $duo =Application\Controller::instance()->default_url_options()
                    ?: false;
            else
            {
                $CONTROLLER = $ROUTES[0]['controller'];
                $ACTION = $ROUTES[0]['action'];
                $duo = false;
            }
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
                $options['name'] = 0;
            elseif ($options[0][0] === '/')
            {
                if (!isset($options['ssl']))
                    $options['ssl'] = $_SERVER['SERVER_PORT']==(SSL_PORT ?:443);
                        
                return ($options['ssl'] ? SSL_URL : HTTP_URL) . $options[0];        
            }
            elseif (strpos($options[0], '\\') > 0)
                $options['name'] = $RC_2[$options[0]];
            else
                $options['name'] = $RC[$CONTROLLER][$options[0]];
        }
        elseif (!isset($options['name']))
            $options['name'] = $RC[isset($options['controller'])
                ? $options['controller'] : $CONTROLLER]
                [isset($options['action']) ? $options['action'] : $ACTION];
        
        if (LOCALIZATION === true)
            $uri = '/' . (isset($options['locale'])
                ? $options['locale'] : $LOCALE[0]).$ROUTES[$options['name']][0];
        else
            $uri = $ROUTES[$options['name']][0];
        
        if (isset($options['anchor']))
            $uri .= '#' . $options['anchor'];
        
        if (isset($options['params']))
        {    
            if (isset($ROUTES[$options['name']]['pp']))
            {
                if ((array) $options['params'] !== $options['params'])
                {
                    $uri = str_replace(
                        ':' . $ROUTES[$options['name']]['pp'][0],
                        $options['params'],
                        $uri
                    );
                    unset($options['params']);
                }    
                else
                {
                    foreach ($ROUTES[$options['name']]['pp'] as $i => $pp)
                    {
                        if (isset($options['params'][$i]))
                        {
                            $uri = str_replace(":$pp", $options['params'][$i],
                                $uri);
                            unset($options['params'][$i]);
                        }
                        elseif (isset($options['params'][$pp]))
                        {
                            $uri = str_replace(":$pp", $options['params'][$pp],
                                $uri);
                            unset($options['params'][$pp]);
                        }
                    }
                }
            }
            if (!empty($options['params']))
                $uri .= '?' . http_build_query($options['params']);
        }
        
        if (isset($options['ssl']))
            return ($options['ssl'] ? SSL_URL : HTTP_URL) . $uri;
        elseif (isset($ROUTES[$options['name']]['ssl']))
            return ($ROUTES[$options['name']]['ssl'] ? SSL_URL : HTTP_URL).$uri;
        
        return HTTP_URL . $uri;
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
     * Reads or writes the instant message stored in the session. 
     * Once read it is discarded upon the next request. 
     * The message is stored under the given name.
     *
     * This function requires session to be enabled.
     * 
     * Examples:
     *
     * <code>
     * flash('notice', 'This is a notice.'); # saves the message
     * </code>
     *
     * <code>
     * echo flash('notice'); # gets the message - now it is marked as read
     * </code>
     *
     * @param string $name Message name
     * @param mixed $message Message (for writing) or null (for reading)
     * @return mixed Message (if reading) or null (if writing)
     * @author Szymon Wrozynski
     */
    function flash($name, $message=null)
    {   
        if ($message !== null)
            $_SESSION['__PRAGWORK_10_FLASH'][$name] = array($message, false);
        elseif (isset($_SESSION['__PRAGWORK_10_FLASH'][$name])) 
        {
            $_SESSION['__PRAGWORK_10_FLASH'][$name][1] = true;
            return $_SESSION['__PRAGWORK_10_FLASH'][$name][0];
        }
    }
    
    /**
     * Sends the HTTP error 403 - Forbidden. It renders the 403.php file from
     * the 'errors' directory and stops other processing. It is used if, for
     * example, a plain HTTP request was made to action required SSL protocol.
     *
     * @param bool $stop If true stops further execution and throws an exception
     * @throws {@link \Application\StopException} If true passed (default)
     * @author Szymon Wrozynski
     */
    function send_403($stop=true)
    {
        header('HTTP/1.1 403 Forbidden');
        require APPLICATION_PATH . DIRECTORY_SEPARATOR . 'errors'
            . DIRECTORY_SEPARATOR . '403.php';
        if ($stop)
            throw new \Application\StopException;
    }

    /**
     * Sends the HTTP error 404 - Not Found. It renders the 404.php file from
     * the 'errors' directory and stops other processing. It is used if, for
     * example, a request was made to an unknown resource.
     *
     * @param bool $stop If true stops further execution and throws an exception
     * @throws {@link \Application\StopException} If true passed (default)
     * @author Szymon Wrozynski
     */
    function send_404($stop=true)
    {
        header('HTTP/1.1 404 Not Found');
        require APPLICATION_PATH . DIRECTORY_SEPARATOR . 'errors' 
            . DIRECTORY_SEPARATOR . '404.php';
        if ($stop)
            throw new \Application\StopException;
    }

    /**
     * Sends the HTTP error 405 - Method Not Allowed. It renders the 405.php 
     * file from the 'errors' directory and stops other processing. It is used
     * if, for example, a request was made to the known resource but using 
     * a wrong HTTP method.
     *
     * @param bool $stop If true stops further execution and throws an exception
     * @throws {@link \Application\StopException} If true passed (default)
     * @author Szymon Wrozynski
     */
    function send_405($stop=true)
    {
        header('HTTP/1.1 405 Method Not Allowed');
        require APPLICATION_PATH . DIRECTORY_SEPARATOR . 'errors' 
            . DIRECTORY_SEPARATOR . '405.php';
        if ($stop)
            throw new \Application\StopException;
    }
    
    /**
     * Translates the given key according to the current locale loaded. 
     * If the translation was not found the given key is returned back.
     *
     * The key can be a string but it is strongly advised not to use
     * the escape characters like \ inside though it is technically possible. 
     * Instead, use double quotes to enclose single quotes and vice versa. 
     * This will help the <b>prag</b> tool to recognize such keys and maintain
     * locale files correctly. Otherwise, you will have to handle such keys by
     * hand. The same applies to compound keys evaluated dynamically.
     *
     * <code>
     * t('Editor\'s Choice');   # Avoid!
     * t($editor_msg);          # Avoid!
     * t("Editor's Choice");    # OK
     * </code>
     *
     * Pragwork requires the first entry (0th index) in the locale file
     * array contains the locale code therefore, by specifying <code>t(0)</code> 
     * or just <code>t()</code>, the current locale code is returned.
     * Also, if there is no locale loaded yet this will return 0 (the passed or
     * implied locale key). Such test against 0 (int) might be helpful while
     * translating and customizing error pages, where there is no certainty
     * that the locale code was parsed correctly (e.g. a 404 error).
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
     * Returns the array of strings with available locale codes based on
     * filenames found in the 'locales' directory. Filenames starting with
     * a dot <b>.</b> are omitted.
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
<?php
namespace Application;

abstract class Controller extends Singleton
{
	static $layout = null;	 
	static $before_filter = null;
	static $before_render_filter = null;
	static $after_filter = null;
	static $exception_filter = null;
	static $caches_page = null;
	static $caches_action = null;
	
	public $params;
	public $session;
	public $cookies;
	public $flash;
	public $request;
	public $response;
	public $action;
	public $controller;
	
	protected static $instance;
	
	private static $_content;
	private static $_ch_file;
	private static $_ch_dir;
	private static $_ch_layout;
	private static $_ch_if;
	private static $_rendered;
	private static $_ssl_url;
	private static $_http_url;
	private static $_cache;
	
	protected function __construct()
	{
		$class = get_class($this);
		do 
		{
			require HELPERS . str_replace('\\', DIRECTORY_SEPARATOR, substr($class, 12, -10)) . 'Helper.php';
		}
		while (($class = get_parent_class($class)) !== __CLASS__);
	}
	
	/**
	 * Resets all data of the current instance of the controller. It is handled
	 * automatically by the test environment.
	 */
	public final function clean_up()
	{
		self::$_content = null;
		self::$_ch_file = null;
		self::$_ch_dir = null;
		self::$_ch_layout = null;
		self::$_ch_if = null;
		self::$_rendered = null;
		self::$_http_url = null;
		self::$_ssl_url = null;
		self::$_cache = null;
		
		$_SERVER['SERVER_PORT'] = 80;
		
		if ($this->params)
			$this->params->clean_up();
			
		if ($this->session)
			$this->session->clean_up();
		
		if ($this->flash)
			$this->flash->clean_up();
		
		if ($this->cookies)
			$this->cookies->clean_up();
		
		if ($this->request)
			$this->request->clean_up();
		
		if ($this->response)
			$this->response->clean_up();
		
		static::$instance = null;
		$_SESSION = array();
		$_COOKIE = array();
	}
	
	public function process($request, $response)
	{
		$this->action = $action = $request->route['action'];
		$this->controller = $request->route['controller'];
		$config = Configuration::instance();
		
		self::$_ssl_url = $config->ssl_url();
		self::$_http_url = $config->http_url();
		self::$_cache = $config->cache;
		
		$this->request = $request;
		$this->response = $response;
		$this->params = Parameters::instance();
		$this->session = Session::instance();
		$this->flash = Flash::instance();
		$this->cookies = Cookies::instance();

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
				throw $e;
			}
		}
	}
	
	public function default_url_options() {}
	
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
		
		if ($this->response->storage->is_file($cached_page))
		{
			$this->response->storage->unlink($cached_page);
		
			while (($dir = dirname($cached_page)) !== '.')
			{
				$handle =& $this->response->storage->get_handle($dir);
				if (!empty($handle))
					break;
					
				$handle = null;
				$cached_page = $dir;
			}
		}
	}
	
	public function expire_action($options=array())
	{
		$key = url_for($options);
		$key = substr($key, strlen(($key[4] === 's') ? self::$_ssl_url : self::$_http_url));
		
		# if longer than 1 char (e.g. longer than '/')
		if (isset($key[1])) 
			$key = rtrim($key, '/.');
			
		$cached_dir = TEMP . 'ca_' . md5($key);
		
		if ($this->response->storage->is_dir($cached_dir))
			$this->response->storage->unlink($cached_dir);

		$cached_action = $cached_dir . '.cache';

		if ($this->response->storage->is_file($cached_action))
			$this->response->storage->storage->unlink($cached_action);
	}
	
	public function fragment_exists($options=array())
	{
		return $this->response->storage->is_file(self::fragment_file($options));
	}
	
	public function expire_fragment($options=array())
	{
		$fragment = self::fragment_file($options);
		if ($this->response->storage->is_file($fragment))
			$this->response->storage->unlink($fragment);
	}
	
	public function cache($options, $closure)
	{
		if (!self::$_cache)
			return $closure($this);
		
		$frag = self::fragment_file($options);
		
		if ($this->response->storage->is_file($frag))
			echo $this->response->storage->file_get_contents($frag);
		
		ob_start();
		$closure($this);
		$output = ob_get_clean();
		$this->response->storage->file_put_contents($frag, $output);
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
		if ($this->response->storage->is_dir(self::$_ch_dir))
		{
			foreach($this->response->storage->scandir(self::$_ch_dir) as $f)
			{
				self::$_content[$f] = $this->response->storage->file_get_contents(
					self::$_ch_dir . DIRECTORY_SEPARATOR . $file);
			}
		}
		
		$this->render(array(
			'text' => $this->response->storage->file_get_contents(self::$_ch_file),
			'layout' => true
		));
		
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
				if ($this->response->storage->is_file(self::$_ch_file))
					$this->render_cache_in_layout();
				
				self::$_ch_layout = self::resolve_layout($this->action);
				static::$layout = null;
			}
			elseif ($this->response->storage->is_file(self::$_ch_file))
			{
				echo $this->response->storage->file_get_contents(self::$_ch_file);
				throw new StopException;
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
				
			if (!$this->response->storage->is_dir($dir))
				$this->response->storage->mkdir($dir);
		}
		
		$this->response->storage->file_put_contents(self::$_ch_file, $this->response->body);
		
		if (self::$_ch_layout)
		{
			if (self::$_content)
			{
				if ($this->response->storage->is_dir(self::$_ch_dir))
				{
					foreach ($this->response->storage->scandir(self::$_ch_dir) as $f)
						$this->response->storage->unlink(self::$_ch_dir . DIRECTORY_SEPARATOR . $f);
				}
				else
					$this->response->storage->mkdir(self::$_ch_dir);
				
				foreach (self::$_content as $r => $c)
					$this->response->storage->file_put_contents(self::$_ch_dir . DIRECTORY_SEPARATOR . $r, $c);	   
			}
			
			ob_start();
			$this->render(array('text' => $this->response->body, 'layout' => self::$_ch_layout));
			$this->response->body = ob_get_clean();
		}
	}
	
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
			
			$this->response->template = str_replace(DIRECTORY_SEPARATOR, '\\', substr($template, strlen(VIEWS)));
			
			$layout = self::resolve_layout($this->action);
			
			if ($layout)
			{
				$this->response->layout = $layout;
				ob_start();
				require $template . '.php';
				self::$_content[0] = ob_get_clean();
				require VIEWS . 'layouts' . DIRECTORY_SEPARATOR . str_replace('\\',DIRECTORY_SEPARATOR,$layout) .'.php';
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
					{
						$this->render_partial(
							$partial,
							array($name => $item, $key_name => $key) + $options
						);
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
				
				$this->response->layout = $options['layout'];
				
				self::$_content[0] = $options['text'];
				require VIEWS . 'layouts' . DIRECTORY_SEPARATOR
					. str_replace('\\', DIRECTORY_SEPARATOR, $options['layout']) . '.php';
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
		
		$this->response->template = str_replace(DIRECTORY_SEPARATOR, '\\', substr($template, strlen(VIEWS)));
		
		if ($options['layout'])
		{
			$this->response->layout = $options['layout'];
			ob_start();
			require $template . '.php';
			self::$_content[0] = ob_get_clean();
			require VIEWS . 'layouts' . DIRECTORY_SEPARATOR 
				. str_replace('\\', DIRECTORY_SEPARATOR, $options['layout']) . '.php';
		}
		else
			require $template . '.php';
	}
	
	public function render_to_string($options=array())
	{
		ob_start();
		
		if (self::$_rendered)
			$str = $this->render($options);
		else
		{
			self::$_rendered = true;
			$str = $this->render($options);
			self::$_rendered = false;
		}
		
		return ob_get_clean() ?: $str;
	}
	
	private function render_partial($___path___, $___args___)
	{	
		foreach ($___args___ as $___n___ => $___v___) 
			$$___n___ = $___v___;
		
		require $___path___;
	}
	
	public function yield($region=0)
	{
		if (isset(self::$_content[$region]))
			return self::$_content[$region];
	}
	
	public function content_for($region, $closure)
	{
		ob_start();
		$closure($this);
		self::$_content[$region] = ob_get_clean();
	}
	
	private static final function resolve_layout($action)
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
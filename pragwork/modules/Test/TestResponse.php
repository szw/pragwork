<?php
namespace Test;

/**
 * Class encapsulating the controller's response details prepared on performing functional tests.
 * 
 * @package Test
 * @author Szymon Wrozynski
 */
class TestResponse extends \Application\Response
{	
	/**
	 * The template name used in the response (if any).
	 *
	 * @var mixed String or null
	 */
	public $template;
	
	/**
	 * The layout name used in the response (if any).
	 *
	 * @var mixed String or null
	 */
	public $layout;
	
	/**
	 * The storage simulating the 'temp' and 'public' directories while performing and action.
	 *
	 * @see Storage
	 * @var Storage
	 */
	public $storage;
	
	protected function __construct()
	{
		$this->storage = new Storage;
		$this->storage->add_location(TEMP);
	}
	
	/**
	 * Returns the TestResponse instance.
	 *
	 * @param bool $create If true and there is no response yet, the new instance will be created
	 * @return TestResponse
	 */
	public static function &instance($create=false)
	{
		if (!static::$instance && $create)
			static::$instance = new TestResponse;
		
		return static::$instance;
	}
	
	/**
	 * Destroys the TestResponse instance.
	 */
	public function clean_up()
	{
		static::$instance = null;
	}
	
	public function remove_header($name)
	{
		foreach ($this->headers as &$h)
		{
			if ($name === substr($h, 0, strpos($h, ':')))
				unset($h);
		}
	}
	
	public function headers_list()
	{
		return $this->headers;
	}
	
	public function render()
	{
		if ((string) $this->status === $this->status)
			$this->status = self::$http_codes_by_symbols[$this->status];
		
		if (($this->status > 300) && ($this->status < 400))
		{
			$this->add_header("Location: $this->location");
			return;
		}
		elseif (($this->status >= 400) && ($this->status < 500) && !$this->body)
		{
			$file = APPLICATION . DIRECTORY_SEPARATOR . 'errors' . DIRECTORY_SEPARATOR . $this->status . '.php';
			
			if (is_file($file))
			{
				ob_start();
				require $file;
				$this->body = ob_get_clean();
			}
		}
		elseif ($this->status >= 500)
			$this->body = $this->error_500();
		
		$ctype = "Content-Type: $this->content_type";
		
		if ($this->charset)
			$ctype .= "; charset=$this->charset";
		
		$this->add_header($ctype);
	}
}
?>
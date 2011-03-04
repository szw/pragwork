<?php
namespace Application;

/**
 * Contains information about the response being generated (headers, status, body).
 *
 * @author Szymon Wrozynski
 * @package Application
 */
class Response extends Singleton
{
	protected static $http_codes_by_symbol = array(
		'continue' => 100,
		'switching_protocols' => 101,
		'processing' => 102, 
		'ok' => 200, 
		'created' => 201, 
		'accepted' => 202, 
		'non_authoritative_information' => 203, 
		'no_content' => 204, 
		'reset_content' => 205, 
		'partial_content' => 206, 
		'multi_status' => 207, 
		'im_used' => 226, 
		'multiple_choices' => 300, 
		'moved_permanently' => 301, 
		'found' => 302, 
		'see_other' => 303, 
		'not_modified' => 304, 
		'use_proxy' => 305, 
		'temporary_redirect' => 307, 
		'bad_request' => 400, 
		'unauthorized' => 401, 
		'payment_required' => 402, 
		'forbidden' => 403, 
		'not_found' => 404, 
		'method_not_allowed' => 405, 
		'not_acceptable' => 406, 
		'proxy_authentication_required' => 407, 
		'request_timeout' => 408, 
		'conflict' => 409, 
		'gone' => 410, 
		'length_required' => 411, 
		'precondition_failed' => 412, 
		'request_entity_too_large' => 413, 
		'request_uri_too_long' => 414, 
		'unsupported_media_type' => 415, 
		'requested_range_not_satisfiable' => 416, 
		'expectation_failed' => 417, 
		'unprocessable_entity' => 422, 
		'locked' => 423, 
		'failed_dependency' => 424, 
		'upgrade_required' => 426, 
		'internal_server_error' => 500, 
		'not_implemented' => 501, 
		'bad_gateway' => 502, 
		'service_unavailable' => 503, 
		'gateway_timeout' => 504, 
		'http_version_not_supported' => 505, 
		'insufficient_storage' => 507, 
		'not_extended' => 510, 
	);
	
	protected static $http_codes = array(
		100 => 'Continue', 
		101 => 'Switching Protocols', 
		102 => 'Processing', 
		200 => 'OK', 
		201 => 'Created', 
		202 => 'Accepted', 
		203 => 'Non-Authoritative Information', 
		204 => 'No Content', 
		205 => 'Reset Content', 
		206 => 'Partial Content', 
		207 => 'Multi-Status', 
		226 => 'IM Used', 
		300 => 'Multiple Choices', 
		301 => 'Moved Permanently', 
		302 => 'Found', 
		303 => 'See Other', 
		304 => 'Not Modified', 
		305 => 'Use Proxy', 
		307 => 'Temporary Redirect', 
		400 => 'Bad Request', 
		401 => 'Unauthorized', 
		402 => 'Payment Required', 
		403 => 'Forbidden', 
		404 => 'Not Found', 
		405 => 'Method Not Allowed', 
		406 => 'Not Acceptable', 
		407 => 'Proxy Authentication Required', 
		408 => 'Request Timeout', 
		409 => 'Conflict', 
		410 => 'Gone', 
		411 => 'Length Required', 
		412 => 'Precondition Failed', 
		413 => 'Request Entity Too Large', 
		414 => 'Request-URI Too Long', 
		415 => 'Unsupported Media Type', 
		416 => 'Requested Range Not Satisfiable', 
		417 => 'Expectation Failed', 
		422 => 'Unprocessable Entity', 
		423 => 'Locked', 
		424 => 'Failed Dependency', 
		426 => 'Upgrade Required', 
		500 => 'Internal Server Error', 
		501 => 'Not Implemented', 
		502 => 'Bad Gateway', 
		503 => 'Service Unavailable', 
		504 => 'Gateway Timeout', 
		505 => 'HTTP Version Not Supported', 
		507 => 'Insufficient Storage', 
		510 => 'Not Extended', 
	);
	
	/**
	 * The status code of the response. The available statuses are:
	 *
	 * <ul>
	 * <li>continue (100)</li>
	 * <li>switching_protocols (101)</li>
	 * <li>processing (102)</li> 
	 * <li>ok (200)</li> 
	 * <li>created (201)</li> 
	 * <li>accepted (202)</li> 
	 * <li>non_authoritative_information (203)</li> 
	 * <li>no_content (204)</li> 
	 * <li>reset_content (205)</li> 
	 * <li>partial_content (206)</li> 
	 * <li>multi_status (207)</li> 
	 * <li>im_used (226)</li> 
	 * <li>multiple_choices (300)</li> 
	 * <li>moved_permanently (301)</li> 
	 * <li>found (302)</li> 
	 * <li>see_other (303)</li> 
	 * <li>not_modified (304)</li> 
	 * <li>use_proxy (305)</li> 
	 * <li>temporary_redirect (307)</li> 
	 * <li>bad_request (400)</li> 
	 * <li>unauthorized (401)</li> 
	 * <li>payment_required (402)</li> 
	 * <li>forbidden (403)</li> 
	 * <li>not_found (404)</li> 
	 * <li>method_not_allowed (405)</li> 
	 * <li>not_acceptable (406)</li> 
	 * <li>proxy_authentication_required (407)</li> 
	 * <li>request_timeout (408)</li> 
	 * <li>conflict (409)</li> 
	 * <li>gone (410)</li> 
	 * <li>length_required (411)</li> 
	 * <li>precondition_failed (412)</li> 
	 * <li>request_entity_too_large (413)</li> 
	 * <li>request_uri_too_long (414)</li> 
	 * <li>unsupported_media_type (415)</li> 
	 * <li>requested_range_not_satisfiable (416)</li> 
	 * <li>expectation_failed (417)</li> 
	 * <li>unprocessable_entity (422)</li> 
	 * <li>locked (423)</li> 
	 * <li>failed_dependency (424)</li> 
	 * <li>upgrade_required (426)</li> 
	 * <li>internal_server_error (500)</li> 
	 * <li>not_implemented (501)</li> 
	 * <li>bad_gateway (502)</li> 
	 * <li>service_unavailable (503)</li> 
	 * <li>gateway_timeout (504)</li> 
	 * <li>http_version_not_supported (505)</li> 
	 * <li>insufficient_storage (507)</li> 
	 * <li>not_extended (510)</li>
	 * </ul>
	 *
	 * @var mixed Int or symbolic string
	 */
	public $status = 200;
	
	/**
	 * The content type of the response.
	 *
	 * @var string
	 */
	public $content_type = 'text/html';
	
	/**
	 * The charset of the content (default utf-8);
	 *
	 * @var string
	 */
	public $charset = 'utf-8';
	
	/**
	 * The string containg the output rendered while performing an action.
	 *
	 * @var mixed String or null
	 */
	public $body;
	
	/**
	 * The URL of the redirection (if any).
	 *
	 * @var mixed String or null
	 */
	public $location;
	
	/**
	 * The exception occured (if any).
	 *
	 * @var \Exception
	 */
	public $exception;
	
	protected static $instance;
	protected $headers = array();
	
	/**
	 * Renders the generated response (sends headers and print out the body or an error template).
	 */
	public function render()
	{
		if ((string) $this->status === $this->status)
			$this->status = self::$http_codes_by_symbol[$this->status];
		
		header(((strpos(PHP_SAPI, 'cgi') === 0) ? 'Status: ' : 'HTTP/1.1 ') 
			. $this->status . ' ' . self::$http_codes[$this->status]);
		
		if (($this->status > 300) && ($this->status < 400))
		{
			header("Location: $this->location");
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
		
		foreach ($this->headers as $h)
			header($h, false);
		
		$ctype = "Content-Type: $this->content_type";
		
		if ($this->charset)
			$ctype .= "; charset=$this->charset";
		
		header($ctype);
		
		echo $this->body;
	}
	
	/**
	 * Returns the full HTTP status string of the current response.
	 *
	 * @return string
	 */
	public function full_status()
	{
		return self::resolve_full_status($this->status);
	}
	
	/**
	 * Returns the code (<code>int</code>) of the HTTP status of the current response.
	 *
	 * @return int
	 */
	public function status_code()
	{
		return ((string) $this->status === $this->status) 
			? self::$http_codes_by_symbol[$this->status] : $this->status;
	}
	
	/**
	 * Returns the full HTTP status string basing on passed status.
	 *
	 * @see $status
	 * @params mixed $status Symbolic string or int
	 * @return string The full HTTP status string
	 */
	public static function resolve_full_status($status)
	{
		if ((string) $status === $status)
			$status = self::$http_codes_by_symbol[$status];
		
		return $status . ' ' . self::$http_codes[$status];
	}
	
	/**
	 * Adds a raw HTTP header to send (just like the <code>header()</code> function).
	 *
	 * @param string $string The header string
	 * @param bool $replace If true replaces the previously added similar 
	 *	   headers with the current one instead of appending.
	 * @params mixed $status Optional HTTP status
	 */
	public function add_header($string, $replace=true, $status=null)
	{
		if ($status)
			$this->status = $status;
		
		if ($replace)
			$this->remove_header(substr($string, strpos($string, ':')));
		
		$this->headers[] = $string;
	}
	
	/**
	 * Removes similar headers (they will not be sent).
	 *
	 * @param string $name The header name
	 */
	public function remove_header($name)
	{
		foreach ($this->headers as &$h)
		{
			if ($name === substr($h, 0, strpos($h, ':')))
				unset($h);
		}
		header_remove($name);
	}
	
	/**
	 * Returns the list of headers ready to sending.
	 *
	 * @return array
	 */
	public function headers_list()
	{
		return array_merge(headers_list(), $this->headers);
	}
	
	protected function error_500()
	{
		$e = $this->exception;
		$date = "Date/Time: " . date('Y-m-d H:i:s');
		
		if (strpos(Configuration::instance()->environment, 'production') !== false) 
		{
			error_log(get_class($e) . ': ' . $e->getMessage() . ' at line ' . $e->getLine() 
				. ' in file ' . $e->getFile() . PHP_EOL . $date . PHP_EOL . 'Stack trace:' . PHP_EOL
				. $e->getTraceAsString() . PHP_EOL . '------------------------------' . PHP_EOL,
				3, TEMP . 'errors.log');
			ob_start();
			require APPLICATION . DIRECTORY_SEPARATOR . 'errors' . DIRECTORY_SEPARATOR . '500.php';
			return ob_get_clean();
		}
		
		$result = '<p>' . get_class($e) . ': <b>' . $e->getMessage() . '</b> at line ' 
			. $e->getLine() . ' in file ' . $e->getFile() . '. ' . $date . '</p>';
			
		$app_path_cut_point = strlen(realpath(APPLICATION)) + 1;
			
		$trace = $e->getTrace();
		array_pop($trace); # remove the last entry (public/index.php)
		
		$traces = '';
		
		foreach ($trace as $entry)
		{
			# ignore if the entry neither has 'file' nor 'line' keys
			if (!isset($entry['file'], $entry['line']))
				continue;
				
			$file = substr($entry['file'], $app_path_cut_point);
				
			# omit the modules
			if (strpos($file, 'modules') === 0)
				continue;
				
			$traces .= '<li><b>' . $file . ':' . $entry['line'] . '</b> &mdash; ';
					
			if (isset($entry['class']) && $entry['class'])
				$traces .= 'method: <i>' . $entry['class'] . $entry['type'];
			else
				$traces .= 'function: <i>';
					
			$traces .= $entry['function'] . '(' . implode(', ', array_map(function($a) {
				if (($a === null) || ((bool) $a === $a))
					return gettype($a);
				elseif ((object) $a === $a)
					return get_class($a);
				elseif ((string) $a === $a)
					return "'$a'";
				else
					return strval($a);
				}, $entry['args'])) . ')</i></li>';
		}
		
		if ($traces)
			$result .= "<p>Local trace:<ol>$traces</ol></p>";
		
		return $result;
	}
}
?>
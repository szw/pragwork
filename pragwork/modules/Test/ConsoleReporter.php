<?php
namespace Test;

class ConsoleReporter extends Reporter
{
	private static $colors = array(
		'red' => "\033[31m",
		'green' => "\033[32m",
		'blue' => "\033[34m",
		'yellow' => "\033[33m",
		'default' => "\033[0m"
	);
	
	private $use_color = USE_COLOR;
	
	public function enable_color() 
	{
		$this->use_color = true;
	}
	
	protected function report_test_pass() 
	{
		echo $this->wrap('.', 'green');
	}
	
	protected function report_test_fail(AssertionFailed $eaf) 
	{
		echo $this->wrap('F', 'red');
	}
	
	protected function report_test_error(\Exception $e) 
	{
		echo $this->wrap('E', 'red');	
	}
	
	protected function print_small_trace($e)
	{
		$app_path_cut_point = strlen(realpath(APPLICATION)) + 1;
		$trace = $e->getTrace();
		$i = 1;
		
		foreach ($trace as $entry)
		{
			# ignore if the entry neither has 'file' nor 'line' keys
			if (!isset($entry['file'], $entry['line']))
				continue;
			
			if (strrpos($entry['file'], DIRECTORY_SEPARATOR . 'prag') 
				=== strlen($entry['file']) - strlen(DIRECTORY_SEPARATOR . 'prag'))
				continue;
			
			$file = substr($entry['file'], $app_path_cut_point);
				
			# omit the modules
			if (strpos($file, 'modules') === 0)
				continue;
				
			echo "$i. $file:", $entry['line'], ' - ';
					
			if (isset($entry['class']) && $entry['class'])
				echo 'method: ', $entry['class'], $entry['type'];
			else
				echo 'function: ';
					
			echo $entry['function'], '(', implode(', ', array_map(function($a) {
				if (($a === null) || ((bool) $a === $a))
					return gettype($a);
				elseif ((object) $a === $a)
					return get_class($a);
				elseif ((string) $a === $a)
					return "'$a'";
				else
					return strval($a);
			}, $entry['args'])), ')';
			echo "\n";
			$i++;
		}
	}
	
	protected function report_summary() 
	{
		echo "\n";
		
		foreach ($this->incidents as $e) 
		{
			echo "\n";
			$message = $e->getMessage() ? $e->getMessage() : '(no message)';
			
			if ($e instanceof AssertionFailed) 
				echo "Failure: $message\n";
			else 
			{
				$class = get_class($e);
				echo "Error: $class {$message}\n";
			}
			
			$this->print_small_trace($e);
		}
		
		echo "\nSummary: ";
		
		echo $this->wrap_by_success("{$this->test_passes}/{$this->test_total} tests passed",
			$this->test_passes,	$this->test_total);
		echo ", ";
		echo $this->wrap_by_success("{$this->assert_passes}/{$this->assert_total} assertions",
			$this->assert_passes, $this->assert_total);
		
		echo sprintf("\n%fs\n", $this->exec_time);
	}
	
	private function wrap($string, $color) 
	{
		return $this->use_color ? self::$colors[$color] . $string . self::$colors['default'] : $string;
	}
	
	private function wrap_by_success($string, $success, $total) 
	{
		return $this->wrap($string, $success == $total ? 'green' : 'yellow');
	}
}
?>
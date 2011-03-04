<?php
namespace Test;

class TestSuite
{
	private $name;
	private $tests	= array();
	
	public function __construct($name) 
	{
		$this->name = $name;	
	}
	
	public function require_all($dir, $extensions=array('php')) 
	{
		$ext_match = '/\.(' . implode('|', $extensions) . ')$/'; 
		$dir = APPLICATION . DIRECTORY_SEPARATOR . 'test' . DIRECTORY_SEPARATOR . $dir;
		$stack = array($dir);
		while (count($stack)) 
		{
			$dir = array_pop($stack);
			$dh = opendir($dir);
			while (($file = readdir($dh)) !== false) 
			{
				if ($file[0] == '.') 
					continue;
				
				$fqd = $dir . DIRECTORY_SEPARATOR . $file;
				
				if (is_dir($fqd)) 
					$stack[] = $fqd;
				elseif (preg_match($ext_match, $fqd)) 
					require_once $fqd;
			}
			closedir($dh);
		}
	}
	
	public function auto_fill() 
	{
		$test_case = new \ReflectionClass('Test\\TestCase');
		foreach (get_declared_classes() as $class_name) 
		{
			$r = new \ReflectionClass($class_name);
			
			if ($r->isSubclassOf($test_case) && !$r->isInterface() && !$r->isAbstract()) 
				$this->add_test(new $class_name);	
		}
	}
	
	public function add_test(TestCase $test) 
	{
		$this->tests[] = $test;
	}
	
	public function run(Reporter $reporter=null) 
	{
		if (!$reporter)
			$reporter = new ConsoleReporter;
		
		if (!$this->tests)
			$this->auto_fill();
		
		$reporter->start();
		
		foreach ($this->tests as $test) 
			$test->run($reporter);
		
		$reporter->end();
		$reporter->summary();
	}
}
?>
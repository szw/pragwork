<?php
namespace Test;

class MockMethodSpecification
{
	private $mock;
	private $pattern;
	private $closure;
	
	public function __construct(MockSpecification $mock, $pattern) 
	{
		$this->mock = $mock;
		$this->pattern = $pattern;
	}
	
	public function get_pattern() 
	{
		return $this->pattern;
	}
	
	public function get_closure() 
	{
		return $this->closure;
	}
	
	public function returning($thing) 
	{
		if ($thing instanceof Closure)
			$this->closure = $thing;
		
		return $this;
	}
	
	public function back() 
	{
		return $this->mock;
	}
	
	public function __call($method, $args) 
	{
		return call_user_func_array(array($this->mock, $method), $args);
	}
}
?>
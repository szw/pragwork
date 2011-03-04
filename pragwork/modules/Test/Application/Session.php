<?php
namespace Application;

class Session extends Store
{
	protected static $instance;

	protected function __construct()
	{
		parent::__construct($_SESSION);
	}

	public function kill()
	{
		$_SESSION = array();
	}
}
?>
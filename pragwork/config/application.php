<?php
date_default_timezone_set('Europe/Warsaw');

Application\Configuration::initialize(function($config) 
{
	$config->environment = 'development';
});
?>
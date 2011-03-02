<?php
ActiveRecord\Configuration::initialize(function($config) 
{
	$config->connection = array(
		'development' => 'mysql://pragwork:secret@localhost/pragwork_development?charset=utf8',
		'test' => 'mysql://pragwork:secret@localhost/pragwork_test?charset=utf8',
		'production' => 'mysql://pragwork:secret@localhost/pragwork_production?charset=utf8'
	);
});
?>
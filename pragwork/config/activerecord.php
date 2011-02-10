<?php
ActiveRecord\Config::initialize(function($cfg) 
{
    $cfg->set_connections(array(
        'development' => 'mysql://pragwork:secret@localhost/pragwork?charset=utf8',
        'production' => 'mysql://pragwork:secret@localhost/pragwork?charset=utf8'
    ));
    $cfg->set_default_connection('development');
});
?>
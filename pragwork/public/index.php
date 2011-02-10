<?php
# PRAGWORK SETTINGS
const LIVE = false;

const APPLICATION_PATH = '/Users/sw/Dropbox/Projekty/pragwork/git-repo/Pragwork/pragwork';
const SERVER_PATH = null;
const HTTP_PORT = null;
const SSL_PORT = null;

const IMAGES_PATH = '/images';
const JAVASCRIPTS_PATH = '/javascripts';
const STYLESHEETS_PATH = '/stylesheets';

const LOCALIZATION = false;
const SESSION = true;
const CACHE = false;

date_default_timezone_set('Europe/Warsaw');

# Start request processing ##################################################### 

define('MODULES', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'modules'
    . DIRECTORY_SEPARATOR);
require MODULES . 'application.php';

Application\start();
?>
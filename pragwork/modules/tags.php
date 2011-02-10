<?php
/**
 * Tags Module 1.0 for Pragwork 1.0.2.1
 *
 * @copyright Copyright (c) 2009-2011 Szymon Wrozynski
 * @license Licensed under the MIT License
 * @version 1.0.2.1
 * @package Tags
 */

namespace
{
    /**
     * Creates the <a> tag from the passed text and options. 
     * The text is used as the inner text of the link. It might be a plain text
     * or other HTML code. The options are used to construct the URL for the
     * link (see {@link url_for} for syntax details). All other options left are 
     * appended to the constructed tag as its attributes.
     *
     * <code>
     * echo link_to('link 1', 'index');
     *
     * # <a href="http://www.mydomain.com/shop/index">link 1</a>;
     *
     * echo link_to('link 2', array(
     *     'action' => 'add', 
     *     'controller' => 'Shop', 
     *     'anchor' => 'foo', 
     *     'class' => 'my-link'
     * ));
     *
     * # <a href="http://www.mydomain.com/shop/add#foo" class="my-link">
     * # link 2</a>
     * </code>
     *
     * @see link_to_url
     * @see url_for
     * @param string $text Inner text of the link
     * @param mixed $options Options for URL and attributes
     * @return string <a> HTML tag
     * @author Szymon Wrozynski
     */
    function link_to($text, $options=array())
    {
        if ((array) $options !== $options)
            return link_to_url($text, url_for($options));
        
        $url = url_for($options);
        
        unset(
            $options['params'], 
            $options[0],
            $options['name'],
            $options['ssl'], 
            $options['anchor'],
            $options['locale'],
            $options['action'], 
            $options['controller']
        );
        
        return link_to_url($text, $url, $options);
    }
    
    /**
     * Creates the <a> tag from the passed text, URL, and options. 
     * The text is used as the inner text of the link. It might be a plain text
     * or other HTML code. The URL is placed in the 'href' attribute. 
     * Options are appended to the constructed tag as its attributes.
     *
     * <code>
     * echo link_to_url('Pragwork', 'http://pragwork.com');
     *
     * # <a href="http://pragwork.com">Pragwork</a>
     *
     * echo link_to_url('Pragwork', 'http://pragwork.com', array(
     *     'class' => 'my-link'
     * ));
     *
     * # <a href="http://pragwork.com" class="my-link">Pragwork</a>
     * </code>
     *
     * @see link_to
     * @param string $text Inner text of the link
     * @param string $url URL used to create the hiperlink
     * @param array $options Attributes
     * @return string <a> HTML tag
     * @author Szymon Wrozynski
     */
    function link_to_url($text, $url, $options=array())
    {
        $html = '<a href="' . $url . '"';
        
        foreach ($options as $n => $v)
            $html .= ' ' . $n . '="' . $v . '"';
        
        return $html . '>' . $text . '</a>';
    }
    
    /**
     * Creates the one button form (An <input> tag enclosed in a
     * <form>). The text is used as the value of the button.
     * The options are used to construct the URL for the
     * link (see {@link url_for} for syntax details). 
     * However, there are special options:
     * 
     * <ul>
     * <li><b>method</b>: HTTP method for the form (default: POST)</li>
     * <li><b>confirm</b>: confirmation message (default: null)</li>
     * <li><b>hidden_fields</b>: (array) adds hidden fields to the form</li>
     * </ul>
     *
     * If the HTTP GET method is used then all query parameters are abandoned
     * because the new query string is created automatically from form fields
     * upon form sending. Therefore you should specify custom parameters as
     * 'hidden_fields' in such case.
     *
     * All other options left are appended to the <input> tag as its
     * attributes. The possible confirm message is used to construct a
     * javascript confirm dialog. All quotes in the message are safely encoded.
     *
     * The <form> tag has a special class - 'button-to'. The <input>
     * can have the class defined explicitly in the options.
     * 
     * <code>
     * echo button_to('button 1', 'index');
     *
     * # <form class="button-to" action="http://www.mydomain.com/shop/index"
     * # method="post"><input type="submit" 
     * # value="button 1" /></form>
     * 
     * echo button_to('button 2', array(
     *     'action' => 'add', 
     *     'controller' => 'Shop',  
     *     'method' => 'get',
     *     'class' => 'my-button'
     * ));
     *
     * # <form class="button-to" action="http://www.mydomain.com/shop/add"
     * # method="get"><input type="submit" value="button 2"
     * # class="my-button"/></form>
     *
     * echo button_to('button 3', array('delete', 'params' => array(':id' => 3),
     *     'confirm' => 'Are you sure?'));
     *
     * # <form class="button-to"
     * # action="http://www.mydomain.com/shop/delete/3" method="post"
     * # onSubmit="return confirm('Are you sure?');">
     * # <input type="submit" value="button 1" /></form>
     * </code>
     *
     * @see button_to_url
     * @see url_for
     * @param string $text Value of the <submit> tag
     * @param mixed $options Options for URL and attributes
     * @return string One button <form> tag
     * @author Szymon Wrozynski
     */
    function button_to($text, $options=array())
    {
        if ((array) $options !== $options)
            return button_to_url($text, url_for($options));
        
        $url = url_for($options);
        
        unset(
            $options['params'], 
            $options[0],
            $options['name'],
            $options['ssl'], 
            $options['anchor'],
            $options['locale'],
            $options['action'], 
            $options['controller']
        );
        
        return button_to_url($text, $url, $options);
    }
    
    /**
     * Creates the one button form (An <input> tag enclosed in a
     * <form>). The text is used as the value of the button.
     * The URL serves as the form action. There are special options:
     * <b>method</b>, <b>confirm</b>, and <b>hidden_fields</b> described here:
     * {@link button_to}. Other options are appended to the <input> tag 
     * as its attributes.
     *
     * @see button_to
     * @see link_to_url
     * @param string $text Value of the button
     * @param string $url Form action
     * @param array $options Options and attributes
     * @return string One button <form> tag
     * @author Szymon Wrozynski
     */
    function button_to_url($text, $url, $options=array())
    {
        $form = '<form class="button-to" action="' . $url . '" method="';
        
        if (isset($options['method']))
        {
            $form .= $options['method'];
            unset($options['method']);
        }
        else
            $form .= 'post';
        
        if (isset($options['confirm']))
        {
            $form .= '" onSubmit="return confirm(\'' 
                . str_replace(
                    array('\'', '"'), 
                    array('\\x27', '\\x22'), 
                    $options['confirm']
                ) . '\');';
            
            unset($options['confirm']);
        }
        
        $form .= '">';
        
        if (isset($options['hidden_fields']))
        {
            foreach ($options['hidden_fields'] as $n => $v)
                $form .= '<input type="hidden" name="' . $n . '" value="' 
                    . $v . '" />';
            unset($options['hidden_fields']);
        }
        
        $form .= '<input type="submit" value="' . $text . '" ';
        
        foreach ($options as $n => $v)
            $form .= $n . '="' . $v . '" ';
        
        return $form . '/></form>';
    }
    
    /**
     * Creates a form for a model. The model might be an object (usually 
     * {@link ActiveRecord\Model} or {@link ActiveRecord\TablelessModel} 
     * instance), an array, or a null value. If the array is passed it is
     * automatically cast to an object (stdClass). Although the model is not
     * necessary, the form can work with it internally if present. Also, model
     * values are present in form fields and as form properties.
     *
     * The options are used to construct a form action URL (see {@link url_for}
     * for syntax details). The closure should be a function with one 
     * or two arguments. The first parameter is the {@link Tags\Form} instance.
     * The second one is the instance of current controller. That way you can
     * make the controller context ($this) available inside the closure.
     * All other options are parsed as the <form> tag attributes. 
     * By default, the form method is equal to 'post' and the 'accept-charset'
     * is set to 'utf-8'.
     * 
     * The form body is constructed within the $closure function and it 
     * uses an instance of the helper class {@link Tags\Form}.
     *
     * <code>
     * <?php echo form_for($this->person, 'update', function($f) { ?>
     *
     * <p>
     *     <?php echo $f->label('name', 'Name') ?>
     *     <?php echo $f->text_field('name', array('size' => 60)) ?>
     *     <?php echo $f->error_messages('name', array('wrap_in' => 'p', 
     *         'class' => 'error')) ?>
     * </p>
     *
     * <p>
     *     <?php echo $f->submit('Save', array('class' => 'button')) ?>
     * </p>
     *
     * <?php }) ?>
     * </code>
     *
     *
     * Example with two parameters used in the closure:
     *
     * <code>
     * <?php echo form_for(null, 'search', function($f, $that) { ?>
     *     <p>Last search: <?php echo $that->session->last_search ?></p>
     *     <p><?php echo $f->text_field('q') ?></p>
     * <?php }) ?>
     * </code>
     *
     * @see ActiveRecord\Model
     * @see ActiveRecord\TablelessModel
     * @see Tags\Form
     * @see form_for_url
     * @param mided $model Model corresponding with the form or null
     * @param mixed $options Array or string used to construct the form action
     * @param \Closure $closure Form body constructing closure
     * @return string <form> HTML tag
     * @author Szymon Wrozynski
     */
    function form_for($model, $options, $closure)
    {
        if ((array) $options !== $options)
            return form_for_url($model, url_for($options), null, $closure);
        
        $url = url_for($options);
        
        unset(
            $options['params'], 
            $options[0],
            $options['name'],
            $options['ssl'], 
            $options['anchor'],
            $options['locale'],
            $options['action'], 
            $options['controller']
        );
        
        return form_for_url($model, $url, $options, $closure);
    }
    
    /**
     * Creates a form for a model. The model might be an object (usually 
     * {@link ActiveRecord\Model} or {@link ActiveRecord\TablelessModel} 
     * instance), an array, or a null value. If the array is passed it is
     * automatically cast to an object (stdClass). Although the model is not
     * necessary, the form can work with it internally if present. Also, model
     * values are present in form fields and as form properties. 
     * The URL is used as the form action.
     *
     * @see form_for
     * @param mixed $model Model corresponding with the form or null
     * @param string $url Form action
     * @param mixed $options Form attributes or null to use default ones
     * @param \Closure $closure Form body constructing closure
     * @return string <form> HTML tag
     * @author Szymon Wrozynski
     */
    function form_for_url($model, $url, $options, $closure)
    {   
        $html = '<form action="' . $url . '"';
        
        if (isset($options['confirm']))
        {
            $html .= ' onSubmit="return confirm(\'' 
                . str_replace(
                    array('\'', '"'), 
                    array('\\x27', '\\x22'), 
                    $options['confirm']
                ) . '\');"';
            unset($options['confirm']);
        }
            
        if (!isset($options['method']))
            $html .= ' method="post"';
            
        if (!isset($options['accept-charset']))
            $html .= ' accept-charset="utf-8"';
        
        if ($options)
        {
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
        }
        
        ob_start();
        $closure(new Tags\Form($model), Application\Controller::instance());
        return $html . '>' . ob_get_clean() . '</form>';
    }
    
    /**
     * Creates a 'mailto' link for the specified email and options. 
     * The following options are available:
     *
     * <ul>
     * <li><b>text</b>: The text to be displayed within the created 
     *     hyperlink. If not specified, the $email will be used.</li>
     * <li><b>replace_at</b>: sets a replacement for the '@' sign, 
     *     to obfuscate the email address displayed if there is no custom text
     *     for the link</li>
     * <li><b>replace_dot</b>: same as above but obfuscates all dots in the 
     *     email address</li>
     * <li><b>subject</b>: sets the subject line of the email</li>
     * <li><b>body</b>: sets the body of the email</li>
     * <li><b>cc</b>: sets Carbon Copy recipients on the email</li>
     * <li><b>bcc</b>: sets Blind Carbon Copy recipients on the email</li>
     * </ul>
     *
     * Other options are appended to the <a> tag as its attributes.
     *
     * @see link_to_url
     * @param string $email Email address to use
     * @param array $options Options and attributes
     * @return string <a> tag with a 'mailto' reference
     * @author Szymon Wrozynski
     */
    function mail_to($email, $options=array())
    {
        if (isset($options['text']))
        {
            $text = $options['text'];
            unset($options['text']);
        }
        else
        {
            $text = $email;
            
            if (isset($options['replace_at']))
            {
                $text = str_replace('@', $options['replace_at'], $text);
                unset($options['replace_at']);
            }
            
            if (isset($options['replace_dot']))
            {
                $text = str_replace('.', $options['replace_dot'], $text);
                unset($options['replace_dot']);
            }
        }
        
        $params = array();
        
        if (isset($options['subject']))
        {
            $params['subject'] = $options['subject'];
            unset($options['subject']);
        }
        
        if (isset($options['body']))
        {
            $params['body'] = $options['body'];
            unset($options['body']);
        }
        
        if (isset($options['cc']))
        {
            $params['cc'] = $options['cc'];
            unset($options['cc']);
        }
        
        if (isset($options['bcc']))
        {
            $params['bcc'] = $options['bcc'];
            unset($options['bcc']);
        }
        
        $url = 'mailto:' . $email;
        
        if ($params)
            $url .= '?' .  str_replace('+', '%20', http_build_query($params));
        
        return link_to_url($text, $url, $options);    
    }
    
    /**
     * Returns the <img> tag with the URL to the static image according 
     * to file specified as the parameter. If the $file starts with ('/') it
     * is treated as it would reflect the public directory structure. 
     * Otherwise, the file is get along to the IMAGES_PATH constant defined in
     * the 'index.php' file. The path defined there can be a local public
     * directory like '/images' or even a standalone server  
     * (e.g. 'http://static.mydomain.com/images'). Also the $file can be an 
     * independent full URL address:
     *
     * <code>
     * <?php echo image_tag('http://static.mydomain.com/images/my_logo.png') ?>
     * </code>
     *
     * @see url_for
     * @param string $file Image file name or path
     * @param array $options HTML attributes appended to the <img> tag
     * @return string <img> HTML tag
     * @author Szymon Wrozynski
     */
    function image_tag($file, $options=array())
    {
        $html = '<img src="' . Tags\_asset_url(IMAGES_PATH, $file) . '"';
        
        foreach ($options as $n => $v)
            $html .= ' '. $n . '="' . $v . '"';
        
        return $html . ' />';
    }
    
    /**
     * Returns the <link> tag with the URL to the CSS file according 
     * to specified parameter. If the $file starts with ('/') it is
     * treated as it would reflect the public directory structure.
     * Otherwise the file is get along to the STYLESHEETS_PATH constant defined
     * in the 'index.php' file. The path defined there can be a local public
     * directory like '/stylesheets' or even a standalone server 
     * (e.g. 'http://static.mydomain.com/stylesheets').
     *
     * @see url_for     
     * @param string $file CSS file name or path
     * @param array $options HTML attributes appended to the <link> tag
     * @return string <link> HTML tag
     * @author Szymon Wrozynski
     */
    function stylesheet_link_tag($file, $options=array())
    {       
        $html = '<link rel="stylesheet" href="'
            . Tags\_asset_url(STYLESHEETS_PATH, $file) . '"';
            
        if (!isset($options['type']))
            $html .= ' type="text/css"';
        
        if (!isset($options['media']))
            $html .= ' media="screen"';
                    
        foreach ($options as $n => $v)
            $html .= ' ' . $n . '="' . $v . '"';
        
        return $html . ' />';
    }
    
    /**
     * Returns the <script> tag with the URL to the javascript file 
     * according to specified parameter. If the $file starts with ('/') it
     * is treated as it would reflect the public directory structure.
     * Otherwise the file is get along to the JAVASCRIPTS_PATH constant defined
     * in the 'index.php' file. The path defined there can be a local public
     * directory like '/javascripts' or even a standalone server 
     * (e.g. 'http://static.mydomain.com/javascripts').
     *
     * @see url_for     
     * @param string $file Javascript file name or path
     * @param array $options HTML attributes appended to the <script> tag
     * @return string <script> HTML tag
     * @author Szymon Wrozynski
     */
    function javascript_include_tag($file, $options=array())
    {
        $html = '<script src="' . Tags\_asset_url(JAVASCRIPTS_PATH, $file) .'"';
            
        if (!isset($options['type']))
            $html .= ' type="text/javascript"';
        
        if (!isset($options['charset']))
            $html .= ' charset="utf-8"';
                    
        foreach ($options as $n => $v)
            $html .= ' ' . $n . '="' . $v . '"';
        
        return $html . '></script>';
    }
    
    spl_autoload_register(function($class)
    {
        if ($class === 'Tags\Form')
            require MODULES . 'Tags' . DIRECTORY_SEPARATOR . 'Form.php';
    });
}

namespace Tags
{
    /**
     * Internal function for assets URL resolving.
     *
     * @internal This function should not be used explicitly! Internal use only.    
     * @param string $static Static asset path
     * @param mixed $asset Requested asset
     * @return string URL to the asset
     * @author Szymon Wrozynski
     */
    function _asset_url($static, $asset)
    {
        if ($asset[0] === '/')
            return url_for($asset);
        
        if (strpos($asset, '://') !== false) 
            return $asset;
        
        return ($static[0] === '/') 
            ? url_for($static . '/' . $asset)
            : $static . '/' . $asset;
    }
}
?>
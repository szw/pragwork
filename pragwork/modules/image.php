<?php
/**
 * Image Module 1.0 for Pragwork 1.0.2.1
 *
 * @copyright Copyright (c) 2009-2011 Szymon Wrozynski
 * @license Licensed under the MIT License
 * @version 1.0.2.1
 * @package Image
 */

/**
 * Sends the image from the given path and with the given name optionally. 
 * It is a final action. The request processing will stop after.
 *
 * @param string $file_path Image file path
 * @param string $file_name Optional file name
 * @return bool False if the image cannot be sent
 * @throws {@link \Application\StopException} In order to stop execution
 * @author Szymon Wrozynski
 */
function send_image($file_path, $file_name=null)
{    
    if (is_file($file_path))
    {
        $info = getimagesize($file_path);
        $size = filesize($file_path);
        
        header('Content-Type: ' . $info['mime']);
        header('Content-Disposition: inline; filename="' 
            . (($file_name === null) ? basename($file_path) : $file_name) .'"');
        header('Content-Length: ' . $size);
        
        readfile($file_path);
        throw new \Application\StopException;
    }
    
    return false;
}

/**
 * Creates a thumbnail image from the given image path. The thumbnail file is
 * stored under the $thumb_path. Allowed image formats are: PNG, GIF, and JPG.
 *
 * @param string $file_path Image file path (source)
 * @param string $thumbnail_path Image thumbnail path (target)
 * @param int $max_width Max thumbnail width (in pixels)
 * @param int $max_height Max thumbnail height (in pixels)
 * @param int $jpg_quality Quality of the thumbnail if the file is a JPG one 
 *     (default: 95)
 * @author Szymon Wrozynski (based on the public code found in the Internet)
 */
function save_thumbnail($file_path, $thumbnail_path, $max_width=100,
    $max_height=100, $jpg_quality=95)
{
    $info = getimagesize($file_path);
    
    if (($info[0] <= $max_width) && ($info[1] <= $max_height))
    {
        $w = $info[0];
        $h = $info[1];
    }
    else
    {
        $scale = ($info[0] > $info[1]) 
            ? $info[0] / $max_width : $info[1] / $max_height;
    
        $w = floor($info[0] / $scale);
        $h = floor($info[1] / $scale);
    }
    
    $thumb = imagecreatetruecolor($w, $h);
    $image_type = get_image_type($info['mime']);
    
    if (!$image_type)
        trigger_error('Incorrect image type: ' . $info['mime']);
    elseif ($image_type === 'PNG')
    {
        imagecopyresampled($thumb, imagecreatefrompng($file_path), 
            0, 0, 0, 0, $w, $h, $info[0], $info[1]);
        
        imagepng($thumb, $thumbnail_path);
    }
    elseif ($image_type === 'GIF')
    {
        imagecopyresampled($thumb, imagecreatefromgif($file_path),
            0, 0, 0, 0, $w, $h, $info[0], $info[1]);
        
        imagegif($thumb, $thumbnail_path);
    }
    elseif ($image_type === 'JPG')
    {
        imagecopyresampled($thumb, imagecreatefromjpeg($file_path), 
            0, 0, 0, 0,  $w, $h, $info[0], $info[1]);
            
        imagejpeg($thumb, $thumbnail_path, $jpg_quality);
    }
    
    imagedestroy($thumb);
}

/**
 * Returns the string ('PNG', 'GIF', or 'JPG') with image type based on the MIME
 * information or false if no image was found. Recognized image formats are:
 * PNG, GIF, and JPG.
 *
 * @param string $mime MIME information
 * @return mixed String ('PNG', 'GIF', or 'JPG'), or false
 * @author Szymon Wrozynski
 */
function get_image_type($mime)
{
    if ($mime)
    {
        if (stripos($mime, 'png', 6) !== false)
            return 'PNG';
        elseif (stripos($mime, 'gif', 6) !== false)
            return 'GIF';
        elseif (stripos($mime, 'jp', 6) !== false)
            return 'JPG';
    }
    return false;
}
?>
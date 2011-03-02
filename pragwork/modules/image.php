<?php
/**
 * Image Module 1.1 for Pragwork 1.1.0
 *
 * @copyright Copyright (c) 2009-2011 Szymon Wrozynski
 * @license Licensed under the MIT License
 * @version 1.1.0
 * @package Image
 */

namespace Image;

/**
 * Utility class for handling images.
 *
 * @author Szymon Wrozynski
 * @package Image 
 */
class Image
{
	/**
	 * Sends the image from the given path and with the given name optionally. 
	 * It is a final action. The request processing will stop after.
	 *
	 * @param string $path Image file path
	 * @param string $name Optional file name
	 * @return bool False if the image cannot be sent
	 * @throws {@link \Application\StopException} In order to stop execution
	 */
	public static function render($path, $name=null)
	{	 
		if (is_file($path))
		{
			$info = getimagesize($path);
			$size = filesize($path);
			
			$response = \Application\Response::instance();
			
			$response->content_type = $info['mime'];
			$response->add_header('Content-Disposition: inline; filename="' 
				. (($name === null) ? basename($path) : $name) .'"');
			$response->add_header('Content-Length: ' . $size);
			
			readfile($path);
			throw new \Application\StopException;
		}

		return false;
	}

	/**
	 * Creates a thumbnail image from the given image path. 
	 * The thumbnail file is stored under the $thumb. Allowed image formats
	 * are: PNG, GIF, and JPG.
	 *
	 * @param string $file Image file path (source)
	 * @param string $thumbnail Image thumbnail path (target)
	 * @param int $max_width Max thumbnail width (in pixels)
	 * @param int $max_height Max thumbnail height (in pixels)
	 * @param int $jpg_quality Quality of the thumbnail if the file is a JPG one (default: 95)
	 */
	public static function save_thumbnail($file, $thumbnail, $max_width=100,
		$max_height=100, $jpg_quality=95)
	{
		$info = getimagesize($file);

		if (($info[0] <= $max_width) && ($info[1] <= $max_height))
		{
			$w = $info[0];
			$h = $info[1];
		}
		else
		{
			$scale = ($info[0] > $info[1]) ? $info[0] / $max_width : $info[1] / $max_height;

			$w = floor($info[0] / $scale);
			$h = floor($info[1] / $scale);
		}

		$thumb = imagecreatetruecolor($w, $h);
		$image_type = self::get_type($info['mime']);

		if (!$image_type)
			throw new \ErrorException('Incorrect image type: ' . $info['mime']);
		elseif ($image_type === 'PNG')
		{
			imagecopyresampled($thumb, imagecreatefrompng($file), 0, 0, 0, 0, $w, $h, $info[0], $info[1]);
			imagepng($thumb, $thumbnail);
		}
		elseif ($image_type === 'GIF')
		{
			imagecopyresampled($thumb, imagecreatefromgif($file), 0, 0, 0, 0, $w, $h, $info[0], $info[1]);
			imagegif($thumb, $thumbnail);
		}
		elseif ($image_type === 'JPG')
		{
			imagecopyresampled($thumb, imagecreatefromjpeg($file), 0, 0, 0, 0, $w, $h, $info[0], $info[1]);
			imagejpeg($thumb, $thumbnail, $jpg_quality);
		}

		imagedestroy($thumb);
	}

	/**
	 * Returns the string ('PNG', 'GIF', or 'JPG') with image type based on the
	 * MIME information or false if no image was found. Recognized image formats
	 * are: PNG, GIF, and JPG.
	 *
	 * @param string $mime MIME information
	 * @return mixed String ('PNG', 'GIF', or 'JPG'), or false
	 */
	public static function get_type($mime)
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
}
?>
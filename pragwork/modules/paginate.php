<?php
/**
 * Paginate Module 1.0 for Pragwork 1.0.2.1
 *
 * @copyright Copyright (c) 2009-2011 Szymon Wrozynski
 * @license Licensed under the MIT License
 * @version 1.0.2.1
 * @package Paginate
 */

/**
 * Splits the collection into smaller chunks and returns the chunk, 
 * its ordinal number (page) and the overall number of extracts (total pages).
 * 
 * <code>
 * list($people, $current_page, $total_pages) = paginate($all_people, 3, 10);
 * </code>
 * 
 * Creates the $people array containing 10 people max (if possible it would be
 * records 20 to 29 of the $all_people array) along with the $current_page and 
 * $total_pages variables. The $current_page it is not always the same as the 
 * passed $page parameter. If the passed $page parameter was lower than 1 
 * the $current_page is set to 1, and if the passed $page was greater than 
 * the greatest possible value, the $current_page is corrected accordingly.
 * The $total_pages is computed according to the $per_page parameter 
 * and the passed collection size.  
 *
 * @param array $collection Collection to split
 * @param int $page Ordinal number of the extract to return
 * @param int $per_page Extract size
 * @return array Array of the extract, current page, and total pages count
 * @author Szymon Wrozynski
 */
function paginate($collection, $page, $per_page)
{
    if ($page < 1)
        $page = 1;
    
    $size = count($collection);
    $total_pages = ($size > $per_page) ? intval(ceil($size / $per_page)) : 1;
    
    if ($page > $total_pages)
        $page = $total_pages;
    
    $start = $per_page * ($page - 1);
    
    return array(
        array_slice($collection, $start, $per_page), 
        $page, 
        $total_pages
    );
}
?>
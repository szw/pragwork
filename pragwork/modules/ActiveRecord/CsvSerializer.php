<?php
namespace ActiveRecord;
/**
 * CSV serializer.
 *
 * @package ActiveRecord
 */
class CsvSerializer extends Serialization
{
    public static $delimiter = ',';
    public static $enclosure = '"';

    public function to_s()
    {
        if (@$this->options['only_header'] == true) return $this->header();
        return $this->row();
    }

    private function header()
    {
        return $this->to_csv(array_keys($this->to_a()));
    }

    private function row()
    {
        return $this->to_csv($this->to_a());
    }

    private function to_csv($arr)
    {
        $outstream = fopen('php://temp', 'w');
        fputcsv($outstream, $arr, self::$delimiter, self::$enclosure);
        rewind($outstream);
        $buffer = trim(stream_get_contents($outstream));
        fclose($outstream);
        return $buffer;
    }
}
?>
<?php 
if(isset($_GET['id']) == 1){
	$data = file_get_contents($_SERVER['HTTP_REFERER']);
	$dom = new DOMDocument();

    libxml_use_internal_errors(true);       
    $dom->loadHTML($data);
    libxml_use_internal_errors(false);

    $table = $dom->getElementById('files_upload_table');
	echo $table->nodeValue;
    $aVal = array();
            foreach ($table as $tr){
                $trVal = $tr->getElementsByTagName('tr');
                foreach ($trVal as $td){
                    $tdVal = $td->getElementsByTagName('td');
					echo $td->item(1)->nodeValue;
                    foreach($tdVal as $a){
                        $aVal[] = $a->getElementsByTagName('a')->nodeValue;
						echo $aVal[0];
                    }
                }
            }
	
}
    ?>
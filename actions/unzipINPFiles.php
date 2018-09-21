<?php
session_start();
$path    = "../server/php/files/".session_id();
chmod($path, 0777);

echo "teste";

foreach (new DirectoryIterator($path) as $file) {
	if ($file->isFile()) {
		$fileName = strtolower($file->getFilename());
		if(strpos($fileName, ".zip")){
			$zip = new ZipArchive;
			$res = $zip->open($path."/".$fileName);
			echo "<br>Unziping the file: ".$fileName;
			if ($res === TRUE) {
			  $zip->extractTo($path);
			  $zip->close();
			  unlink($path."/".$fileName);
			  echo "Unziping the file: ". $fileName." DONE";
			} 
		}
	}
}
			
		

?>
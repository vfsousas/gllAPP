<?php
session_start();
$path = "../server/php/files/" . session_id();
chmod($path, 0777);
echo $path;
foreach (new DirectoryIterator($path) as $file) {
    if ($file->isFile()) {
        $fileName = strtolower($file->getFilename());
		echo "$path/$fileName";
		unlink("$path/$fileName");
	}
}

?>
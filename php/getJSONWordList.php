<?php

	
	$fileAsArray = Array();

	if (($handle = fopen("../files/example.csv", "r")) !== FALSE) {
		while (($data = fgetcsv($handle, 1000, ";")) !== FALSE) {
			$fileAsArray[] = $data;
		}
		fclose($handle);
	}

	die(json_encode($fileAsArray));

	//echo json_encode($files);
?>

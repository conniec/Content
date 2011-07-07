<?php

	$lesson = $_GET['group'];
	$fileAsArray = Array();
	$fileDir = "../files/".$lesson."/".$lesson.".csv";

	if (($handle = fopen($fileDir, "r")) !== FALSE) {
		while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
			$fileAsArray[] = $data;
		}
		fclose($handle);
	}
	die(json_encode($fileAsArray));

?>

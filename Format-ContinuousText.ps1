function Format-ContinuousText($text) {
    return $text -replace "`r`n"," "
}

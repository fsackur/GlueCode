$Forecast = Invoke-RestMethod $WeatherURL -Body @{Location='London'; Days=3}

if (($Forecast.Days.Temperature | Measure-Object -Sum)/3 -gt 23) {
    $SpinUpMore = $true
}

if ($SpinUpMore) {
    Invoke-RestMethod $RackspaceCloudUrl -Body @{Servers=12}
}

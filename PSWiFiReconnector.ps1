<#

PSWiFiReconnector

by distractal

6/23/2018 Last Update - 1.0

I wrote this script while living at a location where I did not have access to perform
troubleshooting & make changes to Cable Modem / Router + WAP settings, and only had
access to a WiFi network.

I would experience packet drops overwhelmingly while playing Overwatch, but noticed that
if I disconnected/reconnected to the WiFi network, the issues would go away for 
a while (~5 minutes to all day).

This Powershell script will disconnect/reconnect you to a WiFi network
you have a profile set up for in Windows if the following conditions are met:
- Packet loss (specifially, a "request timed out" message) is detected
- Within endlessly repeating sets of 10 ping samples, more than 4 of the pings exceed a 99 ms return time

Tested under the following conditions:
- Windows 10 Pro
- Single WiFi Adapter
- Stable WiFi connection, with periodic intermittent packet loss somewhere between the router and endpoint

TODO:
- Make packet sampling continuous vs 10-ping sets (if this doesn't work to fix my issue)
- Move to a new location with better internet!

#>


function Reconnect-WiFi-Network {
	$WiFiProfileName = "profilename"
    $WiFiSSID = "SSID"
    & netsh wlan disconnect
    Start-Sleep -Seconds 5
    & netsh wlan connect $WiFiProfileName $WiFiSSID
}
While ($true)
{
    $numHighPings = 0
    $TestIP = "8.8.8.8"
    try
    {
        $PingResults = Test-Connection -Count 10 $TestIP
    }
    catch [System.Net.NetworkInformation.PingException]
    {
        Write-Host "Ping exception detected, reconnecting."
        Reconnect-WiFi-Network
        continue
    }
    catch 
    {
        Write-Host "Packet Loss Recovery encountered an unhandleable exception, quitting."
        Write-Host $Error[0].Exception.GetType().FullName
        exit
    }

    $CurrDate = Get-Date -Format g
    Write-Host "====== Ping set at ${CurrDate}: ======"
    $PingResults

	foreach ($PingResult in $PingResults)
    {
        if ($PingResult.ResponseTime -gt 99)
        {
            ++$numHighPings
        }
    }

    if ($numHighPings -gt 4)
    {
        Write-Host "Number of pings >= 100 in 10-ping sample exceeded 4, reconnecting."
        Reconnect-WiFi-Network
        $numHighPings = 0
    }	
}


Set-PSDebug -Trace 1
.\deletePrivateEndpoints.ps1 2>&1 | Tee-Object -FilePath delete.log
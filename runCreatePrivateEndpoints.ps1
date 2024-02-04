Set-PSDebug -Trace 1
.\createPrivateEndpoints.ps1 2>&1 | Tee-Object -FilePath create.log

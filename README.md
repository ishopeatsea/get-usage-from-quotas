Adds current quota information for students in Azure Lab Services labs and adds them to a running CSV.

My current setup involves scheduling a task to run once a day at 9am using my credentials to start the program `powershell.exe -ExecutionPolicy Bypass -File "C:\github\azurelabs\usage\quotas\get-current-quotas.ps1"`.

This was created because there's no way to access historical usage data other than inferring it from the Activity Log, which is a pain in the ass.

TODO:
- flesh out this readme properly
- add a script that creates the scheduled task for you
- add one or a few basic python + pandas data processing scripts that show you the difference in usage per day

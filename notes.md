
# Preamble

The majority of talks that we have in this group are demonstrations of software products. I’d like to talk about the code that stitches products together. Along the way I'm going to expound on my obsession with software contracts.

I have a rough distinction between application code, that is probably in a single repository and may be valuable to different use cases, and glue code, that you write to make applications work in your context. Powershell is a great choice for glue code.

An example might be - there’s a weather API - you have a cloud API - when there’s hot weather approaching you want to spin up more instances of your beachwear shopfront.

(.\Two-API-example.ps1)
$Forecast = Invoke-RestMethod $WeatherURL -Body @{Location='London'; Days=3}

if (($Forecast.Days.Temperature | Measure-Object -Sum)/3 -gt 23) {
    $SpinUpMore = $true
}

if ($SpinUpMore) {
    Invoke-RestMethod $RackspaceCloudUrl -Body @{Servers=12}
}



This is what you should not do. This has a large and ragged surface area. 
 - It’s deeply coupled to both APIs
 - it’s hard to break down into testable chunks
 - it’s hard to reuse if you want to also, say, spin up more instances when an advertising campaign kicks off.
 - the field names won't match in the APIs you’re using, so you are going to have variable names that don't make sense in the entire context

I advocate that there’s little extra time involved in making wrapper code for each API that exposes the functionality you need. Then your glue code will interface the two pieces of wrapper code together.

That keeps your business logic separate to your implementation details.

It will push all the translation code into the wrapper modules and let your glue code have more internal consistency.

This is also your opportunity to let your glue code be completely covered with unit tests, so you don’t have to run full end-to-end tests on every code change.

Here’s an example that makes it easier to see the last two points:
I have code that determines the highest-priority network adapter from WMI
https://github.com/fsackur/LegacyNetAdapter
We currently use nvspbind.exe, which wraps the Win32 APIs:
https://gallery.technet.microsoft.com/Hyper-V-Network-VSP-Bind-cf937850

The task is to set the network adapter binding order so the "primary" adapter is at the top.

<Demo LegacyNetAdapter, show Guid property>
This isn't perfect code, but it gives us the GUID property
Makes sense that the glue code would refer to "AdapterGuid" - makes sense in both contexts


<Show sketching out of Invoke-NVSPbind>

Links!
Param block
Output type
Throws statement

I’m cooking the bare minimum. All this is really about is translating the external command into PS form and only exposing the functionality we need. This defines the “surface area”, or “contract”, or “interface”.

I do want to highlight the concept of a “software contract” because it is a valid methodology to write your method signatures, param blocks, return types what-have-you before you write any code at all - that’s called Design-By-Contract. I don’t follow it but I do try to always have a software contract defined for most of the functions I write.

It’s hard to directly mock out an external utility in Pester. The way you test this is to use Invoke-Expression in your code and mock that out instead.

Side note- how to test WMI?
Mock out Get-WmiObject and return a custom object that has the mock code you require.





An interface in a strongly-typed language is very similar to a class except that you can never create an object out of it. It exists because, when you define a class as implementing an interface, the compiler forces you to back up your promise by implementing all the methods of the interface. In other words, an interface is part of how a strongly-typed language gives you a contract.

Taking a step back from the language-specific meaning of an interface, an interface means the expected parameters and return types of some code

<switch back to Invoke-NVSPbind>
Powershell is dynamically typed, and does not enforce OutputType. You can make it enforce your param block with the CmdletBinding() attribute, but it won’t enforce the outputtype and it won’t enforce the exception type. Anyone who’s developed C# code knows that IntelliSense won’t stop squiggling red lines until you complete all possible code paths with a return statement of the correct type. PS doesn’t do that. Nonetheless, I advocate that you code as if it does. That’s because it teaches you to think about the state of your objects as they go down code paths.

Exceptions - example common error scenario, menu takes credentials, but only when some lower-level code tries the operation do you find "permission denied"
The excpetions that code throws in well-known scenraios form part of the contract
Powershell doesn't support it but other languages let you have "throws" keytword in interface definition
Won't ever tell you all the exceptions! You could always get an "Out of memory" excpetion

So the ideal output of this little coding exercise is something that completely maps the input range to the output domain in a one-to-one relationship. If we trust the msdn documentation, we expect our call to SetDNSServerSearchOrder to only ever return one of 39 different states (assuming that you accept “Other” to be a single state defined by any return code between 101 and 4,294,967,295)
https://msdn.microsoft.com/en-us/library/aa393295(v=vs.85).aspx


So, why are we doing this again?
You work with colleagues, or people in the community
Including yourself
They would find it easier to develop a solution if they can call Powershell functions that they can understand quickly
They expect errors to be raised through exceptions, not return values
This is all about translation. This is the adapter design pattern (or an approximation of it)


Design patterns
https://en.wikipedia.org/wiki/Software_design_pattern

I am working on a pet project that I want to have general applicability to service providers, including Rackspace. All these guys will have a configuration management database. At my last firm, we had commercial products called Kaseya and N-able. Both of these are apps that also allow remote access for helpdesk, runbooks, monitoring and a bunch of other stuff. But at the core is a database that holds all the hostnames, IP addresses, OS versions and a bunch of other information about each endpoint under support. Rackspace has a few of these as CMDBs well. Obviously every single CMDB has a different interface! So if I am writing a tool with general applicability, how to handle that?

All of these things will have some information in common.

Presumably every device has a unique ID
Every ID will match some regex pattern
Every device will have at least one IP address, at least one set of credentials, exactly one OS type
Every device will belong to exactly one customer account
Every account will have a unique ID that matches some other regex pattern

For my software, all I’m ever going to want to do out of CRUD, is Read and Update.

So i can start to define the interface that my software is looking for from a CMDB app. And in this case, I’m now working backwards to the typical PS way, and later I’ll be filling in the gap with glue code.

Since my software is composed of multiple modules, this all belongs in the DB module. The DB module defines Import-DeviceInfo and Import-AccountInfo (export may come later)
    sl C:\dev\GlueCode\Proxy2
    ise .\DB.psm1

(It took me a while to settle on Import as the verb)

I’ll probably refactor into C# classes - to support PS4 and below, and because PS classes are still dynamic objects.

All this adds up to an interface that can be matched up to most CMDB apps with glue code, and it makes the glue code testable.

Once we have this, we’re done; we have abstracted away a layer. I can provide a systems integrator with my app and with minimum effort, he or she should be able to make it work with your database. And the unit tests will show that it’s working. And it will throw exceptions if it is wrong, and the exceptions will be in the appropriate part of the project, so it ought to be easier to debug than if we let incorrect data further into our code.

Now let's see what we can do given a tightly-defined software contract.

This hits the API multiple times. It would be nice to use caching. This is a good candidate for a proxy command.
    ise CacheLayer.psm1

Exports same functions. Same method signatures. Imports DB.psm1 as a nested module. Within functions, calls DB by module-qualified name

It's transparent to the calling code whether this caching layer is loaded or not. You can disable it. It's a question of dynamically choosing which module to load.

That is the "Proxy" design pattern.

PS is very suited for this design pattern because command resolution is dynamic.

Alias > function > cmdlet
Local module > global scope
Can fully-qualify function names

You can use this to override behaviour in a foreign module without having to change the code in that module. Is there anyone here who has *never* cursed at someone else’s choice to use Write-Host?

    sl ..\Proxy1
Shimming Write-Host into Write-Output

Shimming Write-Verbose to also log



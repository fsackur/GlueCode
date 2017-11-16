
# Preamble

The majority of talks that we have in this group are demonstrations of software products. I’d like to talk about the code that stitches products together.

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



This is what you should not do. This has a large and ragged surface area. It’s deeply coupled to both APIs, it’s hard to break down into testable chunks, and it’s hard to reuse if you want to also spin up more instances when an advertising campaign kicks off.

I advocate that there’s little extra time involved in making wrapper code for each API that exposes the functionality you need. Then your glue code will interface the two pieces of wrapper code together.

That keeps your business logic separate to your implementation details.

You won’t find that the field names match in the APIs you’re using, so this is your opportunity to push all the translation code into the wrapper modules and let your glue code have more internal consistency.

This is also your opportunity to let your glue code be completely covered with unit tests, so you don’t have to run full end-to-end tests on every code change.

Here’s an example that makes it easier to see the last two points:
I have code that determines the highest-priority network adapter from WMI
https://github.com/fsackur/LegacyNetAdapter
We currently use nvspbind.exe, which wraps the Win32 APIs:
https://gallery.technet.microsoft.com/Hyper-V-Network-VSP-Bind-cf937850


I want to set the network adapter binding order

<Demo LegacyNetAdapter, show Guid property>

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



















Interface for SetDNSServerSearchOrder method of the Win32_NetworkAdapterConfiguration class:
https://msdn.microsoft.com/en-us/library/aa393295(v=vs.85).aspx


So in this case, you might want glue code that does the following:
Accepts one or more IP addresses
Performs some validation (e.g. RFC1918)
Runs the WMI method
Returns null
Throws an exception with the error code

I would start developing like this:
ISE
Get the class - start mucking about with code interactively
stop and write the param block INCLUDING the OutputType. 
If I’m feeling generous I might also include a section on exceptions in the help block.
Flesh out the code to meet the spec of the param block

https://github.com/fsackur/LegacyNetAdapter/blob/master/LegacyNetAdapter.psm1#L693


An interface in a strongly-typed language is very similar to a class except that you can never create an object out of it. It exists because, when you define a class as implementing an interface, the compiler forces you to back up your promise by implementing all the methods of the interface. In other words, an interface is part of how a strongly-typed language gives you a contract.

Taking a step back from the language-specific meaning of an interface, an interface means the expected parameters and return types of some code

Powershell is dynamically typed, and does not enforce OutputType. You can make it enforce your param block with the CmdletBinding() attribute, but it won’t enforce the outputtype and it won’t enforce the exception type. Anyone who’s developed C# code knows that IntelliSense won’t stop squiggling red lines until you complete all possible code paths with a return statement of the correct type. PS doesn’t do that. Nonetheless, I advocate that you code as if it does. That’s because it teaches you to think about the state of your objects as they go down code paths.

So the ideal output of this little coding exercise is something that completely maps the input range to the output domain in a one-to-one relationship. If we trust the msdn documentation, we expect our call to SetDNSServerSearchOrder to only ever return one of 39 different states (assuming that you accept “Other” to be a single state defined by any return code between 101 and 4,294,967,295)

So, why are we doing this again?
You work with colleagues, or people in the community
Including yourself
They would find it easier to develop a solution if they can call Powershell functions that they can understand quickly
They expect errors to be raised through exceptions, not return values
This is all about translation. This is the adapter design pattern (or an approximation of it)


Design patterns
https://en.wikipedia.org/wiki/Software_design_pattern

I am working on a pet project that I want to have general applicability to service providers, including my own employer. All these guys will have a configuration management database. At my last firm, we had commercial products called Kaseya and N-able. Both of these are apps that also allow remote access for helpdesk, runbooks, monitoring and a bunch of other stuff. But at the core is a database that holds all the hostnames, IP addresses, OS versions and a bunch of other information about each endpoint under support. Rackspace has a few of these as CMDBs well. Obviously every single CMDB has a different interface! So if I am writing a tool with general applicability, how to handle that?

All of these things will have some information in common.

Presumably every device has a unique ID
Every ID will match some regex pattern
Every device will have at least one IP address, at least one set of credentials, exactly one OS type
Every device will belong to exactly one customer account
Every account will have a unique ID that matches some other regex pattern

For my software, all I’m ever going to want to do out of CRUD, is Read and Update.

So i can start to define the interface that my software is looking for from a CMDB app. And in this case, I’m now working backwards to the typical PS way, and later I’ll be filling in the gap with glue code.

Since my software is composed of multiple modules, this all belongs in the DB module. The DB module defines Import-DeviceInfo and Import-AccountInfo (export may come later)

It took me a while to settle on Import, the Approved Verbs page features quite prominently in my browser history because it’s not always a clear-cut choice. But I do know that it’s going to return objects with certain characteristics and, since I’m happy to support only PS5 in version 1, I’ve written PS classes to define that interface.

I’ve also written my own custom exceptions. These are just PS Classes that extend Exception.

I’m sure that eventually I’ll refactor these into proper C# classes - I say proper, because PS classes are still dynamic objects that can have fields added. Therefore they don’t offer the tightness of interface that I’m looking for. I want to have the concept of type safety - it’s either correct, or it throws an exception and you KNOW that it has blown up.

Defining my own exception classes also means that the code in my project can handle well-understood error conditions with simpler code.

All this adds up to an interface that can be matched up to most CMDB apps with glue code, and it makes the glue code testable.

In my employer, the two main CMDB apps have web APIs. One of them is good, the other one has its quirks. We have powershell modules for them both already, but they do not return objects with matching fields. This is the point of the adapter design pattern.

My DB module loads an array of glue code modules. This is hard-coded, but you can imagine that this could be dynamically populated from a plugins folder. One glue module for each CMDB app that we’re coding to. The glue modules expose the same function names and method signatures as the DB module, but include the actual implementation. The glue modules will also expose the regex for the valid unique IDs. We can pick which one we call, ultimately, by getting the regex from each glue module and seeing what our input sticks to, and we can then call the appropriate glue module’s function by fully-qualifying the function name.

To make the glue code testable, we create mocks of the app we’re wrapping that return certain values for valid input, and throw the same exceptions or return the same nulls as the wrapped app in error conditions. Then we can test that our glue code handles errors according to our specs as well as returning correctly under correct conditions.

Once we have this, we’re done; we have abstracted away a layer. I can provide a systems integrator with my app and with minimum effort, he or she should be able to make it work with your database. And the unit tests will show that it’s working. And it will throw exceptions if it is wrong, and the exceptions will be in the appropriate part of the project, so it ought to be easier to debug than if we let incorrect data further into our code.

There is one fly in the ointment, of course.

Is there anyone here who has *never* cursed at a colleague’s choice to use Write-Host?


Shimming Write-Host into Write-Output

Shimming Write-Verbose to also log

Shimming to add caching

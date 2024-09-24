---
sidebar_position: 2
---

# Getting Started

## Install

Install [ComputeLua](https://create.roblox.com/store/asset/17268345147/ComputeLua) directly from Roblox. Then, place it into ReplicatedStorage so both the Server and Client can access it.

---

## Basic Setup

The first thing you always do with any library, is require the module. So, let's require it.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComputeLua = require(ReplicatedStorage.ComputeLua)
```

### Creating a Dispatcher

Without a Dispatcher nothing will run, so this is pretty important. 

A Dispatcher's whole job is to handle a lot of workers and execute their threads. It will manage all of this so you don't have to.

You can create a Dispatcher by called the `ComputeLua.CreateDispatcher()` method. This method will take in two parameters.

- **numWorkers** -- How many workers do you want this Dispatcher to handle? This will vary depending on your needs, but it is recommended to pick a number that is a multiple of 4.
- **worker** -- The template of the worker script, this is what will be running the threads you create.

You are going to need a worker template, so, for now, let's create a blank script and place it as a child of the current script.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComputeLua = require(ReplicatedStorage.ComputeLua)

local worker = script.Worker
local numWorkers = 256

local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, worker)
```

:::caution
Workers will be parented under their template when they are created by the Dispatcher. 
Make sure they are able to run in their current location.
:::

---

### ComputeBuffers

ComputeBuffers are the main way to send bulks of data for the workers to process and spit out a result. They are really just very large tables of elements.

To create a ComputeBuffer, all you need to call is the `Dispatcher.SetComputeBuffer()` method, this method takes in two parameters

- **bufferName** -- What is the name of this buffer? If you name two buffers the same name, they will override their data
- **bufferData** -- What is the data of this buffer? This is the large table of elements which was said before

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComputeLua = require(ReplicatedStorage.ComputeLua)

local worker = script.Worker
local numWorkers = 256

local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, worker)

Dispatcher:SetComputeBuffer("buffer", table.create(8192, 2))
```

:::danger 
**ComputeBuffers can only have certain data types**

- First, the keys of the data must only be numbers, this will allow fast and effective sending of the data.
- Second, the only data types allowed for the data are:
	- Vector2
	- Vector3 
	- CFrame 
	- Color3 
	- UDim 
	- UDim2 
	- number 
	- boolean 
	- string
	- Table containing any of these (nested tables)

```lua
-- Allowed
{
	15,
	Vector3.zero,
	false,
	"string",
	CFrame.new(),
	{
		Vector3.new(0, 2, 1)
	},
	[7] = "sfas"
}

-- Not allowed
{
	stringKey = 1512,
	function() end
}

```
:::

If you ever wish to change the data in a ComputeBuffer that was already made. Then, just call the `Dispatcher.SetComputeBuffer()` method again and it will override the data.

---

### Workers

Workers are the brain of the operation. They are what is actually running the code and processing the data.

First, you will need to check if the current script is running in an actor, this is to make sure that this script can run in parallel.

```lua
local actor = script:GetActor()
if actor == nil then
	return
end
```

After that, you want to require ComputeLua so you can access its functions.

:::danger
**NEVER** call the "Parallel Unsafe" functions within ComputeLua. This will either cause an error or break something
:::

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local actor = script:GetActor()
if actor == nil then
	return
end

local ComputeLua = require(ReplicatedStorage.ComputeLua)
```

Now, you want to get the data key's of every ComputeBuffer to reference them later. In this example the only ComputeBuffer we have is called "buffer", so you get the key by calling `ComputeLua.GetBufferDataKey()`

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local actor = script:GetActor()
if actor == nil then
	return
end

local ComputeLua = require(ReplicatedStorage.ComputeLua)

local BUFFER_KEY = ComputeLua.GetBufferDataKey("buffer")
```

Finally, the last thing you need to do is create a thread. You can easily create a thread by running `ComputeLua.CreateThread()`. This takes in three parameters

- **actor** -- ComputeLua needs this to keep track of the workers
- **threadName** -- This should be unique to prevent overlap.
- **callback** -- This is a function that is called when the thread is executed. It takes in two parameters.
	- **id** -- This is the dispatch ID. You can easily use the dispatch ID to focus on one value within Compute Buffers.
	- **bufferData** -- The massive table containing all your buffer data

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local actor = script:GetActor()
if actor == nil then
	return
end

local ComputeLua = require(ReplicatedStorage.ComputeLua)

local BUFFER_KEY = ComputeLua.GetBufferDataKey("buffer")

ComputeLua.CreateThread(actor, "ProcessSquareRoot", function(id: number, bufferData: SharedTable)
	
end)
```

Now to get the data of the buffer you want, you want to first find the data for that buffer by indexing `bufferData` with the buffer's key

Then, if your buffers are configured correctly then the index in that buffer's data of the data you wish to edit will be the dispatch's ID, in our case is the variable `id`. So, index the buffer's data with the dispatch ID

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local actor = script:GetActor()
if actor == nil then
	return
end

local ComputeLua = require(ReplicatedStorage.ComputeLua)

local BUFFER_KEY = ComputeLua.GetBufferDataKey("buffer")

ComputeLua.CreateThread(actor, "ProcessSquareRoot", function(id: number, bufferData: SharedTable)
	local value = bufferData[BUFFER_KEY][id]
end)
```

Finally, once you are done processing your data you must return a value (if no value is returned, an error is raised). In this case, we will simply run `math.sqrt()` on it

But, ComputeLua needs to know what ComputeBuffer this value was assigned to so it can reassign it back, so you are required to return a table. 

How it works is by one element equals two indices in the table. The first index is the buffer's key and the second one is the data. For example, in our case we only have one ComputeBuffer so the returning table will be `{BUFFER_1_KEY, data_1}`. But, if you had three ComputeBuffers and edited all of them, then your returning table would be `{BUFFER_1_KEY, data_1, BUFFER_2_KEY, data_2, BUFFER_3_KEY, data_3}`

So filling in the values, our returning table will be `{BUFFER_KEY, math.sqrt(value)}`

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local actor = script:GetActor()
if actor == nil then
	return
end

local ComputeLua = require(ReplicatedStorage.ComputeLua)

local BUFFER_KEY = ComputeLua.GetBufferDataKey("buffer")

ComputeLua.CreateThread(actor, "ProcessSquareRoot", function(id: number, bufferData: SharedTable)
	local value = bufferData[BUFFER_KEY][id]
	return {BUFFER_KEY, math.sqrt(value)}
end)
```

---

### Dispatching

Now it's time to execute your workers. You can do this by dispatching your Dispatcher by running `Dispatcher:Dispatch()`. This takes in two required arguments and one optional.

- **thread** -- The name of the thread to dispatch, this is the same name as the one in the worker
- **numThreads** -- How many times of this thread should be calling
- **overridebatchSize** -- (optional) (NOT RECOMMENDED) override the default batch size

The Dispatch method will return a Promise. You can either await this promise, which will yield the current thread, or you could use `:andThen()` which will run the function passed after the Promise is resolved, this is what is recommended.

The resulting data works like this, it is the same massive table that the workers were given but now with the new data!

You will need to use `ComputeLua.GetBufferDataKey()` to get the index of the buffer you want to access, from there it is just the dispatch's ID starting at 1

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComputeLua = require(ReplicatedStorage.ComputeLua)

local worker = script.Worker
local numWorkers = 256

local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, worker)

Dispatcher:SetComputeBuffer("buffer", table.create(8192, 2))

local BUFFER_KEY = ComputeLua.GetBufferDataKey("buffer")
Dispatcher:Dispatch("ProcessSquareRoot", 8192):andThen(function(data: {[number]: {ComputeBufferDataType}})
	local bufferData = data[BUFFER_KEY]
end)
```

From here you can do whatever you wish with the data

---

### Cleaning Up

Finally, Dispatchers take up memory and if you don't get rid of them after you are done using them then problems will occur.

Simply call the `Dispatcher:Destroy()` method to get rid of your Dispatcher

```lua
Dispacther:Destroy()
```
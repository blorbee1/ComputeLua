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

local workerTemplate = script.Worker
local numWorkers = 64

local ComputeLua = require(ReplicatedStorage.ComputeLua)
local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, workerTemplate)
```

:::caution
Workers will be parented under their template when they are created by the Dispatcher. 
Make sure they are able to run in their current location.
:::

---

### Compute Buffers

Compute Buffers are just a large table of items that are sent over to the workers so they can edit them and send them back. This is how you can send data back and forth between the main thread and the workers.

To create a Compute Buffer, all you need to call is the `ComputeLua.CreateComputeBuffer()` method. This method takes in one parameter.

- **bufferName** -- What is the name of this buffer? It should be unique to prevent data loss when getting the data back.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComputeLua = require(ReplicatedStorage.ComputeLua)

local PositionBuffer = ComputeLua.CreateComputeBuffer("PositionBuffer")
```

Next you would want to set the data of the Compute Buffer. You can set the data of the buffer by running `ComputeBuffer:SetData()`. This takes in one parameter.

- **bufferData** -- A table of the data you want to set this buffer to have.

:::caution Compute Buffers can only have certain data types
Buffer data is limited due to limitations in Roblox

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

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComputeLua = require(ReplicatedStorage.ComputeLua)

local PositionBuffer = ComputeLua.CreateComputeBuffer("PositionBuffer")
PositionBuffer:SetData({
	Vector3.zero,
	Vector3.new(5, 1, 2),
	Vector3.yAxis,
	Vector3.zAxis
})
```

Finally, you probably want the compiled data from the Compute Buffer after the Dispatcher has dispatched and the workers are finished.

You can easily get this by running `ComputeBuffer:GetData()`. This will return a **read-only** table of all the data the workers have made together.

```lua
local result = PositionBuffer:GetData()
```

---

### Variable Buffer

Just like Compute Buffers, there is a Variable Buffer. This is unique however, this buffer cannot be edited by any worker and it is passed in through the parameters of the thread callback function. 

You can use this buffer to set constant variables that the workers will need to be able to use, for example:
- Size of the map
- Size of a Compute Buffer's data
- Constant variable for a function

To set the data of this Variable Buffer, you call `Dispatcher:SetVariableBuffer()`. This takes in one parameter

- **bufferData** - A table of the data you want to set this buffer to have.

:::caution The Variable Buffer can only have certain data types
The limited data types are exactly the same to Compute Buffers, except you cannot have nested tables with the Variable Buffer
:::
:::tip The Variable Buffer is not Compute Buffers
The Variable Buffer was not made to act like a Compute Buffer. You should not place a lot of information into it (by a lot of information, I mean over 1,000 elements)

Use a Compute Buffer if you need a lot of data sent over.
:::

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local workerTemplate = script.Worker
local numWorkers = 64

local ComputeLua = require(ReplicatedStorage.ComputeLua)
local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, workerTemplate)

Dispatcher:SetVariableBuffer({
	15,
	Vector3.zero,
	false,
	"string",
	CFrame.new()
})
```

---

### Worker Script

Worker scripts are very simple. Firstly, you will need to check if the current script is running in an actor. This is to make sure that this script can run in parallel.

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

Finally, the last thing you need to do is create a thread. You can easily create a thread by running `ComputeLua.CreateThread()`. This takes in three parameters

- **actor** -- ComputeLua needs this to keep track of the workers
- **threadName** -- This should be unique to prevent overlap.
- **callback** -- This is a function that is called when the thread is executed. It takes in two parameters.
	- **id** -- This is the dispatch ID. You can easily use the dispatch ID to focus on one value within Compute Buffers.
	- **variableBuffer** -- The read-only table which is the data from the Variable Buffer.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local actor = script:GetActor()
if actor == nil then
	return
end

local ComputeLua = require(ReplicatedStorage.ComputeLua)

ComputeLua.CreateThread(actor, "CalculatePositions", function(id, variableBuffer)
	local value = variableBuffer[1] -- Get the first variable within the Variable Buffer
end)
```

---

### Dispatching

Now it's time to execute your workers. You can do this by dispatching your Dispatcher by running `Dispatcher:Dispatch()`. This takes in two required arguments and one optional.

- **numThreads** --  How many workers will be invoked to run their code. If using serial dispatch, this cannot exceed the number of workers. Try to match the size of data you are going to process if you are not using a serial dispatch.
- **thread** -- The name of the thread to execute.
- **batchSize** -- (optional) Defaults to '50'. This will determine how many items each thread will work on. If this is 1 it will be one item per worker per thread
- **useSerialDispatch** -- (optional) Defaults to 'true' **NOT RECOMMENDED UNLESS YOU KNOW WHAT YOU ARE DOING**. This will cause every worker to only be called once.

The Dispatch method will return a Promise. You can either await this promise, which will yield the current thread, or you could use `:andThen()` which will run the function passed after the Promise is resolved, this is what is recommended.

```lua
Dispatcher:Dispatch(4, "CalculatePositions"):andThen(function()
	local data = PositionBuffer:GetData()
	print("starting data:")
	print({
		Vector3.zero,
		Vector3.new(5, 1, 2),
		Vector3.yAxis,
		Vector3.zAxis
	})
	print("resulting data:")
	print(data)
end)
```

---

### Cleaning Up

Make sure to clean up your Compute Buffers and Dispactchers by calling their respective clean up function. 

This will free up all the memory they are using and get rid of all the worker script clones.

```lua
Dispacther:Destroy()
ComputeBuffer:Clean()
```
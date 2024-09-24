---
sidebar_position: 5
---

# Worker

A worker is a script that is cloned by the [Dispatcher](dispatcher) which will perform small tasks. It may not seem important at first but the Dispatcher will clone a lot of things and they will all run in parallel, allowing these small tasks to add up into one big tasks that would take several seconds or even minutes to calculated if it was running serially. 

## Creating a Worker

To create a worker script, you just create a new script and pass in that script into the `ComputeLua.CreateDispatcher()` method as the worker template in whatever script is running the Dispatchers.

Make sure to disable it so it doesn't run without the Dispatcher cloning it.

This will automatically clone the workers the Dispatcher needs and enable them.

:::caution Worker parent is the template
The Dispatcher will automatically parent the workers to the worker template. So wherever the worker template is should be a spot where that script can run.
:::

The basic layout of a worker script is:
- Check if this script has an actor
- Require ComputeLua
- Create the threads

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local actor = script:GetActor()
if actor == nil then
	return
end

local ComputeLua = require(ReplicatedStorage.ComputeLua)
```

---

## Creating a Thread

To create a thread you simply call `ComputeLua.CreateThread()` with the correct arguments. This will connect a new thread so the Dispatcher knows what function to call when invoking this worker. The thread name should be unique to prevent overlapping functions.

The CreateThread method's last argument is the callback. This is the function that will run for every worker that gets executed. It takes in two parameters, the dispatch ID and the buffer data.

```lua
ComputeLua.CreateThread(actor, "ProcessSquareRoot", function(id: number, bufferData: SharedTable)
	
end)
```

The dispatch ID (id) is the current ID of the worker, this starts at 1 and ends at how many threads that the Dispatcher is executing.

The buffer data (bufferData) is the massive table of data that the ComputeBuffers are put into. This is where you get everything you need to process.

To get a certain ComputeBuffer within the buffer data, you will first need the key of it. You can get this key by running `ComputeLua.GetBufferDataKey()` with the name of the ComputeBuffer. Now simply index the buffer data table with that key to get the data for that buffer. It is recommended that you get the buffer's key outside of the thread function since that will be called many times so no need to ask for the key every time.

```lua
local BUFFER_KEY = ComputeLua.GetBufferDataKey("buffer")
ComputeLua.CreateThread(actor, "ProcessSquareRoot", function(id: number, bufferData: SharedTable)
	local data = bufferData[BUFFER_KEY]
end)
```

---

## Example : Apply noise to positions

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local actor = script:GetActor()
if actor == nil then
	return
end

local ComputeLua = require(ReplicatedStorage.ComputeLua)

local POSITION_BUFFER_KEY = ComputeLua.GetBufferDataKey("PositionBuffer")
ComputeLua.CreateThread(actor, "CalculateNoise", function(id: number, bufferData: SharedTable)
	local PositionBuffer = bufferData[POSITION_BUFFER_KEY]

	local position = PositionBuffer[id]
	return math.nosie(position.x, position.y, position.z)
end)
```
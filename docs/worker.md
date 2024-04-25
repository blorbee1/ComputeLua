---
sidebar_position: 5
---

# Worker

A worker is a script that is cloned by the [Dispatcher](dispatcher) which will perform small tasks. It may not seem important at first but the Dispatcher will clone a lot of things and they will all run in parallel, allowing these small tasks to add up into one big tasks that would take several seconds or even minutes to calculated if it was running serially. 

## Creating a Worker

To create a worker script, disable it so it doesn't run without the Dispatcher cloning it, you just create a new script and pass in that script into the `ComputeLua.CreateDispatcher()` method as the worker template in whatever script is running the Dispatchers.

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

The CreateThread method's last argument is the callback. This is the function that will run for every worker that gets executed. It takes in two parameters, the dispatch ID and the Variable Buffer.

You should keep your Compute Buffers simple, remove nested tables and make everything on the same level. Nested tables will take longer to write to, so keep it short and simple.

```lua
ComputeLua.CreateThread(actor, "ThreadName", function(id, variableBuffer)
	
end)
```

The dispatch ID (id) is the current ID of the worker, this starts at 1 and ends at how many threads that the Dispatcher is executing.

The Variable Buffer (variableBuffer) is the data of the Variable Buffer you assigned to the Dispatcher.

:::caution The Variable Buffer is read-only
If you attempt to edit the Variable Buffer, it will throw an error.
:::

---

## Getting Compute Buffer data

`ComputeLua.GetComputeBufferData()` is the way to get the data of a Compute Buffer, it takes in the name of the buffer.

`ComputeLua.GetComputeBufferData()` will return a **SharedTable**. The SharedTable means that there is a different way to iterate through the table. You can no longer use `ipairs` or `pairs`, you must use `in table` to iterate through it. But theres a catch, Roblox will shallow clone the SharedTable whenever you iterate through it; therefore no edits you make to it will apply. Due to this, if you need to loop through a Compute Buffer's data in a worker; you should supply the size of the table in the Variable Buffers so you can use a range loop.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local actor = script:GetActor()
if actor == nil then
	return
end

local ComputeLua = require(ReplicatedStorage.ComputeLua)

ComputeLua.CreateThread(actor, "ThreadName", function(id, variableBuffer)
	local bufferData = ComputeLua.GetComputeBufferData("ComputeBuffer")
	local bufferSize = variableBuffer[1]

	for i = 1, bufferSize do
		-- Since I'm using a range loop, I am able to make changes to the data and have it update the table
		bufferData[i] = 5
	end

	for i, v in bufferData do
		-- Since this is a 'in' loop, any edits will not apply to the bufferData
		bufferData[i] = 10
	end
end)

-- What gets returned to the Dispatcher:
-- All bufferData values equal 5
```

You can use the dispatch ID to easily access the current data the current worker instance is working on. All you do is just index the Compute Buffer's data with the dispatch ID and you will get the data the worker is working on.

:::tip
If the number of threads executed is greater than the size of the data of the Compute Buffer, then the workers may receive `nil` data near the end of the execution
:::

---

## Example : Apply noise to positions

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local actor = script:GetActor()
if actor == nil then
	return
end

local ComputeLua = require(ReplicatedStorage.ComputeLua)

ComputeLua.CreateThread(actor, "CalculatePositions", function(id, variableBuffer)
	local PositionBuffer = ComputeLua.GetComputeBufferData("PositionBuffer")
	local numPositions = variableBuffer[1] -- Get the first index of the variable buffer, which in this case is the size of the PositionBuffer

	for i = 1, numPositions do
		local position = PositionBuffer[i]
		PositionBuffer[i] = math.nosie(position.x, position.y, position.z)
	end
end)
```
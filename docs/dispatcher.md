---
sidebar_position: 3
---

# Dispatcher

The Dispatcher is the main class that will handle all the workers and threads. You can multiple Dispatchers if you want, but they will have their own workers.

## Creating a Dispatcher

To create a Dispatcher you will just need to call `ComputeLua.CreateDispatcher()` with the correct arguments. This will return a Dispatcher which can be used to dispatch a thread or update the Variable Buffer.

`Dispatcher:SetVariableBuffer()` This will set the Variable Buffer's data. Make sure your table's data matchs the allowed data types or it will throw an error. This should be called before the Dispatcher is dispatched. If it is called while the workers are working, then you may lose data or the workers will be unable to work correctly.

:::caution
The Variable Buffer's data is a read-only table. If you try to manually modify it within a worker or a non-worker (outside the `Dispatcher:SetVariableBuffer()` method), it will throw an error.
:::

---

## Dispatching Threads

Dispatching a thread is very simple. All you need to do is call `Dispatcher:Dispatch()` with the correct arguments. This will return a Promise so you can process that Promise as you please.

Once the Promise is resolved, then it is safe to get the data from the Compute Buffers if you have any. Before the Promise is resolved, that you may get unfinished data or just the original data.

---

## Example

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local workerTemplate = script.Worker
local numWorkers = 128 -- I want to have a total worker count of 128

local ComputeLua = require(ReplicatedStorage.ComputeLua)
local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, workerTemplate)

local PositionBuffer = ComputeLua.CreateComputeBuffer("PositionBuffer")
local startingData = table.create(64, Vector3.zero) -- This will precreate a table with 64 elements all with Vector3.zero as the value

PositionBuffer:SetData(startingData)

Dispatcher:Dispatch(64, "CalculatePositions"):andThen(function()
	local data = PositionBuffer:GetData() -- Get the data back from the PositionBuffer which should have all the new positions
	print("Starting data:")
	print(startingData)
	print("Resulting data:")
	print(data)
end)
```
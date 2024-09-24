---
sidebar_position: 3
---

# Dispatcher

A Dispatcher is the one in charge of everything. It is the one holding the data from your ComputeBuffers and sending those off to the many many workers it has to process them.

Multiple Dispatchers can be made, as many as you want.

Below is a more detailed explaination about Dispatchers compared to [Getting Started](gettingstarted)

## Creating a Dispatcher

To create a Dispatcher you will just need to call `ComputeLua.CreateDispatcher()` with the correct arguments. This will return a Dispatcher which can be used to dispatch a thread or create/set ComputeBuffers

`Dispatcher:SetComputeBuffer()` This will set a ComputeBuffer's data. If that certain ComputeBuffer does not exist, then it will create it.

`Dispatcher:DestroyComputeBuffer()` This will delete a ComputeBuffer's data. Just a simple cleanup function.

---

## Dispatching Threads

Dispatching a thread is very simple. All you need to do is call `Dispatcher:Dispatch()` with the correct arguments. This will return a Promise so you can process that Promise as you please.

Once the Promise is resolved, it will return the resulting data that the workers worked on

---

## Example

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
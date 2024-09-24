---
sidebar_position: 4
---

# ComputeBuffer

The ComputeBuffer is what sends data between your Dispatcher and workers. It is very important since it's the only way to send and receive data.

## Creating a ComputeBuffer

To create a ComputeBuffer you will just need to call `Dispatcher:SetComputeBuffer()` with the correct arguments. This will either set or create a ComputeBuffer with the data you give it.

:::caution
ComputeBuffers have only certain data types allowed. Refer to [Getting Started](gettingstarted) to find out those types.
:::

---

## Common Practices

The workers use their dispatch ID to index the ComputeBuffers' data to figure out the exact data they are working with. Therefore if you have a lot of data to edit, such as positions for some terrain generation, then if you store them in one list and send them in a ComputeBuffer you will be able to use the dispatch ID to find the exact data to edit. Dispatch IDs go from 1 to how many threads you are dispatching.

Another important issue is ComputeBuffers will be usually used for lots of data. So if you give the workers a dynamic table (one that has nothing in it and will resize itself when new values are put into it) then when you fill it out to complete the data it will be a bit slow, especially if you need to run this a lot per game tick.

For this reason, you should precreate all the data you are going to put into a ComputeBuffer.

```lua
table.create(5000, Vector3.zero) -- This will precreate a table of 5000 entries with a zero-ed out Vector3 at each one.
```

:::tip Functions cannot be sent to the workers
You cannot send functions to workers through a ComputeBuffer. Therefore you will have to have the function on the worker script and then send the parameters required to run the function through a ComputeBuffer.
:::

---

## Examples

### Load in a list of vertices

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local worker = script.Worker
local numWorkers = 256 -- 4 * 64

local ComputeLua = require(ReplicatedStorage.ComputeLua)
local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, worker)

local numVertices = 10000
local vertices = table.create(numVertices, Vector3.zero) -- Create a table of 10000 entries all with Vector3.zero

Dispatcher.SetComputeBuffer("PositionBuffer", vertices)

local POSITION_BUFFER_KEY = ComputeLua.GetBufferDataKey("PositionBuffer")
Dispatcher:Dispatch("CalculatePositions", numVertices):andThen(function(data: {[number]: {ComputeBufferDataType}})
	local vertices = data[POSITION_BUFFER_KEY]
	for _, pos in pairs(vertices) do
		editableMesh:AddVertex(pos) -- Add the vertex position to the mesh
	end
end)
```
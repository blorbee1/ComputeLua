---
sidebar_position: 4
---

# Compute Buffer

A Compute Buffer is the way to send big bunches of data to the workers so they can process it and send it back.

## Creating a Compute Buffer

To create a Compute Buffer you will just need to call `ComputeLua.CreateComputeBuffer()` with the correct arguments. This will return a ComputeBuffer which can be used to get the complied data and set the data to send over the workers.

`ComputeBuffer:SetData()` This will set the Compute Buffer's data. Make sure your table's data matchs the allowed data types or it will throw an error. This should be called before the Dispatcher is dispatched. If it is called while the workers are working, then you may lose data or the workers will be unable to work correctly.
`ComputeBuffer:GetData()` This will get the data from the Compute Buffer. This should be called after the Dispatcher has dispatched all its threads and the workers have finished otherwise you may get unfinished data.

:::caution
The Compute Buffer's data is a read-only table. If you try to manually modify it within a worker or a non-worker (outside the `ComputeBuffer:SetData()` method), it will throw an error.
:::

:::danger Compute Buffers are global
Compute Buffers ignore Dispatchers. If you have the same name for two Compute Buffers but different areas and Dispatchers, that doesn't matter it will pick the data and set the data of whatever Compute Buffer was made/edited last.
:::

---

## Common Practices

You should keep your Compute Buffers simple, remove nested tables and make everything on the same level. Nested tables will take longer to write to, so keep it short and simple.

Here is an example of how you can convert your nested tables, or tables with non valid keys, into un-nested/safe tables.

```lua
-- This table is unsafe due to it using a string key ("key1", "key2", etc). The keys must be a number which is just a regular array
local unsafeTable = {
	{
		key1 = true,
		key2 = "hello",
		key3 = 5182
	},
	{
		key1 = true,
		key2 = "hello",
		key3 = 5182
	},
	{
		key1 = true,
		key2 = "hello",
		key3 = 5182
	},
	{
		key1 = true,
		key2 = "hello",
		key3 = 5182
	},
}

local stride = 3 -- This number is how many indices your nested table takes up. For this example, that is three elements
local data = {}

-- This will take everything within the unsafeTable and convert it to being safe (removing the string keys)
for _, v in pairs(unsafeTable) do
	table.insert(data, v.key1)
	table.insert(data, v.key2)
	table.insert(data, v.key3)
end

print(data) -- Your compiled safe and non-nested data table
```

The worker scripts can use their dispatch ID to index the Compute Buffers' data to figure out the exact data they are working with. Therefore if you have a lot of data to edit, such as positions for some terrain generation, then if you store them in one list and send them in a Compute Buffer you will be able to use the dispatch ID to find the exact data to edit.

Another important issue is Compute Buffers will be usually used for lots of data. So if you give the workers a dynamic table (one that has nothing in it and will resize itself when new values are put into it) then the workers will work very slowly since resizing a table, especially a SharedTable, takes time.

For this reason, you should precreate all the data you are going to put into a Compute Buffer, even if the workers will not read anything from the table you at least should put some template value like '0'

```lua
local data = table.create(5000, Vector3.zero) -- This will precreate a table of 5000 entries with a zero-ed out Vector3 at each one.
PositionBuffer:SetData(data)
```

:::tip Functions cannot be sent to the workers
You cannot send functions to workers through a Compute Buffer or Variable Buffer. Therefore you will have to have the function on the worker script and then send the values required to run the function through a Compute Buffer or Variable Buffer.
:::

---

## Getting the data

`ComputeBuffer:GetData()` and `ComputeLua.GetComputeBufferData()` will return a **SharedTable**. The SharedTable means that there is a different way to iterate through the table. You can no longer use `ipairs` or `pairs`, you must use `in table` to iterate through it. But theres a catch, Roblox will shallow clone the SharedTable whenever you iterate through it; therefore no edits you make to it will apply. Due to this, if you need to loop through a Compute Buffer's data in a worker; you should supply the size of the table in the Variable Buffers so you can use a range loop.

:::caution
`ComputeBuffer:GetData()` returns a **read-only** table.
:::

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

---

## Examples

### Load in a list of vertices

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local workerTemplate = script.Worker
local numWorkers = 240 -- 4 * 60

local ComputeLua = require(ReplicatedStorage.ComputeLua)
local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, workerTemplate)

local PositionBuffer = ComputeLua.CreateComputeBuffer("PositionBuffer")

local numVertices = 10000
local vertices = table.create(numVertices, Vector3.zero) -- Create a table of 10000 entries all with Vector3.zero
PositionBuffer:SetData(vertices)

Dispatcher:Dispatch(numVertices, "CalculatePositions"):andThen(function()
	local vertices = PositionBuffer:GetData() -- Get the positions back from the workers
	for _, pos in vertices do
		editableMesh:AddVertex(pos) -- Add the vertex position to the mesh
	end
end)
```

### Get the height for some terrain noise

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local workerTemplate = script.Worker
local numWorkers = 240 -- 4 * 60

local ComputeLua = require(ReplicatedStorage.ComputeLua)
local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, workerTemplate)

local HeightBuffer = ComputeLua.CreateComputeBuffer("HeightBuffer")

local numHeights = 10000
local heights = table.create(numHeights, 0) -- Create a table of 10000 entries all with 0
HeightBuffer:SetData(heights)

Dispatcher:Dispatch(numVertices, "CalculatePositions"):andThen(function()
	local heights = HeightBuffer:GetData() -- Get the heights back from the workers
	for _, height in heights do
		print(height) -- Print the height
	end
end)
```
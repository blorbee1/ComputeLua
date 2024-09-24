# ComputeLua

A simple library to make Parallel Luau easier using Unity like ComputeBuffers with a Dispatcher.

---

## Why Use ComputeLua?

### Fully Typed

ComputeLua has typing for functions, classes, everything. Every type will be also checked and will throw an error if it is the incorrect type, so double check your types.

### Big Computing Projects

ComputeLua will allow you to create workers that will repeat the same small task all in parallel. It will then compile all the data the workers made into one table and return it back to you to use in the main thread! 
* Wave/Ocean simulation
* Editable mesh generation
* Terrain generation

These all require a lot of small information to be processsed very quickly and that is exactly what doing things in parallel does.

### Developer Friendly

ComputeLua may be a bit complex to a newcomer, but the design of the library was made keeping in mind of the ease of use. 

---

## Benchmarks

Processing the square root of 2, 8192 times and repeating that 100 times

Using 256 works with a batch size of 32 (8192 / 256)

**13th Gen Intel(R) Core(TM) i9-13900F @ 2.00 GHz**

- 1.3.0: 20ms average; 2s total; 50fps average

- 1.2.1: 40ms average; 4s total; 40fps average

**11th Gen Intel(R) Core(TM) i7-1195G7 @ 2.92 GHz**

- 1.3.0: 30ms average; 3s total; 45fps average

- 1.2.1: 70ms average; 7s total; 17fps average

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComputeLua = require(ReplicatedStorage.ComputeLua)

local worker = script.Worker
local numWorkers = 256

local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, worker)

Dispatcher:SetComputeBuffer("buffer", table.create(8192, 2))

local total = 0
local count = 0
local function process()
	local start = os.time()
	
	local _, data = Dispatcher:Dispatch("ProcessSquareRoot", 8192):await()
	total += os.time() - start
	count += 1
	
	if count < 100 then
		process()
	else
		print(`Average time to process: {(total / count) * 1000}ms`)
		print(`Total time to process: {total}s`)
	end
end

process()
```

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
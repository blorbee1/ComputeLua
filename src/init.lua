-- ComputeLua
-- blorbee
-- Stable Release (1.3.0) - 9/24/2024

local RunService = game:GetService("RunService")
local Promise = require(script.promise)

type Promise<T...> = {
	andThen: (self: Promise<T...>, successHandler: (...any) -> ...any, failureHandler: (...any) -> ...any) -> Promise<...any>,
	catch: (self: Promise<T...>, failureHandler: (...any) -> ...any) -> Promise<...any>,
	cancel: (self: Promise<T...>) -> (),
	finally: (self: Promise<T...>, finallyHandler: (...any) -> ...any) -> Promise<...any>,
	await: (self: Promise<T...>) -> (boolean, T...),
}

--[=[
	@class Dispatcher

	Responsible for handling and dispatching workers. 
	This should never be created by a worker or in parallel.

	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local ComputeLua = require(ReplicatedStorage.ComputeLua)

	local worker = script.Worker
	local numWorkers = 256

	local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, worker)
	```
]=]
local Dispatcher = {}
Dispatcher.__index = Dispatcher

--[=[
	@type BufferDataType Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | string
	@within Dispatcher
	The only data types allowed in buffers
]=]
--[=[
	@type BufferDataType Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | string
	@within ComputeLua
	The only data types allowed in buffers
]=]

--[=[
	@type ComputeBufferDataType { [number]: BufferDataType | ComputeBufferDataType }
	@within Dispatcher
	Type for the data of a ComputeBuffer
]=]
--[=[
	@type ComputeBufferDataType { [number]: BufferDataType | ComputeBufferDataType }
	@within ComputeLua
	Type for the data of a ComputeBuffer
]=]

export type BufferDataType = Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | string
export type ComputeBufferDataType = {[number]: BufferDataType | ComputeBufferDataType}

export type Dispatcher = typeof(setmetatable({} :: DispatcherSelf, Dispatcher))

type DispatcherSelf = {
	numWorkers: number,
	worker: Script | LocalScript,
	workerFolder: Folder,
	workers: {Actor},
	workerRemote: BindableEvent,
	computeBuffers: {[number]: ComputeBufferDataType},

	Dispatch: (self: Dispatcher, thread: string, numThreads: number, overrideBatchSize: number?) -> Promise<{[number]: {ComputeBufferDataType}}>,
	SetComputeBuffer: (self: Dispatcher, bufferName: string, bufferData: ComputeBufferDataType) -> (),
	DestroyComputeBuffer: (self: Dispatcher, bufferName: string) -> (),
	Destroy: (self: Dispatcher) -> ()
}
--[=[
	@prop numWorkers number
	@within Dispatcher
	@readonly
	@private
]=]
--[=[
	@prop computeBuffers { [number]: ComputeBufferDataType }
	@within Dispatcher
	@readonly
	@private
]=]
--[=[
	@prop worker Script | LocalScript
	@within Dispatcher
	@readonly
	@private
]=]
--[=[
	@prop workerFolder Folder
	@within Dispatcher
	@readonly
	@private
]=]
--[=[
	@prop workers {Actor}
	@within Dispatcher
	@readonly
	@private
]=]
--[=[
	@prop workerRemote BindableEvent
	@within Dispatcher
	@readonly
	@private
]=]

export type ComputeLua = {
	CreateDispatcher: (numWorkers: number, worker: Script | LocalScript) -> Dispatcher,
	CreateThread: (actor: Actor, threadName: string, callback: (id: number, bufferData: SharedTable) -> {[number]: any}) -> (),
	GetBufferDataKey: (bufferName: string) -> number
}

local function doesBufferElementHaveCorrectDataType(element: BufferDataType): boolean
	if typeof(element) ~= "table" 
		and typeof(element) ~= "Vector2"
		and typeof(element) ~= "Vector3"
		and typeof(element) ~= "CFrame"
		and typeof(element) ~= "Color3"
		and typeof(element) ~= "UDim"
		and typeof(element) ~= "UDim2"
		and typeof(element) ~= "number"
		and typeof(element) ~= "boolean"
		and typeof(element) ~= "string"
	then
		return false
	end
	return true
end

local function doesComputeBufferDataHaveCorrectTyping(bufferData: ComputeBufferDataType): boolean
	local function checkTable(t: {BufferDataType})
		for key, value in pairs(t) do
			if typeof(key) ~= "number" then
				return false
			end
			if typeof(value) == "table" and not checkTable(value) then
				return false
			end
			if not doesBufferElementHaveCorrectDataType(value) then
				return false
			end
		end
		return true
	end
	return checkTable(bufferData)
end

local function convertStringToNumber(str: string): number
	local hash = 0
	local prime = 31
	local mod = math.pow(2, 32) - 1
	for i = 1, #str do
		local char = string.byte(str, i)
		hash = (hash * prime + char) % mod
	end
	return math.abs(hash)
end

--[=[
	Create a Dispatcher
	@since v1.0.0
	@tag Parallel Unsafe
	@private

	@param numWorkers number -- How many workers to create
	@param worker Script | LocalScript -- The worker template to use
	@return Dispatcher
]=]
function Dispatcher._new(numWorkers: number, worker: Script | LocalScript)
	assert(type(numWorkers) == "number", "numWorkers must be a number")
	assert(typeof(worker) == "Instance", "worker must be an Instance")
	assert(worker:IsA("Script") or worker:IsA("LocalScript"), "worker must be a Script or LocalScript")
	assert(numWorkers > 0, "numWorkers must be greater than 0")

	local self = setmetatable({} :: Dispatcher, Dispatcher)

	self.numWorkers = math.round(numWorkers)
	self.worker = worker
	self.workers = table.create(numWorkers, 0)
	self.constantBuffer = {}
	self.computeBuffers = {}

	local folder = Instance.new("Folder")
	folder.Name = "Workers"
	folder.Parent = self.worker
	self.workerFolder = folder

	self.workerRemote = Instance.new("BindableEvent")

	for i = 1, numWorkers do
		local actor = Instance.new("Actor")
		local w = self.worker:Clone()
		w.Parent = actor
		w.Enabled = true
		self.workers[i] = actor
	end

	for _, actor in self.workers do
		actor.Parent = self.workerFolder
	end

	return self
end

--[=[
	Dispatch a number of threads to the workers
	@since v1.3.0
	@tag Parallel Unsafe

	@param thread string -- The name of the thread to dispatch, this is the same name as the one in the workers
	@param numThreads number -- How many times of this thread should be calling
	@param overrideBatchSize number? -- (NOT RECOMMENDED) override the default batch size
	@return Promise
]=]
function Dispatcher.Dispatch(self: Dispatcher, thread: string, numThreads: number, overrideBatchSize: number?)
	assert(type(numThreads) == "number", "numThreads must be a number")
	if numThreads <= 0 then
		warn("numThreads must be greater than 0")
		return Promise.reject()
	end
	assert(type(thread) == "string", "thread must be a string")
	if overrideBatchSize ~= nil then
		assert(type(overrideBatchSize) == "number", "overrideBatchSize must be a number")
		assert(overrideBatchSize > 0, "overrideBatchSize must be greater than 0")
		overrideBatchSize = math.ceil(overrideBatchSize)	
	end

	local batchSize = overrideBatchSize or math.floor(numThreads / #self.workers)
	local data = {}
	for key, bufferData in pairs(self.computeBuffers) do
		data[key] = bufferData
	end
	data = SharedTable.new(data)

	return Promise.defer(function(res)
		local result = data
		local workersDone = 0
		local connection = self.workerRemote.Event:Connect(function(id: number, bufferKey: number, data: any, calls: number)
			result[bufferKey][id] = data
			workersDone += calls
		end)

		local workerCount = #self.workers
		local index = 1
		for i = 1, numThreads, batchSize do
			self.workers[index]:SendMessage(thread, i, batchSize, numThreads, data, self.workerRemote)
			index = (index % workerCount) + 1
		end

		repeat
			RunService.Stepped:Wait()
		until workersDone >= numThreads

		if connection ~= nil then
			connection:Disconnect()
		end
		connection = nil

		res(result)
	end)
end

--[=[
	Set/Create ComputeBuffer data
	@since v1.3.0
	@tag Parallel Unsafe

	@param bufferName string -- The name of the buffer
	@param bufferData ComputeBufferDataType -- The data to set
]=]
function Dispatcher.SetComputeBuffer(self: Dispatcher, bufferName: string, bufferData: ComputeBufferDataType)
	assert(doesComputeBufferDataHaveCorrectTyping(bufferData), "bufferData must have only elements that are acceptable ComputeBuffer types")
	assert(typeof(bufferName) == "string", "bufferName must be a string")
	local key = convertStringToNumber(bufferName)
	self.computeBuffers[key] = bufferData
end

--[=[
	Delete a ComputeBuffer's data
	@since v1.3.0
	@tag Parallel Unsafe
	
	@param bufferName string -- The name of the buffer
]=]
function Dispatcher.DestroyComputeBuffer(self: Dispatcher, bufferName: string)
	assert(typeof(bufferName) == "string", "bufferName must be a string")
	local key = convertStringToNumber(bufferName)
	self.computeBuffers[key] = nil
end

--[=[
	The cleanup function for a Dispatcher. This is important to call to free up memory
	@since v1.0.0
	@tag Parallel Unsafe
]=]
function Dispatcher.Destroy(self: Dispatcher)
	for i = 1, self.numWorkers do
		self.workers[i]:Destroy()
	end
	self.workerRemote:Destroy()
	self.workerFolder:Destroy()
	table.clear(self.computeBuffers)
	table.clear(self)
	table.freeze(self)
end


--[=[
	@class ComputeLua

	The handler for the Dispatcher, threads, and data keys

	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ComputeLua = require(ReplicatedStorage.ComputeLua)
	```
]=]
local ComputeLua: ComputeLua = {}

--[=[
	Create a Dispatcher to run a bunch of workers in parallel
	@since v1.0.0
	@tag Parallel Unsafe

	@param numWorkers number -- How many workers to use, balanced this with performance and speed
	@param worker Script | LocalScript -- The template script to clone as the worker
	@return Dispatcher
]=]
function ComputeLua.CreateDispatcher(numWorkers: number, worker: Script | LocalScript): Dispatcher
	return Dispatcher._new(numWorkers, worker)
end

--[=[
	Create a thread for the Dispatcher to execute
	@since v1.3.0
	@tag Serial Unsafe

	@param actor Actor -- The Actor to bind the thread to, this should be the same actor as the parent of the worker.
	@param threadName string -- The unique name of the thread.
	@param callback (id: number, bufferData: SharedTable) -> {any} -- The function that will be executed when the thread is called and what returns the data
]=]
function ComputeLua.CreateThread(actor: Actor, threadName: string, callback: (id: number, bufferData: SharedTable) -> {any})
	assert(typeof(actor) == "Instance", "actor must be an Actor")
	assert(type(threadName) == "string", "threadName must be a string")
	assert(type(callback) == "function", "callback must be a function")
	assert(actor:IsA("Actor"), "actor must be an Actor instance")

	actor:BindToMessageParallel(threadName, function(
		startDispatchId: number, 
		batchSize: number,
		numThreads: number,
		bufferData: SharedTable,
		resultRemote: BindableEvent
	)
		for i = startDispatchId, math.min(startDispatchId + (batchSize - 1), numThreads) do
			local result = callback(i, bufferData)
			if result ~= nil then
				local amount = #result
				for i = 1, amount, 2 do
					resultRemote:Fire(i, result[i], result[i + 1], 2 / amount)
				end
			else
				error(`Thread {threadName}'s workers is not returning a value!`)
			end
		end
	end)
end

--[=[
	Get a ComputeBuffer's data key through its name
	@since v1.3.0

	@param bufferName string -- The name of the buffer
	@return number
]=]
function ComputeLua.GetBufferDataKey(bufferName: string): number
	return convertStringToNumber(bufferName)
end

return ComputeLua

-- ComputeLua
-- blorbee
-- Stable Release (1.2.1) - 5/29/2024

local SharedTableRegistry = game:GetService("SharedTableRegistry")

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

	local workerTemplate = script.Worker
	local numWorkers = 64

	local ComputeLua = require(ReplicatedStorage.ComputeLua)
	local Dispatcher = ComputeLua.CreateDispatcher(numWorkers, workerTemplate)
	```
]=]
local Dispatcher = {}
Dispatcher.__index = Dispatcher

local SHARED_TABLE_PREFIX = "ComputeLua-"

--[=[
	@type BufferDataType Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | string
	@within Dispatcher
	The only data types allowed in buffers, Compute or Variable
]=]
--[=[
	@type BufferDataType Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | string
	@within ComputeBuffer
	The only data types allowed in buffers, Compute or Variable
]=]
--[=[
	@type BufferDataType Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | string
	@within ComputeLua
	The only data types allowed in buffers, Compute or Variable
]=]

--[=[
	@type ComputeBufferDataType { [number]: BufferDataType | ComputeBufferDataType }
	@within ComputeBuffer
	Type for the data of a ComputeBuffer
]=]
--[=[
	@type VariableBufferDataType { [number]: BufferDataType }
	@within Dispatcher
	Type for the data of the VariableBuffer
]=]

--[=[
	@type ComputeBufferDataType { [number]: BufferDataType | ComputeBufferDataType }
	@within ComputeLua
	Type for the data of a ComputeBuffer
]=]
--[=[
	@type VariableBufferDataType { [number]: BufferDataType }
	@within ComputeLua
	Type for the data of the VariableBuffer
]=]

export type BufferDataType = Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | string
export type ComputeBufferDataType = {[number]: BufferDataType | ComputeBufferDataType}
export type VariableBufferDataType = {[number]: BufferDataType}

export type Dispatcher = typeof(setmetatable({} :: DispatcherSelf, Dispatcher))

type DispatcherSelf = {
	numWorkers: number,
	worker: Script | LocalScript,
	workerFolder: Folder,
	workers: {Actor},
	workerRemote: BindableEvent,
	variableBuffer: SharedTable,

	Dispatch: (self: Dispatcher, numThreads: number, thread: string,  batchSize: number?, useSerialDispatch: boolean?) -> Promise,
	SetVariableBuffer: (self: Dispatcher, bufferData: VariableBufferDataType) -> (),
	Destroy: (self: Dispatcher) -> ()
}
--[=[
	@prop numWorkers number
	@within Dispatcher
	@readonly
	How many workers this Dispatcher has
]=]
--[=[
	@prop variableBuffer VariableBufferDataType
	@within Dispatcher
	@readonly
	@private
	The current VariableBuffer data
]=]
--[=[
	@prop worker Script | LocalScript
	@within Dispatcher
	@readonly
	@private
	The worker template
]=]
--[=[
	@prop workerFolder Folder
	@within Dispatcher
	@readonly
	@private
	The worker holder folder
]=]
--[=[
	@prop workers {Actor}
	@within Dispatcher
	@readonly
	@private
	The workers' actors
]=]
--[=[
	@prop workerRemote BindableEvent
	@within Dispatcher
	@readonly
	@private
	The remote that a worker calls when it finished working
]=]

export type ComputeLua = {
	CreateDispatcher: (numWorkers: number, worker: Script | LocalScript) -> Dispatcher,
	CreateComputeBuffer: (bufferName: string) -> ComputeBuffer,
	GetComputeBufferData: (bufferName: string) -> SharedTable,
	CreateThread: (actor: Actor, threadName: string, callback: (number, VariableBufferDataType) -> ()) -> ()
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
	local function checkTable(t: {BufferElementType})
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

local function doesVariableBufferHaveCorrectTyping(variableBuffer: VariableBufferDataType): boolean
	local function checkTable(t: {VariableElementType})
		for key, value in pairs(t) do
			if typeof(key) ~= "number" then
				return false
			end
			if not doesBufferElementHaveCorrectDataType(value) then
				return false
			end
		end
		return true
	end
	return checkTable(variableBuffer)
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
function Dispatcher._new(numWorkers: number, worker: Script | LocalScript): Dispatcher
	assert(type(numWorkers) == "number", "numWorkers must be a number")
	assert(typeof(worker) == "Instance", "worker must be an Instance")
	assert(worker:IsA("Script") or worker:IsA("LocalScript"), "worker must be a Script or LocalScript")
	assert(numWorkers > 0, "numWorkers must be greater than 0")

	local self = setmetatable({} :: Dispatcher, Dispatcher)

	self.numWorkers = math.round(numWorkers)
	self.worker = worker
	self.workers = table.create(numWorkers, 0)
	self.rand = Random.new()
	self.variableBuffer = {}

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
	@since v1.0.0
	@tag Parallel Unsafe

	@param numThreads number -- How many workers will be invoked to run their code. If using serial dispatch, this cannot exceed the number of workers. Try to match the size of data you are going to process if you are not using a serial dispatch.
	@param thread string -- The name of the thread to dispatch, this is the same name as the one in the workers
	@param batchSize number -- The amount of items a worker will work on per thread. If this number is 1 then each worker execution will work on one item. Defaults to 50 (Recommended)
	@param useSerialDispatch boolean? -- **NOT RECOMMENDED UNLESS YOU KNOW WHAT YOU ARE DOING** Default to 'true'. This will cause every worker to only be called once.
	@return Promise
]=]
function Dispatcher.Dispatch(self: Dispatcher, numThreads: number, thread: string, batchSize: number?, useSerialDispatch: boolean?): Promise
	assert(type(numThreads) == "number", "numThreads must be a number")
	if numThreads <= 0 then
		warn("numThreads must be greater than 0")
		return Promise.reject()
	end
	assert(type(thread) == "string", "thread must be a string")
	if useSerialDispatch == nil then
		useSerialDispatch = false
	end
	assert(type(useSerialDispatch) == "boolean", "useSerialDispatch must be a boolean")
	if batchSize == nil then
		batchSize = 50
	end
	assert(type(batchSize) == "number", "batchSize must be a number")
	assert(batchSize > 0, "batchSize must be greater than 0")
	batchSize = math.ceil(batchSize)

	if batchSize < numThreads then
		batchSize = 1
	end

	if useSerialDispatch then
		assert(numThreads <= self.numWorkers, "numThreads cannot exceed numWorkers if using a serial dispatch")
	end

	local workersFinished = 0
	local timeout = 60

	return Promise.defer(function(res)
		local timedOut = false
		local connection = nil
		task.delay(timeout, function()
			if workersFinished < numThreads then
				timedOut = true
				if connection ~= nil then
					connection:Disconnect()
				end
				connection = nil
				res()
			end
		end)

		connection = self.workerRemote.Event:Connect(function()
			workersFinished += 1
		end)

		for i = 1, numThreads do
			if not useSerialDispatch then
				self.workers[self.rand:NextInteger(1, self.numWorkers)]:SendMessage(thread, i, batchSize, self.workerRemote, self.variableBuffer)
			else
				self.workers[i]:SendMessage(thread, i, batchSize, self.workerRemote, self.variableBuffer)
			end

			i = math.min(i + batchSize, numThreads)
		end

		repeat
			task.wait()
		until timedOut or workersFinished >= numThreads

		if connection ~= nil then
			connection:Disconnect()
		end
		connection = nil

		if not timedOut then
			res()
		end
	end)
end

--[=[
	Set the data of the SetVariableBuffer for this Dispatcher. Be careful to only call this when no workers are working
	@since v1.0.0
	@tag Parallel Unsafe

	@param bufferData VariableBufferDataType -- The data to set the variable buffer to.
]=]
function Dispatcher.SetVariableBuffer(self: Dispatcher, bufferData: VariableBufferDataType): ()
	assert(doesVariableBufferHaveCorrectTyping(bufferData), "variableData must have only elements that are acceptable variable buffer types")
	self.variableBuffer = SharedTable.cloneAndFreeze(SharedTable.new(bufferData), true)
end

--[=[
	The cleanup function for a Dispatcher. This is important to call to free up memory
	@since v1.0.0
	@tag Parallel Unsafe
]=]
function Dispatcher.Destroy(self: Dispatcher): ()
	for i = 1, self.numWorkers do
		self.workers[i]:Destroy()
	end
	self.workerRemote:Destroy()
	self.workerFolder:Destroy()
	table.clear(self)
	table.freeze(self)
end

--[=[
	@class ComputeBuffer

	Data storage to be sent over to the workers.

	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local ComputeLua = require(ReplicatedStorage.ComputeLua)

	local computeBuffer = ComputeLua.CreateComputeBuffer("PositionBuffer")
	computeBuffer:SetData({
		Vector3.zero,
		Vector3.new(5, 1, 2),
		Vector3.yAxis,
		Vector3.zAxis
	})
	```
]=]
--[=[
	@prop name string
	@within ComputeBuffer
	@readonly
	The name of the buffer.
]=]
--[=[
	@prop _bufferName string
	@within ComputeBuffer
	@readonly
	@private
	The extended name of the buffer, used to define the SharedTable ID.
]=]
local ComputeBuffer = {}
ComputeBuffer.__index = ComputeBuffer

export type ComputeBuffer = typeof(setmetatable({} :: ComputeBufferSelf, ComputeBuffer))
type ComputeBufferSelf = {
	name: string,
	_bufferName: string,

	GetData: (self: ComputeBuffer) -> SharedTable,
	SetData: (self: ComputeBuffer, bufferData: ComputeBufferDataType) -> (),
	Clean: (self: ComputeBuffer) -> (),
}

--[=[
	Create a ComputeBuffer
	@since v1.0.0
	@tag Parallel Unsafe
	@private

	@param name string -- Name of the buffer
	@return ComputeBuffer
]=]
function ComputeBuffer._new(name: string): ComputeBuffer
	assert(type(name) == "string", "bufferName must be a string")

	local self = setmetatable({} :: ComputeBuffer, ComputeBuffer)
	self.name = name
	self._bufferName = SHARED_TABLE_PREFIX..name
	return self
end

--[=[
	Get the data of the ComputeBuffer
	@since v1.0.0
	@tag Parallel Unsafe

	@return ComputeBufferDataType -- The data of the buffer, a read-only table
]=]
function ComputeBuffer.GetData(self: ComputeBuffer): SharedTable
	local data = SharedTableRegistry:GetSharedTable(self._bufferName)
	return data
end

--[=[
	Set the data of the ComputeBuffer. Be careful to only call this when no workers are working
	@since v1.0.0
	@tag Parallel Unsafe

	@param bufferData ComputeBufferDataType -- The data to set the buffer with, only certain data types are allowed.
]=]
function ComputeBuffer.SetData(self: ComputeBuffer, bufferData: ComputeBufferDataType): ()
	assert(doesComputeBufferDataHaveCorrectTyping(bufferData), "bufferData must have only elements that are acceptable compute buffer types")

	local sharedTable = SharedTable.new(bufferData)
	SharedTableRegistry:SetSharedTable(self._bufferName, sharedTable)
end

--[=[
	The cleanup function for a ComputeBuffer. This is important to call to free up memory
	@since v1.0.0
	@tag Parallel Unsafe
]=]
function ComputeBuffer.Clean(self: ComputeBuffer): ()
	SharedTableRegistry:SetSharedTable(self._bufferName, nil)
	table.clear(self)
	table.freeze(self)
end

--[=[
	@class ComputeLua

	Main module for ComputeLua, holds all the functions to manage ComputeBuffers, Dispatchers, threads, and more.

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
	Create a ComputeBuffer to store vital information that is then sent to each worker.
	@since v1.0.0
	@tag Parallel Unsafe

	@param bufferName string -- The name of the buffer.
	@return ComputeBuffer
]=]
function ComputeLua.CreateComputeBuffer(bufferName: string): ComputeBuffer
	return ComputeBuffer._new(bufferName)
end

--[=[
	Get the ComputeBuffer data
	@since v1.0.0
	@tag Serial Unsafe

	@param bufferName string -- The name of the buffer.
	@return ComputeBufferDataType -- The data of the ComputeBuffer
]=]
function ComputeLua.GetComputeBufferData(bufferName: string): SharedTable
	assert(type(bufferName) == "string", "bufferName must be a string")
	return SharedTableRegistry:GetSharedTable(SHARED_TABLE_PREFIX..bufferName)
end

--[=[
	Create a thread for the Dispatcher to execute
	@since v1.1.0
	@tag Serial Unsafe

	@param actor Actor -- The Actor to bind the thread to, this should be the same actor as the parent of the worker.
	@param threadName string -- The unique name of the thread.
	@param callback (dispatchId: number, variableBuffer: VariableBufferDataType) -> () -- The function that will be executed when the thread is called
]=]
function ComputeLua.CreateThread(actor: Actor, threadName: string, callback: (number, VariableBufferDataType) -> ())
	assert(typeof(actor) == "Instance", "actor must be an Actor")
	assert(type(threadName) == "string", "threadName must be a string")
	assert(type(callback) == "function", "callback must be a function")
	assert(actor:IsA("Actor"), "actor must be an Actor instance")

	actor:BindToMessageParallel(threadName, function(
		startDispatchId: number, 
		batchSize: number,
		finishRemote: BindableEvent, 
		variableBuffer: ComputeLua.VariableBufferDataType
	)
		for i = startDispatchId, startDispatchId + (batchSize - 1) do
			callback(i, variableBuffer)
		end
		finishRemote:Fire()
	end)
end

return ComputeLua

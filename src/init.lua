-- ComputeLua
-- blorbee
-- Stable Release (1.1.0) - 4/24/2024

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

    The class responsible for handling and dispatching workers.
]=]
local Dispatcher = {}
Dispatcher.__index = Dispatcher

local SHARED_TABLE_PREFIX = "ComputeLua-"
local VARIABLE_BUFFER_NAME = SHARED_TABLE_PREFIX.."VARIABLE_BUFFER"

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
	variableBuffer: VariableBufferDataType,

	Dispatch: (self: Dispatcher, numThreads: number, thread: string, randomDispatch: boolean) -> Promise,
	SetVariableBuffer: (self: Dispatcher, variableBuffer: VariableBufferDataType) -> (),
	Destroy: (self: Dispatcher) -> ()
}

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

--[[
	Dispatch a thread to the workers. Use this to get the workers to do a job, 
	this should only be called in serial context by a non-worker
	
	@param numThreads How many times to run a worker, this cannot exceed the number of workers. 
						Match the size of the compute buffer if you are using a compute buffer
	@param thread The name of the thread to run, this will match the BindToMessageParallel() message name
	@param randomDispatch **NOT RECOMMENDED UNLESS YOU KNOW WHAT YOU ARE DOING** Defaults to 'true'
							When false, it ensures that every worker is called only once, 
							this is useful if you want only one worker doing one job
	@returns Promise
--]]
function Dispatcher.Dispatch(self: Dispatcher, numThreads: number, thread: string, randomDispatch: boolean?): Promise
	assert(type(numThreads) == "number", "numThreads must be a number")
	assert(type(thread) == "string", "thread must be a string")
	if randomDispatch == nil then
		randomDispatch = true
	end
	assert(type(randomDispatch) == "boolean", "randomDispatch must be a boolean")

	if not randomDispatch then
		assert(numThreads <= self.numWorkers, "numThreads cannot exceed numWorkers if not using random dispatch")
	end

	local workersFinished = 0
	local timeout = 60

	return Promise.defer(function(res, rej)
		local timedOut = false
		local connection = nil
		task.delay(timeout, function()
			if workersFinished < numThreads then
				timedOut = true
				if connection ~= nil then
					connection:Disconnect()
				end
				connection = nil
				rej()
			end
		end)

		connection = self.workerRemote.Event:Connect(function()
			workersFinished += 1
		end)
		
		local variableBufferShared = SharedTable.cloneAndFreeze(SharedTable.new(self.variableBuffer), true)
		
		for i = 1, numThreads do
			if randomDispatch then
				self.workers[self.rand:NextInteger(1, self.numWorkers)]:SendMessage(thread, i, self.workerRemote, variableBufferShared)
			else
				self.workers[i]:SendMessage(thread, i, self.workerRemote, variableBufferShared)
			end
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

--[[
	Set the variable buffer data to send to the workers, this should only be called in serial context by a non-worker
	Only certain types are allowed to be sent to workers
	Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | string
	And the only type of index the data can use is a number. 
	
	@param variableBuffer The list of variable elements
--]]
function Dispatcher.SetVariableBuffer(self: Dispatcher, variableBuffer: VariableBufferDataType): ()
	assert(doesVariableBufferHaveCorrectTyping(variableBuffer), "variableData must have only elements that are acceptable variable buffer types")
	self.variableBuffer = variableBuffer
end

--[[
	Make sure to call this when you are done using the Dispatcher
	It will get rid of all the workers
--]]
function Dispatcher.Destroy(self: Dispatcher): ()
	for i = 1, self.numWorkers do
		self.workers[i]:Destroy()
	end
	self.workerRemote:Destroy()
	self.workerFolder:Destroy()
	table.clear(self)
	table.freeze(self)
end

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

function ComputeBuffer._new(name: string): ComputeBuffer
	assert(type(name) == "string", "bufferName must be a string")

	local self = setmetatable({} :: ComputeBuffer, ComputeBuffer)
	self.name = name
	self._bufferName = SHARED_TABLE_PREFIX..name
	return self
end

--[[
	Get the data of the Compute Buffer, this should only be called in serial context by a non-worker
	
	@returns SharedTable The data of the buffer, this is a read-only table
--]]
function ComputeBuffer.GetData(self: ComputeBuffer): SharedTable
	local data = SharedTableRegistry:GetSharedTable(self._bufferName)
	return SharedTable.cloneAndFreeze(data, true)
end

--[[
	Set the data of the Compute Buffer, this should only be called in serial context by a non-worker
	Only certain types are allowed to be sent to workers
	Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | string
	And the only type of index the data can use is a number. 
	Each worker will use it's dispatch ID to figure out which one it is working on
	
	@param bufferData The data to set the buffer with, only certain types is allowed to be in this table
--]]
function ComputeBuffer.SetData(self: ComputeBuffer, bufferData: ComputeBufferDataType): ()
	assert(doesComputeBufferDataHaveCorrectTyping(bufferData), "bufferData must have only elements that are acceptable compute buffer types")

	local sharedTable = SharedTable.new(bufferData)
	SharedTableRegistry:SetSharedTable(self._bufferName, sharedTable)
end

--[[
	Make sure to call this when you are done using the buffer. 
	This cleans up all the memory it is using
--]]
function ComputeBuffer.Clean(self: ComputeBuffer): ()
	SharedTableRegistry:SetSharedTable(self._bufferName, nil)
	table.clear(self)
	table.freeze(self)
end

local ComputeLua: ComputeLua = {}

--[[
	Create a Dispatcher to run a bunch of workers in parallel
	
	@param numWorkers The amount of workers to use, balance this with performance and speed
	@param worker The script to use as a template for the worker. This must be a Script or LocalScript, 
					this is also the parent of the workers so the worker should be able to run in its current location
	@returns Dispatcher
--]]
function ComputeLua.CreateDispatcher(numWorkers: number, worker: Script | LocalScript): Dispatcher
	return Dispatcher._new(numWorkers, worker)
end

--[[
	Create a Compute Buffer which stores data that is sent to each worker
	Every element a part of the buffer's data must be of certain types, more information about the types at ComputeBuffer.SetData()
	This should never be called while in parallel context or within a worker
	
	@param bufferName The name of the Compute Buffer, this must match whatever the worker is going to use
	@returns ComputeBuffer
--]]
function ComputeLua.CreateComputeBuffer(bufferName: string): ComputeBuffer
	return ComputeBuffer._new(bufferName)
end

--[[
	Get the Compute Buffer data, this should only be called within a worker while in parallel
	
	@param bufferName The name of the Compute Buffer, this must match whatever the worker is going to use
	@returns SharedTable The data of the Compute Buffer
--]]
function ComputeLua.GetComputeBufferData(bufferName: string): SharedTable
	assert(type(bufferName) == "string", "bufferName must be a string")
	return SharedTableRegistry:GetSharedTable(SHARED_TABLE_PREFIX..bufferName)
end

--[[
	Create a thread with a callback, this should only be called within a worker while in parallel
	
	@param actor The actor to use, (script:GetActor())
	@param threadName The name of the thread, this should be unique
	@param callback The function that will be called when the thread is called
--]]
function ComputeLua.CreateThread(actor: Actor, threadName: string, callback: (number, VariableBufferDataType) -> ())
	assert(typeof(actor) == "Instance", "actor must be an Actor")
	assert(type(threadName) == "string", "threadName must be a string")
	assert(type(callback) == "function", "callback must be a function")
	assert(actor:IsA("Actor"), "actor must be an Actor instance")
	
	actor:BindToMessageParallel(threadName, function(
		id: number, 
		finishRemote: BindableEvent, 
		variableBuffer: ComputeLua.VariableBufferDataType
	)
		callback(id, variableBuffer)
		finishRemote:Fire()
	end)
end

return ComputeLua

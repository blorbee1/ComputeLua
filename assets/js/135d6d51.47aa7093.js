"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[300],{28665:e=>{e.exports=JSON.parse('{"functions":[{"name":"_new","desc":"Create a Dispatcher","params":[{"name":"numWorkers","desc":"How many workers to create","lua_type":"number"},{"name":"worker","desc":"The worker template to use","lua_type":"Script | LocalScript"}],"returns":[{"desc":"","lua_type":"Dispatcher"}],"function_type":"static","tags":["Parallel Unsafe"],"since":"v1.0.0","private":true,"source":{"line":203,"path":"src/init.lua"}},{"name":"Dispatch","desc":"Dispatch a number of threads to the workers","params":[{"name":"self","desc":"","lua_type":"Dispatcher"},{"name":"numThreads","desc":"How many workers will be invoked to run their code. If using serial dispatch, this cannot exceed the number of workers. Try to match the size of data you are going to process if you are not using a serial dispatch.","lua_type":"number"},{"name":"thread","desc":"The name of the thread to dispatch, this is the same name as the one in the workers","lua_type":"string"},{"name":"useSerialDispatch","desc":"**NOT RECOMMENDED UNLESS YOU KNOW WHAT YOU ARE DOING** Default to \'true\'. This will cause every worker to only be called once.","lua_type":"boolean?"}],"returns":[{"desc":"","lua_type":"Promise"}],"function_type":"static","tags":["Parallel Unsafe"],"since":"v1.0.0","source":{"line":249,"path":"src/init.lua"}},{"name":"SetVariableBuffer","desc":"Set the data of the SetVariableBuffer for this Dispatcher. Be careful to only call this when no workers are working","params":[{"name":"self","desc":"","lua_type":"Dispatcher"},{"name":"bufferData","desc":"The data to set the variable buffer to.","lua_type":"VariableBufferDataType"}],"returns":[],"function_type":"static","tags":["Parallel Unsafe"],"since":"v1.0.0","source":{"line":314,"path":"src/init.lua"}},{"name":"Destroy","desc":"The cleanup function for a Dispatcher. This is important to call to free up memory","params":[{"name":"self","desc":"","lua_type":"Dispatcher"}],"returns":[],"function_type":"static","tags":["Parallel Unsafe"],"since":"v1.0.0","source":{"line":324,"path":"src/init.lua"}}],"properties":[{"name":"numWorkers","desc":"How many workers this Dispatcher has","lua_type":"number","readonly":true,"source":{"line":100,"path":"src/init.lua"}},{"name":"variableBuffer","desc":"The current VariableBuffer data","lua_type":"VariableBufferDataType","private":true,"readonly":true,"source":{"line":107,"path":"src/init.lua"}},{"name":"worker","desc":"The worker template","lua_type":"Script | LocalScript","private":true,"readonly":true,"source":{"line":114,"path":"src/init.lua"}},{"name":"workerFolder","desc":"The worker holder folder","lua_type":"Folder","private":true,"readonly":true,"source":{"line":121,"path":"src/init.lua"}},{"name":"workers","desc":"The workers\' actors","lua_type":"{Actor}","private":true,"readonly":true,"source":{"line":128,"path":"src/init.lua"}},{"name":"workerRemote","desc":"The remote that a worker calls when it finished working","lua_type":"BindableEvent","private":true,"readonly":true,"source":{"line":135,"path":"src/init.lua"}}],"types":[{"name":"BufferDataType","desc":"The only data types allowed in buffers, Compute or Variable","lua_type":"Vector2 | Vector3 | CFrame | Color3 | UDim | UDim2 | number | boolean | string","source":{"line":43,"path":"src/init.lua"}},{"name":"VariableBufferDataType","desc":"Type for the data of the VariableBuffer","lua_type":"{ [number]: BufferDataType }","source":{"line":64,"path":"src/init.lua"}}],"name":"Dispatcher","desc":"Responsible for handling and dispatching workers. \\nThis should never be created by a worker or in parallel.\\n\\n```lua\\nlocal ReplicatedStorage = game:GetService(\\"ReplicatedStorage\\")\\n\\nlocal workerTemplate = script.Worker\\nlocal numWorkers = 64\\n\\nlocal ComputeLua = require(ReplicatedStorage.ComputeLua)\\nlocal Dispatcher = ComputeLua.CreateDispatcher(numWorkers, workerTemplate)\\n```","source":{"line":33,"path":"src/init.lua"}}')}}]);
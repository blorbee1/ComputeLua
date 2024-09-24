## **1.3.0**

---

* Huge performance increases
* Reworked how workers return their data
* ComputeBuffers are now linked to Dispatchers
* The VariableBuffer has been removed
* Added `ComputeLua.GetBufferDataKey: (bufferName: string) -> number`
* Removed `ComputeLua.CreateComputeBuffer`
* Added `Dispatcher.SetComputeBuffer: (self: Dispatcher, bufferName: string, bufferData: ComputeBufferDataType) -> ()`
* Added `Dispatcher.DestroyComputeBuffer: (self: Dispatcher, bufferName: string) -> ()`
* Removed `Dispatcher.SetVariableBuffer`

## **1.2.1**

---

* Fixed typo in documentation

## **1.2.0**

---

* Added the ability to edit the batch size
* Fixed batch size not working correctly
* Fixed batches breaking if it was less than the amount of threads
* Fixed typo in documentation

## **1.1.1**

---

* Performance increase

## **1.1.0**

---

* Added `ComputeLua.CreateThead(actor: Actor, threadName: name, callback: (number, VariableBufferDataType) -> ())`
* Changed `Dispatcher:Dispatch()` to return a `Promise.defer()`
* Variable Buffer is now a SharedTable

## **1.0.0**

---

* Initial release
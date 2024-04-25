# ComputeLua

---

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
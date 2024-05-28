"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[982],{3905:(e,t,r)=>{r.d(t,{Zo:()=>p,kt:()=>f});var a=r(67294);function n(e,t,r){return t in e?Object.defineProperty(e,t,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[t]=r,e}function i(e,t){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);t&&(a=a.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),r.push.apply(r,a)}return r}function o(e){for(var t=1;t<arguments.length;t++){var r=null!=arguments[t]?arguments[t]:{};t%2?i(Object(r),!0).forEach((function(t){n(e,t,r[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):i(Object(r)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(r,t))}))}return e}function l(e,t){if(null==e)return{};var r,a,n=function(e,t){if(null==e)return{};var r,a,n={},i=Object.keys(e);for(a=0;a<i.length;a++)r=i[a],t.indexOf(r)>=0||(n[r]=e[r]);return n}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(a=0;a<i.length;a++)r=i[a],t.indexOf(r)>=0||Object.prototype.propertyIsEnumerable.call(e,r)&&(n[r]=e[r])}return n}var s=a.createContext({}),c=function(e){var t=a.useContext(s),r=t;return e&&(r="function"==typeof e?e(t):o(o({},t),e)),r},p=function(e){var t=c(e.components);return a.createElement(s.Provider,{value:t},e.children)},u="mdxType",h={inlineCode:"code",wrapper:function(e){var t=e.children;return a.createElement(a.Fragment,{},t)}},d=a.forwardRef((function(e,t){var r=e.components,n=e.mdxType,i=e.originalType,s=e.parentName,p=l(e,["components","mdxType","originalType","parentName"]),u=c(r),d=n,f=u["".concat(s,".").concat(d)]||u[d]||h[d]||i;return r?a.createElement(f,o(o({ref:t},p),{},{components:r})):a.createElement(f,o({ref:t},p))}));function f(e,t){var r=arguments,n=t&&t.mdxType;if("string"==typeof e||n){var i=r.length,o=new Array(i);o[0]=d;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l[u]="string"==typeof e?e:n,o[1]=l;for(var c=2;c<i;c++)o[c]=r[c];return a.createElement.apply(null,o)}return a.createElement.apply(null,r)}d.displayName="MDXCreateElement"},2509:(e,t,r)=>{r.r(t),r.d(t,{assets:()=>s,contentTitle:()=>o,default:()=>h,frontMatter:()=>i,metadata:()=>l,toc:()=>c});var a=r(87462),n=(r(67294),r(3905));const i={sidebar_position:3},o="Dispatcher",l={unversionedId:"dispatcher",id:"dispatcher",title:"Dispatcher",description:"The Dispatcher is the main class that will handle all the workers and threads. You can multiple Dispatchers if you want, but they will have their own workers.",source:"@site/docs/dispatcher.md",sourceDirName:".",slug:"/dispatcher",permalink:"/ComputeLua/docs/dispatcher",draft:!1,editUrl:"https://github.com/blorbee1/ComputeLua/edit/main/docs/dispatcher.md",tags:[],version:"current",sidebarPosition:3,frontMatter:{sidebar_position:3},sidebar:"defaultSidebar",previous:{title:"Getting Started",permalink:"/ComputeLua/docs/gettingstarted"},next:{title:"Compute Buffer",permalink:"/ComputeLua/docs/computebuffer"}},s={},c=[{value:"Creating a Dispatcher",id:"creating-a-dispatcher",level:2},{value:"Dispatching Threads",id:"dispatching-threads",level:2},{value:"Example",id:"example",level:2}],p={toc:c},u="wrapper";function h(e){let{components:t,...r}=e;return(0,n.kt)(u,(0,a.Z)({},p,r,{components:t,mdxType:"MDXLayout"}),(0,n.kt)("h1",{id:"dispatcher"},"Dispatcher"),(0,n.kt)("p",null,"The Dispatcher is the main class that will handle all the workers and threads. You can multiple Dispatchers if you want, but they will have their own workers."),(0,n.kt)("h2",{id:"creating-a-dispatcher"},"Creating a Dispatcher"),(0,n.kt)("p",null,"To create a Dispatcher you will just need to call ",(0,n.kt)("inlineCode",{parentName:"p"},"ComputeLua.CreateDispatcher()")," with the correct arguments. This will return a Dispatcher which can be used to dispatch a thread or update the Variable Buffer."),(0,n.kt)("p",null,(0,n.kt)("inlineCode",{parentName:"p"},"Dispatcher:SetVariableBuffer()")," This will set the Variable Buffer's data. Make sure your table's data matchs the allowed data types or it will throw an error. This should be called before the Dispatcher is dispatched. If it is called while the workers are working, then you may lose data or the workers will be unable to work correctly."),(0,n.kt)("admonition",{type:"caution"},(0,n.kt)("p",{parentName:"admonition"},"The Variable Buffer's data is a read-only table. If you try to manually modify it within a worker or a non-worker (outside the ",(0,n.kt)("inlineCode",{parentName:"p"},"Dispatcher:SetVariableBuffer()")," method), it will throw an error.")),(0,n.kt)("hr",null),(0,n.kt)("h2",{id:"dispatching-threads"},"Dispatching Threads"),(0,n.kt)("p",null,"Dispatching a thread is very simple. All you need to do is call ",(0,n.kt)("inlineCode",{parentName:"p"},"Dispatcher:Dispatch()")," with the correct arguments. This will return a Promise so you can process that Promise as you please."),(0,n.kt)("p",null,"Once the Promise is resolved, then it is safe to get the data from the Compute Buffers if you have any. Before the Promise is resolved, that you may get unfinished data or just the original data."),(0,n.kt)("hr",null),(0,n.kt)("h2",{id:"example"},"Example"),(0,n.kt)("pre",null,(0,n.kt)("code",{parentName:"pre",className:"language-lua"},'local ReplicatedStorage = game:GetService("ReplicatedStorage")\n\nlocal workerTemplate = script.Worker\nlocal numWorkers = 128 -- I want to have a total worker count of 128\n\nlocal ComputeLua = require(ReplicatedStorage.ComputeLua)\nlocal Dispatcher = ComputeLua.CreateDispatcher(numWorkers, workerTemplate)\n\nlocal PositionBuffer = ComputeLua.CreateComputeBuffer("PositionBuffer")\nlocal startingData = table.create(64, Vector3.zero) -- This will precreate a table with 64 elements all with Vector3.zero as the value\n\nPositionBuffer:SetData(startingData)\n\nDispatcher:Dispatch(64, "CalculatePositions"):andThen(function()\n    local data = PositionBuffer:GetData() -- Get the data back from the PositionBuffer which should have all the new positions\n    print("Starting data:")\n    print(startingData)\n    print("Resulting data:")\n    print(data)\nend)\n')))}h.isMDXComponent=!0}}]);
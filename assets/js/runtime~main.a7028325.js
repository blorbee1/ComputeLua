(()=>{"use strict";var e,t,r,d,o,a={},f={};function n(e){var t=f[e];if(void 0!==t)return t.exports;var r=f[e]={exports:{}};return a[e].call(r.exports,r,r.exports,n),r.exports}n.m=a,e=[],n.O=(t,r,d,o)=>{if(!r){var a=1/0;for(b=0;b<e.length;b++){r=e[b][0],d=e[b][1],o=e[b][2];for(var f=!0,c=0;c<r.length;c++)(!1&o||a>=o)&&Object.keys(n.O).every((e=>n.O[e](r[c])))?r.splice(c--,1):(f=!1,o<a&&(a=o));if(f){e.splice(b--,1);var i=d();void 0!==i&&(t=i)}}return t}o=o||0;for(var b=e.length;b>0&&e[b-1][2]>o;b--)e[b]=e[b-1];e[b]=[r,d,o]},n.n=e=>{var t=e&&e.__esModule?()=>e.default:()=>e;return n.d(t,{a:t}),t},r=Object.getPrototypeOf?e=>Object.getPrototypeOf(e):e=>e.__proto__,n.t=function(e,d){if(1&d&&(e=this(e)),8&d)return e;if("object"==typeof e&&e){if(4&d&&e.__esModule)return e;if(16&d&&"function"==typeof e.then)return e}var o=Object.create(null);n.r(o);var a={};t=t||[null,r({}),r([]),r(r)];for(var f=2&d&&e;"object"==typeof f&&!~t.indexOf(f);f=r(f))Object.getOwnPropertyNames(f).forEach((t=>a[t]=()=>e[t]));return a.default=()=>e,n.d(o,a),o},n.d=(e,t)=>{for(var r in t)n.o(t,r)&&!n.o(e,r)&&Object.defineProperty(e,r,{enumerable:!0,get:t[r]})},n.f={},n.e=e=>Promise.all(Object.keys(n.f).reduce(((t,r)=>(n.f[r](e,t),t)),[])),n.u=e=>"assets/js/"+({13:"931ae152",15:"572cd6d1",33:"55185c05",53:"935f2afb",85:"1f391b9e",159:"a4c8fbc0",216:"3c460bdf",300:"135d6d51",326:"6ae618c0",374:"d3874e59",391:"da7e18d7",465:"3061bed7",514:"1be78505",556:"8deedfb8",570:"9217916a",616:"5e867df4",627:"c4d0d0d8",669:"a31da6c8",671:"0e384e19",849:"5ff44994",909:"b019829d",918:"17896441",960:"d8353890",975:"c01f7b99",982:"ed08a624"}[e]||e)+"."+{13:"fe2e1887",15:"f0de43f0",33:"3fd594f0",53:"ae3a393a",85:"324eb1d3",159:"db674474",216:"5e96ab15",289:"3adf4ac8",300:"de2e24e3",326:"165aebac",339:"ea7d7f66",343:"0365238a",374:"f541d14d",391:"e6b2b30b",465:"7492f75a",514:"c96f2a93",556:"82dca478",570:"832232b3",616:"3efc3413",627:"ef77383a",669:"4b19b7a6",671:"d52f2cba",849:"99f6a674",878:"27baceba",909:"32ecc09d",918:"74242fc9",960:"577be47e",972:"b370daa7",975:"651e6b22",982:"572c9628"}[e]+".js",n.miniCssF=e=>{},n.g=function(){if("object"==typeof globalThis)return globalThis;try{return this||new Function("return this")()}catch(e){if("object"==typeof window)return window}}(),n.o=(e,t)=>Object.prototype.hasOwnProperty.call(e,t),d={},o="docs:",n.l=(e,t,r,a)=>{if(d[e])d[e].push(t);else{var f,c;if(void 0!==r)for(var i=document.getElementsByTagName("script"),b=0;b<i.length;b++){var u=i[b];if(u.getAttribute("src")==e||u.getAttribute("data-webpack")==o+r){f=u;break}}f||(c=!0,(f=document.createElement("script")).charset="utf-8",f.timeout=120,n.nc&&f.setAttribute("nonce",n.nc),f.setAttribute("data-webpack",o+r),f.src=e),d[e]=[t];var l=(t,r)=>{f.onerror=f.onload=null,clearTimeout(s);var o=d[e];if(delete d[e],f.parentNode&&f.parentNode.removeChild(f),o&&o.forEach((e=>e(r))),t)return t(r)},s=setTimeout(l.bind(null,void 0,{type:"timeout",target:f}),12e4);f.onerror=l.bind(null,f.onerror),f.onload=l.bind(null,f.onload),c&&document.head.appendChild(f)}},n.r=e=>{"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},n.p="/ComputeLua/",n.gca=function(e){return e={17896441:"918","931ae152":"13","572cd6d1":"15","55185c05":"33","935f2afb":"53","1f391b9e":"85",a4c8fbc0:"159","3c460bdf":"216","135d6d51":"300","6ae618c0":"326",d3874e59:"374",da7e18d7:"391","3061bed7":"465","1be78505":"514","8deedfb8":"556","9217916a":"570","5e867df4":"616",c4d0d0d8:"627",a31da6c8:"669","0e384e19":"671","5ff44994":"849",b019829d:"909",d8353890:"960",c01f7b99:"975",ed08a624:"982"}[e]||e,n.p+n.u(e)},(()=>{var e={303:0,532:0};n.f.j=(t,r)=>{var d=n.o(e,t)?e[t]:void 0;if(0!==d)if(d)r.push(d[2]);else if(/^(303|532)$/.test(t))e[t]=0;else{var o=new Promise(((r,o)=>d=e[t]=[r,o]));r.push(d[2]=o);var a=n.p+n.u(t),f=new Error;n.l(a,(r=>{if(n.o(e,t)&&(0!==(d=e[t])&&(e[t]=void 0),d)){var o=r&&("load"===r.type?"missing":r.type),a=r&&r.target&&r.target.src;f.message="Loading chunk "+t+" failed.\n("+o+": "+a+")",f.name="ChunkLoadError",f.type=o,f.request=a,d[1](f)}}),"chunk-"+t,t)}},n.O.j=t=>0===e[t];var t=(t,r)=>{var d,o,a=r[0],f=r[1],c=r[2],i=0;if(a.some((t=>0!==e[t]))){for(d in f)n.o(f,d)&&(n.m[d]=f[d]);if(c)var b=c(n)}for(t&&t(r);i<a.length;i++)o=a[i],n.o(e,o)&&e[o]&&e[o][0](),e[o]=0;return n.O(b)},r=self.webpackChunkdocs=self.webpackChunkdocs||[];r.forEach(t.bind(null,0)),r.push=t.bind(null,r.push.bind(r))})()})();
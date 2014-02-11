# Elastic Search API
## Basic node.js library to access elastic search functionality.

[![Build Status](https://travis-ci.org/data-avail/baio-es.png?branch=master)](https://travis-ci.org/data-avail/baio-es)

##Install
`npm install baio-es`

##Test
`npm test`

##Build
Gulp demands node version >= 0.10

`gulp --require coffee-script/register`

##API reference
[API](http://data-avail.github.com/baio-es/es.html)

## Features

+ All queries return [Q](https://github.com/kriskowal/q) promises
+ Injectors for `http` and `log` modules
+ Add custom queries easily

### Q promises
Each function in library return [Q](https://github.com/kriskowal/q) promise, no more callbacks!

### Injectors
Use custom `http` or `log` module

#### Http module
Inject - `es.injector("$http", ...);`

Module should expose `request(opts)` method with `Q` promise to return resulted response in JSON object

```
    //opts structure
    {
        uri : "http://...", //request uri to elastic search server
        method : "get", //get, post or delete http method
        json : {}, //json formatted data for server
        json : {}, //string data pass for server
    }
```

Promise should return response from elastic search server (json formatted)

#### Log module
Inject - `es.injector("$log", ...);`

Should expose `log` method similar to standard `console.log`

#### Custom queries

Add custom query

```
    es.queryTemplates.admin_cookies_count_tripled =
     parent : "count"
     req: (opts) -> #format data to send
      bool :
        must :
          term :
            user : "admin"
          term :
            cookie_type : opts.cookie_type
     resp: (res) -> res * 3 #parse data when received

    #find!
    es.query("admin_cookies_count_tripled", {cookie_type : "chocolate"}).then (cnt) ->
        console.log(cnt)

    es.query("admin_cookies_count_tripled", {cookie_type : "lemon"}).then (cnt) ->
        console.log(cnt)
```

`parent` property

+ Define which another `query.req` formatter will be used to format data, after current `req` formatting.
+ When data received from server they will be passed to previous formatters in chain then result of transformation will be passed to `resp` method.

Chain of custom queries could be created as needed.

2014 Max Putilov, Data-Avail

Baio-es may be freely distributed under the MIT license.










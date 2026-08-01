var connect = require('connect');
var express = require('express');
var http = require('http');
var fs = require('fs');
var serveStatic = require('serve-static');
var morgan  = require('morgan');
var colors = require('colors');
var	argv = require('optimist').argv;
var	portfinder = require('portfinder');
var path = require('path');
var logger, port;
var log = console.log;
var proxy = require('express-http-proxy');
var slow = require('connect-slow');
var url = require('url');

function start() {
 // if (!argv.ip) { argv.ip = '127.0.0.01'; }
 var addr = '127.0.0.1';
 if(argv.listen) { addr = argv.listen; }
 var tmp = addr.split(':');
 var options = {};
 options.address = tmp.shift();
 options.port = tmp.shift();
 if (!options.port) {
    portfinder.basePort = 8080;
    portfinder.getPort(function (err, openPort) {
      if (err) throw err;
      options.port = openPort
      listen(options);
    });
  } else {
    listen(options);
  }
}

//CORS middleware
function allowCrossDomain(req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
    res.header('Access-Control-Allow-Headers', 'Content-Type');

    next();
}

function setHeaders(res, path) {
  if ( false && path.indexOf(".opf") > -1 ) {
    res.setHeader('Content-Type', 'text/html');
  }
}

function listen(options) {

  var app = express();
  var staticServer = serveStatic(path.resolve(__dirname, '../../'), {
    'index': ['index.html', 'index.htm'],
    'setHeaders': setHeaders
  })
  var appPath = path.resolve(__dirname + '/../../');
  var indexPaths = process.env.EPUB3_PATH || 'epub3-local:epub3-samples';
  indexPaths = indexPaths.split(':');
  for(var i = 0; i < indexPaths.length; i++) {
    if ( indexPaths[i].substr(0,1) != '/' ) {
      indexPaths[i] = path.resolve(appPath, indexPaths[i]);
    }
  }

  var server = http.createServer(app);

  app.use(allowCrossDomain);
  if ( process.env.USE_SLOW ) {
    log(`Delaying requests ${process.env.USE_SLOW}`.yellow);
    app.use(slow({
      url: /\/epub3/i,
      delay: process.env.USE_SLOW
    }));
  }

  if ( process.env.USE_DEV_EPUB ) {
    if ( process.env.USE_DEV_EPUB.indexOf('http://') > -1 ) {
      app.use('/cozy-sun-bear/vendor/javascripts/engines/', proxy(process.env.USE_DEV_EPUB, { 
        https: false,
        forwardPath: function(req) {
          return '/dist' + require('url').parse(req.url).path;
        }
      }));
    } else {
      var epubJsPath = path.resolve(process.env.USE_DEV_EPUB);
      app.get('/cozy-sun-bear/vendor/javascripts/engines/epub.js', function(req, res) {
        res.sendFile(epubJsPath + '/epub.js');
      });
      app.get('/cozy-sun-bear/vendor/javascripts/engines/epub.js.map', function(req, res) {
        res.sendFile(epubJsPath + '/epub.js.map');
      });
      app.get('/cozy-sun-bear/vendor/javascripts/engines/epub.legacy.min.js', function(req, res) {
        res.sendFile(epubJsPath + '/epub.legacy.min.js');
      });
      app.get('/cozy-sun-bear/vendor/javascripts/engines/epub.legacy.js', function(req, res) {
        res.sendFile(epubJsPath + '/epub.legacy.js');
      });
      app.get('/cozy-sun-bear/vendor/javascripts/engines/epub.legacy.js.map', function(req, res) {
        res.sendFile(epubJsPath + '/epub.legacy.js.map');
      });      
    }
  }

  if ( process.env.USE_EPUB_SEARCH ) {
    var search_config = url.parse(process.env.USE_EPUB_SEARCH);
    app.use('/cozy-sun-bear/epub_search', proxy(process.env.USE_EPUB_SEARCH, { 
      https: true,
      forwardPath: function(req) {
        return search_config.path + '?q=' + req.query.q;
      }
    }));
  } else {
    app.get('/cozy-sun-bear/epub_search/:bookId(*)', function(req, res) {
      var filename = req.params.bookId.replace(/\/$/, '').split("/").pop() + '.json';
      console.log("AHOY SEARCH LOOKING FOR", appPath + '/cozy-sun-bear/examples/epub_search/' + filename);
      if ( fs.existsSync(appPath + '/cozy-sun-bear/examples/search/' + filename) ) {
        console.log("AHOY SENDING ", filename);
        res.sendFile(appPath + '/cozy-sun-bear/examples/search/' + filename)
      } else {
        console.log("AHOY SENDING SAMPLE RESULTS");
        res.sendFile(appPath + '/cozy-sun-bear/examples/search/sample_results.json');
      }
    })
  }

  app.get('/cozy-sun-bear/examples/books.json', function(req, res) {
    var books = [];
    var queue = indexPaths.slice(0);
    while ( queue.length ) {
      var thisPath = queue.shift();
      var items = fs.readdirSync(thisPath);
      for(var i in items) {
        if ( items[i][0] == '.' ) { continue; }
        var fullPath = path.resolve(thisPath, items[i]);
        var stat = fs.statSync(fullPath);
        if ( stat.isDirectory() ) {
          if ( fs.existsSync(path.resolve(fullPath, "mimetype")) ) {
            // actual book
            var indexPathInfo = fullPath.replace(appPath, '');
            books.push(indexPathInfo + "/");
          } else {
            queue.push(fullPath);
          }
        }
      }
    }
    res.send(books);
  })
  app.use('/common', proxy('https://babel.hathitrust.org/common', { 
    https: true,
    forwardPath: function(req) {
      return '/common' + require('url').parse(req.url).path;
    }
  }));
  app.use(staticServer);

  if(!logger) app.use(morgan('dev'))

  server.listen(options.port, options.address);

  log('Starting up Server, serving '.yellow
    + __dirname.replace("tools", '').green
    + ' on port: '.yellow
    + `${options.address}:${options.port}`.cyan);
  log('Hit CTRL-C to stop the server');

}

process.on('SIGINT', function () {
  log('Server stopped.'.red);
  process.exit();
});

module.exports = start;

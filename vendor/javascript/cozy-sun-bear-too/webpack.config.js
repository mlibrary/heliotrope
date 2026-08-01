var webpack = require("webpack");
var path = require("path");
var MINIMIZE = (process.env.MINIMIZE === "true")
var hostname = "localhost";
var port = 8080;

var filename = "[name]";
filename = 'cozy-sun-bear';
var sourceMapFilename = "cozy-sun-bear";
if (MINIMIZE) {
  filename += ".min.js";
  sourceMapFilename += ".min.js.map";
} else {
  filename += ".js";
  sourceMapFilename += ".js.map";
}

var LEGACY=false;

module.exports = {
  mode: process.env.NODE_ENV,
  entry: {
    "epub": "./src/cozy.js",
  },
  devtool: MINIMIZE ? false : 'source-map',
  output: {
    path: path.resolve(__dirname, "./dist"),
    filename: filename,
    sourceMapFilename: sourceMapFilename,
    library: "cozy",
    libraryTarget: "umd",
    libraryExport: "default",
    publicPath: "/dist/"
  },
  optimization: {
    minimize: MINIMIZE
  },
  externals: {
    "jszip/dist/jszip": "JSZip",
    "xmldom": "xmldom"
  },
  resolve: {
    alias: {
      path: "path-webpack"
    }
  },
  devServer: {
    host: hostname,
    port: port,
    inline: true,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,PUT,POST,DELETE",
      "Access-Control-Allow-Headers": "Content-Type"
    }
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
          options: {
            presets: ["@babel/preset-env"]
          }
        }
      }
    ]
  },
  performance: {
    hints: false
  }
}

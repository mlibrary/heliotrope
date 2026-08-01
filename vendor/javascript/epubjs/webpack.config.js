var webpack = require("webpack");
var path = require("path");
var PROD = (process.env.NODE_ENV === "production")
var LEGACY = (process.env.LEGACY)
var MINIMIZE = (process.env.MINIMIZE === "true")
var hostname = "localhost";
var port = 8080;

var filename = "[name]";
var sourceMapFilename = "[name]";
if (LEGACY) {
	filename += ".legacy";
}
if (MINIMIZE) {
	filename += ".min.js";
	sourceMapFilename += ".min.js.map";
} else {
	filename += ".js";
	sourceMapFilename += ".js.map";
}

module.exports = {
	mode: process.env.NODE_ENV,
	entry: {
		"epub": "./src/epub.js",
	},
	devtool: MINIMIZE ? false : 'source-map',
	output: {
		path: path.resolve("./dist"),
		filename: filename,
		sourceMapFilename: sourceMapFilename,
		library: {
			name: "ePub",
			type: "umd",
			export: "default"
		},
		publicPath: "/dist/"
	},
	optimization: {
		minimize: MINIMIZE
	},
	externals: {
		"jszip/dist/jszip": "JSZip",
		"@xmldom/xmldom": "@xmldom/xmldom"
	},
	plugins: [],
	resolve: {
		alias: {
			"marks-pane": require.resolve("marks-pane/src/marks.js")
		},
		fallback: {
			path: require.resolve("path-webpack")
		}
	},
	devServer: {
		host: hostname,
		port: port,
		allowedHosts: "all",
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
						presets: [["@babel/preset-env", {
							targets: LEGACY ? "defaults" : "last 2 Chrome versions, last 2 Safari versions, last 2 ChromeAndroid versions, last 2 iOS versions, last 2 Firefox versions, last 2 Edge versions",
							corejs: 3,
							useBuiltIns: "usage",
							bugfixes: true,
							modules: false
						}]]
					}
				}
			}
		]
	},
	performance: {
		hints: false
	}
}

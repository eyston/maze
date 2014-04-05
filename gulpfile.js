var gulp = require('gulp');
var gutil = require('gulp-util');

var path = require('path');

var webpack = require('webpack');
var WebpackDevServer = require("webpack-dev-server");

var _ = require('underscore');

var beeplog = function (err) {
    gutil.beep();
    gutil.log(err);
}

var vendors = {
    react: path.join(__dirname, 'bower_components/react/react.js')
};

var config = {
    entry: './src/main.coffee',
    output: {
        path: path.join(__dirname, 'public/js'),
        // filename: 'main.js'
        filename: "[name].js",
        chunkFilename: "[chunkhash].js"
    },
    module: {
        loaders: [
            { test: /\.coffee$/, loader: 'coffee-loader' },
            { test: /\.less$/, loader: 'style-loader!css-loader!less-loader' }
        ],
        noParse: _.map(vendors, function (path, name) { return path; })
    },
    resolve: {
        alias: vendors
    }
};

gulp.task('index', function () {
    gulp.src('./index.html')
        .pipe(gulp.dest('./public'));
});

gulp.task('build', ['index'], function (callback) {

    webpack(config, function (err, stats) {
        if (err) throw new gutil.PluginError('webpack', err);
        gutil.log('[webpack]', stats.toString({
            colors: true
        }));
        callback();
    });
});

gulp.task('watch', function () {
    gulp.watch('src/**/*', ['build']);
});

gulp.task('server', ['index'], function (callback) {

    new WebpackDevServer(webpack(config), {
        contentBase: path.join(__dirname, 'public'),
        publicPath: '/js/',
        stats: {
            colors: true
        }
    }).listen(4000, 'localhost', function(err) {
        if (err) throw new gutil.PluginError('webpack-dev-server', err);
        gutil.log('[webpack-dev-server]', 'http://localhost:4000/webpack-dev-server/index.html');
    });
});

gulp.task('default', ['server']);

var gulp = require('gulp');
var coffee = require('gulp-coffee');
var gutil = require('gulp-util');
var less = require('gulp-less');

var beeplog = function (err) {
    gutil.beep();
    gutil.log(err);
}

var paths = {
    coffee: ['./src/**/*.coffee'],
    styles: ['./styles/**/*.less'],
    vendor: [
        './node_modules/mori/mori.js',
        './bower_components/react/react.js'
    ]
};

gulp.task('coffee', function () {
    gulp.src(paths.coffee)
        .pipe(coffee().on('error', beeplog))
        .pipe(gulp.dest('./public/js'));
});

gulp.task('less', function () {
    gulp.src(paths.styles)
        .pipe(less())
        .pipe(gulp.dest('./public/styles'))
});

gulp.task('vendor', function () {
    gulp.src(paths.vendor)
        .pipe(gulp.dest('./public/js/vendor'));
});

gulp.task('watch', function () {
    gulp.watch(paths.coffee, ['coffee']);
    gulp.watch(paths.styles, ['less']);
});

gulp.task('default', ['coffee', 'vendor', 'less'], function () {
    gulp.src('./index.html')
        .pipe(gulp.dest('./public'));
});

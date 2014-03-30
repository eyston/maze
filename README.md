Maze Builder
============

![omg a maze](map.gif)

Inspired by http://mazeworks.com/mazegen/mazetut/index.htm (via HN) I wanted to create a visualization around buliding mazes with depth first search.  I also wanted an excuse to play with a few libraries I've had interest in trying out, namely [mori](https://github.com/swannodette/mori) and [react](http://facebook.github.io/react/) but also [coffeescript](http://coffeescript.org/) and [gulp.js](http://gulpjs.com/).

First pass is working, but the visualization performance scales linearly with the size of the maze.  I think it should be pretty easy to make it scale log.
require './main.less'

React = require 'react'
Maze = require './components/maze.coffee'

React.renderComponent Maze.MazeComponent(), document.getElementById('content')

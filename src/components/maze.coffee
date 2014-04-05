React = require 'react'
{ svg, g, line} = React.DOM

m = require 'mori'

walls = require './walls.coffee'
path = require './path.coffee'
rg = require '../grid.coffee'
maze = require '../maze.coffee'

time = (name, fn) ->
    start = (new Date()).getTime()
    fn()
    end = (new Date()).getTime()
    console.log name, end - start

module.exports =
    MazeComponent: React.createClass
        cellWidth: 50
        padding: 10

        delay: 50

        generate: true

        getDefaultProps: ->
            width: 10
            height: 10

        getInitialState: ->
            time 'create grid', =>
                @grid = rg.rectangular(@props.width, @props.height)

            grid: @grid
            path: m.vector()

        componentWillMount: ->
            if @generate
                @generator = maze.generator @state.grid
                @interval = setInterval @advance, @delay
                @setState
                    grid: m.get @generator, 'grid'
                    path: m.vector()

        advance: ->
            time 'advance', () =>
                if maze.complete @generator
                    clearTimeout @interval
                else
                    @generator = maze.advance @generator
                    @setState
                        grid: m.get @generator, 'grid'
                        path: m.get @generator, 'stack'

        segments: () ->
            m.map m.vector, @state.path, m.rest @state.path

        render: ->
            svg { width: @cellWidth * @props.width + 2 * @padding, height: @cellWidth * @props.height + 2 * @padding },
                g {transform: "translate(#{@padding}, #{@padding})" },
                    walls.GridWallGroups
                        cellWidth: @cellWidth
                        type: 'walls'
                        wall_groups: rg.wall_groups @state.grid
                    walls.GridWalls
                        cellWidth: @cellWidth
                        type: 'borders'
                        walls: rg.borders @state.grid
                    path.GridPath
                        cellWidth: @cellWidth
                        segments: @segments()

React = require 'react'
{ g, line} = React.DOM

m = require 'mori'

GridWall = React.createClass

    offsets: m.hash_map(
        m.vector(0, -1), [0, 0, 1, 0]
        m.vector(0, 1), [0, 1, 1, 1]
        m.vector(1, 0), [1, 0, 1, 1]
        m.vector(-1, 0), [0, 0, 0, 1]
    )

    statics:
        key: (wall) ->
            w = m.into m.vector(), wall
            x1 = m.get_in w, [0, 0]
            y1 = m.get_in w, [0, 1]
            x2 = m.get_in w, [1, 0]
            y2 = m.get_in w, [1, 1]
            "#{x1}-#{y1}-#{x2}-#{y2}"

    shouldComponentUpdate: (np, ns) ->
        !(m.equals np.wall, @props.wall)

    render: ->
        wall = m.into m.vector(), @props.wall

        cell1 = m.get wall, 0
        cell2 = m.get wall, 1

        [x, y] = m.into_array cell1
        [x1, y1, x2, y2] = m.get @offsets, (m.map ((a, b) -> a - b), cell2, cell1)

        line
            x1: (x + x1) * @props.cellWidth
            y1: (y + y1) * @props.cellWidth
            x2: (x + x2) * @props.cellWidth
            y2: (y + y2) * @props.cellWidth

GridWalls = React.createClass

    shouldComponentUpdate: (np, ns) ->
        !(m.equals np.walls, @props.walls)

    statics:
        key: (walls) ->
            m.hash walls

    createWall: (wall) ->
        GridWall
            key: GridWall.key wall
            wall: wall
            cellWidth: @props.cellWidth

    render: ->
        g {className: @props.type},
            m.into_array m.map @createWall, @props.walls


GridWallGroups = React.createClass

    shouldComponentUpdate: (np, ns) ->
        !(m.equals np.wall_groups, @props.wall_groups)

    createWalls: (walls) ->
        GridWalls
            key: GridWalls.key walls
            cellWidth: @props.cellWidth
            type: @props.type
            walls: walls

    render: ->
        g {},
            m.into_array m.map @createWalls, @props.wall_groups


module.exports =
    GridWall: GridWall
    GridWalls: GridWalls
    GridWallGroups: GridWallGroups

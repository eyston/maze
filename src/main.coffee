{svg, g, line} = React.DOM
m = mori

rand_nth = (coll) ->
    m.nth coll, (Math.random() * m.count coll) | 0

rg = (->

    adjacent_offsets = m.vector(
        m.vector(0, 1)
        m.vector(0, -1)
        m.vector(1, 0)
        m.vector(-1, 0)
    )

    offset_positions = m.hash_map(
        m.vector(0, -1), 'north'
        m.vector(0, 1), 'south'
        m.vector(1, 0), 'east'
        m.vector(-1, 0), 'west'
    )

    position_offsets = m.hash_map(
        'north', m.vector(0, -1)
        'south', m.vector(0, 1)
        'east', m.vector(1, 0)
        'west', m.vector(-1, 0)
    )

    _diff = (a, b) -> b - a

    _adjacent_cells = (cells, cell) ->
        possible_cells = m.set m.map (m.partial m.map, m.sum, cell), adjacent_offsets
        m.intersection possible_cells, cells

    _add_borders = (borders, cells, direction) ->
        m.into borders, (m.map ((c) -> m.vector(c, direction)), cells)

    create = (width, height) ->
        xs = m.range(0, width)
        ys = m.range(0, height)

        ## the real stuff ##

        # set of coordinates: #{ [0, 0], [0, 1], ..., [9, 9] }
        cells = m.set m.mapcat ((x) -> m.map ((y) -> m.vector(x,y)), ys), xs

        # connections from cell to cells: { [0, 0] #{[0, 1], [1, 0]}, ..., [9, 9] #{[9, 8], [8, 9]} }
        connections = m.into m.hash_map(), (m.map ((cell) ->
            m.vector cell, m.set (_adjacent_cells cells, cell)
        ), cells)


        ## display oriented ##

        # set of pairs of coordinate and wall direction: #{ [[0,0], 'south'], [[0,0], 'east'] ... [[9,9], 'north'] }
        walls = m.reduce_kv ((ws, cell, neighbors) ->
            m.into ws, (m.map ((n) ->
                m.vector cell, (m.get offset_positions, m.map _diff, cell, n)
            ), neighbors)
        ), m.set(), connections


        north = m.map ((x) -> m.vector(x, 0)), xs
        south = m.map ((x) -> m.vector(x, height - 1)), xs
        west = m.map ((y) -> m.vector(0, y)), ys
        east = m.map ((y) -> m.vector(width - 1, y)), ys

        # set of pairs of coordinate and border direction: #{ [[0,0], 'north'], [[0,0], 'west'] ... [[9,9], 'south'] }
        borders = m.pipeline(m.set(),
            m.curry _add_borders, north, 'north'
            m.curry _add_borders, south, 'south'
            m.curry _add_borders, east, 'east'
            m.curry _add_borders, west, 'west'
        )

        m.hash_map(
            'cells', cells
            'connections', connections
            'walls', walls
            'borders', borders
        )

    borders = (grid) ->
        m.get grid, 'borders'

    walls = (grid) ->
        m.get grid, 'walls'

    cells = (grid) ->
        m.get grid, 'cells'

    neighbors = (grid, cell) ->
        m.get_in grid, ['connections', cell]

    remove_wall = (grid, cell1, cell2) ->
        cell1_direction = m.get offset_positions, m.map _diff, cell1, cell2
        cell2_direction = m.get offset_positions, m.map _diff, cell2, cell1

        m.pipeline(
            grid
            # remove connections
            m.curry m.update_in, ['connections', cell1], m.disj, cell2
            m.curry m.update_in, ['connections', cell2], m.disj, cell1
            # also update the (duplicate) wall data for the view
            m.curry m.update_in, ['walls'], m.disj, (m.vector cell1, cell1_direction)
            m.curry m.update_in, ['walls'], m.disj, (m.vector cell2, cell2_direction)
        )


    create: create
    cells: cells
    walls: walls
    borders: borders
    neighbors: neighbors
    remove_wall: remove_wall

)()

map = (->

    generator = (grid) ->
        start = rand_nth m.into m.vector(), rg.cells grid
        m.hash_map(
            'grid', grid
            'stack', m.vector(start),
            'current', start
            'visited', m.set([start])
        )

    advance = (generator) ->
        grid = m.get generator, 'grid'
        current = m.get generator, 'current'
        visited = m.get generator, 'visited'

        neighbors = rg.neighbors grid, current
        visited_neighbors = m.intersection neighbors, visited
        available_neighbors = m.difference neighbors, visited_neighbors

        if m.is_empty available_neighbors
            m.pipeline(
                generator
                m.curry m.update_in, ['stack'], m.pop
                (g) -> m.assoc g, 'current', m.peek m.get g, 'stack'
            )
        else
            next = rand_nth m.into m.vector(), available_neighbors
            m.pipeline(
                generator
                m.curry m.update_in, ['grid'], rg.remove_wall, current, next
                m.curry m.assoc, 'current', next
                m.curry m.update_in, ['stack'], m.conj, next
                m.curry m.update_in, ['visited'], m.conj, next
            )

    complete = (generator) ->
        m.is_empty m.get generator, 'stack'

    solve = (grid) ->
        m.pipeline(
            generator grid
            m.partial m.iterate, advance
            m.partial m.drop_while, (g) -> !map.complete g
            m.partial m.take, 1
            m.first
            m.curry m.get, 'grid'
        )


    generator: generator
    advance: advance
    complete: complete
    solve: solve

)()

time = (name, fn) ->
    start = (new Date()).getTime()
    fn()
    end = (new Date()).getTime()
    console.log name, end - start

GridWall = React.createClass

    wallOffsets:
        north: [0, 0, 1, 0]
        south: [0, 1, 1, 1]
        east: [1, 0, 1, 1]
        west: [0, 0, 0, 1]

    shouldComponentUpdate: (np, ns) ->
        !(m.equals np.wall, @props.wall)

    render: ->
        [[x, y], direction] = m.clj_to_js(@props.wall)
        [x1, y1, x2, y2] = @wallOffsets[direction]
        line
            x1: (x + x1) * @props.cellWidth
            y1: (y + y1) * @props.cellWidth
            x2: (x + x2) * @props.cellWidth
            y2: (y + y2) * @props.cellWidth


GridPathSegment = React.createClass

    shouldComponentUpdate: (np, ns) ->
        !(m.equals np.segment, @props.segment)

    render: ->
        [[x1, y1], [x2, y2]] = m.clj_to_js(@props.segment)
        mid = @props.cellWidth / 2
        line
            x1: x1 * @props.cellWidth + mid
            y1: y1 * @props.cellWidth + mid
            x2: x2 * @props.cellWidth + mid
            y2: y2 * @props.cellWidth + mid

GridBorder = React.createClass

    shouldComponentUpdate: (np, ns) ->
        !(m.equals np.borders, @props.borders)

    key: (wall) ->
        m.hash wall

    createWall: (wall) ->
        GridWall
            key: @key wall
            wall: wall
            cellWidth: @props.cellWidth

    render: ->
        g {className: 'borders'},
            m.into_array m.map @createWall, @props.borders

GridPath = React.createClass

    shouldComponentUpdate: (np, ns) ->
        !(m.equals np.segments, @props.segments)

    key: (segment) ->
        m.hash m.flatten segment

    createSegment: (segment) ->
        GridPathSegment
            key: @key segment
            segment: segment
            cellWidth: @props.cellWidth

    render: ->
        g {className: 'path'},
            m.into_array m.map @createSegment, @props.segments

GridWalls = React.createClass

    shouldComponentUpdate: (np, ns) ->
        !(m.equals np.walls, @props.walls)

    key: (wall) ->
        m.hash wall

    createWall: (wall) ->
        GridWall
            key: @key wall
            wall: wall
            cellWidth: @props.cellWidth

    render: ->
        g {className: 'walls'},
            m.into_array m.map @createWall, @props.walls


GridComponent = React.createClass
    cellWidth: 10
    padding: 10

    delay: 50

    generate: true

    getDefaultProps: ->
        width: 20
        height: 20

    getInitialState: ->
        time 'create grid', =>
            @grid = rg.create(@props.width, @props.height)

        grid: @grid
        path: m.vector()

    componentWillMount: ->
        if @generate
            @generator = map.generator @state.grid
            @interval = setInterval @advance, @delay
            @setState
                grid: m.get @generator, 'grid'
                path: m.vector()

    advance: ->
        time 'advance', () =>
            if map.complete @generator
                clearTimeout @interval
            else
                @generator = map.advance @generator
                @setState
                    grid: m.get @generator, 'grid'
                    path: m.get @generator, 'stack'

    segments: () ->
        m.map m.vector, @state.path, m.rest @state.path

    render: ->
        svg { width: @cellWidth * @props.width + 2 * @padding, height: @cellWidth * @props.height + 2 * @padding },
            g {transform: "translate(#{@padding}, #{@padding})" },
                GridBorder
                    cellWidth: @cellWidth
                    borders: rg.borders @state.grid
                GridWalls
                    cellWidth: @cellWidth
                    walls: rg.walls @state.grid
                GridPath
                    cellWidth: @cellWidth
                    segments: @segments()


React.renderComponent GridComponent(), document.getElementById('content')

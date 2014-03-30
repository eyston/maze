{svg, g, line} = React.DOM
m = mori

rand_nth = (coll) ->
    m.nth coll, (Math.random() * m.count coll) | 0

rg = (->

    create_cell = (coord) ->
        m.hash_map(
            'coord', coord
            'walls', m.set ['north', 'south', 'east', 'west']
            'borders', m.set()
        )

    set_border = (coords, position, cells) ->
        m.reduce ((cells, coord) -> m.pipeline m.update_in(cells, [coord, 'borders'], m.conj, position)), cells, coords

    create = (width, height) ->
        xs = m.range(0, width)
        ys = m.range(0, height)

        grid = m.mapcat ((x) -> m.map ((y) -> m.vector(x,y)), ys), xs

        north = m.map ((x) -> m.vector(x, 0)), xs
        south = m.map ((x) -> m.vector(x, height - 1)), xs
        west = m.map ((y) -> m.vector(0, y)), ys
        east = m.map ((y) -> m.vector(width - 1, y)), ys

        cells = m.pipeline(
            m.into m.hash_map(), m.map ((coord) -> m.vector coord, create_cell(coord)), grid
            m.partial set_border, north, 'north'
            m.partial set_border, south, 'south'
            m.partial set_border, east, 'east'
            m.partial set_border, west, 'west'
        )

        m.hash_map(
            'cells', cells
            'height', height
            'width', width
        )

    edges = (grid, type) ->
        m.mapcat ((cell) ->
                coord = m.get cell, 0
                es = m.get_in cell, [1, type]
                m.map ((position) -> m.vector(coord, position)), es
            ), grid

    borders = (grid) ->
        edges m.get(grid, 'cells'), 'borders'

    walls = (grid) ->
        edges m.get(grid, 'cells'), 'walls'

    cells = (grid) ->
        m.vals m.get grid, 'cells'

    positionOffsets =
        'north': [0, -1]
        'south': [0, 1]
        'east': [1, 0]
        'west': [-1, 0]

    offsetPositions = m.hash_map(
        m.vector(0, -1), 'north'
        m.vector(0, 1), 'south'
        m.vector(1, 0), 'east'
        m.vector(-1, 0), 'west'
    )

    neighbors = (grid, coord) ->
        cell = m.get_in grid, ['cells', coord]
        walls = m.get cell, 'walls'
        m.reduce ((coords, position) ->
            neighborCoord = m.map m.sum, coord, positionOffsets[position]
            if m.has_key (m.get grid, 'cells'), neighborCoord
                m.conj coords, neighborCoord
            else
                coords
        ), m.set(), walls

    remove_wall = (grid, coord1, coord2) ->
        diff = (a, b) -> b - a
        cell1Wall = m.get offsetPositions, m.map diff, coord1, coord2
        cell2Wall = m.get offsetPositions, m.map diff, coord2, coord1

        m.pipeline(
            grid
            m.curry m.update_in, ['cells', coord1, 'walls'], m.disj, cell1Wall
            m.curry m.update_in, ['cells', coord2, 'walls'], m.disj, cell2Wall
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
        start = m.get (rand_nth rg.cells grid), 'coord'
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


GridComponent = React.createClass
    cellWidth: 10
    padding: 10

    getDefaultProps: ->
        width: 20
        height: 20

    getInitialState: ->
        grid: rg.create(@props.width, @props.height)
        path: m.vector()

    componentWillMount: ->
        @generator = map.generator @state.grid
        @interval = setInterval @advance, 50
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
                g {className: 'walls'},
                    m.into_array m.map ((w) => GridWall({key: (m.hash w), wall: w, cellWidth: @cellWidth})), rg.walls @state.grid
                g {className: 'borders'},
                    m.into_array m.map ((w) => GridWall({key: (m.hash w), wall: w, cellWidth: @cellWidth})), rg.borders @state.grid
                g {className: 'path'},
                    m.into_array m.map ((s) => GridPathSegment({key: (m.hash m.flatten s), segment: s, cellWidth: @cellWidth})), @segments()


React.renderComponent GridComponent(), document.getElementById('content')

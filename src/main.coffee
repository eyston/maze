{svg, g, line} = React.DOM
m = mori

rand_nth = (coll) ->
    m.nth coll, (Math.random() * m.count coll) | 0

# Graph suff for adjacent 2 dimensional thingie
Graph = (->

    rectangular = (width, height) ->
        xs = m.range(0, width)
        ys = m.range(0, height)

        nodes = m.set m.mapcat ((x) -> m.map ((y) -> m.vector(x,y)), ys), xs

        build_graph nodes


    circular = (radius) ->
        xs = m.range(0, radius*4)
        ys = m.range(0, radius*4)

        nodes = m.mapcat ((x) -> m.map ((y) -> m.vector(x,y)), ys), xs

        nodes = m.set m.filter ((n) ->
            x = m.get n, 0
            y = m.get n, 1

            (Math.sqrt(Math.pow(radius - x, 2) + Math.pow(radius - y, 2)) < radius)
        ), nodes

        build_graph nodes

    build_graph = (nodes) ->
        m.hash_map(
            'edges', _find_edges nodes
            'missing_edges', _find_missing_edges nodes
            'nodes', nodes
        )

    nodes = (graph) ->
        m.get graph, 'nodes'

    edges = (graph) ->
        m.get graph, 'edges'

    missing_edges = (graph) ->
        m.get graph, 'missing_edges'

    adjacent_offsets = m.vector(
        m.vector(0, 1)
        m.vector(0, -1)
        m.vector(1, 0)
        m.vector(-1, 0)
    )

    _possible_edges = (node) ->
        m.set m.map ((offset) ->
            m.into m.vector(), (m.map m.sum, node, offset)
        ), adjacent_offsets

    _find_edges = (nodes) ->
        m.into m.hash_map(), m.map ((node) ->
            node_edges = m.intersection (_possible_edges node), nodes
            m.vector(node, node_edges)
        ), nodes

    _find_missing_edges = (nodes) ->
        m.into m.hash_map(), m.map ((node) ->
            node_missing_edges = m.difference (_possible_edges node), nodes
            m.vector(node, node_missing_edges)
        ), nodes

    rectangular: rectangular
    circular: circular

    # protocal / interface
    edges: edges
    missing_edges: missing_edges
    nodes: nodes

)()


rg = (->

    _group_size = 5

    _wall_group_hash = (wall) ->
        w = m.into m.vector(), wall
        x = m.get_in w, [0, 0]
        y = m.get_in w, [0, 1]
        m.vector(((x / _group_size) | 0), ((y / _group_size) | 0))

    create = (graph) ->

        walls = m.reduce_kv ((ws, cell, neighbors) ->
            m.pipeline(
                neighbors
                m.partial m.map, m.partial(m.sorted_set, cell)
                m.partial m.into, ws
            )
        ), m.set(), Graph.edges graph

        borders = m.reduce_kv ((bs, cell, neighbors) ->
            m.pipeline(
                neighbors
                m.partial m.map, m.partial(m.sorted_set, cell)
                m.partial m.into, bs
            )
        ), m.set(), Graph.missing_edges graph

        # maps of a hash to a group of walls
        # this is so we can add some hiearchy to walls instead of one big list of 1000's of walls
        wall_groups = m.reduce ((groups, wall) ->
            m.update_in groups, [_wall_group_hash wall], (m.fnil m.conj, m.set()), wall
        ), m.hash_map(), walls

        m.hash_map(
            'graph', graph
            'walls', walls
            'borders', borders
            'wall_groups', wall_groups
        )

    rectangular = (width, height) ->
        create Graph.rectangular width, height

    circle = (radius) ->
        create Graph.circular radius

    borders = (grid) ->
        m.get grid, 'borders'

    walls = (grid) ->
        m.get grid, 'walls'

    cells = (grid) ->
        Graph.nodes (m.get grid, 'graph')

    wall_groups = (grid) ->
        m.vals (m.get grid, 'wall_groups')

    neighbors = (grid, node) ->
        edges = Graph.edges (m.get grid, 'graph')
        m.get edges, node

    remove_wall = (grid, cell1, cell2) ->
        wall = m.sorted_set cell1, cell2

        m.pipeline(
            grid
            m.curry m.update_in, ['walls'], m.disj, wall
            m.curry m.update_in, ['wall_groups', _wall_group_hash wall], m.disj, wall
        )


    rectangular: rectangular
    circle: circle

    cells: cells
    walls: walls
    wall_groups: wall_groups
    borders: borders
    neighbors: neighbors
    remove_wall: remove_wall

)()

# Map Generator / Solver
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

## Views

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

GridPath = React.createClass

    shouldComponentUpdate: (np, ns) ->
        !(m.equals np.segments, @props.segments)

    key: (segment) ->
        x1 = m.get_in segment, [0, 0]
        y1 = m.get_in segment, [0, 1]
        x2 = m.get_in segment, [1, 0]
        y2 = m.get_in segment, [1, 1]
        "#{x1}-#{y1}-#{x2}-#{y2}"

    createSegment: (segment) ->
        GridPathSegment
            key: @key segment
            segment: segment
            cellWidth: @props.cellWidth

    render: ->
        g {className: 'path'},
            m.into_array m.map @createSegment, @props.segments

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


GridComponent = React.createClass
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
                GridWallGroups
                    cellWidth: @cellWidth
                    type: 'walls'
                    wall_groups: rg.wall_groups @state.grid
                GridWalls
                    cellWidth: @cellWidth
                    type: 'borders'
                    walls: rg.borders @state.grid
                GridPath
                    cellWidth: @cellWidth
                    segments: @segments()


## lets do this!
React.renderComponent GridComponent(), document.getElementById('content')

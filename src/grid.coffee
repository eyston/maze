m = require 'mori'

Graph = require('./graph.coffee');

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


module.exports =
    rectangular: rectangular
    circle: circle

    cells: cells
    walls: walls
    wall_groups: wall_groups
    borders: borders
    neighbors: neighbors
    remove_wall: remove_wall

m = require 'mori'

module.exports =
    rectangular: (width, height) ->
        xs = m.range(0, width)
        ys = m.range(0, height)

        nodes = m.set m.mapcat ((x) -> m.map ((y) -> m.vector(x,y)), ys), xs

        build_graph nodes


    circular: (radius) ->
        xs = m.range(0, radius*4)
        ys = m.range(0, radius*4)

        nodes = m.mapcat ((x) -> m.map ((y) -> m.vector(x,y)), ys), xs

        nodes = m.set m.filter ((n) ->
            x = m.get n, 0
            y = m.get n, 1

            (Math.sqrt(Math.pow(radius - x, 2) + Math.pow(radius - y, 2)) < radius)
        ), nodes

        build_graph nodes

    nodes: (graph) ->
        m.get graph, 'nodes'

    edges: (graph) ->
        m.get graph, 'edges'

    missing_edges: (graph) ->
        m.get graph, 'missing_edges'

build_graph = (nodes) ->
    m.hash_map(
        'edges', find_edges nodes
        'missing_edges', find_missing_edges nodes
        'nodes', nodes
    )

adjacent_offsets = m.vector(
    m.vector(0, 1)
    m.vector(0, -1)
    m.vector(1, 0)
    m.vector(-1, 0)
)

possible_edges = (node) ->
    m.set m.map ((offset) ->
        m.into m.vector(), (m.map m.sum, node, offset)
    ), adjacent_offsets

find_edges = (nodes) ->
    m.into m.hash_map(), m.map ((node) ->
        node_edges = m.intersection (possible_edges node), nodes
        m.vector(node, node_edges)
    ), nodes

find_missing_edges = (nodes) ->
    m.into m.hash_map(), m.map ((node) ->
        node_missing_edges = m.difference (possible_edges node), nodes
        m.vector(node, node_missing_edges)
    ), nodes

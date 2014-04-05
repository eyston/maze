m = require 'mori'

rg = require './grid.coffee'


rand_nth = (coll) ->
    m.nth coll, (Math.random() * m.count coll) | 0

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


module.exports =
    generator: generator
    advance: advance
    complete: complete
    solve: solve

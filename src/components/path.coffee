React = require 'react'
{ g, line} = React.DOM

m = require 'mori'


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

module.exports =
    GridPath: GridPath
    GridPathSegment: GridPathSegment
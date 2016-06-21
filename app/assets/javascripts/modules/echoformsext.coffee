#= require proj4
#= require leaflet-0.7/leaflet-src
#= require modules/map/geoutil
#= require modules/map/leaflet-plugins/proj
#= require modules/map/leaflet-plugins/interpolation

do (L, $=jQuery, projectPath=@edsc.map.L.interpolation.projectPath, Proj=@edsc.map.L.Proj) ->
  class XYBoxSubsetter extends $.echoforms.controls.Grouping
    @selector: 'group[id=XYBox]'

    buildDom: ->
      result = super()

      values = @_xyBoxValuesFromQuery()
      if values.length > 0
        @_setValuesToXyBox()

        @subsetOption = $('
          <div class="echoforms-control echoforms-typed-control"
            <div class="echoforms-elements">
              <label><input type="checkbox" checked> Subset around my spatial search area</label>
            </div>
          </div>')

        $checkbox = @subsetOption.find('input')
        $checkbox.on 'click change', (e) =>
          @_setValuesToXyBox($checkbox.is(':checked'))

        result.children('.echoforms-children').prepend(@subsetOption)

      # NSIDCs forms set the projection dropdown to be irrelevant despite it being used,
      # I think as a hack for Reverb / WIST's Jaz panel.
      @controls[0].relevantExpr = null
      @controls[0].relevant(true)
      result

    loadFromModel: ->
      $checkbox = @el.find('input[type="checkbox"]')
      if $checkbox.is(':checked')
        @_setValuesToXyBox(true, false)
      else
        super()

    _setValuesToXyBox: (readonly=true, events=true) ->
      values = @_xyBoxValuesFromQuery()
      controls = @controls

      for value, i in values
        control = controls[i]
        control.readonlyExpr = null
        control.inputs().val(value)
        control.inputs().change() if events
        control.readonly(readonly)


    _xyBoxValuesFromQuery: ->
      return @_xyBoxValues if @_xyBoxValues?

      spatial = edsc.page.query.spatial()
      return @_xyBoxValues = [] unless spatial? && spatial.length > 0

      [type, spatial...] = spatial.split(':')
      spatial = (pt.split(',').reverse().map((c) -> parseFloat(c)) for pt in spatial)
      latlngs = (L.latLng(p) for p in spatial)

      llbounds = L.latLngBounds(latlngs)

      # Figure out which hemisphere we're in.  If the search area is near the equator,
      # neither projection works, so we bail
      hemisphere = null
      if llbounds.getSouth() > 20
        hemisphere = 0
      else if llbounds.getNorth() < -20
        hemisphere = 1
      else
        return @_xyBoxValues = []

      # Since we're in a polar projection, we need to account for all 4 corners of bounding boxes
      interpolationStrategy = 'geodetic'
      if type == 'bounding_box'
        box = L.latLngBounds(latlngs)
        latlngs = [box.getNorthEast(), box.getNorthWest(), box.getSouthEast(), box.getSouthWest()]
        interpolationStrategy = 'cartesian'

      projectionSelect = @controls[0]
      projection = projectionSelect.items[hemisphere][1]

      # Pick the right projection
      if projection.indexOf('EASE') > 0
        proj = [Proj.epsg3408, Proj.epsg3409][hemisphere]
      else
        proj = [Proj.epsg3413, Proj.epsg3031][hemisphere]

      proj = proj.projection
      path = projectPath({latLngToLayerPoint: (ll) -> proj.project(ll)}, latlngs, [], interpolationStrategy, 10)

      bounds = L.bounds(path.boundary)

      @_xyBoxValues = [
        projection,
        Math.round(bounds.min.y),
        Math.round(bounds.min.x),
        Math.round(bounds.max.y),
        Math.round(bounds.max.x)
      ]

  $.echoforms.control(XYBoxSubsetter)

  null


class ChocEditor
  WRAP_CLASS = "CodeMirror-activeline"

  constructor: (options) ->
    defaults =
      id: "#choc"
      maxIterations: 1000
      maxAnimationFrames: 100
      editorId: "#editor"
      amountId: "#amount"
      sliderId: "#slider"
      timelineId: "#timeline"
      messagesId: "#messages"
      timeline: false

    @options = _.extend(defaults, options)
    @$ = options.$
    @state = 
      delay: null
      lineWidgets: []
      editor:
        activeLine: null
      timeline:
        activeLine: null
        activeFrame: null
      slider:
        value: 0
      mouse:
        x: 0
        y: 0
      mouseovercell: false
      container: null
      amountElement: null
      sliderContainer: null
      editorElement: null

    @setupEditor()

  setupEditor: () ->
    @state.container = @$(@options.id)

    # setup a slider container with the amount and slider within it
    @state.sliderContainer = $('<div class="slider-container"></div>')
    @state.amountElement = $('<div class="amount-container"></div>')
    @state.sliderElement = $('<div class="slider-container"></div>')
    @state.sliderContainer.append(@state.amountElement)
    @state.sliderContainer.append(@state.sliderElement)

    # setup the editor container
    @state.editorContainer = $('<div class="editor-container"></div>')
    @state.editorElement = $('<div></div>')
    @state.editorContainer.append(@state.editorElement)

    # if we have a timeline
    if @options.timeline
      @state.timelineContainer = $('<div class="timeline-container"></div>')
      @state.timelineElement = $('<div class="timeline"></div>')
      @state.timelineContainer.append(@state.timelineElement)
      
    # add it all together
    @state.container.append(@state.sliderContainer)
    @state.container.append(@state.editorContainer)
    @state.container.append(@state.timelineContainer) if @options.timeline

     # container.append()
    @interactiveValues = {
      onChange: (v) =>
        clearTimeout(@state.delay)
        @state.delay = setTimeout(
          (() => 
            @calculateIterations()), 
          1)
    }

    console.log @state.editorElement

    @codemirror = CodeMirror @state.editorElement[0], {
      value: @options.code
      mode:  "javascript"
      viewportMargin: Infinity
      tabMode: "spaces"
      interactiveNumbers: @interactiveValues
      highlightSelectionMatches: {showToken: /\w/}
      }

    @codemirror.on "change", () =>
      clearTimeout(@state.delay)
      @state.delay = setTimeout((() => @calculateIterations()), 500)

    onSliderChange = (event, ui) =>
      @state.amountElement.text( "step #{ui.value}" ) 
      if event.hasOwnProperty("originalEvent") # e.g. triggered by a user interaction, not programmatically below
        @state.slider.value = ui.value
        @updatePreview()

    @slider = @state.sliderElement.slider {
      min: 0
      max: 50
      change: onSliderChange
      slide: onSliderChange
      }

  beforeScrub: () -> @options.beforeScrub()
  
  afterScrub: () -> @options.afterScrub()

  clearActiveLine: () ->
    if @state.editor.activeLine
      @state.editor.activeLine.removeClass(WRAP_CLASS)
    if @state.timeline.activeLine
      @state.timeline.activeLine.removeClass("active")
    if @state.timeline.activeFrame
      @state.timeline.activeFrame.removeClass("active")

  updateActiveLine: (cm, lineNumber, frameNumber) ->
    line = @$(@$(".CodeMirror-lines pre")[lineNumber])
    return if cm.state.activeLine is line
    @clearActiveLine()
    line.addClass(WRAP_CLASS) if line
    @state.editor.activeLine = line

    @state.timeline.activeLine = @$(@$("#{@options.timelineId} table tr")[lineNumber + 1])
    @state.timeline.activeLine.addClass("active") if @state.timeline.activeLine
    
    # update active frame
    # splitting this up into three 'queries' is a lot faster than one giant query (in my profiling in Chrome)
    activeRow   = @$("#{@options.timelineId} table tr")[lineNumber + 1]
    activeTd    = @$(activeRow).find("td")[frameNumber]
    activeFrame = @$(activeTd).find(".cell")
    @state.timeline.activeFrame = activeFrame
    @state.timeline.activeFrame.addClass("active") if @state.timeline.activeFrame

    runTds        = @$("#{@options.timelineId} table tr").find("td:nth-child(-n+#{frameNumber}) .cell")
    notYetRunTds  = @$("#{@options.timelineId} table tr").find("td:nth-child(n+#{frameNumber + 1}) .cell")
    @$(runTds).addClass("executed")
    @$(notYetRunTds).removeClass('executed')
    @updateTimelineMarker(activeFrame)

  updateTimelineMarker: (activeFrame, shouldScroll=true) ->
    if activeFrame?.position()?
      timeline = @$(@options.timelineId)
      relX = activeFrame.position().left + timeline.scrollLeft() + (activeFrame.width() / 2.0)
      $("#tlmark").css('left', relX)
      if !@state.mouseovercell # ew
        timeline.scrollLeft(relX - 40) if shouldScroll # TODO - tween
      @state.mouseovercell = false

  onScrub: (info,opts={}) ->
    @updateActiveLine(@codemirror, info.lineNumber - 1, info.frameNumber)

  # When given an array of messages, add CodeMirror lineWidgets to each line
  onMessages: (messages) ->
    firstMessage = messages[0]?.message
    if firstMessage
      _.map messages, (messageInfo) =>
        messageString = ""

        # to make the annotations API cleaner, we allow either a string to be
        # returned or an object with the keys 'message' or 'timeline'
        if _.isObject(messageInfo.message)
          messageString = messageInfo.message.inline
        else
          messageString = messageInfo.message

        line = @codemirror.getLineHandle(messageInfo.lineNumber - 1)
        widgetHtml = $("<div class='line-messages'>" + messageString + "</div>")
        widget = @codemirror.addLineWidget(line, widgetHtml[0])
        @state.lineWidgets.push(widget)

  # Generate the HTML view of the timeline data structure
  generateTimelineTable: (timeline) ->
    tdiv = @state.timelineElement
    execLine = @$("#executionLine")
    table = $('<table></table>')

    # header
    headerRow = $("<tr></tr>")

    for column in [0..(timeline.steps.length-1)] by 1
      value = ""
      klass = ""
      if (column % 10) == 0
        value = column
        klass = "mod-ten"
      else if (column % 5) == 0
        value = "<div class='tick'></div>"
        klass = "mod-five"
      else 
        value = "<div class='tick'></div>"
        klass = "mod-one"

      headerRow.append("<th><div class='cell #{klass}'>#{value}</div></th>")
    table.append(headerRow)

    # build a table where the number of rows is
    #   rows: timeline.maxLines
    #   columns: number of elements in 
    rowidx  = 0
    while rowidx < timeline.maxLines + 1
      row = $('<tr class="timeline-row"></tr>')
      column = 0
      while column < timeline.steps.length
        idx = rowidx * column

        if timeline.stepMap[column][rowidx]
          info = timeline.stepMap[column][rowidx]

          message = info.messages?[0]

          display = "&nbsp;" #&#8226;
          frameId = "data-frame-#{info.frameNumber}"
          cell = $("<td></td>")
          innerCell = $("<div></div>")
            .addClass("cell content-cell circle")
            .attr("id", frameId)
            .attr("data-frame-number", info.frameNumber)
            .attr("data-line-number", info.lineNumber)
          cell.append(innerCell)

          if message?.message?.timeline?
            timelineCreator = message.message.timeline
            if _.isFunction(timelineCreator)
              # display = timelineCreator("#" + frameId) # the table hasn't been created yet
              timelineCreator(innerCell)
              innerCell.removeClass('circle')

          else if message?.timeline? 
            display = message.timeline
            if display.hasOwnProperty("_choc_timeline")
              display = display._choc_timeline()
            innerCell.removeClass('circle')
            innerCell.html(display)
          else
            innerCell.html(display)
         
          row.append(cell)
        else
          value = ""
          cell = $("<td><div class='cell'>#{value}</div></td>")
          row.append(cell)
        column += 1
      rowidx += 1
      table.append(row)

    tdiv.html(table)

    tlmark = $("<div id='tlmark'>&nbsp;</div>")
    tlmark.height(tdiv.height() - (2 * row.height()))
    tlmark.css('top', row.height())
    tdiv.append(tlmark)

    slider = @slider
    updatePreview = @updatePreview
    self = @
    updateSlider = (frameNumber) ->
      self.$( @options.sliderId ).text( "step #{frameNumber}" ) 
      self.state.slider.value = frameNumber
      updatePreview.apply(self)

    for cell in @$("#{@options.timelineId} .content-cell")
      ((cell) -> 
        $(cell).on 'mouseover', () ->
          cell = $(cell)
          frameNumber = cell.data('frame-number')
          info = {lineNumber: cell.data('line-number'), frameNumber: frameNumber}
          self.state.mouseovercell = true # ew
          updateSlider(info.frameNumber + 1)
      )(cell)
    
    # TODO -- 
    # timeline.onScroll (e) -> updateSlider on the frame

  onTimeline: (timeline) ->
    @generateTimelineTable(timeline)

  updatePreview: () ->
    # clear the lineWidgets (e.g. the text description)
    _.map @state.lineWidgets, (widget) -> widget.clear()

    try
      code = @codemirror.getValue()

      window.choc.scrub code, @state.slider.value, 
        onFrame:    (args...) => @onScrub.apply(@, args)
        beforeEach: (args...) => @beforeScrub.apply(@, args)
        afterEach:  (args...) => @afterScrub.apply(@, args)
        onMessages: (args...) => @onMessages.apply(@, args)
        locals: @options.locals
      @$(@options.messagesId).text("")
    catch e
      console.log(e)
      console.log(e.stack)
      @$(@options.messagesId).text(e.toString())

  calculateIterations: (first=false) ->
    afterAll = () -> 
    if first
      afterAll = (info) =>
        count = info.frameCount
        @slider.slider('option', 'max', count)
        @slider.slider('value', count)
        # @options.afterCalculatingIterations() if @options.afterCalculatingIterations?
    else
      afterAll = (info) =>
        count = info.frameCount
        @slider.slider('option', 'max', count)
        max = @slider.slider('option', 'max')
        if (@state.slider.value > max)
          @state.slider.value = max
          @slider.slider('value', max)
          @slider.slider('step', count)

    console.log("regular calculate iterations")
    window.choc.scrub @codemirror.getValue(), @options.maxIterations, 
      onTimeline: (args...) => @onTimeline.apply(@, args)
      beforeEach: (args...) => @beforeScrub.apply(@, args)
      afterEach:  (args...) => @afterScrub.apply(@, args)
      afterFrame:  (args...) => @afterFrame.apply(@, args)
      afterAll: afterAll
      locals: @options.locals

    # @updatePreview() # TODO - bring this back?

  start: () ->
    @calculateIterations(true)

root = exports ? this
root.choc ||= {}
root.choc.Editor = ChocEditor

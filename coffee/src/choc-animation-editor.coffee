class ChocAnimationEditor
  gval = eval

  constructor: (options) ->
    defaults =
      id: "#choc"
      maxIterations: 1000
      maxAnimationFrames: 100

    @options = _.extend(defaults, options)
    @$ = options.$
    @state = 
      delay: null
      slider:
        value: 0
      playing: false
      container: null
      amountElement: null
      sliderElement: null
      editorElement: null
      tlmarkElement: null

    @setupEditor()

  setupEditor: () ->
    @state.container = @$(@options.id)

    # setup a controls container with the amount and slider within it
    @state.controlsContainer = $('<div class="controls-container"></div>')
    @state.amountElement = $('<div class="amount-container"></div>')
    @state.sliderElement = $('<div class="slider-container"></div>')
    @state.animationControlsElement = $('<a href="#" class="animation-controls">Play</a>')
    @state.controlsContainer.append(@state.amountElement)
    @state.controlsContainer.append(@state.sliderElement)
    @state.controlsContainer.append(@state.animationControlsElement)

    # setup the editor container
    @state.editorContainer = $('<div class="editor-container"></div>')
    @state.editorElement = $('<div></div>')
    @state.editorContainer.append(@state.editorElement)
     
    # add it all together
    @state.container.append(@state.controlsContainer)
    @state.container.append(@state.editorContainer)

    @interactiveValues = {
      onChange: (v) =>
        clearTimeout(@state.delay)
        @state.delay = setTimeout((() => @updateViews()), 1)
    }

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
      @state.delay = setTimeout((() => @updateViews()), 500)

    onSliderChange = (event, ui) =>
      if event.hasOwnProperty("originalEvent") # e.g. triggered by a user interaction, not programmatically below
        @changeSlider(ui.value)

    @slider = @state.sliderElement.slider {
      min: 0
      max: @options.maxAnimationFrames
      change: onSliderChange
      slide: onSliderChange
      }

    @state.animationControlsElement.click () =>
      if @state.playing
        @onPause()
      else
        @onPlay()
      return false

  changeSliderValue: (newValue) ->
    @state.amountElement.text("frame #{newValue}") 
    @state.slider.value = newValue

  changeSlider: (newValue) ->
    @changeSliderValue(newValue)
    @updateFrameView()


  onPlay: () ->
    @state.animationControlsElement.text("Pause")
    @state.playing = true
    @updateViews()
    @options.play()

  onPause: () ->
    @state.animationControlsElement.text("Play")
    @state.playing = false
    @options.pause()
    @updateViews()

  onFrame: (frameCount, timeDelta) ->
    @changeSliderValue(frameCount)
    @slider.slider('value', frameCount)
    # console.log(frameCount)

  updateFrameView: () ->
    try
      code = @codemirror.getValue()
      if @options.animate?
        # below we run animate for every iteration to make sure we're at the
        # right place in code. However, we don't clear/update everytime because
        # it causes flashing. We only need to clear right before we draw the
        # frame we want to see
        appendSource = """
          for(var __i=0; __i<#{@state.slider.value}; __i++) {
            if(__i == #{@state.slider.value - 1}) {
              pad.clear();
              #{@options.animate}();
              pad.update();
            } else {
            #{@options.animate}();
            }
          }
        """

      @runCode(@codemirror.getValue() + appendSource, false)

      @$("#messages").text("")
    catch e
      console.log(e)
      console.log(e.stack)
      @$("#messages").text(e.toString())

  runCode: (code, isPreview=false) ->
    gval = eval

    localsIndex = if isPreview then 1 else 0

    window._choc_preview_locals = @options.locals
    localsStr = _.map( _.keys(@options.locals), \
                (name) -> 
                  "var #{name} = _choc_preview_locals.#{name}[#{localsIndex}]").join("; ")
    gval(localsStr + "\n" + code )

  updateViews: () ->
    @generatePreview()
    @updateFrameView()

  generatePreview: () ->
    @options.beforeGeneratePreview?()
    @runCode(@codemirror.getValue(), true)
    draw = gval(@options.animate)
    do (() -> draw()) for [1..@options.maxAnimationFrames]
    @options.afterGeneratePreview?()

  start: (frame=1) ->
    @changeSlider(frame)
    @updateViews()

root = exports ? this
root.choc ||= {}
root.choc.AnimationEditor = ChocAnimationEditor

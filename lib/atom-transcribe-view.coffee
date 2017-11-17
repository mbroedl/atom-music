{$, View} = require 'atom-space-pen-views'

module.exports =
class AtomTranscribeView extends View
  thisTrack: null
  markerLayer: null
  setPulsing: false
  hoveredTime: null
  timestampRegexp: /(\d{1,2}:){1,2}\d{1,2}(\.\d{1,})?/
  smallSkip: atom.config.get('atom-transcribe.smallSkip')
  bigSkip: atom.config.get('atom-transcribe.bigSkip')
  pauseSkip: atom.config.get('atom-transcribe.pauseSkip')
  timeStampFormat: atom.config.get('atom-transcribe.timeStampFormat')

  @content: ->
    @div class:'atom-transcribe', =>
      @div class:'audio-controls-container', =>
        @div class: 'block', id: 'progressblock', =>
          @progress class: 'inline-block', max: '0', value='0', id: 'audio-progressbar', outlet: 'progressbar'
          @div id: 'audio-ticker-box', =>
            @span class: 'inline-block', id:'audio-ticker', outlet:'ticker'
        @div class:'btn-group btn-group-sm', =>
          @button class:'btn icon icon-playback-rewind skip_big', click:'fastbackward'
          @button class:'btn icon icon-playback-rewind skip_small', click:'backward'
          @button class:'btn icon playback-button icon-playback-play', click:'togglePlayback'
          @button class:'btn icon icon-playback-fast-forward skip_small', click:'forward'
          @button class:'btn icon icon-playback-fast-forward skip_big', click:'fastforward'
          @button class:'btn icon icon-watch', click:'insertTimestamp'
        @div class:'btn-group btn-group-sm pull-right', =>
          @tag 'label', =>
            @tag 'input', style:'display: none;', type:'file', multiple: false, accept:"audio/*", outlet:"musicFileSelectionInput"
            @span '', class:'btn icon icon-file-directory',
        @div class:'inline-block playing-now-container', =>
          @span 'No file selected.', class:'highlight', outlet:'nowPlayingTitle'
        @div class:'inline-block pull-right', id:'playback-rate', =>
          @span outlet: 'playbackRangeText', class: 'pull-right playback-text'
          @input class: 'input-range', type: 'range', max: '1.6', min:'0.5', value:'1.0', step:'0.01', outlet: 'playbackRangeInput'
      @div class:'atom-transcribe-list-container'
      @tag 'audio', class:'audio-player', outlet:'audio_player', =>

  initialize: ->
    self = @
    @musicFileSelectionInput.on 'change', @filesBrowsed
    @playbackRangeInput.on 'change', @playbackRateSlider
    @audio_player.on 'play', ( ) =>
      $('.playback-button').removeClass('icon-playback-play').addClass('icon-playback-pause')
    @audio_player.on 'pause', ( ) =>
      $('.playback-button').removeClass('icon-playback-pause').addClass('icon-playback-play')
    @audio_player.on 'ended', @songEnded
    @progressbar.on 'click', @jumpToTimeByProgress
    @progressbar.on 'mousemove', @hoverTime
    @progressbar.on 'mouseout', ( ) => @hoveredTime = null

    view = atom.views.getView atom.workspace.getActiveTextEditor()
    view.ondblclick = => @jumpToTimeByMarker()

  show: ->
    @panel ?= atom.workspace.addBottomPanel(item:this)
    @panel.show()

  toggle:->
    if @panel?.isVisible()
      if not @audio_player[0].paused
        @togglePlayback()
      @hide()
    else
      @show()
      @pulsing()
      @moveTicker()

  makeTime: ( t ) ->
    ms = (t % 1).toFixed(2).substring(2)
    t = Math.floor(t)
    s = String('00' + t % 60).slice(-2);
    m = Math.floor(t / 60)
    str = ""
    if m > 60
      h = String('00' + Math.floor(m / 60)).slice(-2)
      m = String('00' + m % 60).slice(-2);
      str = "#{h}:#{m}:#{s}.#{ms}"
    else
      m = String('00' + m).slice(-2);
      str = "#{m}:#{s}.#{ms}"
    return str

  makeTimestamp: ( t ) ->
    tt = t.split(':').reverse()
    flt = 0
    for num, i in tt
        flt += Math.pow(60,i) * parseFloat num
    return flt

  hoverTime: ( e ) =>
    if @thisTrack?
      @hoveredTime = @audio_player[0].duration * e.offsetX / parseInt(@progressbar.css('width'), 10)
      @progressbar.attr('value', @hoveredTime)

  jumpToTimeByProgress: ( e ) =>
    if @thisTrack?
      @audio_player[0].currentTime = @audio_player[0].duration * e.offsetX / parseInt @progressbar.css('width'), 10

  jumpToTimeByMarker: (e) =>
    editor = atom.workspace.getActiveTextEditor()
    pos = editor.getCursorBufferPosition()
    markers = @markerLayer.findMarkers {containsPoint: pos}

    if markers[0]?
      editor.setSelectedScreenRange [markers[0].getStartScreenPosition(), markers[0].getEndScreenPosition()]
      ts = @makeTimestamp editor.getSelectedText()

      @audio_player[0].currentTime = ts

  moveTicker: ->
    setInterval ( ) =>
      if @thisTrack?
        timeSpent = @audio_player[0].currentTime
        totalTime = @audio_player[0].duration
        @progressbar.attr('max', totalTime)
        if @hoveredTime?
          t = @hoveredTime
          @ticker.html('<i>('+@makeTime(t)+')</i> ' + @makeTime(timeSpent) + ' / ' + @makeTime(totalTime))
        else
          t = timeSpent
          @ticker.text(@makeTime(timeSpent) + ' / ' + @makeTime(totalTime))
        @progressbar.attr('value', t)
    , 200

  pulsing: ->
    if @setPulsing
      setInterval ( ) =>
        $(@).addClass('pulse')
        setTimeout ( ) =>
          $(@).removeClass('pulse')
        , 2000
      , 4000

  songEnded: ( e ) =>
    #console.log "Finished."

  skip: ( seconds )->
    delta = @audio_player[0].currentTime + seconds
    if (delta < 0)
      @audio_player[0].currentTime = 0
    else if (delta > @audio_player[0].duration)
      @stopTrack
    else
      @audio_player[0].currentTime += seconds

  forward: ->
    @skip @smallSkip

  fastforward: ->
    @skip @bigSkip

  backward: ->
    @skip -1 * @smallSkip

  fastbackward: ->
    @skip -1 * @bigSkip

  reduceSpeed: ->
    @changePlaybackRate parseFloat(@playbackRangeInput.prop('value')) - 0.05

  increaseSpeed: ->
    @changePlaybackRate parseFloat(@playbackRangeInput.prop('value')) + 0.05

  loadTrack: (track) ->
    player = @audio_player[0]
    if track?
      @nowPlayingTitle.html (track.name)
      @thisTrack = track
      @changePlaybackRate 1.0
      player.pause()
      player.src = track.path
      player.load()
      player.play()
      @markTimestamps()

  stopTrack: ->
    player = @audio_player[0]
    if @thisTrack?
      @togglePlayback() if not player.paused
      @nowPlayingTitle.html ('Nothing to play')
      player.src = null

  playbackRateSlider: ( e ) =>
    @changePlaybackRate $(e.target)[0].value

  changePlaybackRate: ( pbrate ) ->
    if pbrate > @playbackRangeInput.prop('max')
        pbrate = @playbackRangeInput.prop('max')
    if pbrate < @playbackRangeInput.prop('min')
        pbrate = @playbackRangeInput.prop('min')
    pbrate = parseFloat pbrate
    @audio_player[0].playbackRate = pbrate
    @playbackRangeInput.prop('value', pbrate.toFixed(2))
    @playbackRangeText.text('x'+pbrate.toFixed(2))

  filesBrowsed: ( e ) =>
    files = $(e.target)[0].files
    if files? and files.length == 1
      track = { name: files[0].name, path: files[0].path }
      @loadTrack track
    else
      @nowPlayingTitle.html ('Please select only one track.')

  togglePlayback: ->
    player = @audio_player[0]
    if @thisTrack?
      if player.paused or player.currentTime == 0
        @skip(-1 * @pauseSkip)
        player.play()
        $('.playback-button').removeClass('icon-playback-play').addClass('icon-playback-pause')
      else
        player.pause()
        $('.playback-button').removeClass('icon-playback-pause').addClass('icon-playback-play')

  insertTimestamp: ->
    if @thisTrack? and editor = atom.workspace.getActiveTextEditor()
      ts = @makeTime @audio_player[0].currentTime
      txt = @timeStampFormat.replace('%t', ts)
      editor.insertText(txt)
      @markTimestamps()

  markTimestamps: ->
    if @markerLayer?
      @markerLayer.destroy()
    editor = atom.workspace.getActiveTextEditor()
    @markerLayer = editor.addMarkerLayer()
    range =  [[0, 0], editor.getEofBufferPosition()]
    editor.scanInBufferRange new RegExp(@timestampRegexp, 'g'), range, (result) =>
    #console.log result
      m = @markerLayer.markBufferRange(result.range, {'invalidate':'inside'})

    editor.decorateMarkerLayer @markerLayer, {
      type: 'highlight',
      class: 'atom-transcribe-timestamp'
    }

  hide: ->
    @panel?.hide()

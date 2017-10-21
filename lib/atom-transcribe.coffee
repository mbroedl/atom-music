AtomTranscribeView = require './atom-transcribe-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomTranscribe =
  AtomTranscribeView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomTranscribeView = new AtomTranscribeView(state.atomTranscribeViewState)
    # Register commands
    atom.commands.add 'atom-workspace', 'atom-transcribe:toggle': => @atomTranscribeView.toggle()

    atom.commands.add 'atom-text-editor', 'atom-transcribe:fast-backward': => @atomTranscribeView.fastbackward()

    atom.commands.add 'atom-text-editor', 'atom-transcribe:backward': => @atomTranscribeView.backward()

    atom.commands.add 'atom-text-editor', 'atom-transcribe:toggle-playback': => @atomTranscribeView.togglePlayback()

    atom.commands.add 'atom-text-editor', 'atom-transcribe:forward': => @atomTranscribeView.forward()

    atom.commands.add 'atom-text-editor', 'atom-transcribe:fast-forward': =>  @atomTranscribeView.fastforward()

    atom.commands.add 'atom-text-editor', 'atom-transcribe:reduce-playback-speed': =>  @atomTranscribeView.reduceSpeed()

    atom.commands.add 'atom-text-editor', 'atom-transcribe:increase-playback-speed': =>  @atomTranscribeView.increaseSpeed()

    atom.commands.add 'atom-text-editor', 'atom-transcribe:insert-timestamp': =>  @atomTranscribeView.insertTimestamp()

  deactivate: ->
    @atomTranscribeView.destroy()

  serialize: ->
    atomTranscribeViewState: @atomTranscribeView.serialize()

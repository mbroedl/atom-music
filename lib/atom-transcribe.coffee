AtomTranscribeView = require './atom-transcribe-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomTranscribe =
  AtomTranscribeView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomTranscribeView = new AtomTranscribeView(state.atomTranscribeViewState)
    # Register command that toggles this view
    atom.commands.add 'atom-workspace', 'atom-transcribe:toggle': => @atomTranscribeView.toggle()

  deactivate: ->
    @atomTranscribeView.destroy()

  serialize: ->
    atomTranscribeViewState: @atomTranscribeView.serialize()

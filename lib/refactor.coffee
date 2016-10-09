{ Disposable, CompositeDisposable } = require 'atom'
Watcher = require './watcher'
ModuleManager = require './module_manager'
{ packages: packageManager } = atom
d = (require 'debug/browser') 'refactor'

module.exports =
new class Main

  config:
    highlightError:
      type: 'boolean'
      default: true
    highlightReference:
      type: 'boolean'
      default: true


  activate: (state) ->
    d 'activate'

    @moduleManager = new ModuleManager
    @watchers = new Set
    disposeWatchers = () -> w.dispose() for w of @watchers

    @disposables = new CompositeDisposable
    @disposables.add @moduleManager
    @disposables.add new Disposable disposeWatchers
    @disposables.add atom.workspace.observeTextEditors (editor) =>
      watcher = new Watcher @moduleManager, editor
      @watchers.add watcher
      editor.onDidDestroy =>
        @watchers.delete watcher
        watcher.dispose()
    @disposables.add atom.commands.add 'atom-text-editor', 'refactor:rename', @onRename
    @disposables.add atom.commands.add 'atom-text-editor', 'refactor:done', @onDone

  deactivate: ->
    d 'deactivate'
    @disposables.dispose()
    @moduleManager = null
    @watchers = null

  serialize: ->


  onRename: (e) =>
    isExecuted = false
    for watcher in @watchers
      isExecuted or= watcher.rename()
    d 'rename', isExecuted
    return if isExecuted
    e.abortKeyBinding()

  onDone: (e) =>
    isExecuted = false
    for watcher in @watchers
      isExecuted or= watcher.done()
    return if isExecuted
    e.abortKeyBinding()

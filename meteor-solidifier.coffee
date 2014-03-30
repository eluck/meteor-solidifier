SolidDeps =
  inject:  (options) ->
    #options =
    #  target
    #  dependencies
    #  publicMethods
    throw 'Error - SolidDeps:injectDependencies - options should be defined' unless options
    throw 'Error - SolidDeps:injectDependencies - options.target should be defined' unless options.target
    throw 'Error - SolidDeps:injectDependencies - options.dependencies should be defined' unless options.dependencies
    throw 'Error - SolidDeps:injectDependencies - options.publicMethods should be defined' unless options.publicMethods
    target = options.target
    target._launchLazyDependenciesEvaluation = @_launchLazyDependenciesEvaluation
    options.publicMethods.forEach (methodName) ->
      methodToCall = target[methodName]
      target[methodName] = ->
        target._launchLazyDependenciesEvaluation(options)
        return methodToCall.apply(target, arguments)


  _launchLazyDependenciesEvaluation: (options) ->
    options.dependencies.forEach (dependency) ->
      if not @[dependency]
        if eval("typeof #{dependency}") != 'undefined'
          eval("this[dependency] = #{dependency}")
    , @



SolidSynapse =
  inject: (options) ->
    #options =
    #  target
    #  synapseName
    #  trackedMethods
    throw 'Error - SolidSynapse:wrapMethods - options should be defined' unless options
    throw 'Error - SolidSynapse:wrapMethods - options.target should be defined' unless options.target
    throw 'Error - SolidSynapse:wrapMethods - options.synapseName should be defined' unless options.synapseName
    target = options.target
    target[options.synapseName] = new BackboneEvent()
    options.trackedMethods?.forEach (methodName)->
      @_wrapMethod(target, methodName, target[options.synapseName])
    , @


  _wrapMethod: (target, methodName, synapse) ->
    throw 'Error - SolidSynapse:wrapMethod - methodName should be defined' unless methodName
    methodToCall = target[methodName]
    throw "Error - SolidSynapse:wrapMethod - target does not contain a method named #{methodName}" unless methodToCall
    target[methodName] = ->
      synapse.trigger('before:' + methodName, arguments)
      result = methodToCall.apply(target, arguments)
      synapse.trigger('after:' + methodName, result)
      return result



SolidDepsProxy =
  SolidDeps: SolidDeps
  SolidSynapse: SolidSynapse
  BackboneEvent: BackboneEvent
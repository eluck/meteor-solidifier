LazyDeps =
  injectDependencies:  (options) ->
    #options =
    #  target
    #  dependencies
    #  publicMethods
    throw 'Error - LazyDeps:injectDependencies - options should be defined' unless options
    throw 'Error - LazyDeps:injectDependencies - options.target should be defined' unless options.target
    throw 'Error - LazyDeps:injectDependencies - options.dependencies should be defined' unless options.dependencies
    throw 'Error - LazyDeps:injectDependencies - options.publicMethods should be defined' unless options.publicMethods
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



Synapse =
  wrapMethods: (options) ->
    #options =
    #  target
    #  synapseName
    #  trackedMethodsNames
    throw 'Error - Synapse:wrapMethods - options should be defined' unless options
    throw 'Error - Synapse:wrapMethods - options.target should be defined' unless options.target
    throw 'Error - Synapse:wrapMethods - options.synapseName should be defined' unless options.synapseName
    target = options.target
    target[options.synapseName] = new BackboneEvent()
    if options.trackedMethods
      options.trackedMethodsNames.forEach (methodName)->
        @_wrapMethod(target, methodName, target[options.synapseName])
      , @


  _wrapMethod: (target, methodName, synapse) ->
    throw 'Error - Synapse:wrapMethod - methodName should be defined' unless methodName
    methodToCall = target[methodName]
    throw "Error - Synapse:wrapMethod - target does not contain a method named #{methodName}" unless methodToCall
    target[methodName] = ->
      synapse.trigger('before:' + methodName, arguments)
      result = methodToCall.apply(target, arguments)
      synapse.trigger('after:' + methodName, result)
      return result

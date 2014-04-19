Solidifier =
  Synapse:
    wrapMethods: (options) ->
      #options =
      #  target
      #  synapseName
      #  trackedMethods
      throw 'Error - Solidifier:Synapse:wrapMethods - expected parameter options' unless options
      throw 'Error - Solidifier:Synapse:wrapMethods - expected parameter options.target' unless options.target
      throw 'Error - Solidifier:Synapse:wrapMethods - expected parameter options.synapseName' unless options.synapseName
      { target, synapseName, trackedMethods } = options
      target[synapseName] = new BackboneEvent()
      trackedMethods?.forEach(@_wrapMethod.bind(@, target, target[synapseName]), @)



    _wrapMethod: (target, synapse, methodName) ->
      throw 'Error - SolidSynapse:wrapMethod - methodName should be defined' unless methodName
      methodToCall = target[methodName]
      throw "Error - SolidSynapse:wrapMethod - target does not contain a method named #{methodName}" unless methodToCall
      target[methodName] = ->
        synapse.trigger('before:' + methodName, arguments)
        result = methodToCall.apply(target, arguments)
        synapse.trigger('after:' + methodName, result)
        return result



    wrapCollections: (options) ->
      throw 'Error - Solidifier:Synapse:wrapCollections - expected paramtere opitons' unless options
      throw 'Error - Solidifier:Synapse:wrapCollections - expected parameter options.collections' unless options.collections
      throw 'Error - Solidifier:Synapse:wrapCollections - expected parameter options.synapseName' unless options.synapseName
      { collections, synapseName } = options
      collections.forEach(@_wrapCollection.bind(@, synapseName), @)



    _wrapCollection: (synapseName, collection) ->

      collection[synapseName] = new BackboneEvent()

      beforeInsert = (originalArgs) -> collection[synapseName].trigger('before:insert', originalArgs)
      beforeUpdate = (originalArgs) -> collection[synapseName].trigger('before:update', originalArgs)
      beforeUpsert = (originalArgs) -> collection[synapseName].trigger('before:upsert', originalArgs)
      beforeRemove = (originalArgs) -> collection[synapseName].trigger('before:remove', originalArgs)

      afterInsert = (originalArgs, error, result) -> collection[synapseName].trigger('after:insert', error, result, originalArgs)
      afterUpdate = (originalArgs, error, result) -> collection[synapseName].trigger('after:update', error, result, originalArgs)
      afterUpsert = (originalArgs, error, result) -> collection[synapseName].trigger('after:upsert', error, result, originalArgs)
      afterRemove = (originalArgs, error) ->         collection[synapseName].trigger('after:remove', error, originalArgs)

      @_wrapCollectionMethod(collection, 'insert', beforeInsert, afterInsert)
      @_wrapCollectionMethod(collection, 'update', beforeUpdate, afterUpdate)
      @_wrapCollectionMethod(collection, 'upsert', beforeUpsert, afterUpsert)
      @_wrapCollectionMethod(collection, 'remove', beforeRemove, afterRemove)



    _wrapCollectionMethod: (collection, wrappingMethod, beforeCallback, afterCallback) ->
      originalMethod = 'original' + wrappingMethod.charAt(0).toUpperCase() + wrappingMethod.slice(1)
      collection[originalMethod] = collection[wrappingMethod]
      self = @
      collection[wrappingMethod] = ->
        originalArgs = Array.prototype.slice.call(arguments, 0)
        beforeCallback(originalArgs)
        after = afterCallback.bind(null, originalArgs)
        args = self._setCallbackArgument originalArgs, after
        result = collection[originalMethod].apply(@, args or originalArgs)
        after(null, result) unless args #here we assume that if there was error, an exception would be thrown
        return result



    _setCallbackArgument: (callArgs, callback) ->
      originalCallback = callArgs[-1]
      return undefined unless originalCallback and typeof(originalCallback) == 'Function' or Meteor.isClient #client-side code always works as if there was a callback
      callbackIndex = callArgs.length
      callbackIndex-- if originalCallback #rewrite original callback if presents
      args = callArgs[..]
      args[callbackIndex] = ->
        callback.apply(null, arguments)
        originalCallback.apply(null, arguments) if originalCallback and typeof(originalCallback) == 'Function'
      return args

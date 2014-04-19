Package.describe({
    summary: "Tools for making Meteor apps SOLID"
});

Package.on_use(function (api) {
    api.use([
        'coffeescript',
        'underscore'
    ]);

    api.add_files([
        'meteor-solidifier.coffee',
        'backboneEvent.js'
    ], ['client', 'server']);

    api.export([
        'BackboneEvent',
        'Solidifier'
    ], ['client', 'server']);
});

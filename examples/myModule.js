const {Elm} = require('./elm');
const app = Elm.MyModule.init();
exports.handler = (event, context, callback) => {
    const caller = (output) => {
        callback(null, output);
        app.ports.outputEvent.unsubscribe(caller);
    }
    app.ports.outputEvent.subscribe(caller);
    app.ports.inputEvent.send(event);
}
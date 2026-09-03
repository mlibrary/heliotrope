import {Evented} from './Events';

var Bus = Evented.extend({
});

var instance;
export var bus = function() {
  return instance || ( instance = new Bus() );
}

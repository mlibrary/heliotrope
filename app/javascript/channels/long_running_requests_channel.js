import consumer from "./consumer";

consumer.subscriptions.create("LongRunningRequestsChannel", {
  connected: function() {
    // Called when the subscription is ready for use on the server
    console.log("LongRunningRequestsChannel connected");
  },

  disconnected: function(){
    // Called when the subscription has been terminated by the server
    console.log("LongRunningRequestsChannel disconnected")
  },

  received: function(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log(data)
    $('#monograph-download-btn').addClass('dropdown-toggle')
    $('#monograph-download-btn').html("Download");
    window.location.replace(data['download_url']);
    //window.open(data['download_url'], '_blank').focus();
  }
});

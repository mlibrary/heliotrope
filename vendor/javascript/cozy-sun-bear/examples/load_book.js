var book = ePub("http://localhost:8080/books/moby-dick.epub");
var rendition = book.renderTo("viewer", {
  width: "100%",
  height: 600
});
rendition.display();

var next = document.getElementById("next");
next.addEventListener("click", function(e){
  rendition.next();
  e.preventDefault();
}, false);

var prev = document.getElementById("prev");
prev.addEventListener("click", function(e){
  rendition.prev();
  e.preventDefault();
}, false);

var keyListener = function(e){
  // Left Key
  if ((e.keyCode || e.which) == 37) {
    rendition.prev();
  }
  // Right Key
  if ((e.keyCode || e.which) == 39) {
    rendition.next();
  }
};
rendition.on("keyup", keyListener);
document.addEventListener("keyup", keyListener, false);

rendition.on("rendered", function(section){
  var nextSection = section.next();
  var prevSection = section.prev();

  if(nextSection) {
    next.textContent = "›";
  } else {
    next.textContent = "";
  }
  if(prevSection) {
    prev.textContent = "‹";
  } else {
    prev.textContent = "";
  }
});


window.addEventListener("unload", function () {
  console.log("unloading");
  this.book.destroy();
});

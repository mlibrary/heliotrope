//HELIO-5155 a little performance improvement for monograph full cover loading
// we don't want them blocking a page load, so we schedule them to load during idle time or after the page has fully loaded

(function() {
  var cleanup;

  function initializeCover() {
    if (cleanup) cleanup();

    var modal = document.getElementById('modalImage');
    if (!modal) return;

    var image = modal.querySelector('img[data-cover-src]');
    if (!image) return;

    var status = modal.querySelector('.cover-image-status');
    var idleId;
    var timerId;
    var loading = image.hasAttribute('src');
    var failed = false;

    function cancelScheduledLoad() {
      window.removeEventListener('load', scheduleLoad);
      if (idleId !== undefined) window.cancelIdleCallback(idleId);
      if (timerId !== undefined) window.clearTimeout(timerId);
      idleId = timerId = undefined;
    }

    function showStatus(message) {
      status.textContent = message;
      status.hidden = false;
      modal.setAttribute('aria-busy', 'true');
    }

    function loaded() {
      failed = false;
      image.hidden = false;
      status.hidden = true;
      status.textContent = '';
      modal.setAttribute('aria-busy', 'false');
    }

    function loadFailed() {
      failed = true;
      image.hidden = true;
      showStatus(status.dataset.errorMessage);
      modal.setAttribute('aria-busy', 'false');
    }

    function loadCover() {
      cancelScheduledLoad();
      if (loading && !failed) return;

      loading = true;
      failed = false;
      showStatus(status.dataset.loadingMessage);
      image.setAttribute('src', image.dataset.coverSrc);
    }

    function scheduleLoad() {
      cancelScheduledLoad();
      if (loading) return;

      if (window.requestIdleCallback) {
        idleId = window.requestIdleCallback(loadCover, { timeout: 2000 });
      } else {
        timerId = window.setTimeout(loadCover, 0);
      }
    }

    image.addEventListener('load', loaded);
    image.addEventListener('error', loadFailed);
    $(modal).on('show.bs.modal.fulcrumCover', loadCover);
    $(modal).on('shown.bs.modal.fulcrumCover', function() {
      modal.querySelector('#modalClose').focus();
    });

    cleanup = function() {
      cancelScheduledLoad();
      image.removeEventListener('load', loaded);
      image.removeEventListener('error', loadFailed);
      $(modal).off('.fulcrumCover');
      cleanup = undefined;
    };

    if (loading) {
      if (image.complete) {
        if (image.naturalWidth > 0) loaded();
        else loadFailed();
      } else {
        showStatus(status.dataset.loadingMessage);
      }
    } else if (document.readyState === 'complete') {
      scheduleLoad();
    } else {
      window.addEventListener('load', scheduleLoad);
    }
  }

  $(document).on('turbolinks:load', initializeCover);
  $(document).on('turbolinks:before-visit turbolinks:before-cache', function() {
    if (cleanup) cleanup();
  });
  $(function() {
    if (typeof Turbolinks === 'undefined' || !Turbolinks.supported) initializeCover();
  });
})();

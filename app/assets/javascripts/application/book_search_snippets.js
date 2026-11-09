$(document).on('turbolinks:load', function() {
  document.querySelectorAll('.book-search-snippets[data-snippets-url]').forEach(async function(section) {
    if (section.dataset.loading) return;
    section.dataset.loading = 'true';

    try {
      const response = await fetch(section.dataset.snippetsUrl, { headers: { Accept: 'application/json' } });
      if (!response.ok) throw new Error('Snippet request failed: ' + response.status);
      const data = await response.json();
      const list = section.querySelector('.book-search-samples');
      list.replaceChildren();

      data.snippets.forEach(function(snippet) {
        const item = document.createElement('li');
        const page = document.createElement('span');
        page.className = 'book-search-page';
        page.textContent = section.dataset.pageLabel + ' ' + snippet.page_number;
        const text = document.createElement('p');
        text.className = 'book-search-excerpt';
        // The endpoint HTML-encodes source text and allows only attribute-free <mark> tags.
        text.innerHTML = snippet.highlight;
        item.append(page, text);
        list.appendChild(item);
      });

      section.hidden = data.snippets.length === 0;
      section.removeAttribute('data-snippets-url');
    } catch (error) {
      console.error('Unable to load book search samples', error);
      const message = section.querySelector('.book-search-error');
      message.textContent = section.dataset.errorMessage;
      message.hidden = false;
      section.hidden = false;
      delete section.dataset.loading;
    }
  });
});

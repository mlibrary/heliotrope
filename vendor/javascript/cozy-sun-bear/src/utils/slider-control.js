export default class SliderControl {
  constructor(input, values, label) {
    this.input = input;
    this.label = label || 'value';
    this.values = values; // Array of discrete values
    this.currentIndex = 0;

    // Find the initial index based on the input's value
    const initialValue = this.input.value;
    this.currentIndex = this.values.findIndex(v => String(v) === initialValue);
    if (this.currentIndex === -1) {
      this.currentIndex = 0; // Default to first value (auto)
    }

    this.wrap();
  }

  wrap() {
    const wrapper = document.createElement('div');
    wrapper.className = 'slider-control';

    // Find the existing reset button (it's a sibling in the same parent)
    const resetBtn = this.input.previousElementSibling;

    const decreaseBtn = document.createElement('button');
    decreaseBtn.className = 'slider-button button--sm';
    decreaseBtn.innerHTML = '<i class="icon-minus oi" data-glyph="minus" aria-hidden="true"></i>';
    decreaseBtn.type = 'button';
    decreaseBtn.setAttribute('aria-label', `Decrease ${this.label}`);

    const increaseBtn = document.createElement('button');
    increaseBtn.className = 'slider-button button--sm';
    increaseBtn.innerHTML = '<i class="icon-plus oi" data-glyph="plus" aria-hidden="true"></i>';
    increaseBtn.type = 'button';
    increaseBtn.setAttribute('aria-label', `Increase ${this.label}`);

    // Convert the input to a range slider
    this.input.type = 'range';
    this.input.min = '0';
    this.input.max = String(this.values.length - 1);
    this.input.step = '1';
    this.input.value = String(this.currentIndex);

    // Insert wrapper before the input
    this.input.parentNode.insertBefore(wrapper, this.input);

    // Add elements in order: reset, minus, slider, plus
    if (resetBtn && resetBtn.classList.contains('reset-text-options')) {
      wrapper.appendChild(resetBtn);
    }
    wrapper.appendChild(decreaseBtn);
    wrapper.appendChild(this.input);
    wrapper.appendChild(increaseBtn);

    decreaseBtn.addEventListener('click', () => this.decrease());
    increaseBtn.addEventListener('click', () => this.increase());

    // Update when slider changes
    this.input.addEventListener('input', () => {
      this.currentIndex = parseInt(this.input.value);
      this.updateDisplay();
    });

    // Initial display update
    this.updateDisplay();
  }

  decrease() {
    if (this.currentIndex > 0) {
      this.currentIndex--;
      this.input.value = String(this.currentIndex);
      this.updateDisplay();
      this.input.dispatchEvent(new Event('input', { bubbles: true }));
      this.input.dispatchEvent(new Event('change', { bubbles: true }));
    }
  }

  increase() {
    if (this.currentIndex < this.values.length - 1) {
      this.currentIndex++;
      this.input.value = String(this.currentIndex);
      this.updateDisplay();
      this.input.dispatchEvent(new Event('input', { bubbles: true }));
      this.input.dispatchEvent(new Event('change', { bubbles: true }));
    }
  }

  updateDisplay() {
    // Store the actual value as a data attribute
    this.input.dataset.actualValue = this.values[this.currentIndex];

    // Update aria attributes
    this.input.setAttribute('aria-valuenow', String(this.currentIndex));
    this.input.setAttribute('aria-valuetext', String(this.values[this.currentIndex]));
  }

  getValue() {
    return this.values[this.currentIndex];
  }
}



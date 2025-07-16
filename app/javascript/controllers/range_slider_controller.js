import { Controller } from "@hotwired/stimulus"
import noUiSlider from 'nouislider'
import wNumb from 'wnumb'

// Connects to data-controller="range-slider"
export default class extends Controller {
  static targets = [ "slider", "currentMin", "currentMax" ]
  static values = {
    min: Number,
    max: Number
  }

  connect() {
    this.slider = noUiSlider.create(this.sliderTarget, {
      range: {
        min: this.minValue,
        max: this.maxValue,
      },
      start: [2, 8],
      step: 1,
      connect: [false, true, false],
      tooltips: [
        wNumb({ decimals: 0 }),
        wNumb({ decimals: 0 })
      ]
    });

    this.slider.on('update', (values, handle, unencoded) => {
      const target = [
        this.currentMinTarget,
        this.currentMaxTarget
      ][handle];

      target.value = Math.round(unencoded[handle]);

      target.dispatchEvent(new CustomEvent('input', { bubbles: true }));
    })
  }

  disconnect() {
    this.slider.destroy();
  }
}

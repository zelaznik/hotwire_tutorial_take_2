import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  connect() {
    this.element.style.animation = "fade-in-quickly-and-out-slowly 4s";
    setTimeout(() => {
      this.element.remove();
    }, 4_000);
  }
}

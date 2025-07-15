import { Controller } from "@hotwired/stimulus"
import debounce from "debounce";

DEBOUNCABLE_TYPES = [
  'color',
  'date',
  'datetime-local',
  'email',
  'month',
  'number',
  'password',
  'range',
  'search',
  'tel',
  'text',
  'time',
  'url',
  'week'
]

// Connects to data-controller="form"
export default class extends Controller {
  initialize() {
    this._submitText = debounce((e) => this._submit(), 350);
  }

  submit(e) {
    var target = (e && e.target) || {};
    var tagName = target.tagName || '';
    if (tagName.match(/input/i) && DEBOUNCABLE_TYPES.indexOf(target.type) > -1) {
      this._submitText();
    } else {
      this._submit();
    }
  }

  _submit() {
    this.element.requestSubmit();
  }
}

class App {
  // controls the application
  constructor() {
    this.main = document.querySelector('main');
    this.compiler();
    this.renderAll();
    this.listener(document.body, this.handler.bind(this));
    this.lookup();
  }

  selectors() {
    this.selected = document.querySelector('#selected-letters');
    this.message = document.querySelector('#message');
    this.score = document.querySelector('#score');
    this.wordList = document.querySelector('.word_list');
    this.container = document.querySelector('.container');
  }

  compiler() {
    this.templates = {};
    let handles = document.querySelectorAll("[type='text/handlebars']");
    handles.forEach(temp => {
      this.templates[temp.id] = Handlebars.compile(temp.innerHTML);
    });
  }

  renderAll() {
    this.main.innerHTML = '';

    fetch(document.URL + "api")
    .then(resp => {
      let data = resp.json();

      Object.values(this.templates).forEach(func => {
        this.main.insertAdjacentHTML('beforeend', func(data));
      });

      this.selectors();
    });
  }

  listener(element, callback) {
    element.addEventListener('click', event => {
      event.preventDefault();
      callback(event);
    });
  }

  handler(event) {
    let form = event.target.closest('form');
    if (form) {
      fetch(form.action, {method: form.method})
      .then(resp => resp.text())
      .then(text => this.method[form.className](text, form));
    } 
  }

  lookup() {
    this.method = {
      'new_puzzle': this.newPuzzle.bind(this),
      'shuffle': this.shuffle.bind(this),
      'enter': this.enter.bind(this),
      'delete': this.delete.bind(this),
      'puzzle': this.addLetter.bind(this),
    }
  }

  addLetter(_, form) {
    let button = form.firstElementChild;
    let value = button.value;
    let text = this.selected.innerText;
    this.selected.innerText = text + value;
  }

  reset() {
    this.selected.innerText = '';
  }

  newPuzzle() {
    this.renderAll();
  }

  shuffle(resp) {
    let pieces = document.querySelectorAll('.puzzle-piece');
    pieces.forEach(piece => piece.remove());
    let data = JSON.parse(resp);
    let shuffled = this.templates['pieces-temp'](data);
    this.container.insertAdjacentHTML('afterend', shuffled);
  }

  flash({ score, message, winning_score, word_list, total }) {
    let pts = score ? `+${score}` : '';

    this.message.innerText = `${pts} ${message}`;
    this.score.innerText = `${total} / ${winning_score} pts`
    this.wordList.innerText = `${word_list.join(', ')}`
  }

  enter(resp) {
    let data = JSON.parse(resp);
    this.flash(data);
    this.reset();
    $("#message").fadeIn(500).delay(4000).fadeOut(500);
  }

  delete(resp) {
    let text = this.selected.innerText;
    this.selected.innerText = text.slice(0, -1);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  new App;
});


#import "utils/utils.typ": empty-object, methods, is-sequence

// touying pause mark
#let pause = [#"<touying-pause>"]

// touying slide counter
#let slide-counter = counter("touying-slide-counter")
#let last-slide-counter = counter("touying-last-slide-counter")
#let last-slide-number = locate(loc => last-slide-counter.final(loc).first())

// parse a sequence into content, and get the repetitions
#let _parse-content-with-pause(self: empty-object, base: 1, index: 1, it) = {
  // get cover function from self
  let cover = self.cover
  // if it is a function, then call it with self, uncover and only
  if type(it) == function {
    // register the methods
    self.methods.uncover = (self: empty-object, i, uncover-cont) => if i == index { uncover-cont } else { cover(uncover-cont) }
    self.methods.only = (self: empty-object, i, only-cont) => if i == index { only-cont }
    it = it(self)
  }
  // repetitions
  let repetitions = base
  // parse the content
  let uncover-arr = ()
  let cover-arr = ()
  if is-sequence(it) {
    for child in it.children {
      if child == pause {
        repetitions += 1
      } else {
        if repetitions <= index {
          uncover-arr.push(child)
        } else {
          cover-arr.push(child)
        }
      }
    }
  } else {
    uncover-arr.push(it)
  }
  return (uncover-arr.sum(default: []) + if cover-arr.len() > 0 { cover(cover-arr.sum()) }, repetitions)
}

// touying-slide
#let touying-slide(self: empty-object, repeat: auto, body) = {
  // update counters
  let update-counters = {
    slide-counter.step()
    if self.freeze-last-slide-number == false {
      last-slide-counter.step()
    }
  }
  // for speed up, do not parse the content if repeat is none
  if repeat == none {
    return {
      let header = self.page-args.at("header", default: none) + update-counters
      set page(..self.page-args, header: header)
      body
    }
  }
  // for single page slide, get the repetitions
  if repeat == auto {
    let (_, repetitions) = _parse-content-with-pause(
      self: self,
      base: 1,
      index: 1,
      body,
    )
    repeat = repetitions
  }
  // render all the subslides
  let result = ()
  let current = 1
  for i in range(1, repeat + 1) {
    let (cont, _) = _parse-content-with-pause(self: self, index: i, body)
    // update the counter in the first subslide
    let header = self.page-args.at("header", default: none)
    if i == 1 {
      header += update-counters
    }
    result.push(page(..self.page-args, header: header, cont))
  }
  // return the result
  result.sum()
}

// build the touying singleton
#let s = {
  let self = empty-object + (
    // cover function, default is hide
    cover: hide,
    // handle mode
    handout: false,
    // freeze last slide counter
    freeze-last-slide-number: false,
    // page args
    page-args: (
      paper: "presentation-16-9",
      header: none,
      footer: align(right, slide-counter.display() + " / " + last-slide-number),
    )
  )
  // register the methods
  self.methods.touying-slide = touying-slide
  self.methods.init = (self: empty-object, body) => {
    set text(size: 20pt)
    body
  }
  self.methods.freeze-last-slide-number = (self: empty-object) => {
    self.freeze-last-slide-number = true
    self
  }
  self
}
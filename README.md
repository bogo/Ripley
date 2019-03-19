<p align="center">
    <img src="Resources/ripley_screenshot.png" width="528" max-width="90%" alt="Ripley" />
</p>

**Ripley** is a tiny REPL toolkit for Swift Playgrounds for iPad. It provides three public types:
 - `RipleyEngine` - a protocol allowing you to power Ripley with an Eval of your implementation,
 - `RipleyTheme` - a simple struct defining how Ripley should look like,
 - `RipleyViewController` - a Terminal-style view controller you can use for Read and Print operations.

## Usage

To start playing with Ripley, check out this repository on your iPad (e.g. via [Working Copy](https://workingcopyapp.com)) and use Swift Playgrounds "Locations" button to open the `Ripley.playground` via Files.app. There is not much configuration necessary - simply add a 

## Background

I decided to travel for my most recent vacation with just an iPad. It so happened, that during my trip Bali was both [celebrating Nyepi](https://en.m.wikipedia.org/wiki/Nyepi) and having three days of constant rain. Stuck in a hotel bar, I started working through [Build Your Own Lisp](http://buildyourownlisp.com) and [Crafting Interpreters](http://craftinginterpreters.com). Keeping the little Lisp apps as strings got old really quick, so Ripley is one of the outcomes.

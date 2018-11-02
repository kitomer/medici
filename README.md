# medici
Self-hosted hub for multimedia streaming and social interaction among friends and family

## Status

Instable. Do not use.

## What is medici?

Medici is a server with a web-based user interface that manages the media collection and social interaction of a small
group of people (amount depends on server hardware).
The target audience of the medici user interface are inexperienced users.
It can either be self-hosted (on your local or remote server) or rented pre-installed by a cloud service provider.
Though in order to self-host medici you need some Linux software installation and server maintenance skills
(but it is no rocket science either).

## Features

- manage multimedia items (videos, images, documents, text) in collections (distinct) and "piles" (arbitrary and hierarchical)
- support for streaming via HTML5, no plugins required (uses MPEG-DASH or HLS to cover all modern devices natively)
- manage social profiles and groups including calendar with events, articles and shared media
- supports downloading media from various sources in the background to the personal media storage (uses youtube-dl)

## Setup

    $ git clone https://github.com/kitomer/medici.git
    $ cd medici-master/
    $ sudo cpan Mojolicious Mojo::SQLite Mojolicious::Plugin::FormFieldsFromJSON Mojolicious::Plugin::Authentication
    $ morbo scripts/medici

## Dependencies

- Perl 5
- SQLite
- Mojolicious Perl web framework with the extensions Mojo::SQLite

## Roadmap

The next release is 1.0 with no specific due date. 

*Estimated delivery of 1.0 is the 1st of April 2019.*

## Organization

### Versioning

Every release version has a major and minor version number.
After version 1.0 there will be four releases scheduled each year (1.1., 1.4., 1.7., 1.10.)
each incrementing the major and/or minor version number.

The size of the version step
indicates the size of the changes: Major version number increment indicates a bunch of
new features or big refactorings whereas minor version number increment indicates small
bug fixes and changes.

### People

- maintainers: kitomer

### Task planning

The things to be done are noted inside the TASKS.md file by the module maintainers.
Any ideas, bugs or other topic discussions are done using the GitHub issues ui.

## Ways to contribute

- donate some money to make time for development
- create some GitHub issues, e.g. bug reports, feature ideas etc.
- grab a task from the task list in TASKS.md by adding yourself to it (using a pull request)



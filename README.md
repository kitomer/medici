# medici
Self-hosted hub for multimedia streaming and social interaction among friends and family

## Status

Instable. Do not use.

## Features

- manage multimedia items (videos, images, documents, text) in collections (distinct) and "piles" (arbitrary and hierarchical)
- support for streaming via HTML5, no plugins required (uses MPEG-DASH or HLS to cover all modern devices natively)
- manage social profiles and groups including calendar with events, articles and shared media
- supports downloading media from various sources in the background to the personal media storage (uses youtube-dl)

## Setup

    $ git clone https://github.com/kitomer/medici.git
    $ cd medici-master/
    $ sudo cpan Mojolicious Mojo::SQLite
    $ morbo scripts/medici

## Dependencies

- Perl 5
- SQLite
- Mojolicious Perl web framework with the extensions Mojo::SQLite


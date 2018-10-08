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

## Shortterm roadmap

- Implement functionality to manage media collections, items and piles
- Implement background downloads of media using youtube-dl.
- Implement functionality to manage social communities, profiles and groups.
- Implement streaming of media items using HTML5 with MPEG-DASH and HLS.
- Refine user interface to improve the user experience.
- Provide a hosted demo installation
- Create a website where medici is actually used to manage a real community.
- Have a first release candidate and release (1.0).

## Longterm roadmap

- Provide a bookmarklet (at least for Firefox, Chrome and iOS browser) for adding urls to the background downloader.
- Wrap the medici user interface in a small native mobile application (probably for desktop, too).
- Be installable from the CentOS package manager.
- Support other Linux distributions and their package managers.
- Provide complete OS images (maybe even container formats like Docker) with pre-installed medici.
- Provide hosted installations of medici.
- Have a testsuite that is run before every release.

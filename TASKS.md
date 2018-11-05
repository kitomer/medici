# Tasks

This summarizes what is to be done. Any details regarding specific tasks
can be found in the tasks directory in dedicated files for ecah task
(filename is the task id).

## Shortterm / high priority tasks for 1.0 release

### Implement functionality to manage media collections, items and piles

#### Mockup design work

- Insert foldable area below detail (video/image play area), bg is a bit brighter

- Pagination mockup
	- basic functions: go to start, go to end, go to next, go to previous, go forward/backward big amount
	- "big" is ~5-10% of total pages
	- nav links: "|<" "<<" "<" "Page x of n" ">" ">>" ">|"
	- design: just plain icons and text (no bg, no border), 
		hover is bright color, current page and total pages is emphasized
	- disable buttons that make no sense
	- mouse-over reveals info above (like a tooltip)

- Realistic placeholders and correct links in templates
	(the view is always a list of elements with one optional detail on top, which is
	all created by the CRUD function)
	- links:
		"SIGN IN/UP" -> login/register dialog (must CHOOSE)
		"MEDIA" -> list of piles of the current user (must be logged in)
			/media
			+ paths needed to generate PARTS of the view, e.g.
				/search?short=1 -> shortlist html
		"SOCIAL" -> list of groups of the user (must be logged in)
			/social
			+ paths needed to generate PARTS of the view, s.a.
				...

- Sign in/up mockup: dialog popup (single form)
	- single form for login and register

- Search help popup dialog
	- ONE SINGLE search field at the top, SEARCH HELP open up in a dialog

#### Common CRUD logic

- Impl. params of crud( $fixed, $dynamic, $defaults ) prinzipien:
	-> the 3 sets of parameters control the behaviour:
			$fixed are ALWAYS used, $dynamic params are tried and if not supplied, $defaults params are used
	-> internally all known parameters have internal defaults as well (which are used as a last resort)
	-> SOME parameters can only be set fixed (e.g. templates etc.)
	-> templates fallbacks: mojos std. render fkt. is used (uses either embedded or file templates)
	-> there is a template-name-fallback in place to have all kinds of templates (from very generic to very specific)

- Crud: <table> -> <div>

- Move the static template parts into crud() and use them there

- Create controllers: Medici::Controller::LaPage mit oui() = main view (start-page and detail!)
	- params:
			short=1 = create html without the surrounding page
			q=... = the query
	- default layout -> extract areas and their content into placeholders and sub-templates (load by controller)
	- central area:
		- OPTIONAL single thing/detail at the top (CONTRACTED view, can be EXPANDED)
		- LIST of more search results at the bottom (paginated, page navi is at the top), loads IN-PLACE!
		- SHORTLIST of related items on the right (updated whenever single one changes!)
	- the ui is same for public and private users: when one part of the ui cannot be loaded
		due to auth probs, ONE login-info-text is displayed CENTRALLY (opens dialog)
	- all links work as full-page-loads, EXCEPT: login/register (same form), help (context-sensitive)
	- the view is the SAME for a single or multiple items!
	- parse query syntax into datastructure
		- query syntax:
				bla blub			= OR combined textual filter
				bla
				"bla blo"
				.uid=bla				= filter on specific field
				*media				= only media tables
				*collection		= only collections
				*<more>				= filter other things (e.g. profiles etc.)
			--- default sorting is by relevance (a suitable cut-off threshold is chosen automatically)
				:newest				= newer stuff is becoming more relevant
				:popular			= popular stuff is becoming more relevant
				:new   				= newer stuff is becoming more relevant
					-> sidenav "New"
				:popular			= popular stuff is becoming more relevant (all time popular)
					-> sidenav "Start"
				:trending			= pupular in the recent time ("hot")
					-> sidenav "Trending"
				:favs 				= eigener pile
					-> shortcut for *pile .
				:topcat				= most popular piles
					-> sidenav "Top Categories" aber nur die Namen der Piles
					-> shortcut for *pile #popular

				???
				/sort=field		= sort by given field
				/only=table		= limit the searched "things", e.g. "media", "collection" etc.

- Startpage controller setup paths -> gehen alle auf LaPage::oui()
		paths to crud lists/newforms/edits of each of the managed items:
			/communities
			/groups
			/profiles
			/collections
			/piles
			/items

- ? List existing media_item records at /, optional filter ?q=bla enhancement
- ? Add some signatures to Model::Media::Collection enhancement
- ? Add some signatures to Model::Media::Item enhancement
- ? Add some signatures to Model::Media::Pile enhancement
- ? Show single media_item at /item/<uid> enhancement

### Implement background downloads of media using youtube-dl.

- ? Setup Minion queue for background tasks enhancement
- ? Implement simple class Medici::Downloader, uses youtube-dl enhancement
- ? Show simple form at /enqueue, paste url, on submit adds to background queue enhancement
- ? Process download, check db, download(), when done create meta_item record enhancement

### Implement functionality to manage social communities, profiles and groups.

- ? Add some signatures to Model::Social::Community enhancement
- ? Add some signatures to Model::Social::Profile enhancement
- ? Add some signatures to Model::Social::Group enhancement
- ? Show single profile at /profile/<uid> enhancement

### Implement rights management

- Check/finish ACL::* functions
	- s. https://github.com/alexanderBendo/Experiments/blob/master/exp0001/mojolicious-auth-session.pl

- ? Implement controller for user authentication enhancement
- ? Create template for login form and make accessable via /login enhancement
- ? Create form for registering and make accessable via /register enhancement
- ? Implement /logout enhancement
- ? Show login status and links in main layout template enhancement
- ? Turn each ACL pseudocode into a proper Perl function enhancement
- ? Add ACL checks to Model::* functions, on error return fake data enhancement

### Implement streaming of media items using HTML5 with MPEG-DASH and HLS.

### Refine user interface to improve the user experience.

### Provide a hosted demo installation

### Create a website where medici is actually used to manage a real community.

### Have a first release candidate and release (1.0).



## Longterm / low priority tasks for releases after 1.0

### Provide a bookmarklet (at least for Firefox, Chrome and iOS browser) for adding urls to the background downloader.

### Wrap the medici user interface in a small native mobile application (probably for desktop, too).

### Be installable from the CentOS package manager.

### Support other Linux distributions and their package managers.

### Provide complete OS images (maybe even container formats like Docker) with pre-installed medici.

### Provide hosted installations of medici.

### Have a testsuite that is run before every release.



















# Tasks

This summarizes what is to be done. Any details regarding specific tasks
can be found in the tasks directory in dedicated files for ecah task
(filename is the task id).

## Shortterm tasks / High priority

### Implement functionality to manage media collections, items and piles

- List existing media_item records at /, optional filter ?q=bla enhancement
- Add some signatures to Model::Media::Collection enhancement
- Add some signatures to Model::Media::Item enhancement
- Add some signatures to Model::Media::Pile enhancement
- Show single media_item at /item/<uid> enhancement

### Implement background downloads of media using youtube-dl.

- Setup Minion queue for background tasks enhancement
- Implement simple class Medici::Downloader, uses youtube-dl enhancement
- Show simple form at /enqueue, paste url, on submit adds to background queue enhancement
- Process download, check db, download(), when done create meta_item record enhancement

### Implement functionality to manage social communities, profiles and groups.

- Add some signatures to Model::Social::Community enhancement
- Add some signatures to Model::Social::Profile enhancement
- Add some signatures to Model::Social::Group enhancement
- Show single profile at /profile/<uid> enhancement

### Implement rights management

- Implement controller for user authentication enhancement
- Create template for login form and make accessable via /login enhancement
- Create form for registering and make accessable via /register enhancement
- Implement /logout enhancement
- Show login status and links in main layout template enhancement
- Turn each ACL pseudocode into a proper Perl function enhancement
- Add ACL checks to Model::* functions, on error return fake data enhancement

### Implement streaming of media items using HTML5 with MPEG-DASH and HLS.

### Refine user interface to improve the user experience.

### Provide a hosted demo installation

### Create a website where medici is actually used to manage a real community.

### Have a first release candidate and release (1.0).



## Longterm tasks / Low priority

### Provide a bookmarklet (at least for Firefox, Chrome and iOS browser) for adding urls to the background downloader.

### Wrap the medici user interface in a small native mobile application (probably for desktop, too).

### Be installable from the CentOS package manager.

### Support other Linux distributions and their package managers.

### Provide complete OS images (maybe even container formats like Docker) with pre-installed medici.

### Provide hosted installations of medici.

### Have a testsuite that is run before every release.



# Reposearch #

Visit the live demo we use ourselves:

[codefinder.org](http://www.codefinder.org)

## Description ##

Reposearch is a powerful source code search web application, making it really easy to look up code examples, implementation details, exception messages, ...

In reposearch, mulitple projects can be added, each project having one or more repository locations assigned. It currently supports SVN, GitHub urls and uploaded Zip-files as repository location.

Reposearch will index all source code files of the HEAD revision that can be found under the repository locations.

### Search features ###

 - Searching within a single or all projects
 - Type-ahead suggestions (aka autocompletion) based on all identifiers found within a single project
 - Search modes:
  - exact (match query terms in exact order) / free order or terms
  - case sensitive / insensitive search
 - Filtering on:
  - file extension
  - repository location
  - defined language constructs
 - Search results:
  - show fragments that are relevant to the user query
  - show the query terms highlighted
  - have code highlighting
  - allow you to browse to the full file
  - allow you to browse to a specific line number in the full file
 - Links are shareable

### Management features ###
 - Administrator account
  - Currently only a single administrator account is supported
  - Multiple email addresses can be setup for retrieval of project requests (submitted by users of Reposearch)
 - Projects
  - Add/Remove a project
  - Enable/disable language construct filters
 - Repositories
  - Add/Remove a repository location to/from a project
  - Force update to HEAD
  - Force a fresh checkout 
 - Language constructs:
  - Add/Remove/Edit a language construct definition
  - A language construct consists of:
   - a name (e.g. `Java class declaration`)
   - a filter on file extension (seperated by comma or whitespace e.g. `txt, md`)
   - a selection of projects to enable a language construct for
   - a regex pattern that matches the targeted language construct (e.g. `(class|interface)\s+([a-zA-Z]+)`)
   - the matching group that represents the searchable term (e.g. `2` in the above example)
 - Repository update scheduler
  - Set the interval at which Reposearch should try to update all repostories to HEAD (12 hours by default)
  - Set the next timestamp at which Reposearch should try to update all repostories to HEAD
  - Controls to force update-to-HEAD / checkout for all repositories at once
 - Frontpage message can be edited (markdown syntax)
 - Search statistics: weekly and total number of searches can be viewed for each project.

## Installation ##

### Build the project ###
Currently, we cannot provide a ready-to-deploy war file of reposearch. You need to build your own using WebDSL:

#### Setup webdsl environment (Eclipse) ####
Make sure you have the latest webdsl eclipse plugin installed. We recommend using Eclipse 3.7.

 1. Install webdsl using the update site `http://webdsl.org/update/nightly` (in eclipse: help->install new software)
 2. Uncheck 'group items by category', check 'contact all update sites during install to find required software'
 3. Select both WebDSL and Spoofax/IMP to be installed
 4. Complete the installation wizard

#### Import reposearch and configure user settings ####
 1. Now, import the reposearch project into eclipse (if asked, it may be imported as general project)
 2. Right click the project name in the project/package explorer and click: 'convert to webdsl project'
 3. Fill in your database/mail/servlet settings, this will generate the application.ini file for you which is used for compilation of a WebDSL project
 4. To enable statistics about the index size, number of executed queries and slowest queries, please add `searchstats=true` to the application.ini file (in the project root folder).

#### Optional: Change google analytics code ####
We currently have our google analytics script inserted into the application code.
The function gAnalytics(), which can be found in [reposearch.app](https://github.com/webdsl/reposearch/blob/master/reposearch.app) , is used to add it to each page. You may want to adapt this code to a different analytics account, or just remove it by returning an empty String instead.
Our analytics profile is setup to ignore other domains than codefinder.org, so it won't do any harm if you leave it like that.

#### Build and run ####
You can now build Reposearch, which will be deployed to the servlet engine as configured in the application.ini file.

### Initialize admin user ###

When Reposearch is deployed, go to the website address of the web application followed by `/init` (e.g. `localhost:8080/reposearch/init`). Now setup the administrator account by providing a username and password.

Now you can log in as administrator (the admin login link in footer) and browse to the manage page where you can start adding projects and repositories.

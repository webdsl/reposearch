# Reposearch #

Visit the live demo we use ourselves:

[http://www.webdsl.org/reposearch](webdsl.org/reposearch)

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

## Installation ##

### Build the project ###
Currently, we cannot provide a ready-to-deploy war file of reposearch. You need to build your own using webdsl:

 1. Get the latest version of webdsl, we recommend using Eclipse 3.7 and install webdsl using the update site `down-at-this-moment`
 2. to be continued :)
 3. some more steps here
 4. remove or change the google analytics code js code ...

### Initialize admin user ###

When Reposearch is deployed to a java servlet container (Tomcat 6/7 is guaranteed to work), go to the website address of the web application followed by `/init` (e.g. `localhost:8080/reposearch/init`). Now enter the admin username and password.

Now you can log in as administrator (the admin login link in footer) and browse to the manage page where you can start adding projects and repositories.

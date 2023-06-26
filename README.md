# Git version script for Unix/Windows

You need to have 'sed' and 'git' installed in order for this script to work.


Your git tags must be in format "1.0.123"

1 is major version

0 is minor version

123 is revision number

You can add before this number a string including lowercase, uppercase, '_', '+' and '-', (for example: "Version-0.1.2").

## Usage 
<pre>
  gitversion [git_repo_folder [input_file output_file]]
</pre>
## Usage example:

<pre>
  gitversion . version.h.in version.h
</pre>

Tags replaced in input file:
* **[MAJOR_VERSION]** - the major version number
* **[MINOR_VERSION]** - the minor version number
* **[REVISION]** - the revision number
* **[GIT_TAG_ONLY]** - only the last git tag
* **[GIT_TAG_HASH]** - git hash for the last git tag
* **[COMMITS_SINCE_TAG]** - number of commits since last tag
* **[GIT_CURRENT_TAG]** - git current tag
* **[GIT_CURRENT_HASH]** - the current git tag hash (will be same as GIT_TAG_HASH if the current tag is checked out)
* **[GIT_COMMITS_FLAG]** - Empty or +number_of_commits_since_last_tag
* **[GIT_DIRTY_FLAG]** - Empty or '-dirty' if not synchronized

Copyright (c) 2012 Leif Ringstad, released under the MIT license  
Copyright (c) 2023 Philippe Corbes released under the MIT license

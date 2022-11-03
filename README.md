![GitDataPlugin](https://user-images.githubusercontent.com/63984796/199632803-cf25e244-c92a-4642-a055-392358ff37b6.png)
# GitDataPlugin

A plugin that maintains a copy of your project's user data folder in your project folder so that it may be versioned with git.  This plugin uses the GitHub API to ensure that the most recent version of the user data folder is kept up to date.  The folder that will be copied lies within the user data folder at the local path 'user://GitProjectData/ProjectData'.  Save to that folder and use Godot and Git as usual.

You will need a GitHub personal access token to utilize this plugin.  This is easy to generate here on github.  Go to your profile at the top right and go to Settings > Developer Settings > Personal Access Tokens > Classic.  From there, make a new token and select the first scope repo.

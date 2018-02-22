# Overview

This prints out a Changelog that you can paste into the #releases Slack channel.

Usage steps:

1. If required, install/configure the app as per the Installation section below.
2. Run `bin/changelog` and it'll find the latest PR to master.
3. Paste the output into a text editor
4. Prune out items that are unnecessary or unclear
5. Work through the github master release log and see if any items in the
   changelog output have already been released to Live. If they are, remove them
   from the output.
6. Paste the output into the #releases channel.

The code will automatically find the correct Pull Request ID, but if you want
to override things, you can force the ID with a command like
`PR_ID=999 bin/changelog`

# Installation

1. Install Ruby and run `bundle` in this directory.
2. On the Pivotal UI, go into your profile and get your personal API token
3. On GitHub, go to your settings and create a 'Personal access token',
  giving permissions to 'repo:status', 'repo_deployment', and 'public_repo'
4. Create a .env file that contains the following (see .env.sample for a
  complete list). Set the GITHUB_TOKEN, GITHUB_USERNAME, and PIVOTAL_TOKEN
  parameters appropriately.
```
  GITHUB_COMPANY=BloomAndWild
  GITHUB_REPO=bloomandwild
  GITHUB_TOKEN=
  GITHUB_USERNAME=
  PIVOTAL_ID=1965735
  PIVOTAL_TOKEN=
```

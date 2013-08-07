Description
===========

This cookbook contains the common configuration that Stock Software uses across it's Jenkins servers.

Platforms
=========
- `ubuntu`, tested on `ubuntu-12.04` only

Requirements
============

Jenkins cookbook from realityforge: http://github.com/realityforge/chef-jenkins

Attributes
==========

* `node['jenkins']['config']['admin-email']` - Email address for Jenkins admin.

Recipes
=======


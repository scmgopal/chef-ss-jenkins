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
* `node['jenkins']['config']['infrastructure-repo']` - The name of the repo from where the infrastructure definitions for doing deployments can be loaded.

Recipes
=======


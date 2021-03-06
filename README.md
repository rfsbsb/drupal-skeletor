# Skeletor Install Profile <img  height="30px" width="30px" src="https://cdn.rawgit.com/wiki/myplanetdigital/drupal-skeletor/images/noun_131083_cc.svg" alt="Skeletor"> 

[![Build Status](https://travis-ci.org/myplanetdigital/drupal-skeletor.svg?branch=8.x)](https://travis-ci.org/myplanetdigital/drupal-skeletor)

A skeleton Drupal install profile to set up an appropriate layout for Myplanet's install profile development strategy, striving toward continuous delivery and greater good.

<small>[Skull icon by Andre Cameron](https://thenounproject.com/CrocodileJock/collection/skulls/?oq=skull&cidx=0&i=131083)</small>

## Table of Contents

1. [Build Instructions](#1-build-instructions)
2. [Layout](#2-layout)
3. [Documentation](#3-documentation)
4. [Configuration Management](#4-configuration-management)
5. [Production Build Requirements](#5-production-build-requirements)

## 1. Build Instructions

### Requirements

* PHP 5.6.*
* Drush 8.0.*
* Drupal Console 8.0.*
* Compass 1.0.*

May be useful to get [multiple versions of drush locally](https://www.lullabot.com/articles/switching-drush-versions)

### Building drupal

From the install profile folder:

`bash tmp/scripts/build.sh [ project ] [ path/to/build/docroot ] [ branch ]`

* `[ project ]` - The name of the installation profile that you'll be building. To build default, use drupal-skeletor.
* `[ path/to/build/docroot ]` - Specify the location of the full docroot for the drupal build.
* `[ branch ]` - Specify a branch (or commit) to build. Avoid this parameter for a production build process.

## 2. Layout

We will be attempting to follow [the Drupal 8 installation profile guidelines laid out for 
packaging distributions on drupal.org](https://www.drupal.org/node/2210443).

The rationale being that when we layout our projects according to these
guidelines, we don't need to document as much, and we will also know how
to package our own distribution for drupal.org in the future.

Here's the additional suggested folder structure for the install profile:

    +-modules/
    | +-contrib/        (gitignored - all contrib modules should go here via makefile)
    | +-custom/         (custom modules for the site)
    +-themes/
    | +-contrib/        (gitignored - any contrib themes should go here via makefile)
    | +-custom/         (custom themes for the site)
    +-tmp/              (files used for development. removed during prod builds)
    | +-config/         
    | | +-sync/         (config used to sync across environments)
    | | +-translations/ (translation files)
    | +-patches/
    | +-scripts/        (any scripts related to project)
    | +-snippets/       (text snippets attached to files during the deploy process)
    | | +-htaccess/
    | | +-settings.php/
    | | +-robots.txt/
    | +-travis_scripts/ (travis specific scripts)

* The `tmp/` directory is intended to be removed before pushing to production.

* If you'd like any code to be appended to `settings.php`, `htaccess`, or `robots.txt`, simply add a
snippet as `tmp/snippets/[filename]/mysnippetname.[filename]`. These snippets will be appended in alphabetical order during the build script.

## 3. Documentation

Documentation for this project (and Skeletor based projects) should be placed in their [github
wiki](/wiki).

## 4. Configuration Management

The Configuration Management system provides a consistent API for defining and 
syncing configuration between instances of a Drupal site. [Read more about 
configuration management in our wiki](https://github.com/myplanetdigital/drupal-skeletor/wiki/Setup-&-Working-with-Configuration-Management)

## 5. Production Build Requirements

### Trusted host security setting in Drupal 8

Drupal 8 supports [trusted host patterns](https://www.drupal.org/node/2410395), where you can (and should) 
specify a set of regular expressions that the domains on incoming requests must match. 
It is important to setup them before deploying to ACQUIA or PANTHEON environments.

Trusted host settings location: `tmp/snippets/settings.php/*-trusted-hosts.settings.php` 


